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

echo "delete wso2is..."
kubectl delete -f ./kubernetes/wso2is.yaml

##########################

echo "delete mariadb...."
kubectl delete -f https://raw.githubusercontent.com/ukhc/mariadb-docker/kub-1/kubernetes/mariadb-single.yaml

##########################

echo "delete the persistent volume for mariadb...."
kubectl delete -f https://raw.githubusercontent.com/ukhc/mariadb-docker/qa/kubernetes/mariadb-single-local-pv.yaml
#rm -rf /Users/Shared/Kubernetes/persistent-volumes/mariadb

##########################

echo "...done"