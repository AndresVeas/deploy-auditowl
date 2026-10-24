# 👥 Guía para el Equipo de Desarrollo: CI/CD y Despliegue Local (OwlAudit)

Esta guía explica paso a paso cómo cada desarrollador del equipo puede trabajar localmente, ejecutar pruebas, integrar cambios mediante el pipeline de **Jenkins** y desplegar la aplicación web **OwlAudit**.

---

## 📌 1. Arquitectura General del Flujo

1. **Código Fuente (`GR4_1BT3_622_26B`):** Contiene la lógica Java, servlets, DAO, modelos y pruebas unitarias con Maven.
2. **Repositorio de Despliegue (`deploy-auditowl`):** Contiene la infraestructura de Docker, scripts de automatización y el pipeline de Jenkins.
3. **Flujo de Integración:**
   * Desarrollas en tu IDE (Eclipse / IntelliJ) conectándote a MariaDB en `localhost:3306`.
   * Haces commit y push en el repositorio de la aplicación `GR4`.
   * El pipeline de Jenkins clona el código de `GR4`, corre las pruebas de Maven, empaqueta el artefacto `.war` en Tomcat y calcula la versión dinámicamente.

---

## 🛠️ 2. Trabajo Local en la Aplicación (Sin Docker)

Cuando estás programando en tu máquina local:
* Abre el proyecto `GR4_1BT3_622_26B` en tu IDE.
* En `src/main/resources/hibernate.cfg.xml`, la conexión apunta a `localhost:3306` con la base `owl_auditv1`, usuario `user` y clave `12345`.
* Gracias a la configuración en `HibernateUtil.java`, si la variable de entorno `DB_HOST` no está definida, el sistema asume automáticamente tu entorno local.
* Para compilar y correr pruebas desde tu terminal:
  ```bash
  mvn clean test
  ```

---

## 🚀 3. Cómo Probar la Aplicación Web en Docker (Despliegue Rápido)

Si deseas probar la aplicación completa corriendo dentro de contenedores (Tomcat + MariaDB) sin compilar Java desde cero:

### Paso 1: Clonar el repositorio de despliegue
```bash
git clone https://github.com/AndresVeas/deploy-auditowl.git
cd deploy-auditowl
```

### Paso 2: Encender los contenedores
* **En Windows:** Haz doble clic o ejecuta en consola:
  ```cmd
  deploy.bat
  ```
* **En Linux / macOS / Git Bash:**
  ```bash
  chmod +x deploy.sh
  ./deploy.sh
  ```

Este script descargará automáticamente las imágenes oficiales desde Docker Hub (`andresveas/owl-audit-app:latest` y `andresveas/mariadb-owlaudit:latest`) y levantará el sistema en segundos.

