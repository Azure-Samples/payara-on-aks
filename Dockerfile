FROM payara/server-full
COPY payara-cafe/target/payara-cafe.war $DEPLOY_DIR
COPY mssql-jdbc-9.2.0.jre8.jar /tmp
RUN echo 'add-library /tmp/mssql-jdbc-9.2.0.jre8.jar' > $POSTBOOT_COMMANDS