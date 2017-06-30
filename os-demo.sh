#!/bin/bash

# VMs configuration
IMAGE_NAME="spark-ubuntu-java8"
FLAVOR_NAME="BigSea.l1.medium"
KEY_NAME="bigsea"
KEY_PATH="~/.ssh/bigsea"
SPARK_HOME="/opt/spark"

## Get credentials
source openrc.sh

## Create master VM
openstack server create --image $IMAGE_NAME --flavor $FLAVOR_NAME --key-name $KEY_NAME "master"
openstack server list

## Create worker VM
openstack server create --image $IMAGE_NAME --flavor $FLAVOR_NAME --key-name $KEY_NAME "worker0"
openstack server list

## Get master and worker IPs
openstack server show "master"
MASTER_IP="`openstack server show "master" | grep addresses | awk {'print $4'} | awk -F '=' {'print $2'}`"

openstack server show "worker0"
WORKER0_IP="`openstack server show "worker0" | grep addresses | awk {'print $4'} | awk -F '=' {'print $2'}`"

## Prepare Spark master
ssh -i $KEY_PATH ubuntu@$MASTER_IP
# Edit /etc/hosts and add:
# $MASTER_IP master

# Start Master
-- /opt/spark/sbin/start-master.sh

## Prepare Spark worker
ssh -i $KEY_PATH ubuntu@$WORKER0_IP
# Edit /etc/hosts and add:
# $MASTER_IP master
# $WORKER0_IP worker0

# Start worker
-- /opt/spark/sbin/start-slave.sh spark://master:7077

## Start Application
ssh -i $KEY_PATH ubuntu@$MASTER_IP
-- /opt/spark/bin/spark-submit --class org.apache.spark.examples.SparkPi --master spark://master:7077 /opt/spark/lib/spark-examples-1.6.0-hadoop2.6.0.jar 2000

## Clean up
openstack server delete "master"
openstack server delete "worker0"


#-----------------------------------------------------------------
# Vertical scaling
#-----------------------------------------------------------------

# Get worker id
WORKER0_ID="`openstack server show worker0 | grep " id" | awk {'print $4'}`"
COMPUTES="c4-compute11 c4-compute12 c4-compute22"

# Locate worker
for compute_node in $COMPUTES
do
	worker_in_host="`ssh root@$compute_node virsh dominfo $WORKER0_ID > /dev/null; echo $?`"

	if [ $worker_in_host = "0" ]
	then
		echo "worker:$compute_node"
		WORKER_COMPUTE=$compute_node
		break
	fi
done

# Simple CPU Bound Application
#-----------------------------------------------------------------
ssh -i $KEY_PATH ubuntu@$WORKER0_IP
-- git clone https://github.com/armstrongmsg/vertical-scaling-demo.git
-- python demo.py

# Spark Application
#-----------------------------------------------------------------
## Run application
ssh -i $KEY_PATH ubuntu@$MASTER_IP
# start application
-- /opt/spark/bin/spark-submit --class org.apache.spark.examples.SparkPi --master spark://master:7077 /opt/spark/lib/spark-examples-1.6.0-hadoop2.6.0.jar 2000

## Change amount of allocated resources
ssh root@$WORKER_COMPUTE virsh schedinfo $WORKER0_ID --set vcpu_quota=50000

## Run application again
ssh -i $KEY_PATH ubuntu@$MASTER_IP
# start application
-- /opt/spark/bin/spark-submit --class org.apache.spark.examples.SparkPi --master spark://master:7077 /opt/spark/lib/spark-examples-1.6.0-hadoop2.6.0.jar 2000

## Clean up
ssh root@$WORKER_COMPUTE virsh schedinfo $WORKER0_ID --set vcpu_quota=100000



#-----------------------------------------------
# Horizontal Scaling
#----------------------------------------------

## Create a second worker
openstack server create --image $IMAGE_NAME --flavor $FLAVOR_NAME --key-name $KEY_NAME "worker1"

## Get second worker ip
WORKER1_IP="`openstack server show "worker1" | grep addresses | awk {'print $4'} | awk -F '=' {'print $2'}`"

ssh -i $KEY_PATH ubuntu@$WORKER1_IP
# Edit /etc/hosts and add:
# $MASTER_IP master
# $WORKER1_IP worker1

# Start worker
-- /opt/spark/sbin/start-slave.sh spark://master:7077

## Run application
ssh -i $KEY_PATH ubuntu@$MASTER_IP
# start application
-- /opt/spark/bin/spark-submit --class org.apache.spark.examples.SparkPi --master spark://master:7077 /opt/spark/lib/spark-examples-1.6.0-hadoop2.6.0.jar 2000

