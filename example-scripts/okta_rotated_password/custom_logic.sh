# Required environment variables to the custom-server (recommended to pass as secrets):
# API_TOKEN - Okta API Token
# API_URL - Okta API URL e.g. https://my-org.okta.com
# The Rotated Secret Payload should look like this:
# { "user_email": "me@mydomain.com", "password": "currentPassword" }
# For more information, visit https://docs.akeyless.io/docs/create-a-custom-rotated-secret

function run_rotate() {
    PAYLOAD=$(echo "$*" | base64 -d)
    PAYLOAD_VALUE=$(echo "$PAYLOAD" | jq -r .payload)
    NEW_PASSWORD="$(dd bs=1000 count=1 if=/dev/urandom status=none | tr -dc '[:alnum:]' | head -c 10)1xV"

    USER_EMAIL=$(echo "$PAYLOAD_VALUE" | jq -r .user_email)
    OLD_PASSWORD=$(echo "$PAYLOAD_VALUE" | jq -r .password)

    USER_ID=$(curl -s -f -X GET -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: SSWS ${API_TOKEN}" "${API_URL}/api/v1/users?filter=profile.login%20eq%20%22${USER_EMAIL}%22" | jq -r '.[].id')

    curl -f -s -X POST -d "{ \"oldPassword\": \"${OLD_PASSWORD}\", \"newPassword\": \"${NEW_PASSWORD}\" }" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: SSWS ${API_TOKEN}" "${API_URL}/api/v1/users/${USER_ID}/credentials/change_password" >/dev/null

    PAYLOAD_VALUE=$(echo "$PAYLOAD_VALUE" | jq -rc ".password = \"${NEW_PASSWORD}\"")
    PAYLOAD_JSON=$(echo -n "$PAYLOAD_VALUE" | jq -Rsa . | sed -e 's/\\n//g' -e 's/\\t//g')
    PAYLOAD_JSON=$(echo -n "{ \"payload\": $PAYLOAD_JSON }")
    echo -n "$PAYLOAD_JSON"
}
