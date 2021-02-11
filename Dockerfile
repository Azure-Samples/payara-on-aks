FROM payara/micro
COPY payara-cafe/target/payara-cafe.war $DEPLOY_DIR
COPY mssql-jdbc-9.2.0.jre8.jar /tmp
CMD ["--contextRoot", "/payara-cafe", "--addLibs", "/tmp/mssql-jdbc-9.2.0.jre8.jar", "--clustermode", "kubernetes", "/opt/payara/deployments/payara-cafe.war"]