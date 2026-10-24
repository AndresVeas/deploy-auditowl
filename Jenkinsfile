pipeline {
    agent any

    environment {
        // Nombre del repositorio en Docker Hub: usuario/nombre-imagen
        IMAGE_NAME = 'owlaudit/owl-audit-app'
        IMAGE_TAG  = 'latest'
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
            when {
                branch 'main'
            }
            steps {
                echo 'Empaquetando la aplicación en la imagen Tomcat (solo rama main)...'
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('4. Push to Docker Hub') {
            when {
                branch 'main'
            }
            environment {
                // Credenciales configuradas en Jenkins solo requeridas para rama main
                DOCKER_HUB_CREDS = credentials('dockerhub-credentials')
            }
            steps {
                echo 'Autenticando y subiendo imagen a Docker Hub (solo rama main)...'
                sh """
                    echo "${DOCKER_HUB_CREDS_PSW}" | docker login -u "${DOCKER_HUB_CREDS_USR}" --password-stdin
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline completado con éxito."
        }
        failure {
            echo "Hubo un error en la ejecución del pipeline."
        }
        always {
            // Cierra la sesión de Docker para mantener el entorno limpio
            sh 'docker logout || true'
        }
    }
}
