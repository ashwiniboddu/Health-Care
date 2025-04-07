pipeline {
    agent any
tools {
    jdk 'jdk17'
    maven 'maven s/w'
}
environment {
    SCANNER_HOME = tool 'sonar-scanner'
    EKS_CLUSTER_NAME = 'test-eks'
    AWS_REGION = 'us-east-1'
}
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/ashwiniboddu/Health-Care.git'
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
        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs . > trivyfs.txt'
            }
        }
        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh '''
                        echo "Building Docker image..."
                        docker build -t ashwiniboddu/healthcare:latest .

                        echo "Pushing Docker image to registry..."
                        docker push ashwiniboddu/healthcare:latest
                '''
            }
        }
    }
}
        stage('Deploy to EKS Cluster') {
            steps {
                script {
                    sh '''
                    echo "Verifying AWS credentials..."
                    aws sts get-caller-identity

                    echo "Configuring kubectl for EKS cluster..."
                    aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $AWS_REGION

                    echo "Verifying kubeconfig..."
                    kubectl config view

                    echo "Deploying application to EKS..."
                    kubectl apply -f deployment.yml
                    kubectl apply -f service.yml

                    echo "Verifying deployment..."
                    kubectl get pods
                    kubectl get svc
                    '''
                }
            }
        }
    }
    post {
        success {
            echo "Deployment successfully Completed"
        }
        failure {
            echo "Deployment has  failed"
        }
    }
}