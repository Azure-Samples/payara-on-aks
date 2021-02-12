FROM payara/micro
COPY mssql-jdbc-9.2.0.jre8.jar /tmp
COPY payara-cafe/target/payara-cafe.war $DEPLOY_DIR
CMD ["--contextRoot", "/", "--addLibs", "/tmp/mssql-jdbc-9.2.0.jre8.jar", "--clustermode", "kubernetes", "/opt/payara/deployments/payara-cafe.war"]
