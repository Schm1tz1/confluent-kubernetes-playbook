git clone https://github.com/zabbix-community/helm-zabbix

#
# Original example
#

# helm upgrade --install zabbix --dependency-update --create-namespace \
#   -f ./helm-zabbix/charts/zabbix/docs/example/kind/values.yaml \
#   ./helm-zabbix/charts/zabbix -n monitoring --debug

helm upgrade --install zabbix --dependency-update --create-namespace \
  -f ./values.yaml \
  ./helm-zabbix/charts/zabbix -n monitoring --debug

# kubectl apply -f traefik-ingress-zabbix.yaml
