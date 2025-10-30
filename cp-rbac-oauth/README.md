# RBAC-Setup with mTLS without IdP/LDAP/OAuth

## Create Certificates, Keys and Secrets
* Deploy Issuer ans Certificate CRs:
```shell
kubectl apply -f ../certs/issuer.yaml
kubectl apply -f ../certs/certs.yaml
```
* Create RSA keypair for MDS token generations:
```shell
openssl genrsa -out mds-keypair-priv.pem 2048
openssl rsa -in mds-keypair-priv.pem -outform PEM -pubout -out mds-keypair-pub.pem
kubectl create secret generic mds-token \
--from-file=mdsPublicKey.pem=mds-keypair-pub.pem \
--from-file=mdsTokenKeyPair.pem=mds-keypair-priv.pem \
-n confluent
```

## Keycloak Deployment
* Create OIDC credentials:
```shell
kubectl create secret generic oidccredential \
--from-file=oidcClientSecret.txt=oidcClientSecret.txt \
-n confluent
```

* Create OIDC Client secrets:
```shell
kubectl create secret generic oauth-jass \
--from-file=oauth.txt=oidcClientSecret.txt \
-n confluent
```

* Deploy Keycloak:
```shell
kubectl apply -f keycloak.yaml
```

* Exporting Keycloak realms:
```shell
# Run inside the pod to export the reals with users
/opt/keycloak/bin/kc.sh export --dir /tmp/ --users realm_file --realm sso_test

# C3 container lacks tar command to use kubectl cp so we need to pull it manually:
kubectl exec -it deploy/keycloak -n confluent -- cat /tmp/sso_test-realm.json >sso_test-realm.json
```
Note: client passwords are note exported (field will be marked `******`). You need to paste the credentals manually.

## Deploy CP, C3 and Rolebindings
* Deploy CP:
```shell
# For CP 8.x
kubectl apply -f cp-v8.yaml

# For CP 7.x you can chose between the old and the new controlcenter. Base infrastructur first:
kubectl apply -f cp-v7.yaml
# for the new controlcenter (also called C3++ or NG)
kubectl apply -f c3-v7.yaml
# for the old controlcenter (also called legacy C3)
kubectl apply -f c3-legacy-v7.yaml
```
Wait for brokers to be in running state.
* Deploy Rolebindings for test users:
```shell
kubectl apply -f rolebindings.yaml
```

## Test C3 and log in with test user
Once Controlcenter is up and running, either add some ingress component or forward the port - e.g.:
```shell
kubectl port-forward -n confluent svc/controlcenter 9021:9021
```
Then point you browser to thre ingress URL or to `https://localhost:9021` - accept the self-signed certificate.
