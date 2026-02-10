#!/bin/bash
# Import Kibana dashboards
# Run this after Kibana is up and accessible

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="${NAMESPACE:-elastic-system}"

# Get Kibana password
PASSWORD=$(kubectl get secret logs-es-elastic-user -n $NAMESPACE -o jsonpath='{.data.elastic}' | base64 -d)
KIBANA_SVC="kibana-kb-http.$NAMESPACE.svc:5601"

echo "Importing dashboards to Kibana..."

# Import each ndjson file
for file in "$SCRIPT_DIR"/*.ndjson; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    echo "Importing $filename..."

    kubectl exec -n $NAMESPACE logs-es-default-0 -- curl -sk -u "elastic:$PASSWORD" \
      "https://$KIBANA_SVC/api/saved_objects/_import?overwrite=true" \
      -H "kbn-xsrf: true" \
      -F "file=@-" < "$file"

    echo ""
  fi
done

echo "Dashboard import complete!"
