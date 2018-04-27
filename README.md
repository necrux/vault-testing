#Testing for Hashicorp Vault + Goldfish

Below are my personal notes for getting Vault + Goldfish up and running. The docker-compose file is made up of 3 containers:
    * vault (vault server)
    * unsealer (unseal vault and generate wrapper token for goldfish w/ 20s ttl)
    * vault_ui (goldfish server)

The unsealer container clearly violates Goldfish's security practice, but that is inconsequential for dev/testing.

###Vault Init:
    * `vault operator init -key-shares=1 -key-threshold=1`
        - Modify accordingly for number of desired keys.
    * `vault operator unseal`
        - Only 1 key needed to unseal; vault is useless if seal is intact.
    * `vault login`

###Goldfish Init (if using approle):
    * `vault auth enable approle`
    * `wget https://raw.githubusercontent.com/Caiyeon/goldfish/master/vagrant/policies/goldfish.hcl -P /tmp`
    * `vault policy write goldfish /tmp/goldfish.hcl`
    * `vault write auth/approle/role/goldfish role_name=goldfish policies=default,goldfish secret_id_num_uses=1 secret_id_ttl=5m period=24h token_ttl=0 token_max_ttl=0`
    * `vault write auth/approle/role/goldfish/role-id role_id=goldfish`
    * `vault write secret/goldfish DefaultSecretPath="secret/" UserTransitKey="usertransit" BulletinPath="secret/bulletins/"`

###Goldfish Init (w/o approle, i.e. permenant secret-id):
    * Not working with the Nomad secret-id as expected.

###Github Auth Integration
    * `vault auth enable -path=github github`
    * `vault write auth/github/config organization=${my-org}`
        - Set ${my-org}.
    * `vault write auth/github/map/teams/${slugified-team-name} value=${policy}`
        - Set ${slugified-team-name} and ${policy}

###Notes:
    * If you wish to use the unsealer container the following must be done:
        - Build the vault and configure the approle for Goldfish (steps above).
        - `cp .env.example .env`
        - Populate .env with VAULT_KEY and VAULT_TOKEN
    * If the unsealer container is removed the following must be manually performed:
        - Unsealing of the vault:
            * When the container starts/restarts.
            * If the vault is manually sealed.
        - Generate a wrapped token and initialize goldfish; command is supplied on login page.
        - Remove -token flag from the goldfish app in docker-compose.yml.
    * Forcing TLS connection w/ a self-signed cert.
        - Command to generate self-signed cert for testing:
            * `openssl req -x509 -newkey rsa:4096 -days 365 -nodes -keyout config/cert.key -out config/cert.pem`
        - Skipping cert verification in docker-compose.yml: VAULT_SKIP_VERIFY=true 
        - Skipping cert verification in goldfish.hcl: tls_skip_verify = 1
    * To login with Github you must create a personal Github token with the `read:org` scope (Vault does not support OAuth)
        - https://www.vaultproject.io/docs/auth/github.html
    * The `policies` dir contains default policies provided by Hashicorp and Caiyeon:
        - https://www.vaultproject.io/guides/identity/policies.html
        - https://github.com/Caiyeon/goldfish/blob/master/vagrant/policies/goldfish.hcl
