# 📦 Despliegue Modular con Docker Compose (Para Evaluación y Demostración)

Esta carpeta contiene las configuraciones aisladas de **Docker Compose** pensadas específicamente para la evaluación del docente y la demostración en video. 

Utiliza las imágenes oficiales precompiladas y publicadas en **Docker Hub**, por lo que **no requiere clonar código fuente ni compilar localmente**.

---

## 📂 Estructura de esta Carpeta

```text
docker-compose-deploy/
├── app/
│   └── docker-compose.yml     # Orquesta MariaDB 11.4 + OwlAudit WebApp (Tomcat 10.1 / Java 21)
└── jenkins/
    └── docker-compose.yml     # Orquesta el servidor Jenkins CI/CD con Docker Engine enlazado
```

---

## 🚀 1. Despliegue de la Aplicación Web (MariaDB + OwlAudit)

### Iniciar:
```bash
cd docker-compose-deploy/app
docker compose up -d
```

* **Acceso Web:** [http://localhost:8080](http://localhost:8080)
* **Credenciales de prueba:**
  * **Docente:** `docente@epn.edu.ec` / `docente123`
  * **Estudiante:** `estudiante1@epn.edu.ec` / `estudiante123`
* **Base de datos (MariaDB):** `localhost:3306` (Base: `owl_auditv1`, Usuario: `user`, Clave: `12345`)

### Detener:
```bash
docker compose down        # Mantiene los datos de la base de datos
docker compose down -v     # Limpieza total (elimina el volumen de datos)
```

---

## 🏗️ 2. Despliegue del Servidor Jenkins (Integración Continua)

Este servicio levanta el contenedor `mi-jenkins` con el socket Docker (`/var/run/docker.sock`) mapeado para permitir construcción de imágenes Docker locales y ejecución del pipeline.

### Iniciar:
```bash
cd docker-compose-deploy/jenkins
docker compose up -d
```

### Obtener la contraseña de Administrador:
```bash
docker exec mi-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

* **Acceso Jenkins:** [http://localhost:8081](http://localhost:8081)
* **Pipeline automático:** Al ingresar observará el trabajo **`OwlAudit-Pipeline`** preconfigurado y listo para ejecutar con **Build Now**.

### Detener:
```bash
docker compose down        # Mantiene las ejecuciones y configuraciones de Jenkins
docker compose down -v     # Limpieza total (elimina volumen de Jenkins)
```
