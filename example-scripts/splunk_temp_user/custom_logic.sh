# Required environment variables to the custom-server (recommended to pass as secrets):
# SPLUNK_AUSR - Splunk administrative username (with permissions to create/delete a new user)
# SPLUNK_APWD - Splunk password matching the user above
# SPLUNK_URL - Splunk base URL e.g. https://splunk.mydomain.com:8089
# USER_ROLE - The Splunk role to add the user to, e.g. user
# For more information, visit https://docs.akeyless.io/docs/custom-producer

function run_create() {
    PAYLOAD=$(echo "$*" | base64 -d)
    PAYLOAD_VALUE=$(echo "$PAYLOAD" | jq -r .)

    NEW_USER="tmp.$(dd bs=1000 count=1 if=/dev/urandom status=none | tr -dc '[:alnum:]' | head -c 10)"
    NEW_PASS="$(dd bs=1000 count=1 if=/dev/urandom status=none | tr -dc '[:alnum:]' | head -c 10)1xV"
    curl -f -s -ku ${SPLUNK_AUSR}:${SPLUNK_APWD} ${SPLUNK_URL}/services/authentication/users -d "output_mode=json&name=${NEW_USER}&password=${NEW_PASS}&roles=${USER_ROLE}" | jq . >> /dev/null
    echo "{ \"id\": \"${NEW_USER}\", \"response\": {\"username\":\"${NEW_USER}\", \"password\":\"${NEW_PASS}\"} }"
}

function run_revoke() {
    PAYLOAD=$(echo "$*" | base64 -d)
    PAYLOAD_VALUE=$(echo "$PAYLOAD" | jq -r .)

    USER1=$(echo "$PAYLOAD_VALUE" | jq -r .ids[0])
    USER1=$(echo "$USER1" | sed -E 's/^tmp\.[0-9a-zA-Z]+_//')
    curl -f -s -ku ${SPLUNK_AUSR}:${SPLUNK_APWD} -X DELETE "${SPLUNK_URL}/services/authentication/users/${USER1}?output_mode=json" | jq . >> /dev/null
    echo "{ \"revoked\": [\"${USER1}\"], \"message\": \"User [$USER1] was successfully deleted\" }"
}
