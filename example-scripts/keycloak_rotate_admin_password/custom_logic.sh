# Required environment variables to the custom-server (recommended to pass as secrets):
# API_URL - Keycloak API URL e.g. https://keycloak.mydomain.com
# The Rotated Secret Payload should look like this:
#     { "user": "admin", "password": "currentPassword" }
# For more information, visit https://docs.akeyless.io/docs/create-a-custom-rotated-secret


function run_rotate() {
    PAYLOAD=$(echo "$*" | base64 -d)
    PAYLOAD_VALUE=$(echo "$PAYLOAD" | jq -r .payload)
    NEW_PASSWORD="$(dd bs=1000 count=1 if=/dev/urandom status=none | tr -dc '[:alnum:]' | head -c 10)1xV"

    KCLK_USER=$(echo "$PAYLOAD_VALUE" | jq -r .user)
    KCLK_PASS=$(echo "$PAYLOAD_VALUE" | jq -r .password)

    # Get the access token using Keycloak API
    ACCESS_TOKEN=$(curl -s --data "grant_type=password&client_id=admin-cli&username=$KCLK_USER&password=$KCLK_PASS" \
                    ${API_URL}/auth/realms/master/protocol/openid-connect/token \
                    | jq -r '.access_token')

    # Get the admin user ID using Keycloak API
    USER_ID=$(curl -s -X GET "${API_URL}/auth/admin/realms/master/users?username=admin" \
               --header "Authorization: Bearer $ACCESS_TOKEN" \
               --header 'Content-Type: application/json' \
               | jq -r '.[].id')

    # Reset the admin user's password using Keycloak API
    curl -s -X PUT "${API_URL}/auth/admin/realms/master/users/${USER_ID}/reset-password" \
        --header 'Accept: application/json' \
        --header "Authorization: Bearer $ACCESS_TOKEN" \
        --header 'Content-Type: application/json' \
        --data-raw "{ \"value\": \"$NEW_PASSWORD\", \"temporary\": \"false\" }"

    PAYLOAD_VALUE=$(echo "$PAYLOAD_VALUE" | jq -rc ".password = \"${NEW_PASSWORD}\"")
    PAYLOAD_JSON=$(echo -n "$PAYLOAD_VALUE" | jq -Rsa . | sed -e 's/\\n//g' -e 's/\\t//g')
    PAYLOAD_JSON=$(echo -n "{ \"payload\": $PAYLOAD_JSON }")
    echo -n "$PAYLOAD_JSON"
}
