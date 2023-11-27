# Required environment variables to the custom-server (recommended to pass as secrets):
# ROTATED_SECRET_NAME - The name of the Rotated Secret in Akeyless
# GW_URL - Akeyless GW URL (Configuration Management port) e.g. https://my-gw.mydomain.com:8000
# HEROKU_API_KEY - Heroku API Key (required for the API call)
# APP_ID_OR_NAME - Heroku Application ID or Name to push Config Vars to
# TOKEN - Akeyless API Token (Used to rotate/get secret value)
# The Rotated Secret Payload should look like this:
# { "AWS_KEY_ID": "<reducted>", "AWS_SECRET_KEY": "<reducted>" }
# For more information, visit https://docs.akeyless.io/docs/create-a-custom-rotated-secret

function run_rotate() {
    PAYLOAD=$(echo "$*" | base64 -d)
    PAYLOAD_VALUE=$(echo "$PAYLOAD" | jq -r .payload)
    akeyless gateway-rotate-secret -n "$ROTATED_SECRET_NAME" --gateway-url ${GW_URL} --token ${TOKEN} >> /dev/null
    RS_VAL=$(akeyless get-rotated-secret-value -n "$ROTATED_SECRET_NAME" --token ${TOKEN})
    NEW_KEY_ID=$(echo "$RS_VAL" | jq -r .value.username)
    NEW_SECRET_KEY=$(echo "$RS_VAL" | jq -r .value.password)
    PAYLOAD_VALUE=$(echo "$PAYLOAD_VALUE" | jq -rc ".AWS_KEY_ID = \"${NEW_KEY_ID}\" | .AWS_SECRET_KEY = \"${NEW_SECRET_KEY}\"")
    curl -s -f -n -X PATCH -H "Content-Type: application/json" \
     -H "Accept: application/vnd.heroku+json; version=3"   \
     -H "Authorization: Bearer ${HEROKU_API_KEY}"          \
     https://api.heroku.com/apps/$APP_ID_OR_NAME/config-vars -d "$PAYLOAD_VALUE" >> /dev/null
    PAYLOAD_JSON=$(echo -n "$PAYLOAD_VALUE" | jq -Rsa . | sed -e 's/\\n//g' -e 's/\\t//g')
    PAYLOAD_JSON=$(echo -n "{ \"payload\": $PAYLOAD_JSON }")
    echo -n "$PAYLOAD_JSON"
}
