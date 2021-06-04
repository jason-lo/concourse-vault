#!/usr/bin/env bash

# see https://github.com/hashicorp/best-practices/blob/master/packer/config/vault/scripts/setup_vault.sh

cleanup() {
    shred /tmp/vault-keys
}

trap cleanup INT TERM QUIT EXIT

# Unseal Vault and login with root token (EVIL!!!)
unseal_key="$1"
login_token="$2"

echo "Unseal Key: ${unseal_key}"
echo "Login Token: ${login_token}"

docker exec -it concourse-demo_vault_1 /bin/sh -c "export VAULT_CACERT=/vault/certs/vault-ca.crt; /bin/vault operator unseal -tls-skip-verify ${unseal_key}"
docker exec -it concourse-demo_vault_1 /bin/sh -c "export VAULT_CACERT=/vault/certs/vault-ca.crt; /bin/vault login -tls-skip-verify '${login_token}'"

