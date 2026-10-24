# OwlAudit - Repositorio de Despliegue y CI/CD

Este repositorio contiene la infraestructura automatizada con **Docker**, **Docker Compose** y **Jenkins** para el empaquetado, pruebas continuas y ejecución de la aplicación web **OwlAudit**.

---

## 🚀 Guía Rápida para Compañeros y Evaluadores

Tienes dos formas de utilizar este repositorio según tu rol:

---

### Opción A: Solo Desplegar y Probar la Aplicación (Sin compilar ni usar Jenkins)

Si eres un **evaluador, tester o desarrollador** que solo necesita tener el sistema corriendo localmente:

1. **Clonar este repositorio:**
   ```bash
   git clone https://github.com/AndresVeas/deploy-auditowl.git
   cd deploy-auditowl
   ```

2. **Levantar la aplicación y la base de datos:**
   * En **Windows:** Haz doble clic o ejecuta en la consola:
     ```cmd
     deploy.bat
     ```
   * En **Linux / macOS / Git Bash:**
     ```bash
     chmod +x deploy.sh
     ./deploy.sh
     ```

3. **Acceder a los servicios:**
   * **Aplicación Web (Tomcat):** [http://localhost:8080](http://localhost:8080)
   * **Credenciales de prueba semilla:**
     * **Docente:** `docente@epn.edu.ec` / `docente123`
     * **Estudiante:** `estudiante1@epn.edu.ec` / `estudiante123`
   * **Base de datos (MariaDB):** `localhost:3306` (Base: `owl_auditv1`, Usuario: `user`, Clave: `12345`)

4. **Para detener la aplicación:**
   * En Windows: `stop-deploy.bat`
   * En Linux / macOS: `./stop-deploy.sh`

---

### Opción B: Levantar el Servidor Jenkins (Integración Continua)

Si deseas ejecutar el pipeline de CI/CD para compilar el código fuente de [GR4_1BT3_622_26B](https://github.com/ErickBaja05/GR4_1BT3_622_26B.git) y validar pruebas unitarias:

1. **Iniciar el servidor Jenkins:**
   * En **Windows:**
     ```cmd
     cd jenkins-setup
     start-jenkins.bat
     ```
   * En **Linux / macOS / Git Bash:**
     ```bash
     cd jenkins-setup
     chmod +x start-jenkins.sh
     ./start-jenkins.sh
     ```
   *(El script iniciará el contenedor y mostrará en pantalla la **clave inicial de administrador** y la URL).*

2. **Acceso al navegador y Pipeline automático:**
   * Abre: [http://localhost:8081](http://localhost:8081)
   * Pega la clave inicial mostrada por el script y crea tu usuario administrador.
   * **¡El Pipeline `OwlAudit-Pipeline` ya estará creado y configurado automáticamente por defecto!** No tienes que crearlo manualmente.

3. **Ejecutar el Pipeline:**
   * Entra a `OwlAudit-Pipeline` y haz clic en **Construir ahora (Build Now)**.
   * Jenkins descargará el código fuente de `GR4`, ejecutará Maven, correrá las pruebas unitarias y empaquetará la imagen Docker local.
   * *(Nota: La subida a Docker Hub se omitirá de forma segura si no posees las credenciales oficiales de publicación).*

4. **Para detener Jenkins:**
   * En Windows: `cd jenkins-setup && stop-jenkins.bat`
   * En Linux / macOS: `cd jenkins-setup && ./stop-jenkins.sh`

---

## 🐳 Imagen Docker de Jenkins Publicada en Docker Hub

Para cumplir con el requerimiento académico de la entrega:
* **Nombre de la Imagen:** `andresveas/jenkins-owlaudit:latest`
* **Enlace público:** [https://hub.docker.com/r/andresveas/jenkins-owlaudit](https://hub.docker.com/r/andresveas/jenkins-owlaudit)
* **Comando para construir y subir:**
  ```bash
  docker build -t andresveas/jenkins-owlaudit:latest ./jenkins-setup
  docker push andresveas/jenkins-owlaudit:latest
  ```

---

## 📁 Estructura del Repositorio

```text
deploy-auditowl/
├── README.md                          # Guía de uso rápido del repositorio
├── Dockerfile                         # Runtime Tomcat 10.1 con JDK 21
├── Jenkinsfile                        # Pipeline de compilación, tests y publicación
├── docker-compose.yml                 # Orquestación de Tomcat + MariaDB (Red bridge)
├── deploy.bat / deploy.sh             # Scripts de inicio de Tomcat y MariaDB
├── stop-deploy.bat / stop-deploy.sh   # Scripts de apagado de Tomcat y MariaDB
├── db/
│   └── init.sql                       # Esquema y semillas iniciales de MariaDB
└── jenkins-setup/
    ├── Dockerfile                     # Jenkins LTS con JDK 21, Docker CLI y Maven
    ├── docker-compose.yml             # Servicio del servidor Jenkins (Puerto 8081)
    ├── start-jenkins.bat / .sh        # Inicia Jenkins y muestra la clave temporal
    └── stop-jenkins.bat / .sh         # Detiene Jenkins preservando datos
```
