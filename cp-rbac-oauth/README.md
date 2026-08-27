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
# Export the realm with users
kubectl exec deploy/keycloak -n confluent -- /opt/keycloak/bin/kc.sh export --dir /tmp/ --users realm_file --realm sso_test

# Keycloak container lacks tar command to use kubectl cp so we need to pull it manually:
kubectl exec deploy/keycloak -n confluent -- cat /tmp/sso_test-realm.json >sso_test-realm.json
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
Log in with default C3 account: User `c3`, Password `c3-secret`.

## Test Restproxy
### mTLS AuthN
```shell
kubectl exec -it pod/controlcenter-0 -c controlcenter -n confluent -- \
    /usr/bin/curl --key /mnt/sslcerts/privkey.pem --cert /mnt/sslcerts/fullchain.pem --cacert /mnt/sslcerts/cacerts.pem -X GET https://kafkarestproxy:8082
```

## Test the Kafka OAuth listener
Deploy `kcat.yaml` for a general-purpose testing pod, but note it only covers the mTLS listener
(`kcat-mtls.conf`) - the `cp-kcat` image bundles librdkafka <1.9.0, which does not implement
`sasl.oauthbearer.method=oidc` (built-in OIDC/client-credentials support), so kcat cannot
authenticate against the OAuth listener at all.

Instead, use the JVM clients (`kafka-console-producer`, `kafka-console-consumer`,
`kafka-broker-api-versions`, etc.) that already ship on the `kafka-*` broker pods - they support
OAUTHBEARER with a real IdP out of the box. Write a client properties file into a broker pod
(`kubectl cp` won't work there since the image lacks `tar`, so pipe it in instead):
```shell
kubectl exec -i kafka-0 -n confluent -c kafka -- sh -c 'cat > /tmp/oauth-client.properties' <<'EOF'
bootstrap.servers=kafka.confluent.svc.cluster.local:9092
security.protocol=SASL_SSL
ssl.truststore.location=/mnt/sslcerts/truststore.p12
ssl.truststore.password=mystorepassword
ssl.truststore.type=PKCS12
sasl.mechanism=OAUTHBEARER
sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginCallbackHandler
sasl.oauthbearer.token.endpoint.url=http://keycloak.confluent.svc.cluster.local:8080/realms/sso_test/protocol/openid-connect/token
sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required \
  clientId="client" \
  clientSecret="QvCcQKUsYEoFZuCiK4ahxnzNDSdZXUyp" ;
EOF
```
Notes on that properties file:
- `ssl.truststore.password` comes from `jksPassword.txt` in the same `/mnt/sslcerts` mount (`kubectl exec kafka-0 -n confluent -c kafka -- cat /mnt/sslcerts/jksPassword.txt`).
- The `client`/`clientSecret` pair is the "client" service account from the `sso_test` Keycloak realm (`client_id` claim -> `User:client`), matching the `kcat-oauth.conf` config this replaces.
- On Kafka 4.x/CP 8.x, the callback handler class is `org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginCallbackHandler` - the older `...oauthbearer.secured.OAuthBearerLoginCallbackHandler` package was removed.

Kafka 4.x also added an SSRF guard (KIP-1139) that requires the token endpoint to be explicitly
allow-listed via a JVM system property, or every OAUTHBEARER call fails with
`The URL cannot be accessed due to restrictions`:
```shell
kubectl exec kafka-0 -n confluent -c kafka -- env \
  KAFKA_OPTS="-Dorg.apache.kafka.sasl.oauthbearer.allowed.urls=http://keycloak.confluent.svc.cluster.local:8080/realms/sso_test/protocol/openid-connect/token" \
  kafka-broker-api-versions --bootstrap-server kafka.confluent.svc.cluster.local:9092 --command-config /tmp/oauth-client.properties
```
A successful run authenticates as `User:client` and lists the broker's supported API versions.
Use the same `KAFKA_OPTS` and `--producer.config`/`--consumer.config /tmp/oauth-client.properties`
with `kafka-console-producer`/`kafka-console-consumer` to produce/consume as that principal.
