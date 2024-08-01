from opensearchpy import OpenSearch

host = 'localhost'
port = 9200

# Create the client with SSL/TLS and hostname verification disabled.
client = OpenSearch(
    hosts = [{'host': host, 'port': port}],
    http_compress = True, # enables gzip compression for request bodies
    use_ssl = False,
    verify_certs = False,
    ssl_assert_hostname = False,
    ssl_show_warn = False
)

# search for all job logs
response = client.search(index='job_log',size=50)

hits_count = response['hits']['total']['value']
print("Total Job Log Hits: ", hits_count)

first_job = response['hits']['hits'][0]['_source']['kubernetes']['labels']['job-name']

# search for logs of a specific job
query = {
    "query": {
        "match": {
            "kubernetes.labels.job-name": first_job
        }
    },
    "sort": [
        {
            "time": {
                "order": "desc"
            }
        }
    ]
}

response = client.search(index='job_log', body=query, size=50)
hits_count = response['hits']['total']['value']
print("Hits for Job ID", first_job, ":", hits_count)

print("Logs for Job ID", first_job, ":")
for hit in response['hits']['hits']:
    print(hit['_source']['kubernetes']['labels']['job-name'], hit['_source']['time'], hit['_source']['log'])

# search for all workflow logs
response = client.search(index='workflow_log',size=5)

hits_count = response['hits']['total']['value']
print("Total Workflow Log Hits: ", hits_count)

first_wf = response['hits']['hits'][0]['_source']['kubernetes']['labels']['reana-run-batch-workflow-uuid']

# search workflow logs for a specific workflow
query = {
    "query": {
        "match": {
            "kubernetes.labels.reana-run-batch-workflow-uuid": first_wf
        }
    },
    "sort": [
        {
            "time": {
                "order": "desc"
            }
        }
    ]
}

response = client.search(index='workflow_log', body=query, size=50)
hits_count = response['hits']['total']['value']
print("Hits for Workflow ID", first_wf, ":", hits_count)

print("Logs for Workflow ID", first_wf, ":")

for hit in response['hits']['hits']:
    print(hit['_source']['kubernetes']['labels']['reana-run-batch-workflow-uuid'], hit['_source']['time'], hit['_source']['log'])
