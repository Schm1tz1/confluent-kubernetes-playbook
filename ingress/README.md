# Example CP-Cluster with Traefik ingress

## Files
* cp-kraft.yaml
* traefik-values.yaml - Traefik config with override to use google domains resolver (with API as env-var token from secret)
* traefik-ingress-resolver-terminate.yaml - TLS termination at Traefik (uses ACME certificate fom Google Domains resolver), internal traffic is non-TLS
* traefik-ingress-static-certs-passthrough.yaml - TLS passthrough for Kafka, will add TLS for all non-secure HTTP services, (wildcard) certs provided via secret

## Deploy
Deploy CP cluster and TRaefik ingress with automated certificate management using ACME client:
```shell
# (Re-)Configure and install Traefik
vi traefik_values.yaml 
kubectl create secret generic googledomains-token \
 -n=kube-system --from-literal=GOOGLE_DOMAINS_ACCESS_TOKEN={Your API token here}

helm install traefik traefik/traefik  --namespace kube-system --values traefik-values.yaml

# Start Cluster
kubectl apply -f cp-kraft.yaml

# Configure Ingress Controller
kubectl apply -f traefik-ingress-resolver.yaml
```
You will need additional external DNS entries for ingress. 
On OPNsense router there is a wildcard DNS configured in `/usr/local/etc/dnsmasq.conf.d/k8s-wildcards.conf` as follows:
```config
address=/k8s.internal.schmitzi.net/10.0.0.20
address=/k8s.internal.schmitzi.net/10.0.0.21
address=/k8s.internal.schmitzi.net/10.0.0.22
address=/k8s.internal.schmitzi.net/10.0.0.23
address=/k8s.internal.schmitzi.net/10.0.0.24
address=/k8s.internal.schmitzi.net/10.0.0.25
address=/k8s.internal.schmitzi.net/10.0.0.26
```

## Test / Connect
Connectivity tests to brokers are done typically with netcat `nc -vz kafka.k8s.internal.schmitzi.net 443` and OpenSSL `openssl s_client -connect kafka.k8s.internal.schmitzi.net:443 -showcerts`. KCat with SSL:
```shell
kcat -X security.protocol=SSL -b kafka.k8s.internal.schmitzi.net:443 -L
```
