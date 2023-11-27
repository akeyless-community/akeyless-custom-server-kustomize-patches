# The Rotated Secret Payload should look like this:
# { "username": "my-user", "password": "currentPassword" }
# For more information, visit https://docs.akeyless.io/docs/create-a-custom-rotated-secret

function run_rotate() {
    PAYLOAD=$(echo "$*" | base64 -d)
    PAYLOAD_VALUE=$(echo "$PAYLOAD" | jq -r .payload)
    RANDOM_ALNUM=$(dd bs=1000 count=1 if=/dev/urandom status=none | tr -dc '[:alnum:]' | head -c 15)
    PAYLOAD_VALUE=$(echo "$PAYLOAD_VALUE" | jq -rc ".password = \"${RANDOM_ALNUM}\"")
    PAYLOAD_JSON=$(echo -n "$PAYLOAD_VALUE" | jq -Rsa . | sed -e 's/\\n//g' -e 's/\\t//g')
    PAYLOAD_JSON=$(echo -n "{ \"payload\": $PAYLOAD_JSON }")
    echo -n "$PAYLOAD_JSON"
}
