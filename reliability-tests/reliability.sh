#!/bin/bash

sleep_time=10
type=$1

type="${type:-ds}"

dir=reliability_tests/$type

if [ ! -d "$dir" ]; then
    mkdir $dir
fi

############

echo "Testing job eviction..."

reana-dev run-example -c r-d-helloworld -w serial --submit-only --count 1

wf_id=$(reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].id')

echo "Workflow ID: $wf_id"

while [[ $(kubectl get pod -l reana-run-job-workflow-uuid=$wf_id | wc -l) -lt 1 ]] ; do
    sleep $sleep_time
    echo "Pods:"
    kubectl get pod -l reana-run-job-workflow-uuid=$wf_id | wc -l
done

pod_name=$( kubectl get pod -l reana-run-job-workflow-uuid=$wf_id -o jsonpath='{.items[0].metadata.name}')

echo "Pod name: $pod_name"

sleep 20

kubectl evict-pod $pod_name

sleep 20

reana-client logs --workflow helloworld-serial-kubernetes0 > "$dir"/job-eviction.log

if [[ $type == "ds-cached-optimized" || $type == "sc-cached-optimized" || $type == "ka-cached-optimized" ]]; then
    curl "$REANA_SERVER_URL"/api/workflows/helloworld-serial-kubernetes0/job/hello1/log?access_token="$REANA_ACCESS_TOKEN" --insecure >> "$dir"/job-eviction.log
fi

cat "$dir"/job-eviction.log

echo "done."

############

echo "Testing workflow eviction..."

reana-dev run-example -c r-d-helloworld -w serial --submit-only --count 1

wf_id=$(reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].id')

echo "Workflow ID: $wf_id"

while [[ $(kubectl get pod -l reana-run-batch-workflow-uuid=$wf_id | wc -l) -lt 1 ]] ; do
    sleep $sleep_time
    echo "Pods:"
    kubectl get pod -l reana-run-batch-workflow-uuid=$wf_id | wc -l
done

pod_name=$( kubectl get pod -l reana-run-batch-workflow-uuid=$wf_id -o jsonpath='{.items[0].metadata.name}')

echo "Pod name: $pod_name"

sleep 40

kubectl evict-pod $pod_name

sleep 20

reana-client logs --workflow helloworld-serial-kubernetes0 > "$dir"/workflow-eviction.log

if [[ $type == "ds-cached-optimized" || $type == "sc-cached-optimized" || $type == "ka-cached-optimized" ]]; then
    curl "$REANA_SERVER_URL"/api/workflows/helloworld-serial-kubernetes0/job/hello1/log?access_token="$REANA_ACCESS_TOKEN" --insecure >> "$dir"/workflow-eviction.log
fi

cat "$dir"/workflow-eviction.log

echo "done."

############

echo "Testing job OOM..."

reana-dev run-example -c r-d-helloworld -w serial --submit-only --count 1 -p helloworld=code/oom.py

sleep $sleep_time

reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status'

