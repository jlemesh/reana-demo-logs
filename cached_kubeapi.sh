#!/bin/bash

set -e

reana-dev git-checkout proto_cached_partial_logs_from_kube_api

reana-dev cluster-create -m /var/reana:/var/reana --mode debug --worker-nodes 3
kubectl label nodes kind-worker reana.io/system=infrastructure
kubectl label nodes kind-worker2 reana.io/system=jobs
kubectl label nodes kind-worker3 reana.io/system=jobs

if [ $REANA_CLUSTER_BUILD == 1 ]; then
    reana-dev cluster-build --exclude-components=r-a-krb5,r-a-vomsproxy,r-a-rucio --mode debug --parallel 8
else
    reana-dev kind-load-docker-image --exclude-components=r-a-krb5,r-a-vomsproxy,r-a-rucio
fi

reana-dev cluster-deploy --admin-email john.doe@example.org --admin-password mypwd1 --mode debug -v ../reana-demo-logs/values-dev.yaml
