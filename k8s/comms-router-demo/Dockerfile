from tomcat:8
#dordoka/tomcat
RUN echo 'export CATALINA_OPTS="$CATALINA_OPTS -Dhibernate.dialect=org.hibernate.dialect.MySQL57Dialect"'> bin/setenv.sh
COPY conf/setenv.sh bin/setenv.sh
COPY conf/context.xml conf/context.xml
COPY conf/shiro.ini conf/shiro.ini
COPY conf/no-auth.properties conf/application.properties
COPY conf/private.key conf/private.key
COPY *.jar lib/

COPY demo-application.war webapps/cr\#demo.war
