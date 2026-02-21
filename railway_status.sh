#!/bin/bash
TOKEN="4997bf3f-4834-4054-9281-b32da9d9851f"
SERVICE_ID="5a33929a-f70b-4971-ad46-88f54cc543c7"
ENV_ID="f40e4776-260c-4eb2-b46e-343b704fbb5a"
PROJECT_ID="cd84274b-b735-436c-9d61-cf24d133f92f"

echo "=== Latest Deployment Status ==="
curl -s -X POST https://backboard.railway.com/graphql/v2 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"query { deployments(first:3, input:{serviceId:\\\"$SERVICE_ID\\\", environmentId:\\\"$ENV_ID\\\"}) { edges { node { id status createdAt } } } }\"}" | python3 -m json.tool
