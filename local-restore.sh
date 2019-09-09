# Copyright (c) 2019, UK HealthCare (https://ukhealthcare.uky.edu) All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


##########################
# validate positional parameters

if [ "$1" == "" ]
then
	echo "USEAGE: ./local-restore.sh [BACKUP_FOLDER_NAME]"
	echo "e.g. ./local-restore.sh local_2019-10-31_20-05-55"
	exit 1
fi

BACKUP_FOLDER="$1"
if [ -d "./backup/$BACKUP_FOLDER" ] 
then
    # ./backup/$BACKUP_FOLDER exists
    echo "Restoring from $BACKUP_FOLDER..."
else
    echo "ERROR: Directory ./backup/$BACKUP_FOLDER does not exist"
	exit 1
fi

##########################

echo
echo "*** WARNING: This script will restore the the data in the database ***"
echo "*** WARNING: You will lose any changes you have made in the current deployment ***"
echo
read -n 1 -s -r -p "Press any key to continue or CTRL-C to exit..."

echo

##########################

echo "ensure the correct environment is selected..."
KUBECONTEXT=$(kubectl config view -o template --template='{{ index . "current-context" }}')
if [ "$KUBECONTEXT" != "docker-desktop" ]; then
	echo "ERROR: Script is running in the wrong Kubernetes Environment: $KUBECONTEXT"
	exit 1
else
	echo "Verified Kubernetes context: $KUBECONTEXT"
fi

##########################

echo "restore database..."
POD=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'drop database if exists WSO2_CARBON_DB'
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'create database WSO2_CARBON_DB'
kubectl exec -i $POD -- /usr/bin/mysql -u root -padmin WSO2_CARBON_DB < ./backup/$BACKUP_FOLDER/database/WSO2_CARBON_DB-dump.sql
# validate
# kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'use WSO2_CARBON_DB;show tables;'

##########################

echo "restart the wso2is deployment..."
kubectl scale --replicas=0 deployment wso2is
echo "wait a moment..."
sleep 5
kubectl scale --replicas=1 deployment wso2is

##########################

echo "wait for wso2is..."
isPodReady=""
isPodReadyCount=0
until [ "$isPodReady" == "true" ]
do
	isPodReady=$(kubectl get pod -l app=wso2is -o jsonpath="{.items[0].status.containerStatuses[*].ready}")
	if [ "$isPodReady" != "true" ]; then
		((isPodReadyCount++))
		if [ "$isPodReadyCount" -gt "100" ]; then
			echo "ERROR: timeout waiting for wso2is pod. Exit script!"
			exit 1
		else
			echo "waiting...wso2is pod is not ready...($isPodReadyCount)"
			sleep 2
		fi
	fi
done

##########################

echo "open the browser..."
open https://127.0.0.1:9443

##########################

echo
echo "...done"