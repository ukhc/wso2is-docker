# WSO2 Identity Server

## Reference
- https://hub.docker.com/r/wso2/wso2is


## Docker deployment to the local workstation

~~~
# start the container
docker run --name wso2is -p 9763:9763 -p 9443:9443 -p 10389:10389 -d wso2/wso2is:5.8.0

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

## Deploy and development workflow
The basic workflow is... 
1. Deploy WSO2is with a initialized database so you can create a basic configuration
1. Create a backup of that basic configuration
1. Congratulations, you now have a working WSO2is environment

From here you can make whatever changes you like to WSO2is.  You can create more backups for point in time restores.  There's even a script that makes it easy to restart the WSO2is deployment.  When you're all done, there is a delete script that will remove the deployment but don't worry... as long as you have a backup, you can re-deploy and restore to the state where you left off.


NOTE: Run the following commands from the root folder of this repo.

### Deploy a new WSO2is along with a MariaDB that has an initialized WSO2_CARBON_DB database
~~~
./local-apply.sh
~~~

Note: The default admin password is admin


Use this to do the initial installation and configuration for WSO2is.  Once you are satisfied with the setup, you can back it up.  


### Create a backup of the persistent volume and database
~~~
./local-backup.sh
~~~

This backs up the database. The backup will be created in the 'backup' folder in this repo. You can take multiple backups.


### Delete the deployment
~~~
./local-delete.sh
~~~

Once you have a configuration that you are happy with, back it up.


### Restore from backup (pass it the backup folder name)
~~~
./local-restore.sh 2019-10-31_20-05-55
~~~

Restore from one of your backup folders to populate the database.  The backups are stored in the 'backup' folder in this repo.


### Restart the deployment
~~~
./local-restart.sh
~~~

Some changes may require a restart of the containers.  This script will do that for you.


### Scale the deployment
~~~
kubectl scale --replicas=4 deployment/wso2is
~~~
