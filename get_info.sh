#!/bin/bash
#set -x

declare NODES=( node-a node-b )
COMPARTMENT_NAME='NPSTestENV'
COMPARTMENT_ID=$(oci iam compartment list --query "data[?name=='NPSTestEnv'].id|[0]" | xargs)
VIP="172.56.0.91"

declare -A NODEVNICS

for n in "${NODES[@]}";
do
	echo "processing node : $n"
INST_ID=$(oci compute instance list --compartment-id $COMPARTMENT_ID \
	--query "data[?\"display-name\"=='$n'].id|[0]" | xargs)

        echo "instance id : $INST_ID"
  NODEVNICS[$n]=$(oci compute instance list-vnics --instance-id $INST_ID \
	--query "data[].id|[0]" | xargs)
done

declare -A NUM_OF_NODE
NUM_OF_NODE=([1]=node-a [2]=node-b)



for K in "${!NODEVNICS[@]}"; do 
	echo $K -- ${NODEVNICS[$K]};
done

OCF_FILE="./IPaddr2"
#OCF_FILE="/usr/lib/ocf/resource.d/heartbeat/IPaddr2"

 sed -i '64i\##### OCI vNIC variables\' $OCF_FILE
 sed -i '65i\server="`hostname -s`"\' $OCF_FILE
 sed -i "66i\\node1nic=${NODEVNICS[${NUM_OF_NODE[1]}]}\\" $OCF_FILE
 sed -i "67i\\node2nic=${NODEVNICS[${NUM_OF_NODE[2]}]}\\" $OCF_FILE
 sed -i "68i\\vnicip=$VIP\\" $OCF_FILE
 sed -i '614i\##### OCI/IPaddr Integration\' $OCF_FILE
 sed -i "615i\\        if [ '$server' = $NUM_OF_NODE[1] ]; then\\" $OCF_FILE
 sed -i '616i\                /root/bin/oci network vnic assign-private-ip --unassign-if-already-assigned --vnic-id $node1vnic  --ip-address $vnicip \' $OCF_FILE
sed -i '617i\        else \' $OCF_FILE
 sed -i '618i\                /root/bin/oci network vnic assign-private-ip --unassign-if-already-assigned --vnic-id $node2vnic  --ip-address $vnicip \' $OCF_FILE
 sed -i '619i\        fi \' $OCF_FILE

