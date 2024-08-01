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

client.indices.refresh(index='job_log')

# search for all documents in the 'movies' index
response = client.search(index='job_log',size=50)

for hit in response['hits']['hits']:
    print(hit['_source']['kubernetes']['labels']['job-name'])

# extract the count of hits from the response
hits_count = response['hits']['total']['value']

# print the count of hits
print("Total Hits: ", hits_count)

reana_job = "reana-run-job-0b6b2ef1-1350-46bb-9338-8c3892e5b1ad"
query = {
    "query": {
        "match": {
            "kubernetes.labels.job-name": reana_job
        }
    },
    "sort": [
        {
            "time": {
                "order": "desc"
            }
        }
    ],
    "explain": True
}

# search for documents in the 'movies' index with the given query
response = client.search(index='job_log', body=query, size=50)

# extract the count of hits from the response
hits_count = response['hits']['total']['value']

# print the count of hits
print("Total Hits: ", hits_count)

if hits_count != 0:
    print(response['hits']['hits'][0])

for hit in response['hits']['hits']:
    print(hit['_source']['kubernetes']['labels']['job-name'], hit['_source']['time'], hit['_source']['log'])
