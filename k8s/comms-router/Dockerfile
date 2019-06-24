FROM openjdk:8-jdk as build

RUN wget http://archive.apache.org/dist/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz \
&& tar -zxvf apache-maven-3.5.4-bin.tar.gz \
&& rm apache-maven-3.5.4-bin.tar.gz \
&& mv apache-maven-3.5.4 /usr/lib/mvn

ENV PATH=$PATH:/usr/lib/mvn/bin

WORKDIR /usr/src/
COPY ../.. .
RUN mvn clean install
from tomcat:10
RUN echo 'export CATALINA_OPTS="$CATALINA_OPTS -Dhibernate.dialect=org.hibernate.dialect.MySQL57Dialect"'> bin/setenv.sh
COPY --from=builder /usr/src/k8s/comms-router/conf/setenv.sh bin/setenv.sh
COPY --from=builder /usr/src/k8s/comms-router/conf/context.xml conf/context.xml

COPY --from=builder /usr/src/web/target/comms-router-web.war webapps/comms-router-web.war
COPY --from=builder /usr/src/applications/demo/target/demo-application-*.war webapps/
