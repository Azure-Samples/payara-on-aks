# Deploying a Jakarta EE application inside Payara server on an Azure Kubernetes Service cluster

This demo shows how you can deploy a Jakarta EE application to Azure using Docker and Kubernetes. The following is how you run the demo.

## Setup

* You will need an Azure subscription. If you don't have one, you can get one for free for one year [here](https://azure.microsoft.com/free).
* Install a Java SE implementation (for example, [AdoptOpenJDK OpenJDK 8 LTS/OpenJ9](https://adoptopenjdk.net/?variant=openjdk8&jvmVariant=openj9)).
* Install [Maven](https://maven.apache.org/download.cgi) 3.5.0 or higher.
* Install [Docker](https://docs.docker.com/get-docker/) for your OS.
* Install [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest&preserve-view=true) 2.0.75 or later.
* Clone [this repository](https://github.com/Azure-Samples/payara-on-aks) to your local file system.

## Start Managed PostgreSQL on Azure

We will be using the fully managed PostgreSQL offering in Azure for this demo. If you have not set it up yet, please do so now.

* Go to the [Azure portal](http://portal.azure.com).
* Select 'Create a resource'. In the search box, enter and select 'Azure Database for PostgreSQL'. Hit create. Select a single server.
* Specify the Server name, e.g., jakartaee-cafe-db-`<your suffix>` (the suffix could be your first name such as "reza"). Create a new resource group named jakartaee-cafe-group-`<your suffix>` (the suffix could be your first name such as "reza"). Specify the login name, e.g., postgres. Specify the password. Hit 'Create'. It will take a moment for the database to deploy and be ready for use. Log down server name, login name and password.
* In the portal, go to 'All resources'. Find and click on the resource with server name you specified before. Open the connection security panel. Enable access to Azure services, disable SSL connection enforcement and then hit Save.

## Setup the Kubernetes Cluster

You will first need to create the Kubernetes cluster. Go to the [Azure portal](http://portal.azure.com). Hit Create a resource -> Containers -> Kubernetes Service. Select the resource group to be jakartaee-cafe-group-`<your suffix>`. Specify the cluster name as jakartaee-cafe-cluster-`<your suffix>` (the suffix could be your first name such as "reza"). Hit Review + create. Hit Create.

## Setup Kubernetes Tooling

* You will now need to setup kubectl. [Here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) are instructions on how to do that.
* Next you will install the Azure CLI. [Here](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) are instructions on how to do that.
* You will then connect kubectl to the Kubernetes cluster you created. To do so, run the following command:

  ```bash
  az aks get-credentials --resource-group jakartaee-cafe-group-<your suffix> --name jakartaee-cafe-cluster-<your suffix>
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
