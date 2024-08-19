#!/bin/bash

set -e

reana-dev git-checkout master
cd $REANA_SRC_DIR/reana-commons
git checkout proto_cached_fluent_logs_from_opensearch
cd $REANA_SRC_DIR/reana-workflow-controller
git checkout proto_fluent_logs_from_opensearch
cd $REANA_SRC_DIR

reana-dev cluster-create -m /var/reana:/var/reana --mode debug --worker-nodes 3
kubectl label nodes kind-worker reana.io/system=infrastructure
kubectl label nodes kind-worker2 reana.io/system=jobs
kubectl label nodes kind-worker3 reana.io/system=jobs

if [ $REANA_CLUSTER_BUILD == 1 ]; then
    reana-dev cluster-build --exclude-components=r-a-krb5,r-a-vomsproxy,r-a-rucio --mode debug --parallel 8
else
    reana-dev kind-load-docker-image --exclude-components=r-a-krb5,r-a-vomsproxy,r-a-rucio
fi

reana-dev cluster-deploy --admin-email john.doe@example.org --admin-password mypwd1 --mode debug

helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update
helm install opensearch opensearch/opensearch \
    -f reana-demo-logs/opensearch.yaml

# Wait for OpenSearch to be ready
kubectl wait --for=condition=ready pod/opensearch-cluster-master-0 --timeout=300s
kubectl wait --for=condition=ready pod/opensearch-cluster-master-1 --timeout=300s
kubectl wait --for=condition=ready pod/opensearch-cluster-master-2 --timeout=300s

kubectl port-forward service/opensearch-cluster-master 9200:9200 &

sleep 1

curl -XPUT "http://localhost:9200/job_log"
curl -XPUT "http://localhost:9200/workflow_log"
curl -XPUT "http://localhost:9200/job_log/_mapping" \
    -H 'Content-Type: application/json' \
    --data "@reana-demo-logs/daemonset/opensearch/job_log_mapping.json"
curl -XPUT "http://localhost:9200/workflow_log/_mapping" \
    -H 'Content-Type: application/json' \
    --data "@reana-demo-logs/daemonset/opensearch/workflow_log_mapping.json"

helm upgrade --install fluent-bit \
    -f reana-demo-logs/daemonset/opensearch/reana-fluentbit-opensearch.yaml \
    fluent/fluent-bit
