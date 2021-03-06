#!/bin/bash
#help message
usage() {
   echo -e "usage: $0 \n"\
   "options: \n "\
   "-ins|--instance node1,node2,nodeN : specify the name of instance \n "\
   "-img|--image imagetype : specify image type to be used in instance \n "\
   "-flv|--flavor flavortype : specify flavor or specification type to be used in instance \n "\
   "[-ip|--fixed-ip network=networkname,ip=ipaddress,name=fixedipname] : specify fixed ip address to be used by instance\n "\
   "[--create-floating] : create a floating ip"
}

#read pod name
readPod() {
   local arg=$1
   instances=($(echo $arg | tr ',' '\n'))
}
#check if port have a floating ip
isPortIPFloat() {
   local portid="$1"
   openstack floating ip list --port "$portid" | grep "10.1" | cut -d'|' -f3
}

#create fixed ip address
createFixedIp() {
	local netarg=($(echo $1 | tr ',' '\n'))

	network=$(cut -d"=" -f2 <<< "${netarg[0]}")
	fixip=$(cut -d"=" -f2 <<< "${netarg[1]}")
	ipname=$(cut -d"=" -f2 <<< "${netarg[2]}")
	portfixip=$(openstack port create --network "$network" --fixed-ip ip-address="$fixip" "$ipname" | grep "| id " | cut -d"|" -f3 | tr -d [[:blank:]])
}

createFloating() {
	openstack floating ip create ext-net
}

#mapping ip floating to pod
mapFloating() {
   local ports="$1"
   if [ -z "$(isPortIPFloat "$ports")" ]; then
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
#openstack floating ip set --port="${ports[$i]}" "${floats[$i]}"
if [ "$ipname" == "" ]; then
	local ports=($(openstack port list | grep DOWN | sort -k3 | cut -f2 -d'|' | tr -d [[:blank:]]))
	mapFloating "${ports[$i]}" "${floats[$i]}"
	nova boot --nic port-id="${ports[$i]}" --key-name nizar --image "$image" --flavor "$flavor" "${instances[$i]}"
else
	mapFloating "$portfixip" "${floats[$i]}"
	nova boot --nic port-id="$portfixip" --key-name nizar --image "$image" --flavor "$flavor" "${instances[$i]}"
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
		       shift 2
                       exit
		       ;;
      * )              break
                       ;;
    esac
done

#create instance
createInstance
