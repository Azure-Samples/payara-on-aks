# Deploying a Java Application with Payara on an Azure Kubernetes Service Cluster

This sample shows how you can deploy a Java application using Payara on the Azure Kubernetes Service (AKS).

## Setup

* Prepare a local machine with a Unix-like operating system installed (for example, Ubuntu, macOS, Windows Subsystem for Linux).
* You will need an Azure subscription. If you don't have one, you can get one for free for one year [here](https://azure.microsoft.com/free).
* Install a Java SE implementation (for example, [Azul Zulu Java 8 LTS](https://www.azul.com/downloads/zulu-community/?version=java-8-lts&package=jdk)).
* Install [Maven](https://maven.apache.org/download.cgi) 3.5.0 or higher.
* Install [Docker](https://docs.docker.com/get-docker/) for your OS.
* Install [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest&preserve-view=true) 2.0.75 or later. Make sure to sign in to the Azure CLI by using the [az login](https://docs.microsoft.com/cli/azure/reference-index?view=azure-cli-latest#az_login) command. To finish the authentication process, follow the steps displayed in your terminal. For additional sign-in options, see [Sign in with the Azure CLI](https://docs.microsoft.com/cli/azure/authenticate-azure-cli).
* Clone [this repository](https://github.com/Azure-Samples/payara-on-aks) to your local file system.

## Start Azure SQL

We will be using the fully managed Azure SQL offering for this sample.

* Go to the [Azure portal](http://portal.azure.com).
* Hit Create a resource -> Databases -> SQL Database.
* Create and select a new resource group named payara-cafe-group-`<your suffix>` (the suffix could be your first name such as "jane"). Specify the Database name as payara-cafe-db. Create and select a new server. Specify the Server name to be payara-cafe-db-`<your suffix>`. Specify the Server admin login to be, for example, azuresql. Specify the password. Hit Review + create. Hit 'Create'. It will take a moment for the database to deploy and be ready for use. Note your server name, admin login name and password.
* In the portal, go to 'All resources'. Find and click on the resource with server name you specified before. Open the Firewalls and virtual networks panel. Enable access to Azure services and hit Save.

## Set up an ACR instance

You will need to next create an Azure Container Registry (ACR) instance to publish Docker images. Use the [az acr create](https://docs.microsoft.com/cli/azure/acr?view=azure-cli-latest#az_acr_create) command to create the ACR instance:

  ```bash
  RESOURCE_GROUP_NAME=payara-cafe-group-<your suffix>
  REGISTRY_NAME=payaracaferegistry<your suffix>
  az acr create --resource-group $RESOURCE_GROUP_NAME --name $REGISTRY_NAME --sku Basic --admin-enabled  
  ```

## Connect to the ACR instance

You will need to sign in to the ACR instance before you can push a Docker image to it. Run the following commands to connect to ACR:

```bash
LOGIN_SERVER=$(az acr show -n $REGISTRY_NAME --query 'loginServer' -o tsv)
USER_NAME=$(az acr credential show -n $REGISTRY_NAME --query 'username' -o tsv)
PASSWORD=$(az acr credential show -n $REGISTRY_NAME --query 'passwords[0].value' -o tsv)

docker login $LOGIN_SERVER -u $USER_NAME -p $PASSWORD
```

You should see `Login Succeeded` at the end of command output if you have logged into the ACR instance successfully.

## Setup the AKS cluster

You will now need to create the AKS cluster. For this sample, we will use Azure App Gateway as our Kubernetes Ingress Controller. Use the [az aks create](https://docs.microsoft.com/cli/azure/aks?view=azure-cli-latest#az_aks_create) command to create an AKS cluster. This will take several minutes to complete:

```bash
CLUSTER_NAME=payara-cafe-cluster
GATEWAY_NAME=payara-cafe-gateway
az aks create --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --generate-ssh-keys --enable-managed-identity --attach-acr $REGISTRY_NAME --network-plugin azure -a ingress-appgw --appgw-name $GATEWAY_NAME --appgw-subnet-cidr "10.2.0.0/16"
```

Note: You need to be an **owner of the subscription** in order to successfully execute the command, which will automatically attach the ACR instance to the created AKS cluster. If this is not the case, use an image pull secret to enable the AKS cluster to pull the image from the ACR instance instead. You can refer to [this guide](https://docs.microsoft.com/azure/aks/howto-deploy-java-liberty-app#create-an-aks-cluster) to understand more about this approach.

## Set up Kubernetes tooling

* You will need to setup kubectl, the Kubernetes command-line client. Execute the following command to do so:

  ```bash
  az aks install-cli
  ```

* You will then connect kubectl to the AKS cluster you created. To do so, run the following command:

  ```bash
  az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME
  ```

  If you get an error about an already existing resource, you may need to delete the ~/.kube directory.

## Deploy the Java Application on AKS

* Open a terminal. Navigate to where you have this repository code in your file system.
* Open `payara-cafe/src/main/webapp/WEB-INF/web.xml` in a text editor. Replace `${server.name}` with `server name`, replace  `${login.name}` with `admin login name`, and replace `${password}` with `password`.
* Do a full build of the payara-cafe application via Maven.

  ```bash
  mvn clean install --file payara-cafe/pom.xml
  ```

* Download [mssql-jdbc-9.2.0.jre8.jar](https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/9.2.0.jre8/mssql-jdbc-9.2.0.jre8.jar) and put it to current working directory.
* Build a Docker image and push the image to ACR:

  ```bash
  az acr build -t payara-cafe:v1 -r $REGISTRY_NAME .  
  ```

* Replace the `${login.server}` value in the `payara-cafe.yml` file with your ACR server URL (stored in the $LOGIN_SERVER variable used previously).
* You can now deploy the application:

  ```bash
  kubectl create -f payara-cafe.yml
  ```

* Get and watch the status of the deployment:

  ```bash
  kubectl get deployment payara-cafe --watch
  ```

  It may take a few minutes for the deployment to be completed. Wait until you see `2/2` under the `READY` column and `2` under the `AVAILABLE` column, hit `CTRL-C` to stop the `kubectl` watch process.

## Enable Session Affinity

The sample application is stateful and highly available through Payara Kubernetes clustering. For this reason, we will need to enable App Gateway session affinity.

* Go to the [Azure portal](http://portal.azure.com).
* In the portal, go to 'All resources'. Find and click on the resource with `payara-cafe-gateway` as the name.
* Open the HTTP settings panel. Find the setting with `payara-cafe` included in the name and click on it.
* Enable Cookie based session affinity and hit Save.

## Access the Application  
  
Get the external IP address of the App Gateway Ingress, then the application will be accessible at `http://<Address>` (you can also get the address from the App Gateway overview panel in the portal):

```bash
kubectl get ingress
```
  
It may take a moment for the App Gateway to properly connect with the backend pool. It is a good idea to check the Backend health panel for the App Gateway in the portal.

## Delete the Resources

Once you are done exploring the sample, you should delete the payara-cafe-group-`<your suffix>` resource group. You can do this by going to the portal, going to resource groups, finding and clicking on payara-cafe-group-`<your suffix>` and hitting delete. This is especially important if you are not using a free subscription.

Another option to delete Azure resources is using `az group delete`:

```bash
az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait
```
