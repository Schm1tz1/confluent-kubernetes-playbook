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

* deploy with helm:
```
helm install <RELEASE_NAME> -f values.yaml  --set datadog.apiKey=<DATADOG_API_KEY> datadog/datadog --set targetSystem=<TARGET_SYSTEM>
```

* example minimal deployment:
```
helm install latest -f values-minimal.yaml datadog/datadog
```
