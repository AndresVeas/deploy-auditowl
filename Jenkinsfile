pipeline {
    agent any

    environment {
        // Repositorio de código fuente de la aplicación Java (GR4)
        APP_REPO_URL = 'https://github.com/ErickBaja05/GR4_1BT3_622_26B.git'
        APP_BRANCH   = 'main'

        // Configuración de imagen para Docker Hub
        IMAGE_NAME   = 'andresveas/owl-audit-app'
        IMAGE_TAG    = 'latest'
    }

    stages {
        stage('1. Clonar Código de GR4') {
            steps {
                echo "Descargando el código fuente de OwlAudit desde ${APP_REPO_URL} (rama: ${APP_BRANCH})..."
                dir('source-code') {
                    git branch: "${APP_BRANCH}", url: "${APP_REPO_URL}"
                }
            }
        }

        stage('2. Build y Tests con Maven') {
            steps {
                echo 'Compilando proyecto Java y ejecutando las pruebas unitarias de GR4...'
                dir('source-code') {
                    sh 'mvn clean package -Dtest="!*DAO*" -DfailIfNoTests=false'
                }
            }
        }

        stage('3. Build Docker Image') {
            when {
                branch 'main'
            }
            steps {
                echo 'Copiando el archivo .war compilado y empaquetando en Tomcat...'
                sh '''
                    mkdir -p target
                    cp source-code/target/*.war target/
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('4. Push to Docker Hub') {
            when {
                branch 'main'
            }
            environment {
                DOCKER_HUB_CREDS = credentials('dockerhub-credentials')
            }
            steps {
                echo 'Autenticando y subiendo imagen terminada a Docker Hub...'
                sh """
                    echo "${DOCKER_HUB_CREDS_PSW}" | docker login -u "${DOCKER_HUB_CREDS_USR}" --password-stdin
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline completado con éxito. La imagen ${IMAGE_NAME}:${IMAGE_TAG} está lista."
        }
        failure {
            echo "Hubo un error durante la compilación, pruebas o despliegue."
        }
        always {
            // Limpia la sesión de Docker en el agente
            sh 'docker logout || true'
        }
    }
}
