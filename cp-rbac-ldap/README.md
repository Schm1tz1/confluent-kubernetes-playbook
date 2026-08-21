# RBAC-Setup with mTLS without IdP/LDAP/OAuth

## Create Certificates, Keys and Secrets
* Deploy Issuer ans Certificate CRs:
```shell
kubectl apply -f ../certs/issuer.yaml
kubectl apply -f ../certs/certs.yaml
```
* Create RSA keypair for MDS token generations and Credentials:
```shell
./create_secrets.sh
```

## OpenLDAP Deployment
* Deploy OpenLDAP via Helm Chart:
```shell
./openldap_install.sh
```

* Test LDAP query:
```shell
./openldap_test.sh
```
## (WIP) Deploy CP, C3 and Rolebindings
* Deploy minimal CP:
```shell
kubectl apply -f cp.yaml
```
Wait for brokers to be in running state.
* Deploy Rolebindings for test users:
```shell
kubectl apply -f rolebindings-ssologin.yaml
```
* Deploy Controlcenter (C3):
```shell
kubectl apply -f c3.yaml
```

## Test C3 and log in with test user
Once Controlcenter is up and running, either add some ingress component or forward the port - e.g.:
```shell
kubectl port-forward -n confluent svc/controlcenter 9021:9021
```
Then point you browser to thre ingress URL or to `https://localhost:9021` - accept the self-signed certificate.

## Kafka client listeners: LDAP callback vs. static SASL

The `Kafka` CR exposes two client listeners that authenticate with SASL/PLAIN but validate credentials differently — useful for comparing both mechanisms side by side. Both are SASL_SSL (TLS on the wire).

| Listener | Port | Auth | Validates against | Example user |
|----------|------|------|-------------------|--------------|
| `external` | 9092 | `type: ldap` (LDAP callback handler) | LDAP directory (reuses the MDS LDAP provider) | any LDAP `uid`, e.g. `peter` |
| custom `externalplain` | 9093 | `type: plain` + `jaasConfigPassThrough` | static creds in `plain-jaas.conf` | `kafka`, `control-center` |

### Why `jaasConfigPassThrough`
Once a SASL/PLAIN **LDAP** listener exists, every other SASL/PLAIN listener on the broker (`internal`, `replication` and the custom one) must use `jaasConfigPassThrough` with `PlainLoginModule` instead of `jaasConfig` — CFK renders `jaasConfig` with `FileBasedLoginModule`, and mixing the two login modules crashes the brokers. `create_secrets.sh` therefore creates a `plain-jaas` secret from `credentials/plain-jaas.conf`; its usernames/passwords mirror the LDIF service accounts in `openldap.yaml`.

### Testing both listeners with kcat
Deploy the client pod and its config:
```shell
kubectl apply -f kcat.yaml
```
Static-credential listener (9093), authenticates as `kafka` against `plain-jaas.conf`:
```shell
kubectl exec -n confluent kcat -- kcat -F /mnt/configs/kcat-plain-tls-9093.conf -L
```
LDAP-callback listener (9092), authenticates as the LDAP user `peter` (member of the `admins` group → `SystemAdmin`):
```shell
kubectl exec -n confluent kcat -- kcat -F /mnt/configs/kcat-ldap-tls-9092.conf -L
```
That LDAP user (`peter`) is **rejected** on 9093, and the `plain-jaas.conf`-only user (`kafka`) authenticates on 9093 but is not an LDAP identity on 9092 — which is the point of the comparison.
