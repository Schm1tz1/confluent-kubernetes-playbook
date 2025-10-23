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
