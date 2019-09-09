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

echo "delete conf configmap..."
kubectl delete -f ./kubernetes/wso2is-configmap-conf.yaml

##########################

echo "delete conf datasources configmap..."
kubectl delete -f ./kubernetes/wso2is-configmap-conf-datasources.yaml

##########################

echo "delete conf identity configmap..."
kubectl delete -f ./kubernetes/wso2is-configmap-conf-identity.yaml

##########################

echo "delete wso2is..."
kubectl delete -f ./kubernetes/wso2is.yaml

##########################

echo "delete mariadb...."
kubectl delete -f https://raw.githubusercontent.com/ukhc/mariadb-docker/master/kubernetes/mariadb-single.yaml

##########################

echo "delete the persistent volume for mariadb...."
kubectl delete -f https://raw.githubusercontent.com/ukhc/mariadb-docker/master/kubernetes/mariadb-single-local-pv.yaml
rm -rf /Users/Shared/Kubernetes/persistent-volumes/default/mariadb

##########################

echo
echo "#####################################"
echo "##  REMOVE ENTRY FROM /ETC/HOSTS   ##"
echo "##               ---               ##"
echo "##    If you are prompted for a    ##"
echo "##    password, use your local     ##"
echo "##    account password.            ##"
echo "#####################################"
echo

sudo sed -ie "\|^127.0.0.1 wso2is\$|d" /etc/hosts

##########################

echo "...done"