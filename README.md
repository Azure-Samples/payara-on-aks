# Deploying a Java Application with Payara on an Azure Kubernetes Service Cluster

This sample shows how you can deploy a Java application using Payara on the Azure Kubernetes Service (AKS).

## Setup

* You will need an Azure subscription. If you don't have one, you can get one for free for one year [here](https://azure.microsoft.com/free).
* Install a Java SE implementation (for example, [Azul Zulu Java 11 LTS](https://www.azul.com/downloads/zulu-community/?version=java-11-lts&package=jdk)).
* Install [Maven](https://maven.apache.org/download.cgi) 3.5.0 or higher.
* Install [Docker](https://docs.docker.com/get-docker/) for your OS.
* Install [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest&preserve-view=true) 2.0.75 or later.
* Clone [this repository](https://github.com/Azure-Samples/payara-on-aks) to your local file system.

## Start Azure SQL

We will be using the fully managed Azure SQL offering for this sample.

* Go to the [Azure portal](http://portal.azure.com).
* Hit Create a resource -> Databases -> SQL Database.
* Create and select a new resource group named payara-cafe-group-`<your suffix>` (the suffix could be your first name such as "jane"). Specify the Database name as payara-cafe-db. Create and select a new server. Specify the Server name to be payara-cafe-db-`<your suffix>`. Specify the Server admin login to be, e.g., azuresql. Specify the password. Hit Review + create. Hit 'Create'. It will take a moment for the database to deploy and be ready for use. Note your server name, admin login name and password.
* In the portal, go to 'All resources'. Find and click on the resource with server name you specified before. Open the Firewalls and virtual networks panel. Enable access to Azure services and hit Save.

## Setup the AKS cluster

You will now need to create the AKS cluster. Go to the [Azure portal](http://portal.azure.com). Hit Create a resource -> Containers -> Kubernetes Service. Select the resource group to be payara-cafe-group-`<your suffix>`. Specify the cluster name as payara-cafe-cluster-`<your suffix>`. Hit Review + create. Hit Create.

## Setup Kubernetes Tooling

* You will now need to setup kubectl. [Here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) are instructions on how to do that.
* Next you will install the Azure CLI. [Here](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) are instructions on how to do that.
* You will then connect kubectl to the AKS cluster you created. To do so, run the following command:

  ```bash
  az aks get-credentials --resource-group payara-cafe-group-<your suffix> --name payara-cafe-cluster-<your suffix>
  ```

  If you get an error about an already existing resource, you may need to delete the ~/.kube directory.
* You need to have docker cli installed and you must be signed into your Docker Hub account. To create a Docker Hub account go to [https://hub.docker.com](https://hub.docker.com).

## Deploy the Java EE Application on Kubernetes

* Open a terminal. Navigate to where you have this repository code in your file system.
* Open `jakartaee-cafe/src/main/webapp/WEB-INF/web.xml` in a text editor. Replace `${server.name}` with `Server name`, replace  `${login.name}` with `login name`, and replace `${password}` with `password`.
* Do a full build of the jakartaee-cafe application via Maven

  ```bash
  mvn clean install --file jakartaee-cafe/pom.xml
  ```

* Download [postgresql-42.2.4.jar](https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.4/postgresql-42.2.4.jar) and put it to current working directory.
* Log in to Docker Hub using the docker login command:

  ```bash
  docker login
  ```

* Build a Docker image and push the image to Docker Hub:

  ```bash
  docker build -t <your Docker Hub ID>/jakartaee-cafe:v1 .
  docker push <your Docker Hub ID>/jakartaee-cafe:v1
  ```

* Replace the `${your.docker.hub.id}` value with your account name in `jakartaee-cafe.yml` file.
* You can now deploy the application:

  ```bash
  kubectl create -f jakartaee-cafe.yml
  ```

* Get and watch the status of the deployment:

  ```bash
  kubectl get deployment jakartaee-cafe --watch
  ```

  It may take a few minutes for the deployment to be completed. Wait until you see `2/2` under the `READY` column and `2` under the `AVAILABLE` column, hit `CTRL-C` to stop the `kubectl` watch process.
* Get the External IP address of the Service, then the application will be accessible at `http://<External IP Address>/jakartaee-cafe`:

  ```bash
  kubectl get svc jakartaee-cafe --watch
  ```

  It may take a few minutes for the load balancer to be created. When the external IP changes over from *pending* to a valid IP, just hit `Control-C` to exit.
* Scale your application:

  ```bash
  kubectl scale deployment jakartaee-cafe --replicas=3
  ```

## Deleting the Resources

Delete the application deployment:

```bash
kubectl delete -f jakartaee-cafe.yml
```

Once you are done exploring the demo, you should delete the jakartaee-cafe-group-`<your suffix>` resource group. You can do this by going to the portal, going to resource groups, finding and clicking on jakartaee-cafe-group-`<your suffix>` and hitting delete. This is especially important if you are not using a free subscription. The another option to delete all Azure resources is using `az group delete`:

```bash
az group delete --name jakartaee-cafe-group-<your suffix> --yes --no-wait
```
