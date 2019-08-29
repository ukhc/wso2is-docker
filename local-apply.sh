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

echo "ensure the correct environment is selected..."
KUBECONTEXT=$(kubectl config view -o template --template='{{ index . "current-context" }}')
if [ "$KUBECONTEXT" != "docker-desktop" ]; then
	echo "ERROR: Script is running in the wrong Kubernetes Environment: $KUBECONTEXT"
	exit 1
else
	echo "Verified Kubernetes context: $KUBECONTEXT"
fi

##########################

echo "setup the persistent volume for mariadb...."
mkdir -p /Users/Shared/Kubernetes/persistent-volumes/mariadb
kubectl apply -f https://raw.githubusercontent.com/ukhc/mariadb-docker/qa/kubernetes/mariadb-single-local-pv.yaml

##########################

echo "deploy mariadb...."
kubectl apply -f https://raw.githubusercontent.com/ukhc/mariadb-docker/kub-1/kubernetes/mariadb-single.yaml

echo "wait for mariadb..."
sleep 2
isPodReady=""
isPodReadyCount=0
until [ "$isPodReady" == "true" ]
do
	isPodReady=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].status.containerStatuses[*].ready}")
	if [ "$isPodReady" != "true" ]; then
		((isPodReadyCount++))
		if [ "$isPodReadyCount" -gt "100" ]; then
			echo "ERROR: timeout waiting for mariadb pod. Exit script!"
			exit 1
		else
			echo "waiting...mariadb pod is not ready...($isPodReadyCount/100)"
			sleep 2
		fi
	fi
done

##########################

echo "init the database...."
POD=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'create database WSO2_CARBON_DB'
kubectl exec -i $POD -- /usr/bin/mysql -u root -padmin -s -DWSO2_CARBON_DB < ./dbscripts/mysql.sql
kubectl exec -i $POD -- /usr/bin/mysql -u root -padmin -s -DWSO2_CARBON_DB < ./dbscripts/identity/mysql.sql
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'show databases'

##########################

echo
echo "#################################"
echo "##  ADDING DNS TO /ETC/HOSTS   ##"
echo "##             ---             ##"
echo "## If you are prompted for a   ##"
echo "## password, use your local    ##"
echo "## account password.           ##"
echo "#################################"
echo

# add dns
sudo -- sh -c "echo 127.0.0.1 wso2is  >> /etc/hosts"

##########################

echo "deploy wso2is..."
kubectl apply -f ./kubernetes/wso2is.yaml

echo "wait for wso2is..."
sleep 2
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
			echo "waiting...wso2is pod is not ready...($isPodReadyCount/100)"
			sleep 2
		fi
	fi
done

##########################

echo "opening the browser..."
echo "username: admin"
echo "password: admin"
open https://wso2is:9443

##########################

echo "...done"