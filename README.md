# WSO2 Identity Server

## Reference
- https://hub.docker.com/r/wso2/wso2is


## Docker deployment to the local workstation

~~~
# start the container
VERSION=$(cat version)
docker run --name wso2is -p 9443:9443 -d wso2/wso2is:5.8.0

# see the status
docker container ls

# open the url
open https://127.0.0.1:9443/carbon

# destroy the container
docker container stop wso2is
docker container rm wso2is
~~~


## Kubernetes deployment to the local workstation (macOS only)

## Prep your local workstation (macOS only)
1. Clone this repo and work in it's root directory
1. Install Docker Desktop for Mac (https://www.docker.com/products/docker-desktop)
1. In Docker Desktop > Preferences > Kubernetes, check 'Enable Kubernetes'
1. Click on the Docker item in the Menu Bar. Mouse to the 'Kubernetes' menu item and ensure that 'docker-for-desktop' is selected.


## Deploy
Before you deploy, you will need a running instance of MariaDB in Kubernetes: https://github.com/ukhc/mariadb-docker


Deploy (run these commands from the root folder of this repo)
~~~
mkdir -p /Users/Shared/Kubernetes/persistent-volumes/wso2is
kubectl apply -f ./kubernetes/wso2is-local-pv.yaml
kubectl apply -f ./kubernetes/wso2is.yaml

# validation
kubectl get pods

open http://127.0.0.1
~~~

Note: The default admin password is admin

Delete
~~~
kubectl delete -f ./kubernetes/wso2is.yaml
kubectl delete -f ./kubernetes/wso2is-local-pv.yaml
rm -rf /Users/Shared/Kubernetes/persistent-volumes/wso2is
~~~