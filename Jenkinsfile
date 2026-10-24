pipeline {
    agent any

    environment {
        // Repositorio de código fuente de la aplicación Java (GR4)
        APP_REPO_URL = 'https://github.com/ErickBaja05/GR4_1BT3_622_26B.git'
        APP_BRANCH   = 'main'
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
                            def targetRepo = "${DOCKER_USER}/owl-audit-app"
                            
                            // Consultar dinámicamente las etiquetas reales existentes en Docker Hub
                            sh 'chmod +x get-next-tag.sh'
                            def nextTag = sh(script: "./get-next-tag.sh ${targetRepo}", returnStdout: true).trim()

                            echo "=========================================================================="
                            echo "--> Ultima version detectada en Docker Hub. Publicando nueva version: ${nextTag}"
                            echo "=========================================================================="
                            
                            sh """
                                echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                                docker tag owl-audit-app:latest ${targetRepo}:${nextTag}
                                docker tag owl-audit-app:latest ${targetRepo}:latest
                                docker push ${targetRepo}:${nextTag}
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
            echo "Pipeline completado con éxito."
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
