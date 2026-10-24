# Runtime base ligero con Tomcat 10.1 y JDK 21 (compatible con pom.xml Java 21)
FROM tomcat:10.1-jdk21-temurin

# Limpiar las aplicaciones por defecto de Tomcat
RUN rm -rf /usr/local/tomcat/webapps/*

# Copiar el archivo WAR generado en el build como la aplicación raíz (ROOT.war)
COPY target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
