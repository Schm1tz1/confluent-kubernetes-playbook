# Datadog on Kubernetes

## Docs
*  
* 
* 

## Configuration/Installation
Preferred method here: use helm charts (customer requirement)

* fresh install:
```
helm repo add datadog https://helm.datadoghq.com
helm repo update
```
* adapt [values.yaml](https://github.com/DataDog/helm-charts/blob/main/charts/datadog/values.yaml) to your needs.

* add your API key to secrets management:
```
kubectl create secret generic datadog-secret --from-literal api-key="<your apy key>"
```
and upgrade or specify in values.yaml as `datadog.apiKeyExistingSecret=datadog-secret`.

* deploy with helm:
```
helm install <RELEASE_NAME> -f values.yaml  --set datadog.apiKey=<DATADOG_API_KEY> datadog/datadog --set targetSystem=<TARGET_SYSTEM> -n <NAMESPACE>
```

* example minimal deployment:
```
helm install <RELEASE_NAME> -f values-minimal.yaml datadog/datadog -n <NAMESPACE> --create-namespace
```

* delete:
```
helm delete <RELEASE_NAME> --namespace <NAMESPACE>
```
