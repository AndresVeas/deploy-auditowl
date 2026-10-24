# Guía Completa de Instalación y Despliegue con Docker: Jenkins, MariaDB y Tomcat

Esta guía cubre la configuración desde cero de un entorno de Integración y Entrega Continua (CI/CD) y ejecución local usando Docker, integrando:
- **Jenkins:** Servidor de automatización (con Docker-out-of-Docker y herramientas para compilar).
- **MariaDB:** Base de datos relacional con carga inicial automática (`init.sql`).
- **Apache Tomcat:** Servidor de aplicaciones web Java (empaquetado con el archivo `.war`).

---

## 1. Arquitectura del Sistema

```
  ┌────────────────────────────────────────────────────────┐
  │                 Entorno Local (Docker)                 │
  │                                                        │
  │  ┌──────────────┐   docker build/push   ┌───────────┐  │
  │  │   Jenkins    │ ────────────────────> │ DockerHub │  │
  │  │ (Puerto 8081)│                       └─────┬─────┘  │
  │  └──────────────┘                             │        │
  │                                         docker pull    │
  │                                               │        │
  │        ┌──────────────────Red: app-network────┴───┐   │
  │        │                                          │   │
  │        │  ┌────────────────┐   ┌───────────────┐  │   │
  │        │  │ Tomcat + App   │   │ MariaDB 10.11 │  │   │
  │        │  │  (Puerto 8080) │──>│ (Puerto 3306) │  │   │
  │        │  └────────────────┘   └───────────────┘  │   │
  │        └──────────────────────────────────────────┘   │
  └────────────────────────────────────────────────────────┘
```

---

## 2. Requisitos Previos

1. **Docker Desktop** (o Docker Engine en Linux) instalado y en ejecución:
   ```bash
   docker --version
   docker compose version
   ```
2. **Cuenta activa en Docker Hub** para publicar las imágenes resultantes.
3. Repositorio de código con proyecto Java (Maven, `pom.xml` configurado para empaquetar tipo `war`).

---

## 3. Configuración del Servidor Jenkins

Jenkins necesita:
- Persistencia de datos (`jenkins_home`).
- Acceso al daemon de Docker del host para poder construir imágenes (`docker.sock`).
- Maven o utilidades de compilación.

### 3.1. Estructura de Directorios para Jenkins
```text
jenkins-setup/
├── Dockerfile
└── docker-compose.yml
```

### 3.2. Dockerfile para Jenkins con Docker CLI
Crea un `Dockerfile` que añada el cliente de Docker dentro del contenedor de Jenkins:

```dockerfile
FROM jenkins/jenkins:lts-jdk17

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

# Asegurar permisos para el usuario jenkins
USER jenkins
```

### 3.3. `docker-compose.yml` para Jenkins
```yaml
version: '3.8'

services:
  jenkins:
    build: .
    container_name: jenkins-server
    restart: unless-stopped
    ports:
      - "8081:8080"      # Acceso a la interfaz web (evita conflicto con Tomcat en el 8080)
      - "50000:50000"    # Comunicación entre agentes
    volumes:
      - jenkins_data:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock # Permite ejecutar comandos 'docker' desde Jenkins
    environment:
      - TZ=America/Guayaquil
    user: root # Facilita el acceso directo al socket de Docker en entornos locales

volumes:
  jenkins_data:
```

### 3.4. Inicialización de Jenkins
Ejecuta:
```bash
docker compose up -d --build
```

Obtén la contraseña inicial de administrador:
```bash
docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword
```

1. Ve a `http://localhost:8081`.
2. Pega la contraseña administrativa.
3. Elige **"Install suggested plugins"**.
4. Crea tu usuario administrador principal.

---

## 4. Configuración de Credenciales en Jenkins

Para que Jenkins pueda subir imágenes a Docker Hub:

1. Dirígete a **Administrar Jenkins (Manage Jenkins)** > **Credentials** > **System** > **Global credentials (unrestricted)**.
2. Haz clic en **Add Credentials**.
3. Configura:
   - **Kind:** Username with password
   - **Username:** Tu usuario de Docker Hub.
   - **Password:** Tu contraseña o Personal Access Token (PAT) de Docker Hub.
   - **ID:** `dockerhub-credentials` *(recuerda este ID para el pipeline)*.
4. Guarda las credenciales.

---

## 5. Empaquetado de la Aplicación (Tomcat + Java)

El empaquetado del archivo `.war` dentro de Tomcat se realiza mediante el `Dockerfile` ubicado en la raíz del proyecto Java.

### `Dockerfile` (Aplicación Web)
```dockerfile
# Runtime base ligero con Tomcat y JDK 17
FROM tomcat:10.1-jdk17-temurin

# Limpiar las aplicaciones por defecto de Tomcat
RUN rm -rf /usr/local/tomcat/webapps/*

# Copiar el archivo WAR generado en el build como la aplicación raíz (ROOT.war)
COPY target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
```

---

## 6. Pipeline de Jenkins (`Jenkinsfile`)

Ubica este archivo en la raíz de tu repositorio de GitHub:

