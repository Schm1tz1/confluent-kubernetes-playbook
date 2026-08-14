# JMXTerm
* Original Repo: https://github.com/jiaqi/jmxterm
* Dockerfile: https://github.com/jiaqi/jmxterm/blob/main/Dockerfile
* Use containerized JMXTerm in k8s:
```shell
kubectl apply -f jmxterm.yaml
```
* Example commands:
```shell
# Interactive Terminal
kubectl exec -it jmxterm -- java -jar jmxterm-1.0.4-uber.jar --url kafka-0-internal.dc1:7203

# List Beans
kubectl exec -it jmxterm -- bash -c "echo beans | java -jar jmxterm-1.0.4-uber.jar --url kafka-0-internal.dc1:7203"
```

## Zabbix
* Community Helm Chart to install infrastructure: https://github.com/zabbix-community/helm-zabbix
* Possible wizard for Configurations: https://zbxwizz.app/docs/getting-started
