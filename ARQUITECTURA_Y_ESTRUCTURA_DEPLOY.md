# 🏛️ Arquitectura y Estructura del Repositorio de Despliegue (`deploy-auditowl`)

Este documento describe la arquitectura técnica, las decisiones de diseño y el propósito específico de cada archivo y directorio que conforman el repositorio **`deploy-auditowl`**.

---

## 📂 1. Árbol de Directorios y Archivos

```text
deploy-auditowl/
├── Dockerfile                             # Empaquetado de la aplicación web en Apache Tomcat 10.1 (Java 21)
├── docker-compose.yml                     # Orquestación de contenedores para despliegue local (App + DB)
├── deploy.bat                             # Script de arranque rápido con docker compose para Windows
├── deploy.sh                              # Script de arranque rápido con docker compose para Linux / macOS
├── stop-deploy.bat                        # Script de detención limpia para Windows
├── stop-deploy.sh                         # Script de detención limpia para Linux / macOS
├── get-next-tag.sh                        # Script de versionamiento dinámico contra la API de Docker Hub
├── Jenkinsfile                            # Pipeline declarativo de CI/CD para Jenkins
├── README.md                              # Documentación general rápida del repositorio
├── GUIA_EQUIPO_DESARROLLO.md              # Manual operativo detallado para los desarrolladores del equipo
├── GUIA_EVALUADOR_PROFESOR.md             # Guía paso a paso para el evaluador / docente (sin clonar código)
├── ARQUITECTURA_Y_ESTRUCTURA_DEPLOY.md    # Este documento (explicación técnica y propósito de cada archivo)
│
├── db/                                    # Módulo de base de datos personalizada
│   ├── Dockerfile                         # Imagen MariaDB con semilla de inicialización inyectada
│   └── init.sql                           # Script DDL/DML con esquema y usuarios de prueba
│
├── docker-compose-deploy/                 # Módulo de despliegue modular para evaluación y demostración en video
│   ├── README.md                          # Manual de uso rápido de los docker compose de evaluación
│   ├── app/                               # Submódulo Aplicación Web + MariaDB
│   │   └── docker-compose.yml             # Orquesta MariaDB y Tomcat usando directamente imágenes de Docker Hub
│   └── jenkins/                           # Submódulo Servidor CI/CD
│       └── docker-compose.yml             # Orquesta Jenkins usando la imagen publicada con Docker Socket montado
│
└── jenkins-setup/                         # Módulo de infraestructura y construcción de imagen Jenkins
    ├── Dockerfile                         # Imagen de Jenkins con Docker CLI, Maven, Git y plugins
    ├── docker-compose.yml                 # Orquestación de Jenkins local con mapeo de Docker Socket
    ├── start-jenkins.bat                  # Script de inicio e impresión de clave de admin para Windows
    ├── start-jenkins.sh                   # Script de inicio e impresión de clave de admin para Linux / macOS
    ├── stop-jenkins.bat                   # Script de apagado de Jenkins para Windows
    ├── stop-jenkins.sh                    # Script de apagado de Jenkins para Linux / macOS
    └── init.groovy.d/                     # Hooks de inicialización automática de Jenkins
        └── 01-create-pipeline.groovy      # Script Groovy que autoprovisiona el job 'OwlAudit-Pipeline'
```

---

## 📄 2. Propósito Detallado de Cada Archivo

### A. Raíz del Repositorio (Despliegue y CI/CD)

#### `Dockerfile`
* **Tecnología:** Dockerfile basado en `tomcat:10.1-jdk21-temurin-jammy`.
* **Propósito:** Toma el archivo binario web empaquetado (`target/*.war`) generado durante la compilación Maven y lo ubica en `/usr/local/tomcat/webapps/ROOT.war`.
* **Decisión de Diseño:** 
  - Se eliminan las aplicaciones por defecto de Tomcat (`rm -rf /usr/local/tomcat/webapps/*`) para reducir peso, eliminar vulnerabilidades y permitir que la aplicación responda directamente en la raíz (`/`) del servidor (puerto 8080) sin necesidad de prefijos como `/Owl_Audit_App`.

#### `docker-compose.yml`
* **Tecnología:** Docker Compose v2 (especificación estándar).
* **Propósito:** Orquestar en un solo comando el entorno de ejecución completo:
  1. Servicio `db`: Contenedor MariaDB con la semilla de datos.
  2. Servicio `app`: Contenedor Tomcat con la aplicación web OwlAudit.
  3. Red `app-net`: Red bridge aislada que permite la resolución de nombres DNS interna entre `app` y `db`.
  4. Volumen `db_data`: Persiste el estado de las tablas y auditorías aun cuando los contenedores se detengan o reinicien.
* **Variables inyectadas:** `DB_HOST=db`, `DB_PORT=3306`, `DB_NAME=owl_auditv1`, `DB_USER=user`, `DB_PASSWORD=12345`.

