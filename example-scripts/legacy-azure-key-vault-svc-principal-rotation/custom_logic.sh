# The Rotated Secret Payload should look something like this:
# {
#   "access_id": "p-oki4w02qfz9c",
#   "k8s_auth_config_name": "cg-lab-aks",
#   "gateway_url": "https://gw-config.cg2.cs.akeyless.fans",
#   "rotated_secret_1_path": "/Azure KV Cg Rotated Secret 1",
#   "rotated_secret_2_path": "/Azure KV Cg Rotated Secret 2",
#   "azure_key_vault_secret_id": "https://cg-akl.vault.azure.net/secrets/azure-sp-ready",
#   "usc_path": "/AKV - USC - cg-akl"
# }
# For more information, visit https://docs.akeyless.io/docs/create-a-custom-rotated-secret

akeyless update

function run_rotate() {
    PAYLOAD=$(echo "$*" | base64 -d)
    PAYLOAD_VALUE=$(echo "$PAYLOAD" | jq -r .payload)
    
    # Extracting required fields from PAYLOAD_VALUE
    ACCESS_ID=$(echo "$PAYLOAD_VALUE" | jq -r .access_id)
    K8S_AUTH_CONFIG_NAME=$(echo "$PAYLOAD_VALUE" | jq -r .k8s_auth_config_name)
    GATEWAY_URL=$(echo "$PAYLOAD_VALUE" | jq -r .gateway_url)
    ROTATED_SECRET_1_PATH=$(echo "$PAYLOAD_VALUE" | jq -r .rotated_secret_1_path)
    ROTATED_SECRET_2_PATH=$(echo "$PAYLOAD_VALUE" | jq -r .rotated_secret_2_path)
    AZURE_KEY_VAULT_SECRET_ID=$(echo "$PAYLOAD_VALUE" | jq -r .azure_key_vault_secret_id)
    USC_PATH=$(echo "$PAYLOAD_VALUE" | jq -r .usc_path)
    
    # Authenticate with Akeyless CLI
    AUTH_RESPONSE=$(akeyless auth --access-id "$ACCESS_ID" --access-type k8s --k8s-auth-config-name "$K8S_AUTH_CONFIG_NAME" --gateway-url "$GATEWAY_URL" --json)
    TOKEN=$(echo $AUTH_RESPONSE | jq -r '.token')
    
    # Describe rotated secrets
    ROTATED_SECRET_1=$(akeyless describe-item -n "$ROTATED_SECRET_1_PATH" --token "$TOKEN" --json)
    ROTATED_SECRET_2=$(akeyless describe-item -n "$ROTATED_SECRET_2_PATH" --token "$TOKEN" --json)
    
    LAST_ROTATION_1=$(echo $ROTATED_SECRET_1 | jq -r '.last_rotation_date')
    LAST_ROTATION_2=$(echo $ROTATED_SECRET_2 | jq -r '.last_rotation_date')
    
    # Convert dates to epoch for comparison
    EPOCH_ROTATION_1=$(date -d "$LAST_ROTATION_1" +"%s")
    EPOCH_ROTATION_2=$(date -d "$LAST_ROTATION_2" +"%s")
    CURRENT_TIME=$(date -u +"%s")
    
    # Determine the oldest secret
    if [ $EPOCH_ROTATION_1 -lt $EPOCH_ROTATION_2 ]; then
        OLDEST_SECRET_PATH="$ROTATED_SECRET_1_PATH"
        ACTIVE_SECRET_PATH="$ROTATED_SECRET_2_PATH"
        OLDEST_ROTATION=$EPOCH_ROTATION_1
    else
        OLDEST_SECRET_PATH="$ROTATED_SECRET_2_PATH"
        ACTIVE_SECRET_PATH="$ROTATED_SECRET_1_PATH"
        OLDEST_ROTATION=$EPOCH_ROTATION_2
    fi
    
    ACTION_TAKEN=false
    
    # Check if the oldest secret is older than 30 minutes
    if [ $((CURRENT_TIME - OLDEST_ROTATION)) -gt 1800 ]; then
        # Get value of the oldest secret
        SECRET_VALUE=$(akeyless rotated-secret get-value -n "$OLDEST_SECRET_PATH" --token "$TOKEN" --json)
        
        # Update Azure Key Vault Secret using USC
        USC_UPDATE_RESPONSE=$(akeyless usc update -n "$USC_PATH" --gateway-url "$GATEWAY_URL" -s "$AZURE_KEY_VAULT_SECRET_ID" -v "$SECRET_VALUE" --token "$TOKEN")
        
        echo "Updated Azure Key Vault Secret: $USC_UPDATE_RESPONSE"
        ACTION_TAKEN=true
    else
        echo "No rotation needed. Oldest secret is not older than 30 minutes."
    fi
    
    # Prepare the payload to return with additional information
    PAYLOAD_JSON=$(echo "$PAYLOAD_VALUE" | jq -c --arg active_secret_path "$ACTIVE_SECRET_PATH" --argjson action_taken "$ACTION_TAKEN" \
    '. + {active_secret_path: $active_secret_path, action_taken: $action_taken}')
    PAYLOAD_JSON=$(echo -n "{ \"payload\": $PAYLOAD_JSON }")
    echo -n "$PAYLOAD_JSON"
}