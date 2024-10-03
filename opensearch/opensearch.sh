#!/bin/bash
#
# This file is part of REANA.
# Copyright (C) 2024 CERN.
#
# REANA is free software; you can redistribute it and/or modify it
# under the terms of the MIT License; see LICENSE file for more details.

set -euo pipefail

# Usage examples:
#
# Local environment with OpenSearch security plugin off:
# ./opensearch.sh
#
# Local environment with OpenSearch security plugin on (kubectl should be installed):
# OPENSEARCH_CN=opensearch-cluster-master.default.svc.cluster.local OPENSEARCH_PROTOCOL=https KUBECTL_CERTS=true ./opensearch.sh
#
# Local environment to remote OpenSearch, with OpenSearch security plugin on (kubectl should be installed):
# OPENSEARCH_CN=opensearch-cluster-master.default.svc.cluster.local OPENSEARCH_HOST=opensearch.cern.ch OPENSEARCH_PROTOCOL=https KUBECTL_CERTS=true ./opensearch.sh
#
# From inside OpenSearch pod, with OpenSearch security plugin on:
# OPENSEARCH_CN=opensearch-cluster-master.default.svc.cluster.local OPENSEARCH_PROTOCOL=https CERTS_FROM_FILE=true ./opensearch.sh
#
# Local environment to remote OpenSearch, with OpenSearch security plugin on:
# OPENSEARCH_HOST=opensearch.cern.ch OPENSEARCH_PROTOCOL=https CERTS_FROM_FILE=true CERT_DIR=. ./opensearch.sh

# OpenSearch address configuration
OPENSEARCH_PROTOCOL="${OPENSEARCH_PROTOCOL:-http}" # http or https
OPENSEARCH_HOST="${OPENSEARCH_HOST:-localhost}"
OPENSEARCH_PORT="${OPENSEARCH_PORT:-9200}"
OPENSEARCH_CN="${OPENSEARCH_CN:-$OPENSEARCH_HOST}" # OpenSearch common name in node's TLS certificate, defaults to OPENSEARCH_HOST
OPENSEARCH_ADDRESS=$OPENSEARCH_PROTOCOL://$OPENSEARCH_CN:$OPENSEARCH_PORT

# Index mapping configuration
JOB_LOG_IDX="${JOB_LOG_IDX:-fluentbit-job_log}"
WORKFLOW_LOG_IDX="${WORKFLOW_LOG_IDX:-fluentbit-workflow_log}"
JOB_LOG_MAPPING_FILE_PATH="${JOB_LOG_MAPPING_FILE_PATH:-job_log_mapping.json}"
WORKFLOW_LOG_MAPPING_FILE_PATH="${WORKFLOW_LOG_MAPPING_FILE_PATH:-workflow_log_mapping.json}"
JOB_LOG_TEMPLATE_FILE_PATH="${JOB_LOG_TEMPLATE_FILE_PATH:-job_log_template.json}"
WORKFLOW_LOG_TEMPLATE_FILE_PATH="${WORKFLOW_LOG_TEMPLATE_FILE_PATH:-workflow_log_template.json}"

# TLS configuration
KUBECTL_CERTS="${KUBECTL_CERTS:-false}" # Use admin certificates from Kubernetes secret; makes cURL use TLS while connecting to OpenSearch
CERTS_FROM_FILE="${CERTS_FROM_FILE:-false}" # Use admin certificates from files; makes cURL use TLS while connecting to OpenSearch
CERT_DIR="${CERT_DIR:-config/certs}" # If CERTS_FROM_FILE is true, the directory where the certificates are stored (files should be named ca.crt, admin.crt and admin.key)
KUBECTL_SECRET_NAME="${KUBECTL_SECRET_NAME:-reana-opensearch-tls-secrets}" # If KUBECTL_CERTS is true, the secret name to use

# Execute cURL when TLS is enabled
curl_exec_secure() {
  curl --connect-to "$OPENSEARCH_CN:$OPENSEARCH_PORT:$OPENSEARCH_HOST" \
    --cacert <(echo "$CACERT") --cert <(echo "$CERT") --key <(echo "$KEY") \
    -H 'Content-Type: application/json' "$@"
  echo ""
}

# Execute cURL when TLS is disabled
curl_exec() {
  curl -H 'Content-Type: application/json' "$@"
  echo ""
}

# Setup indices and mappings
run() {
  exec_fun=$1
  idx=$2
  mapping_file=$3
  template_file=$4

  echo "Create templates:"
  $1 -XPUT "$OPENSEARCH_ADDRESS/_index_template/$idx" \
    --data "@$template_file"

  echo "Check if index $idx exists:"
  response_code=$($1 --head -s -o /dev/null --head -w "%{http_code}" "$OPENSEARCH_ADDRESS/$idx")

  if [[ $response_code -eq 200 ]]; then
    echo "Index $idx exists."
    echo "Create $idx mappings:"
    $1 -XPUT "$OPENSEARCH_ADDRESS/$idx/_mapping" \
      --data "@$mapping_file"

    echo "Update $idx index:"
    $1 -XPOST "$OPENSEARCH_ADDRESS/$idx/_update_by_query"
  fi
}

echo "OpenSearch adderess: $OPENSEARCH_ADDRESS."

# Execute script
if [[ $KUBECTL_CERTS = true ]]; then
    echo "Using certificates from Kubernetes secret."
    CACERT=$(kubectl get secret "$KUBECTL_SECRET_NAME" \
      -ogo-template='{{ index .data "ca.crt" | base64decode }}')
    CERT=$(kubectl get secret "$KUBECTL_SECRET_NAME" \
      -ogo-template='{{ index .data "admin.crt" | base64decode }}')
    KEY=$(kubectl get secret "$KUBECTL_SECRET_NAME" \
      -ogo-template='{{ index .data "admin.key" | base64decode }}')
    run curl_exec_secure "$JOB_LOG_IDX" "$JOB_LOG_MAPPING_FILE_PATH" "$JOB_LOG_TEMPLATE_FILE_PATH"
    run curl_exec_secure "$WORKFLOW_LOG_IDX" "$WORKFLOW_LOG_MAPPING_FILE_PATH" "$WORKFLOW_LOG_TEMPLATE_FILE_PATH"
elif [[ $CERTS_FROM_FILE = true ]]; then
    echo "Using certificates from files."
    CACERT=$(cat "$CERT_DIR"/ca.crt)
    CERT=$(cat "$CERT_DIR"/admin.crt)
    KEY=$(cat "$CERT_DIR"/admin.key)
    run curl_exec_secure "$JOB_LOG_IDX" "$JOB_LOG_MAPPING_FILE_PATH" "$JOB_LOG_TEMPLATE_FILE_PATH"
    run curl_exec_secure "$WORKFLOW_LOG_IDX" "$WORKFLOW_LOG_MAPPING_FILE_PATH" "$WORKFLOW_LOG_TEMPLATE_FILE_PATH"
else
    echo "Not using TLS."
    run curl_exec "$JOB_LOG_IDX" "$JOB_LOG_MAPPING_FILE_PATH" "$JOB_LOG_TEMPLATE_FILE_PATH"
    run curl_exec "$WORKFLOW_LOG_IDX" "$WORKFLOW_LOG_MAPPING_FILE_PATH" "$WORKFLOW_LOG_TEMPLATE_FILE_PATH"
fi

echo "Done."
