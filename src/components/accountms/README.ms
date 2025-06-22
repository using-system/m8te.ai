
TOKEN=$(curl -s -X POST "https://dev-connect.m8te.ai/realms/m8t/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=account" \
  -d "username=user@example.com" \
  -d "password=password" | jq -r '.access_token')

curl -H "Authorization: Bearer $TOKEN" https://dev-api.m8te.ai/api/v1/apikeys