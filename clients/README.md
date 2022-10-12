# Clients on k8s

## Config Maps from files
- import properties:
```bash
kubectl create configmap kstreams-config --from-file=kstreams-dev.properties --from-file=kstreams-uat.properties --from-file=kstreams-prod.properties
```

## Importing local docker images in k3s
- build and export docker image:
- copy to k3s master
- on master import using `sudo k3s ctr images import test-app-v1.0.0.tar`

