# 🎓 Guía de Evaluación y Ejecución para el Docente / Evaluador
### Proyecto: OwlAudit — Despliegue e Integración Continua
**Grupo 4 | EPN - Metodologías Ágiles de Desarrollo de Software**

---

> [!NOTE]  
> **Estimado Evaluador / Profesor:**  
> Esta guía fue diseñada específicamente para que **NO requiera clonar repositorios de código ni compilar proyectos localmente**.  
> Todos los artefactos entregables (Aplicación Web, Base de Datos persistente e Infraestructura CI/CD de Jenkins) han sido construidos, empaquetados y publicados en **Docker Hub**. Usted puede descargar las imágenes y verificar todo el funcionamiento mediante simples comandos estándar de Docker.

---

## 📌 1. Enlaces a los Entregables Oficiales

En cumplimiento con los requerimientos de la práctica:

| Entregable | Enlace / Identificador |
| :--- | :--- |
| **Repositorio Público del Código Fuente (GitHub)** | [https://github.com/ErickBaja05/GR4_1BT3_622_26B](https://github.com/ErickBaja05/GR4_1BT3_622_26B) |
| **Repositorio Público de Despliegue y CI/CD (GitHub)** | [https://github.com/AndresVeas/deploy-auditowl](https://github.com/AndresVeas/deploy-auditowl) |
| **Imagen Docker de la Aplicación Web (Docker Hub)** | [docker.io/andresveas/owl-audit-app:latest](https://hub.docker.com/r/andresveas/owl-audit-app) |
| **Imagen Docker de Jenkins CI/CD (Docker Hub)** | [docker.io/andresveas/jenkins-owlaudit:latest](https://hub.docker.com/r/andresveas/jenkins-owlaudit) |
| **Imagen Docker de MariaDB con Semilla (Docker Hub)** | [docker.io/andresveas/mariadb-owlaudit:latest](https://hub.docker.com/r/andresveas/mariadb-owlaudit) |
| **Video 1: Prácticas XP (4 min)** | *(Insertar enlace al video de 4 minutos)* |
| **Video 2: Demostración de la Aplicación Web (2 min)** | *(Insertar enlace al video de 2 minutos)* |

---

## 🚀 2. Despliegue y Ejecución de la Aplicación Web

Para evaluar el sistema web funcionando (Tomcat 10.1 + Java 21 + MariaDB 11.4), solo requiere tener **Docker Desktop** (o el servicio Docker en Linux) encendido.

### Opción A: Despliegue Directo con Comandos Docker (Recomendada)

Abra su terminal (PowerShell, CMD, Bash o Zsh) y ejecute los siguientes 3 comandos:

#### 1. Crear la red interna de comunicación:
```bash
docker network create app-net
```

#### 2. Iniciar el contenedor de Base de Datos (MariaDB):
Descarga la imagen con la base `owl_auditv1` y las cuentas de usuario ya inicializadas:
```bash
docker run -d \
  --name db \
  --network app-net \
  -v db_data:/var/lib/mysql \
  -e MARIADB_ROOT_PASSWORD=root \
  -e MARIADB_DATABASE=owl_auditv1 \
  -e MARIADB_USER=user \
  -e MARIADB_PASSWORD=12345 \
  -p 3306:3306 \
  andresveas/mariadb-owlaudit:latest
```
*(Nota: El mapeo `-v db_data:/var/lib/mysql` crea un volumen persistente de Docker para que los datos registrados se guarden de forma permanente en su equipo aunque el contenedor sea apagado o reiniciado).*

#### 3. Iniciar el contenedor de la Aplicación Web (OwlAudit):
Descarga el empaquetado final de producción (`ROOT.war`) sobre Apache Tomcat 10.1 con Java 21:
```bash
docker run -d \
  --name webapp \
  --network app-net \
  -e DB_HOST=db \
  -e DB_PORT=3306 \
  -e DB_NAME=owl_auditv1 \
  -e DB_USER=user \
  -e DB_PASSWORD=12345 \
  -p 8080:8080 \
  andresveas/owl-audit-app:latest
```

---

### Opción B: Despliegue en un solo paso con Docker Compose

Si tiene este repositorio clonado, simplemente ingrese a la carpeta `docker-compose-deploy/app` y ejecute:

```bash
cd docker-compose-deploy/app
docker compose up -d
```

*(Si no clonó el repositorio, puede guardar el siguiente contenido en un archivo `docker-compose.yml` y ejecutar `docker compose up -d`):*

```yaml
services:
  db:
    image: andresveas/mariadb-owlaudit:latest
    container_name: db
    restart: always
    environment:
      MARIADB_ROOT_PASSWORD: root
      MARIADB_DATABASE: owl_auditv1
      MARIADB_USER: user
      MARIADB_PASSWORD: 12345
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - app-net

  app:
    image: andresveas/owl-audit-app:latest
    container_name: webapp
    restart: always
    depends_on:
      - db
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=db
      - DB_PORT=3306
      - DB_NAME=owl_auditv1
      - DB_USER=user
      - DB_PASSWORD=12345
    networks:
      - app-net

volumes:
  db_data:

networks:
  app-net:
    driver: bridge
```

---

## 🌐 3. Verificación de la Aplicación Web y Cuentas de Acceso

Una vez levantados los contenedores:

1. Ingrese desde cualquier navegador a:
   👉 **[http://localhost:8080](http://localhost:8080)**

2. Inicie sesión utilizando cualquiera de los usuarios preconfigurados:

| Rol | Correo Electrónico | Contraseña | Perfil / Acciones Disponibles |
| :--- | :--- | :--- | :--- |
| **Docente** | `docente@epn.edu.ec` | `docente123` | Consulta y gestión completa de auditorías, emisión de dictámenes y retroalimentación. |
| **Estudiante 1** | `estudiante1@epn.edu.ec` | `estudiante123` | Envío de repositorios para auditoría, consulta de métricas de calidad y solicitudes de feedback. |
| **Estudiante 2** | `estudiante2@epn.edu.ec` | `estudiante456` | Cuenta secundaria para probar aislamiento de auditorías independientes. |

---

## 🏗️ 4. Evaluación de la Integración Continua (Jenkins en Docker)

Se ha preparado una imagen personalizada de Jenkins (`andresveas/jenkins-owlaudit:latest`) que incluye:
* **Docker CLI preinstalado**, permitiendo ejecutar comandos Docker contra el daemon del host.
* **Apache Maven 3.9 + OpenJDK 21** para compilar y ejecutar las pruebas de software.
* **Script de Autoprovisión Groovy (`init.groovy.d`)**: Configura el job `OwlAudit-Pipeline` de forma automática al iniciar el contenedor por primera vez.

### Paso 1: Ejecutar el Contenedor de Jenkins

#### Opción A: Con Docker Compose (Recomendada si tiene el repositorio)
Navegue a la subcarpeta `docker-compose-deploy/jenkins` y ejecute:
```bash
cd docker-compose-deploy/jenkins
docker compose up -d
```
*(Este comando levanta automáticamente el contenedor `mi-jenkins` con los puertos `8081` y `50000`, montando el socket `/var/run/docker.sock` y persistiendo datos en un volumen).*

---

#### Opción B: Con comando directo `docker run`
Si prefiere no usar Compose o ejecutar directamente la imagen:

* **En Linux / macOS / Git Bash:**
  ```bash
  docker run -d \
    --name mi-jenkins \
    -p 8081:8080 \
    -p 50000:50000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    andresveas/jenkins-owlaudit:latest
  ```

* **En Windows (PowerShell / CMD):**
  ```powershell
  docker run -d `
    --name mi-jenkins `
    -p 8081:8080 `
    -p 50000:50000 `
    -v //var/run/docker.sock:/var/run/docker.sock `
    andresveas/jenkins-owlaudit:latest
  ```

> [!IMPORTANT]  
> El mapeo de volumen `-v /var/run/docker.sock:/var/run/docker.sock` es indispensable para permitir que Jenkins construya imágenes de Docker utilizando el motor de Docker de la máquina anfitriona.

### Paso 2: Obtener la Contraseña de Administrador

Ejecute el siguiente comando para leer la clave inicial generada por Jenkins:
```bash
docker exec mi-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Paso 3: Acceder al Panel de Jenkins

1. Abra en el navegador: 👉 **[http://localhost:8081](http://localhost:8081)**
2. Ingrese la clave obtenida en el Paso 2.
3. Si lo solicita, cree un usuario (o continúe como admin).
4. En el panel principal observará que el trabajo **`OwlAudit-Pipeline`** ya existe y está completamente configurado.

### Paso 4: Ejecutar la Integración y Ver el Reporte

1. Haga clic en **`OwlAudit-Pipeline`**.
2. En el menú lateral izquierdo, haga clic en **Build Now** (Construir ahora).
3. Ingrese a la ejecución en curso (ej. `#1`) y abra **Console Output**.
4. Observará en tiempo real el ciclo de Integración Continua:
   - **Clonado del repositorio fuente:** Descarga el código desde GitHub.
   - **Compilación y Pruebas Unitarias:** Ejecuta las pruebas automatizadas con Maven.
   - **Empaquetado Web:** Genera el archivo WAR de producción.
   - **Construcción de Imagen Docker:** Compila la imagen Tomcat usando el `Dockerfile`.

---

### 📤 4.1. (Opcional) Probar la Carga de Imágenes a Docker Hub

Por defecto, si ejecuta el pipeline sin configurar credenciales de Docker Hub, Jenkins ejecutará todas las etapas (clonado, compilación, pruebas unitarias y construcción local de la imagen) y **terminará exitosamente en VERDE**, mostrando un mensaje amigable indicando que se omite la publicación remota.

Si usted desea probar la funcionalidad de subida a **Docker Hub**:

> [!WARNING]  
> **Importante:** Deberá configurar **sus propias credenciales personales**. La imagen generada **se subirá exclusivamente a su propio repositorio de Docker Hub**, nunca al del estudiante (`andresveas`), asegurando que ningún tercero pueda escribir en el repositorio del autor.

#### Pasos para configurar sus credenciales en Jenkins:
1. En el panel de Jenkins ([http://localhost:8081](http://localhost:8081)), vaya a:  
   **Manage Jenkins** > **Credentials** > **System** > **Global credentials (unrestricted)**.
2. Haga clic en **+ Add Credentials**.
3. Complete el formulario con sus datos:
   * **Kind:** `Username with password`
   * **Username:** Su nombre de usuario en Docker Hub (ejemplo: `mi-usuario-docker`).
   * **Password:** Su Personal Access Token o contraseña de Docker Hub.
   * **ID:** `dockerhub-credentials` *(es crucial que el ID sea exactamente este)*.
4. Haga clic en **Create**.

#### Resultado automático:
Al volver a hacer clic en **Build Now**:
* El pipeline detectará automáticamente su usuario configurado.
* Consultará la API de Docker Hub para obtener el siguiente número de versión correlativo (`1.0.X`).
* Etiquetará la imagen como:
  ```text
  <su-usuario-docker>/owl-audit-app:1.0.X
  <su-usuario-docker>/owl-audit-app:latest
  ```
* Iniciará sesión y la publicará en **su propia cuenta de Docker Hub**.

---

## 🧹 5. Limpieza y Detención de Contenedores

Dependiendo de si desea **conservar los datos** o **hacer una limpieza total**:

### Opción 1: Detener los contenedores y CONSERVAR la Base de Datos
* **Si utilizó Docker Compose:**
  ```bash
  docker compose down
  ```
  *(Detiene los contenedores y redes, pero **mantiene el volumen `db_data` intacto** para que los datos sigan disponibles la próxima vez que ejecute `docker compose up -d`).*

* **Si utilizó comandos Docker directos (`docker run`):**
  ```bash
  # Pausar/apagar los contenedores sin eliminarlos
  docker stop webapp db mi-jenkins
  ```
  *(Si prefiere remover los contenedores con `docker rm -f webapp db`, el volumen `db_data` seguirá existiendo en Docker y volverá a enlazar sus datos cuando vuelva a ejecutar el comando con `-v db_data:/var/lib/mysql`).*

---

### Opción 2: Limpieza total (Borrar contenedores, redes y volumen de base de datos)
Si desea reiniciar todo desde cero eliminando los datos creados durante la prueba:

* **Si utilizó Docker Compose:**
  ```bash
  docker compose down -v
  ```

* **Si utilizó comandos Docker directos (`docker run`):**
  ```bash
  # Remover contenedores
  docker rm -f webapp db mi-jenkins

  # Remover la red virtual
  docker network rm app-net

  # Remover el volumen persistente de la base de datos
  docker volume rm db_data
  ```

*(Opcional: Si desea eliminar también las imágenes descargadas para liberar espacio en disco):*
```bash
docker rmi andresveas/owl-audit-app:latest andresveas/mariadb-owlaudit:latest andresveas/jenkins-owlaudit:latest
```
