#!/usr/bin/env bash

echo 'spec:
  hostAliases:'

while IFS=" " read -r col1 col2 col3
do
    echo "  - ip: \"${col1}\""
    echo "    hostnames:"
    echo "    - \"${col2}\""
    echo "    - \"${col3}\""
done < <(cat < /root/workspace/cp-proxmox-playbook/scripts/hosts.new | grep -v '#' | cut -d ' ' -f1,2,3 )
