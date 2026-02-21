#!/bin/bash
TOKEN="4997bf3f-4834-4054-9281-b32da9d9851f"
DEPLOYMENT_ID="13260248-1515-4576-b1e4-45407819d890"

curl -s -X POST https://backboard.railway.com/graphql/v2 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"query { deploymentLogs(deploymentId:\\\"$DEPLOYMENT_ID\\\", limit:100) { message timestamp } }\"}" \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
logs = data['data']['deploymentLogs']
for l in logs:
    print(l['message'])
" 2>&1 | head -80