while [[ $(reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status') != "failed" ]] ; do
    sleep $sleep_time
    echo "Status:"
    reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status'
done

reana-client logs --workflow helloworld-serial-kubernetes0 > "$dir"/job-oom.log

if [[ $type == "ds-cached-optimized" || $type == "sc-cached-optimized" || $type == "ka-cached-optimized" ]]; then
    curl "$REANA_SERVER_URL"/api/workflows/helloworld-serial-kubernetes0/job/hello1/log?access_token="$REANA_ACCESS_TOKEN" --insecure >> "$dir"/job-oom.log
fi

cat "$dir"/job-oom.log

echo "done."

############

echo "Testing job exception..."

reana-dev run-example -c r-d-helloworld -w serial --submit-only --count 1 -p helloworld=code/exception.py

sleep $sleep_time

reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status'

while [[ $(reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status') != "failed" ]] ; do
    sleep $sleep_time
    echo "Status:"
    reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status'
done

reana-client logs --workflow helloworld-serial-kubernetes0 > "$dir"/job-exception.log

if [[ $type == "ds-cached-optimized" || $type == "sc-cached-optimized" || $type == "ka-cached-optimized" ]]; then
    curl "$REANA_SERVER_URL"/api/workflows/helloworld-serial-kubernetes0/job/hello1/log?access_token="$REANA_ACCESS_TOKEN" --insecure >> "$dir"/job-exception.log
fi

cat "$dir"/job-exception.log

echo "done."

############

echo "Testing job node crash..."

reana-dev run-example -c r-d-helloworld -w serial --submit-only --count 1

sleep $sleep_time

reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status'

while [[ $(reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status') != "running" ]] ; do
    sleep $sleep_time
    echo "Status:"
    reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status'
done

sleep 20

docker container stop -s SIGKILL kind-worker2

sleep 20

docker container start kind-worker2

sleep 40

reana-client logs --workflow helloworld-serial-kubernetes0 > "$dir"/job-node-crash.log

if [[ $type == "ds-cached-optimized" || $type == "sc-cached-optimized" || $type == "ka-cached-optimized" ]]; then
    curl "$REANA_SERVER_URL"/api/workflows/helloworld-serial-kubernetes0/job/hello1/log?access_token="$REANA_ACCESS_TOKEN" --insecure >> "$dir"/job-node-crash.log
fi

cat "$dir"/job-node-crash.log

echo "done."

############

echo "Testing workflow node crash..."

reana-dev run-example -c r-d-helloworld -w serial --submit-only --count 1

sleep $sleep_time

reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status'

while [[ $(reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status') != "running" ]] ; do
    sleep $sleep_time
    echo "Status:"
    reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status'
done

sleep 20

docker container stop -s SIGKILL kind-worker3

sleep 20

docker container start kind-worker3

sleep 40

reana-client logs --workflow helloworld-serial-kubernetes0 > "$dir"/workflow-node-crash.log

if [[ $type == "ds-cached-optimized" || $type == "sc-cached-optimized" || $type == "ka-cached-optimized" ]]; then
    curl "$REANA_SERVER_URL"/api/workflows/helloworld-serial-kubernetes0/job/hello1/log?access_token="$REANA_ACCESS_TOKEN" --insecure >> "$dir"/workflow-node-crash.log
fi

cat "$dir"/workflow-node-crash.log

echo "done."

############

echo "Testing job node drain..."

reana-dev run-example -c r-d-helloworld -w serial --submit-only --count 1

sleep $sleep_time

reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status'

while [[ $(reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status') != "running" ]] ; do
    sleep $sleep_time
    echo "Status:"
    reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status'
done

sleep 20

kubectl drain kind-worker2 --ignore-daemonsets --delete-emptydir-data

sleep 20

kubectl uncordon kind-worker2

sleep 20

reana-client logs --workflow helloworld-serial-kubernetes0 > "$dir"/job-node-drain.log

if [[ $type == "ds-cached-optimized" || $type == "sc-cached-optimized" || $type == "ka-cached-optimized" ]]; then
    curl "$REANA_SERVER_URL"/api/workflows/helloworld-serial-kubernetes0/job/hello1/log?access_token="$REANA_ACCESS_TOKEN" --insecure >> "$dir"/job-node-drain.log
fi

cat "$dir"/job-node-drain.log

echo "done."

############

echo "Testing workflow node drain..."

reana-dev run-example -c r-d-helloworld -w serial --submit-only --count 1

sleep $sleep_time

reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status'

while [[ $(reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status') != "running" ]] ; do
    sleep $sleep_time
    echo "Status:"
    reana-client status --workflow helloworld-serial-kubernetes0 -v --json | jq -r '.[].status'
done

sleep 20

kubectl drain kind-worker3 --ignore-daemonsets --delete-emptydir-data

sleep 20

kubectl uncordon kind-worker3

sleep 20

reana-client logs --workflow helloworld-serial-kubernetes0 > "$dir"/workflow-node-drain.log

if [[ $type == "ds-cached-optimized" || $type == "sc-cached-optimized" || $type == "ka-cached-optimized" ]]; then
    curl "$REANA_SERVER_URL"/api/workflows/helloworld-serial-kubernetes0/job/hello1/log?access_token="$REANA_ACCESS_TOKEN" --insecure >> "$dir"/workflow-node-drain.log
fi

cat "$dir"/workflow-node-drain.log

echo "done."
