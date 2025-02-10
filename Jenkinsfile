
pipeline {
    agent any

    tools{
        jdk 'java s/w'
        maven 'maven s/w'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        GIT_REPO = "https://github.com/ashwiniboddu/Health-Care.git"
        GIT_BRANCH = "main"
        DOCKER_IMAGE = "ashwiniboddu/health-care"
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKERHUB_CREDENTIALS = "dockerhub-cred"
    }
    stages {
        stage ('Git_checkout') {
          steps {
            git branch: "${GIT_BRANCH}",
            url: "${GIT_REPO}"
          }
        }
        stage ('Maven Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Sonar Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh "$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Health-Care -Dsonar.projectKey=Health-CareKey -Dsonar.java.binaries=target"
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token' 
                }
            } 
        }
        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage ('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    echo "docker image built: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
        stage ('Push Image to DockerHub') {
            steps {
                script {
                    //login to DockerHub
                    docker.withRegistry('', DOCKERHUB_CREDENTIALS) {
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    }
                }
            }
        }
        stage("TRIVY Image Scan"){
            steps{
                sh "trivy image ${DOCKER_IMAGE}:${DOCKER_TAG} > trivy.txt" 
            }
        }
        stage ('Deploy to Container') {
            steps {
                sh "docker run -d --name Health-Care -p 8081:8081 ${DOCKER_IMAGE}:${DOCKER_TAG}"
            }
        }
    }
    post {
        success {
            echo "Deployment succesfully completed"
        }
        failure {
            echo "Deployment failed"
        }
    }
}