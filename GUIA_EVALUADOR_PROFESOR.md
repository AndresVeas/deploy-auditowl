# 🎓 Guía de Evaluación y Ejecución para el Docente / Evaluador
### Proyecto: OwlAudit — Aplicación de Prácticas de Programación Extrema (XP)
**Grupo 4 | EPN - Metodologías Ágiles de Desarrollo de Software**

---

> [!NOTE]  
> **Estimado Evaluador / Profesor:**  
> Esta guía fue diseñada específicamente para que **NO requiera clonar repositorios de código ni compilar proyectos localmente**.  
> Todos los artefactos entregables (Aplicación Web, Base de Datos persistente e Infraestructura CI/CD de Jenkins) han sido construidos, empaquetados y publicados en **Docker Hub**. Usted puede descargar las imágenes y verificar todo el funcionamiento mediante simples comandos estándar de Docker.

---

## 📌 1. Enlaces a los Entregables Oficiales (Rúbrica de Evaluación)

En cumplimiento con los puntos **4, 6 y 8** de las especificaciones de la práctica:

| Entregable | Enlace / Identificador |
| :--- | :--- |
| **Repositorio Público del Código Fuente (GitHub)** | [https://github.com/ErickBaja05/GR4_1BT3_622_26B](https://github.com/ErickBaja05/GR4_1BT3_622_26B) |
| **Repositorio Público de Despliegue y CI/CD (GitHub)** | [https://github.com/AndresVeas/deploy-auditowl](https://github.com/AndresVeas/deploy-auditowl) |
| **Imagen Docker de la Aplicación Web (Docker Hub)** | [docker.io/andresveas/owl-audit-app:latest](https://hub.docker.com/r/andresveas/owl-audit-app) |
| **Imagen Docker de Jenkins CI/CD (Docker Hub)** | [docker.io/andresveas/jenkins-owlaudit:latest](https://hub.docker.com/r/andresveas/jenkins-owlaudit) |
| **Imagen Docker de MariaDB con Semilla (Docker Hub)** | [docker.io/andresveas/mariadb-owlaudit:latest](https://hub.docker.com/r/andresveas/mariadb-owlaudit) |
| **Video 1: Prácticas XP (TDD y CI/CD con Jenkins - 4 min)** | *(Insertar enlace al video de 4 minutos)* |
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
Descarga la imagen con la base `owl_auditv1` y las cuentas de usuario de prueba ya inicializadas:
```bash
docker run -d \
  --name db \
  --network app-net \
  -e MARIADB_ROOT_PASSWORD=root \
  -e MARIADB_DATABASE=owl_auditv1 \
  -e MARIADB_USER=user \
  -e MARIADB_PASSWORD=12345 \
  -p 3306:3306 \
  andresveas/mariadb-owlaudit:latest
```

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

Si prefiere utilizar Docker Compose, puede guardar el siguiente contenido en un archivo llamado `docker-compose.yml` y ejecutar `docker compose up -d`:

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

networks:
  app-net:
    driver: bridge
```

---

## 🌐 3. Verificación de la Aplicación Web y Criterios de Aceptación

Una vez levantados los contenedores:

1. Ingrese desde cualquier navegador a:
   👉 **[http://localhost:8080](http://localhost:8080)**

2. Inicie sesión utilizando cualquiera de los usuarios preconfigurados:

| Rol | Correo Electrónico | Contraseña | Capacidades a Evaluar |
| :--- | :--- | :--- | :--- |
| **Docente** | `docente@epn.edu.ec` | `docente123` | Consulta y gestión completa de auditorías de estudiantes, emisión de dictámenes, revisión de métricas de evolución. |
| **Estudiante 1** | `estudiante1@epn.edu.ec` | `estudiante123` | Envío de repositorios GitHub para auditoría, consulta de evolución de calidad, solicitud de retroalimentación sobre hallazgos. |
| **Estudiante 2** | `estudiante2@epn.edu.ec` | `estudiante456` | Cuenta secundaria para probar aislamiento de auditorías y proyectos independientes. |

### Verificación de las Historias de Usuario del Incremento:
* **HU 1 (Consultar Evolución de Calidad):** Permite contrastar dos auditorías consecutivas de un proyecto para evaluar la variación de porcentaje y el estado de cada regla (`Nuevo`, `Persistente` o `Corregido`).
* **HU 2 (Solicitar Retroalimentación de Hallazgos):** Permite al estudiante seleccionar un hallazgo reportado y enviar una justificación o duda técnica al docente.
* **HU 3 (Atender Feedback de Auditoría):** Permite al docente responder y cerrar la solicitud de retroalimentación cambiando el estado a atendido.

---

## 🏗️ 4. Evaluación de la Integración Continua (Jenkins en Docker)

Se ha creado una imagen personalizada de Jenkins (`andresveas/jenkins-owlaudit:latest`) que incluye:
* **Docker CLI preinstalado**, permitiendo ejecutar comandos Docker desde adentro del contenedor contra el daemon del host.
* **Apache Maven 3.9 + OpenJDK 21** para compilar y ejecutar las pruebas de software.
* **Script de Autoprovisión Groovy (`init.groovy.d`)**: Configura el job `OwlAudit-Pipeline` de forma totalmente automática en el primer arranque, sin requerir configuración manual de plugins ni pipelines.

### Paso 1: Ejecutar el Contenedor de Jenkins

Ejecute en su terminal:

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
   - **Clonado del repositorio fuente:** Descarga `GR4_1BT3_622_26B`.
   - **Compilación y Pruebas Unitarias:** Ejecuta la batería de pruebas de Maven (JUnit 5 + Mockito).
   - **Empaquetado Web:** Genera el archivo WAR de producción.
   - **Construcción de Imagen Docker:** Compila la imagen Tomcat usando el `Dockerfile`.
   - **Verificación de Tags Dinámicos:** Consulta Docker Hub para determinar la versión correlativa.

---

## 🧪 5. Evidencias de Prácticas de Programación Extrema (XP)

### A. Test-Driven Development (TDD)
En el repositorio del código se encuentran implementadas y verificadas las pruebas requeridas:
1. **4 Pruebas Unitarias Convencionales:** Pruebas de reglas de negocio en evaluadores (`ReglaLongitudMetodoTest`, `ReglaComentariosTest`, `ReglaComplejidadTest`, `CalculadorMetricasTest`).
2. **1 Prueba Unitaria con Mocks (Mockito):** `DictamenSeveridadTest` en la capa de servicios, donde se aíslan mediante `@Mock` los DAOs (`ReglaDAO`, `AuditoriaDAO`) y el cliente externo (`GitHubClient`) para validar que una auditoría falla si presenta hallazgos de severidad ALTA.
3. **1 Prueba Unitaria Parametrizada:** Evaluaciones de umbrales con `@ParameterizedTest` y `@ValueSource` / `@CsvSource` en reglas de cálculo de calidad.
4. **Ciclo Red-Green-Refactor:** Evidenciado en el historial de commits y documentado en `docs/TDD/Franciel.md`.

### B. Cuatro Refactorizaciones Realizadas
1. **Refactorización 1 - Inyección de Estrategias:** Migración de condicionales extensos de reglas a un patrón `Strategy` gestionado por `EvaluadorReglaFactory`.
2. **Refactorización 2 - Desacoplamiento de Persistencia con Variables de Entorno:** Modificación de `HibernateUtil.java` para resolver dinámicamente el host de base de datos (`DB_HOST`), permitiendo alternancia transparente entre desarrollo local (`localhost`) y contenedores Docker (`db`).
3. **Refactorización 3 - Extracción de Métodos de Validación en Servicios:** Modularización de lógica de validación de entradas de casos de uso para mejorar legibilidad y reusabilidad.
4. **Refactorización 4 - Optimización del Empaquetado WAR:** Estandarización de `ROOT.war` para eliminar contextos anidados en Tomcat y mejorar tiempos de respuesta HTTP.

---

## 🧹 6. Limpieza y Detención de Contenedores

Una vez finalizada la revisión, puede detener y remover los contenedores con los siguientes comandos:

```bash
# Detener y remover la aplicación web y la base de datos
docker rm -f webapp db

# Remover la red virtual
docker network rm app-net

# Detener y remover Jenkins
docker rm -f mi-jenkins
```

*(Si desea eliminar también las imágenes descargadas para liberar espacio en disco):*
```bash
docker rmi andresveas/owl-audit-app:latest andresveas/mariadb-owlaudit:latest andresveas/jenkins-owlaudit:latest
```