#### `deploy.bat` y `deploy.sh`
* **Propósito:** Facilitar la vida al usuario o desarrollador. Al ejecutarlos, verifican si Docker está encendido, descargan las imágenes más recientes de Docker Hub mediante `docker compose pull` y levantan los servicios en segundo plano (`docker compose up -d`), mostrando la URL de acceso (`http://localhost:8080`).

#### `stop-deploy.bat` y `stop-deploy.sh`
* **Propósito:** Detener de forma limpia los servicios de la aplicación web (`docker compose down`) asegurando que los volúmenes de datos no se borren accidentalmente.

#### `get-next-tag.sh`
* **Tecnología:** Bash script con `curl` y `grep`.
* **Propósito:** Resolver el cálculo automático de versiones semánticas (`1.0.X`) consultando en vivo la API pública de Docker Hub:
  `https://hub.docker.com/v2/repositories/${DOCKER_USER}/owl-audit-app/tags`
* **Decisión de Diseño:** 
  - No depender del número interno de build de Jenkins (`env.BUILD_NUMBER`). Si Jenkins se reinstala o se borran builds, el número de build local se reinicia a 1, lo que causaría sobrescrituras indeseadas en Docker Hub. Con este script, el número siempre es correlativo respecto a lo que realmente existe en Docker Hub.

#### `Jenkinsfile`
* **Tecnología:** Pipeline Declarativo de Jenkins (Groovy DSL).
* **Propósito:** Orquestar el ciclo completo de Integración Continua en 4 etapas:
  1. **Stage 1 (Checkout Source Code):** Clona la rama `main` del repositorio oficial de código fuente (`https://github.com/ErickBaja05/GR4_1BT3_622_26B.git`).
  2. **Stage 2 (Compile & Test with Maven):** Ejecuta `mvn clean package -Dtest="!*DAO*" -DfailIfNoTests=false`. Compila el código, corre las 61 pruebas unitarias y empaqueta el artefacto `.war`. *(Se excluyen los DAOs que requieren base de datos viva local para permitir ejecución hermética en CI)*.
  3. **Stage 3 (Build Docker Image):** Copia el `.war` resultante a la carpeta de contexto y construye la imagen `owl-audit-app:latest` utilizando el Docker daemon anfitrión.
  4. **Stage 4 (Dynamic Tag & Push to Docker Hub):** Verifica si el usuario configuró credenciales en Jenkins (`dockerhub-credentials`). Si existen, calcula la versión correlativa, etiqueta la imagen y la publica en Docker Hub. Si no existen, muestra un aviso y completa el pipeline en **VERDE** sin fallar, garantizando portabilidad.

---

### B. Módulo de Base de Datos (`deploy-auditowl/db/`)

#### `db/Dockerfile`
* **Tecnología:** Basada en `mariadb:11.4`.
* **Propósito:** Inyectar el archivo `init.sql` dentro del directorio reservado `/docker-entrypoint-initdb.d/` de MariaDB.
* **Decisión de Diseño:**
  - Cuando el motor de MariaDB arranca por primera vez sin datos en `/var/lib/mysql`, ejecuta automáticamente todos los archivos `.sql` presentes en esa carpeta. Esto permite que la imagen viaje con el esquema y los usuarios semilla preinstalados sin requerir migraciones manuales.

#### `db/init.sql`
* **Propósito:** 
  - Crear la base de datos `owl_auditv1`.
  - Crear la tabla `usuarios` con sus campos (`id`, `nombre`, `correo`, `password`, `rol`).
  - Sembrar 3 usuarios de prueba con contraseñas en texto claro compatibles con la autenticación actual del sistema (`docente@epn.edu.ec`, `estudiante1@epn.edu.ec`, `estudiante2@epn.edu.ec`).
  - **Estrategia Hibernate:** La configuración de Hibernate utiliza `hibernate.hbm2ddl.auto=update`. Por tanto, el resto de tablas (`auditorias`, `hallazgos`, `solicitudes_retroalimentacion`, etc.) son generadas dinámicamente por la aplicación al iniciar, evitando inconsistencias si los desarrolladores cambian las entidades Java.

---

### C. Módulo de Infraestructura CI/CD (`deploy-auditowl/jenkins-setup/`)

#### `jenkins-setup/Dockerfile`
* **Tecnología:** Basada en `jenkins/jenkins:lts-jdk21`.
* **Propósito:** Construir un servidor Jenkins "llave en mano" listo para compilar proyectos Java 21 y construir imágenes Docker.
* **Componentes integrados:**
  1. `docker-ce-cli`: Cliente de línea de comandos de Docker instalado vía los repositorios oficiales de Docker.
  2. `maven` y `openjdk-21-jdk`: Para compilar y probar aplicaciones Java modernas.
  3. Plugins esenciales preinstalados: `workflow-aggregator`, `git`, `docker-workflow` mediante la utilidad oficial `jenkins-plugin-cli`.
  4. Inyección del script Groovy en `/usr/share/jenkins/ref/init.groovy.d/`.
  5. `USER root`: Se establece como usuario principal para tener permisos de lectura y escritura sobre el socket `/var/run/docker.sock` del host, evitando errores de permisos (`permission denied`).

