FROM payara/server-full
COPY jakartaee-cafe/target/jakartaee-cafe.war $DEPLOY_DIR
COPY postgresql-42.2.4.jar /tmp
RUN echo 'add-library /tmp/postgresql-42.2.4.jar' > $POSTBOOT_COMMANDS