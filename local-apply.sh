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
open https://127.0.0.1:30443

##########################

echo "...done"