#!/bin/bash
#help message
usage() {
   echo "usage: $0 -ins|--instance node1,node2,noden -img|--image imagetype -flv|--flavor flavortype"
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
local ports=($(openstack port list | grep port | sort -k3 | cut -f2 -d'|' | tr -d [[:blank:]]))
local floats=($(openstack floating ip list | grep "10." | cut -d'|' -f3 | tr -d [[:blank:]]))
local i
for ((i=0; i<${#instances[@]}; i++)); do
nova boot --nic port-id="${ports[$i]}" --key-name nizar --image "$image" --flavor "$flavor" "${instances[$i]}"
#openstack floating ip set --port="${ports[$i]}" "${floats[$i]}"  
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
