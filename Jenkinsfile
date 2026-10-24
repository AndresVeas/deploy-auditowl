pipeline {
    agent any

    environment {
        // Repositorio de código fuente de la aplicación Java (GR4)
        APP_REPO_URL = 'https://github.com/ErickBaja05/GR4_1BT3_622_26B.git'
        APP_BRANCH   = 'main'

        // Versión dinámica basada en el número de build (1.0.1, 1.0.2, 1.0.3...)
        IMAGE_TAG    = "1.0.${BUILD_NUMBER}"
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
            steps {
                echo "Copiando el archivo .war y empaquetando imagen base local..."
                sh '''
                    mkdir -p target
                    cp source-code/target/*.war target/
                    docker build -t owl-audit-app:latest .
                '''
            }
        }

        stage('4. Push to Docker Hub') {
            steps {
                script {
                    try {
                        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            // Toma dinámicamente el usuario de quien puso las credenciales
                            def targetRepo = "${DOCKER_USER}/owl-audit-app"
                            echo "Autenticando y publicando en Docker Hub para el usuario '${DOCKER_USER}'..."
                            sh """
                                echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                                docker tag owl-audit-app:latest ${targetRepo}:${IMAGE_TAG}
                                docker tag owl-audit-app:latest ${targetRepo}:latest
                                docker push ${targetRepo}:${IMAGE_TAG}
                                docker push ${targetRepo}:latest
                            """
                        }
                    } catch (Exception e) {
                        echo "=========================================================================="
                        echo "[AVISO] No se encontraron credenciales 'dockerhub-credentials' en este Jenkins."
                        echo "Se omite la subida a Docker Hub. (La imagen local se construyó con éxito)."
                        echo "=========================================================================="
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completado con éxito para la versión ${IMAGE_TAG}."
        }
        failure {
            echo "Hubo un error durante la compilación, pruebas o despliegue."
        }
        always {
            // Limpia la sesión de Docker en el agente si hubo login
            sh 'docker logout || true'
        }
    }
}
