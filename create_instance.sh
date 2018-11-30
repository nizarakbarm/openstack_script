#!/bin/bash

instances=(pod43-node1 pod43-node2 pod43-node3)
createInstance() {
local IFS=$'\n'
local ports=($(openstack port list | grep port | sort -k3 | cut -f2 -d'|' | tr -d [[:blank:]]))
local floats=($(openstack floating ip list | grep "10." | cut -d'|' -f3 | tr -d [[:blank:]]))
local i
for ((i=0; i<${#ports[@]}; i++)); do
nova boot --nic port-id="${ports[$i]}" --key-name nizar --image "CentOS-7-x86_64-GenericCloud-1802.qcow2" --flavor "2720d1a3-5922-4099-8323-43d75b560834" "${instances[$i]}"
openstack floating ip set --port="${ports[$i]}" "${floats[$i]}"  
done
}
createInstance
