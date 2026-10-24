FROM jenkins/jenkins:lts-jdk21

USER root

# Instalar dependencias base y cliente oficial de Docker
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce-cli maven && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Pre-instalar plugins oficiales de Pipeline y Git para que no requieran descarga manual
RUN jenkins-plugin-cli --plugins git workflow-aggregator

# Copiar script de inicialización para crear el Pipeline OwlAudit automáticamente
COPY init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/

# Asegurar permisos para el usuario jenkins
USER jenkins
