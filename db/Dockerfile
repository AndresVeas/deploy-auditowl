FROM mariadb:10.11

# Variables de entorno por defecto para inicialización de la base de datos
ENV MARIADB_ROOT_PASSWORD=root_password
ENV MARIADB_DATABASE=owl_auditv1
ENV MARIADB_USER=user
ENV MARIADB_PASSWORD=12345

# Copiar el script SQL de esquema y semillas para que se ejecute en el primer arranque
COPY init.sql /docker-entrypoint-initdb.d/init.sql
