import sys
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
response = client.search(index='fluentd',size=220)

hits_count = response['hits']['total']['value']
print("Total Job Log Hits: ", hits_count)

pod = sys.argv[1]

# search for logs of a specific job
query = {
    "query": {
        "match": {
            "tag": pod
        }
    }
}

response = client.search(index='fluentd', body=query, size=50)
hits_count = response['hits']['total']['value']
print("Hits for Job ID", pod, ":", hits_count)

print("Logs for Job ID", pod, ":")
for hit in response['hits']['hits']:
    print(hit)
