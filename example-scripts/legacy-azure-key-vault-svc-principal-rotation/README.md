# Legacy Azure Key Vault Svc Principal Rotation

This example shows how to rotate a service principal secret and store them inside Azure Key Vault. This method is designed to show how you can use Akeyless to rotate secrets in a legacy process and then work the organization towards migrating to dynamic secrets.

## Prerequisites

TBD

## Example Starting Payload

```json
{
  "access_id": "p-oki4w02qfz9c",
  "k8s_auth_config_name": "cg-lab-aks",
  "gateway_url": "https://gw-config.cg2.cs.akeyless.fans",
  "rotated_secret_1_path": "/Azure KV Cg Rotated Secret 1",
  "rotated_secret_2_path": "/Azure KV Cg Rotated Secret 2",
  "azure_key_vault_secret_id": "https://cg-akl.vault.azure.net/secrets/azure-sp-ready",
  "usc_path": "/AKV - USC - cg-akl"
}
```

## Troubleshooting

You can exec into the custom server pod and run these commands to more closely debug any issues with your custom bash script.

```bash
# Save the payload to a file
cat <<EOF > payload.json
{
  "payload": {
    "access_id": "p-oki4w02qfz9c",
    "k8s_auth_config_name": "cg-lab-aks",
    "gateway_url": "https://gw-config.cg2.cs.akeyless.fans",
    "rotated_secret_1_path": "/Azure KV Cg Rotated Secret 1",
    "rotated_secret_2_path": "/Azure KV Cg Rotated Secret 2",
    "azure_key_vault_secret_id": "https://cg-akl.vault.azure.net/secrets/azure-sp-ready",
    "usc_path": "/AKV - USC - cg-akl"
  }
}
EOF

# Encode the payload in base64
BASE64_PAYLOAD=$(base64 -w 0 payload.json)

# Source the script to make the function available in the current shell
source custom_logic.sh

set -x

# Call the function with the base64-encoded payload
run_rotate "$BASE64_PAYLOAD"
```