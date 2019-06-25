from jamesdbloom/docker-java8-maven
RUN git clone https://github.com/Nexmo/comms-router.git
RUN cd comms-router/db-migrations
COPY liquibase.properties src/main/resources/liquibase.properties
RUN mvn liquibase:updateSQL
RUN apt install mysql-client
RUN cat target/liquibase/migrate.sql | mysql -h comms_router_host -D comms_router_core -u$comms-router -p$comms_password

