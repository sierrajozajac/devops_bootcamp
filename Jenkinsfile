// Jenkinsfile: CI/CD pipeline for the frontend + backend services.
//
// Flow: checkout -> build both images -> smoke-test backend -> push to
// registry -> deploy with docker compose on the cicd-engine.
//
// Prerequisites on the Jenkins host (already provisioned by ansible/playbook.yaml):
//   - docker + docker-compose-v2 installed
//   - the 'jenkins' user is in the 'docker' group
// In Jenkins, add a "Username with password" credential whose ID matches
// REGISTRY_CREDENTIALS below (e.g. your Nexus Docker repo or Docker Hub login).

pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        // Nexus Docker connector (host:port). Private IP keeps registry
        // traffic inside the VPC and matches the daemon.json insecure-registries
        // entry set by ansible/playbook.yaml. No trailing slash.
        REGISTRY             = '10.0.8.228:8082'
        REGISTRY_CREDENTIALS = 'registry-credentials'

        // Tag every image with the build number, plus a moving 'latest'.
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
        FRONTEND_IMAGE = "${REGISTRY}/devops-bootcamp-frontend"
        BACKEND_IMAGE  = "${REGISTRY}/devops-bootcamp-backend"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // Build the two images independently and in parallel to save time.
        stage('Build images') {
            parallel {
                stage('Build frontend') {
                    steps {
                        sh """
                            docker build \
                              -t ${FRONTEND_IMAGE}:${IMAGE_TAG} \
                              -t ${FRONTEND_IMAGE}:latest \
                              ./frontend
                        """
                    }
                }
                stage('Build backend') {
                    steps {
                        sh """
                            docker build \
                              -t ${BACKEND_IMAGE}:${IMAGE_TAG} \
                              -t ${BACKEND_IMAGE}:latest \
                              ./backend
                        """
                    }
                }
            }
        }

        // Start the freshly built backend and confirm /health responds before
        // we publish anything. Container is always cleaned up afterwards.
        stage('Test backend') {
            steps {
                sh '''
                    docker run -d --name bootcamp-test -p 5001:5000 ${BACKEND_IMAGE}:${IMAGE_TAG}
                    for i in $(seq 1 10); do
                        if curl -fsS http://localhost:5001/health; then
                            echo "backend healthy"
                            exit 0
                        fi
                        echo "waiting for backend... ($i)"
                        sleep 2
                    done
                    echo "backend did not become healthy"
                    exit 1
                '''
            }
            post {
                always {
                    sh 'docker rm -f bootcamp-test || true'
                }
            }
        }

        // Publish to Nexus. (Single-branch job: runs every build. If you move
        // to a Multibranch job later, re-add `when { branch 'main' }` here.)
        stage('Push images') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${REGISTRY_CREDENTIALS}",
                    usernameVariable: 'REG_USER',
                    passwordVariable: 'REG_PASS'
                )]) {
                    sh '''
                        echo "$REG_PASS" | docker login ${REGISTRY} -u "$REG_USER" --password-stdin
                        docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                        docker push ${FRONTEND_IMAGE}:latest
                        docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                        docker push ${BACKEND_IMAGE}:latest
                    '''
                }
            }
        }

        // Roll out on the cicd-engine: pull the freshly pushed images and
        // (re)start the stack. Pulls by tag so we deploy exactly what we built.
        stage('Deploy') {
            steps {
                sh '''
                    docker pull ${FRONTEND_IMAGE}:${IMAGE_TAG}
                    docker pull ${BACKEND_IMAGE}:${IMAGE_TAG}
                    docker compose up -d
                '''
            }
        }
    }

    post {
        always {
            // Log out and prune dangling layers so the agent disk stays clean.
            sh 'docker logout ${REGISTRY} || true'
            sh 'docker image prune -f || true'
        }
        success {
            echo "Pipeline succeeded: built tag ${IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline failed. Check the stage logs above.'
        }
    }
}
