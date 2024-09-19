#!/bin/bash

workflow_count=$1
rate=$2
duration=$3
sleep_time=$4
type=$5

workflow_count="${workflow_count:-40}"
rate="${rate:-1}"
duration="${duration:-90s}"
sleep_time="${sleep_time:-10}"
type="${type:-sc-cached-optimized}"

dir=benchmarks/$type
filename="$dir"/"$workflow_count"-"$rate"-"$duration"

if [ ! -d "$dir" ]; then
    mkdir $dir
fi

function do_benchmark() {
    echo "Submitted: " >> $filename.time
    date >> $filename.time

    echo "sleep..."

    pod_count=$(( $workflow_count * 50 ))

    while [[ $(kubectl get pods | wc -l) -lt $pod_count ]] ; do
        sleep $sleep_time
        echo "Pods:"
        kubectl get pods | wc -l
    done

    echo "attack..."

    output_file="$filename"-"$1".bin

    echo "output file: $output_file"

    echo "Benchmark start: " >> $filename.time
    date >> $filename.time

    vegeta attack -duration $duration -rate $rate -targets reana/helm/configurations/targets.txt -insecure | tee $output_file | vegeta report

    echo "Benchmark end: " >> $filename.time
    date >> $filename.time

    echo "done."

    set -x

    vegeta report -type=json $output_file > $output_file.json
    cat $output_file | vegeta plot > $output_file.html
    cat $output_file | vegeta report -type="hist[0,500ms,1000ms,1500ms,2000ms,2500ms,3000ms,3500ms,4000ms,4500ms,5000ms,5500ms,6000ms,6500ms,7000ms,7500ms,8000ms,8500ms,9000ms,9500ms,10000ms]"

    set +x
}

reana-dev run-example -c r-d-helloworld -w yadage --submit-only --count $workflow_count

echo "Benchmark 1" > $filename.time

do_benchmark "b1"

echo "Benchmark 2" >> $filename.time

do_benchmark "b2"

echo "Benchmark 3" >> $filename.time

do_benchmark "b3"

while [[ $(kubectl get pods | wc -l) -gt 12 ]] ; do
    sleep $sleep_time
    echo "Pods:"
    kubectl get pods | wc -l
done

echo "Completed: " >> $filename.time
date >> $filename.time
