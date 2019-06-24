from tomcat:8
RUN echo 'export CATALINA_OPTS="$CATALINA_OPTS -Dhibernate.dialect=org.hibernate.dialect.MySQL57Dialect"'> bin/setenv.sh
COPY conf/setenv.sh bin/setenv.sh
COPY conf/context.xml conf/context.xml

COPY comms-router-web.war webapps/comms-router-web.war

