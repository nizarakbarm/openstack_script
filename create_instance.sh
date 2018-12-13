#!/bin/bash
#help message
usage() {
   echo -e "usage: $0 \n \
   options: \n \
   -ins|--instance node1,node2,nodeN -img|--image imagetype -flv|--flavor flavortype \n \
   [-ip|--fixed-ip network=networkname,ip=ipaddress,name=fixedipname] \n \
   [--create-floating]"
}

#read pod name
readPod() {
   local arg=$1
   instances=($(echo $arg | tr ',' '\n'))
}
#check if pod have a floating ip
isPortIPFloat() {
   openstack floating ip list --port $1 | grep "10.1" | cut -d'|' -f3
}

#create fixed ip address
createFixedIp() {
	local netarg=($(echo $1 | tr ',' '\n'))

	network=$(cut -d"=" -f2 <<< "${netarg[0]}")
	fixip=$(cut -d"=" -f2 <<< "${netarg[1]}")
	ipname=$(cut -d"=" -f2 <<< "${netarg[2]}")

	openstack port create --network "$network" --fixed-ip ip-address="$fixip" "$ipname"
}

createFloating() {
	openstack floating ip create ext-net
}

#mapping ip floating to pod
mapFloating() {
   if [ -z $(isPortIPFloat $1) ]; then
   	openstack floating ip set --port=$1 $2
   fi
}


#create instance
#instances=(pod43-node1 pod43-node2 pod43-node3)
createInstance() {
local IFS=$'\n'
local floats=($(openstack floating ip list | grep "None" | sort -k2 | cut -d'|' -f3 | tr -d [[:blank:]]))
local i
for ((i=0; i<${#instances[@]}; i++)); do
nova boot --nic port-id="${ports[$i]}" --key-name nizar --image "$image" --flavor "$flavor" "${instances[$i]}"
#openstack floating ip set --port="${ports[$i]}" "${floats[$i]}"  
if [ "$ipname" == "" ]; then
	local ports=($(openstack port list | grep DOWN | sort -k3 | cut -f2 -d'|' | tr -d [[:blank:]]))
	mapFloating "${ports[$i]}" "${floats[$i]}"
else
	mapFloating  "$ipname" "${floats[$i]}"
fi

mapFloating "${ports[$i]}" "${floats[$i]}"
done
}


## Main ##
#input options
if [ "$#" == "0" ]; then
   usage
   exit
fi
#read argument
while (( $# )); do
   case $1 in 
      -ins | --instance) readPod $2
                       shift 2
		       ;;
      -img | --image) image="$2"
	              shift 2
		      ;;
      -flv | --flavor) flavor="$2"
                      shift 2
		      ;;
      -ip | --fixed-ip) createFixedIp $2
	             shift 2
		     ;;
      --create-floating) createFloating
	            shift 2
		    ;;
      -h | --help)     usage
		       shift
                       exit
		       ;;
      * )              break
                       ;;
    esac
done

#create instance
createInstance