### Paso 3: Probar en el navegador
* **URL:** [http://localhost:8080](http://localhost:8080)
* **Credenciales de prueba cargadas automáticamente:**
  * **Docente:** `docente@epn.edu.ec` | Contraseña: `docente123`
  * **Estudiante 1:** `estudiante1@epn.edu.ec` | Contraseña: `estudiante123`
  * **Estudiante 2:** `estudiante2@epn.edu.ec` | Contraseña: `estudiante456`

### Paso 4: Apagar los contenedores
* **En Windows:** `stop-deploy.bat`
* **En Linux / macOS:** `./stop-deploy.sh`
*(Los datos registrados se conservan intactos en el volumen `db_data`)*.

---

## ⚙️ 4. Levantar Jenkins en tu Computadora (CI/CD)

Si deseas ejecutar el pipeline de Integración Continua en tu máquina:

### Paso 1: Iniciar Jenkins
* **En Windows:**
  ```cmd
  cd jenkins-setup
  start-jenkins.bat
  ```
* **En Linux / macOS / Git Bash:**
  ```bash
  cd jenkins-setup
  chmod +x start-jenkins.sh
  ./start-jenkins.sh
  ```

El script levantará el contenedor de Jenkins y **mostrará en pantalla la clave de administrador inicial**.

### Paso 2: Ingresar a Jenkins
1. Abre [http://localhost:8081](http://localhost:8081) en tu navegador.
2. Pega la clave que imprimió el script.
3. Crea tu usuario administrador (ej. `admin` / `admin123`).
4. **¡Listo!** En la pantalla principal ya verás el trabajo **`OwlAudit-Pipeline`** preconfigurado automáticamente.

---

## 🔒 5. Cómo Configurar Docker Hub para Subir Imágenes (Caso Erick o Compañeros)

El pipeline está diseñado para que **cualquier compañero pueda correrlo sin errores**.

### Comportamiento por defecto (Sin credenciales):
Si corres el pipeline sin configurar credenciales de Docker Hub, Jenkins:
1. Clonará el código de `GR4`.
2. Correrá las 61 pruebas unitarias con Maven.
3. Construirá la imagen Docker localmente (`owl-audit-app:latest`).
4. En la etapa de Docker Hub, mostrará un mensaje amigable indicando que se omite la subida y **el pipeline terminará en VERDE exitoso**.

---

### ¿Cómo configurar Jenkins para subir a TU PROPIA cuenta de Docker Hub?
Si Erick (o cualquier compañero) desea que el pipeline publique la imagen en su propio Docker Hub personal (ej. `erickbaja/owl-audit-app`):

1. **Obtener un Access Token en Docker Hub:**
   * Entra a [hub.docker.com](https://hub.docker.com/) con tu cuenta.
   * Ve a **Account Settings** > **Security** > **New Access Token**.
   * Nombre: `jenkins-ci`, permisos: `Read & Write`.
   * Copia el token generado (`dckr_pat_...`).

2. **Registrar las credenciales en tu Jenkins local:**
   * En Jenkins ([http://localhost:8081](http://localhost:8081)), ve a **Manage Jenkins** > **Credentials** > **System** > **Global credentials (unrestricted)**.
   * Haz clic en **+ Add Credentials**.
   * Completa los campos:
     * **Kind:** `Username with password`
     * **Username:** Tu nombre de usuario de Docker Hub (ej. `erickbaja`).
     * **Password:** El token que copiaste (`dckr_pat_...`).
     * **ID:** `dockerhub-credentials` *(debe ser exactamente este ID)*.
   * Haz clic en **Create**.

3. **¡Magia dinámica en el Pipeline!**
   El `Jenkinsfile` detecta automáticamente qué usuario colocaste en `dockerhub-credentials`. Al ejecutar **Build Now**, etiquetará y publicará la imagen directamente en tu cuenta:
   ```text
   erickbaja/owl-audit-app:1.0.X
   erickbaja/owl-audit-app:latest
   ```
   *No tienes que modificar ni una sola línea de código en el `Jenkinsfile`.*

---

## 📈 6. Cómo Completar las 3 Integraciones Exitosas Requeridas por la Rúbrica

El profesor solicita:
> *"Cada desarrollador del equipo deberá realizar al menos un commit por cada integración. Ejecutar al menos tres integraciones exitosas mediante el pipeline de Jenkins."*

### Protocolo de Integración en Equipo:

1. **Integración 1 (Desarrollador 1):**
   * Realiza un commit con cambios funcionales o corrección en el repo `GR4_1BT3_622_26B` y hace push a `main`.
   * En Jenkins se ejecuta **Build Now** en `OwlAudit-Pipeline`.
   * El pipeline detecta que no hay versiones previas en Docker Hub y publica **`1.0.1`** y `latest`.

2. **Integración 2 (Desarrollador 2):**
   * El segundo compañero realiza su commit en `GR4_1BT3_622_26B` y hace push a `main`.
   * Se ejecuta el pipeline en Jenkins.
   * El script `get-next-tag.sh` consulta la API de Docker Hub en vivo, detecta que la última es `1.0.1` y publica automáticamente **`1.0.2`** y `latest`.

3. **Integración 3 (Desarrollador 3):**
   * El tercer compañero realiza su commit en `GR4_1BT3_622_26B` y hace push a `main`.
   * Se ejecuta el pipeline en Jenkins.
   * El pipeline detecta que la última es `1.0.2` y publica automáticamente **`1.0.3`** y `latest`.

Al finalizar, el repositorio en Docker Hub mostrará las 3 versiones consecutivas demostrando las 3 integraciones continuas exitosas del equipo.