```groovy
pipeline {
    agent any

    environment {
        // ID de las credenciales configuradas en Jenkins
        DOCKER_HUB_CREDS = credentials('dockerhub-credentials')
        // Nombre del repositorio en Docker Hub: usuario/nombre-imagen
        IMAGE_NAME       = 'tu_usuario/tu-app-java'
        IMAGE_TAG        = 'latest'
    }

    stages {
        stage('1. Checkout SCM') {
            steps {
                echo 'Descargando el código del repositorio...'
                checkout scm
            }
        }

        stage('2. Build y Tests (Maven)') {
            steps {
                echo 'Compilando proyecto y ejecutando pruebas unitarias...'
                sh 'mvn clean package -DskipTests=false'
            }
        }

        stage('3. Build Docker Image') {
            steps {
                echo 'Empaquetando la aplicación en la imagen Tomcat...'
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('4. Push to Docker Hub') {
            steps {
                echo 'Autenticando y subiendo imagen a Docker Hub...'
                sh """
                    echo "${DOCKER_HUB_CREDS_PSW}" | docker login -u "${DOCKER_HUB_CREDS_USR}" --password-stdin
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline completado con éxito. Imagen disponible en ${IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo "Hubo un error en la ejecución del pipeline."
        }
        always {
            // Cierra la sesión de Docker para mantener el entorno limpio
            sh 'docker logout'
        }
    }
}
```

### Configuración del Job en Jenkins:
1. En Jenkins, haz clic en **Nueva Tarea (New Item)**.
2. Ingresa un nombre (ej. `mi-app-pipeline`) y selecciona **Pipeline**.
3. En la sección **Pipeline**:
   - **Definition:** `Pipeline script from SCM`
   - **SCM:** `Git`
   - **Repository URL:** La URL pública de tu repositorio en GitHub.
   - **Branch Specifier:** `*/main` o `*/master`
   - **Script Path:** `Jenkinsfile`
4. Guarda y haz clic en **Construir ahora (Build Now)** para disparar el flujo manual.

---

## 7. Despliegue de la Aplicación y MariaDB

Para ejecutar la aplicación localmente o entregársela al evaluador sin compilar el código Java desde cero, se orquesta Tomcat y MariaDB.

### 7.1. Estructura de Despliegue
```text
despliegue/
├── docker-compose.yml
├── deploy.sh
└── db/
    └── init.sql
```

### 7.2. Script Inicial de Base de Datos (`db/init.sql`)
```sql
CREATE DATABASE IF NOT EXISTS app_db;
USE app_db;

CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO usuarios (nombre, email) VALUES
('Administrador', 'admin@ejemplo.com'),
('Profesor', 'profesor@universidad.edu');
```

### 7.3. `docker-compose.yml` (Orquestación del Runtime)
```yaml
version: '3.8'

services:
  # Servicio de Base de Datos
  db:
    image: mariadb:10.11
    container_name: app-mariadb
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: root_password
      MARIADB_DATABASE: app_db
      MARIADB_USER: app_user
      MARIADB_PASSWORD: user_password
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql
      # Ejecuta el script SQL en el primer arranque
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - app-net
    healthcheck:
      test: ["CMD", "mariadb-admin", "ping", "-h", "localhost", "-u", "root", "-proot_password"]
      interval: 5s
      timeout: 5s
      retries: 5

  # Servicio Web (Tomcat con el WAR dentro)
  app:
    image: tu_usuario/tu-app-java:latest
    container_name: app-tomcat
    restart: unless-stopped
    ports:
      - "8080:8080"
    depends_on:
      db:
        condition: service_healthy # Espera que MariaDB responda antes de arrancar Tomcat
    environment:
      - DB_HOST=db
      - DB_PORT=3306
      - DB_NAME=app_db
      - DB_USER=app_user
      - DB_PASSWORD=user_password
    networks:
      - app-net

volumes:
  db_data:

networks:
  app-net:
    driver: bridge
```

### 7.4. Script de Automatización de Despliegue (`deploy.sh`)
```bash
#!/bin/bash
set -e

# Colores para la salida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}    Iniciando Despliegue del Sistema       ${NC}"
echo -e "${BLUE}===========================================${NC}"

echo -e "\n${GREEN}[1/3] Descargando imagen más reciente de la aplicación...${NC}"
docker compose pull app

echo -e "\n${GREEN}[2/3] Levantando MariaDB y Tomcat...${NC}"
docker compose up -d

echo -e "\n${GREEN}[3/3] Verificando estado de los servicios...${NC}"
docker compose ps

echo -e "\n${BLUE}===========================================${NC}"
echo -e "${GREEN}¡Despliegue completado!${NC}"
echo -e "Aplicación Web (Tomcat): ${GREEN}http://localhost:8080${NC}"
echo -e "Base de datos (MariaDB): ${GREEN}localhost:3306 (DB: app_db)${NC}"
echo -e "${BLUE}===========================================${NC}"
```

Asegúrate de otorgar permisos de ejecución al script antes de usarlo:
```bash
chmod +x deploy.sh
```

---

## 8. Comandos de Operación Rápida

| Acción | Comando |
| :--- | :--- |
| Iniciar Jenkins | `docker compose -f jenkins-setup/docker-compose.yml up -d` |
| Ver logs de Jenkins | `docker logs -f jenkins-server` |
| Desplegar App y Base de Datos | `./deploy.sh` |
| Ver logs de la App Web | `docker logs -f app-tomcat` |
| Detener aplicación y preservar datos | `docker compose down` |
| Detener aplicación y borrar base de datos | `docker compose down -v` |