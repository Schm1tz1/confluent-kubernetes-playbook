helm uninstall zabbix -n monitoring
kubectl delete pvc postgresql-data-zabbix-postgresql-0 -n monitoring