#### `jenkins-setup/docker-compose.yml`
* **Propósito:** Levantar Jenkins exponiendo:
  - Puerto `8081` en el host (evitando conflictos con Tomcat que usa el `8080`).
  - Mapeo de volumen `/var/run/docker.sock:/var/run/docker.sock` (Arquitectura Docker-out-of-Docker).
  - Volumen nombrado `jenkins_home` para preservar configuraciones y credenciales del usuario.

#### `jenkins-setup/init.groovy.d/01-create-pipeline.groovy`
* **Tecnología:** Jenkins Groovy Management Script.
* **Propósito:** Automatización "Zero-Config". Cuando el contenedor de Jenkins arranca por primera vez, este script se ejecuta inmediatamente en memoria:
  1. Comprueba si el trabajo `OwlAudit-Pipeline` ya existe.
  2. Si no existe, crea un nuevo `WorkflowJob`.
  3. Configura el flujo con un `CpsScmFlowDefinition` apuntando al repositorio remoto de despliegue (`https://github.com/AndresVeas/deploy-auditowl.git`), rama `*/main` y script `Jenkinsfile`.
  4. Guarda la configuración en disco.
* **Resultado:** Cualquier evaluador o nuevo compañero que levante la imagen se encuentra el Pipeline ya creado y listo para hacer clic en **Build Now**.

#### `jenkins-setup/start-jenkins.bat` y `start-jenkins.sh`
* **Propósito:** Levantan el contenedor de Jenkins con Docker Compose, esperan a que el servicio inicialice y leen automáticamente `/var/jenkins_home/secrets/initialAdminPassword`, imprimiendo la clave de administrador en la consola para una experiencia sin fricciones.

### C. Módulo de Despliegue Modular (`docker-compose-deploy/`)

Diseñado expresamente para la sustentación, evaluación docente y grabaciones explicativas:

#### `docker-compose-deploy/app/docker-compose.yml`
* **Propósito:** Permite levantar exclusivamente los servicios de la aplicación web (`webapp` en Tomcat 10.1 puerto 8080) y la base de datos (`db` en MariaDB 11.4 puerto 3306) descargando directamente las imágenes oficiales de Docker Hub (`andresveas/owl-audit-app:latest` y `andresveas/mariadb-owlaudit:latest`), sin compilar código localmente.
* **Red y Volúmenes:** Conectados a la red bridge `app-net` y persistidos en el volumen `db_data`.

#### `docker-compose-deploy/jenkins/docker-compose.yml`
* **Propósito:** Permite levantar el servidor de integración continua Jenkins (`mi-jenkins` en el puerto 8081) descargando la imagen `andresveas/jenkins-owlaudit:latest` con acceso al daemon anfitrión mediante `/var/run/docker.sock` y persistencia en `jenkins_data`. Elimina la necesidad de escribir comandos `docker run` largos en la terminal durante el video.

---

## 💡 3. Decisiones Arquitectónicas Clave (Justificación Técnica)

### 1. Desacoplamiento de Repositorios (App vs. Deploy)
* **Problema:** En proyectos académicos y profesionales, ensuciar el repositorio de código fuente con configuraciones de Jenkins, compose de base de datos y scripts de bash genera conflictos entre desarrolladores y dificulta el versionamiento limpio del incremento de software.
* **Solución:** Se separó la lógica de aplicación en `GR4_1BT3_622_26B` y la infraestructura en `deploy-auditowl`. El `Jenkinsfile` clona el código de aplicación durante el pipeline, manteniendo ambos repositorios limpios y con responsabilidades únicas.

### 2. Docker-out-of-Docker (DooD) frente a Docker-in-Docker (DinD)
* **Decisión:** Se utilizó el montaje del socket `/var/run/docker.sock` en lugar de ejecutar un daemon anidado dentro de Jenkins.
* **Ventajas:** 
  - Mucho más rápido y eficiente en uso de memoria RAM y CPU.
  - Las imágenes construidas por Jenkins (`owl-audit-app:latest`) quedan disponibles inmediatamente en el Docker local del host, listas para ser ejecutadas o probadas sin capas intermedias.

### 3. Resolución Dinámica de Base de Datos en Java (`HibernateUtil.java`)
* **Decisión:** Se actualizó `HibernateUtil.java` para inspeccionar la variable de entorno `System.getenv("DB_HOST")`:
  ```java
  String host = (envHost != null && !envHost.isEmpty()) ? envHost : "localhost";
  ```
* **Ventajas:** 
  - Si el desarrollador corre la app desde su IDE en Eclipse o IntelliJ, `DB_HOST` es nulo, por lo que se conecta a `localhost:3306`.
  - Si la app corre dentro de un contenedor Docker, `DB_HOST` se define como `db`, resolviendo automáticamente la dirección IP interna en la red virtual `app-net`.
  - No requiere recompilar código ni alterar archivos `.xml` al cambiar de ambiente.
