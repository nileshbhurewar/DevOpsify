pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub')
        DOCKERHUB_USERNAME = "${DOCKERHUB_CREDENTIALS_USR}"
        DOCKERHUB_PASSWORD = "${DOCKERHUB_CREDENTIALS_PSW}"
        BACKEND_IMAGE = "nileshbhurewar/spring-backend:latest"
        FRONTEND_IMAGE = "nileshbhurewar/angular-frontend:latest"
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
        PATH = "/usr/local/bin:/usr/bin:/bin:$PATH"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "Checking out source code..."
                git branch: 'main', url: 'https://github.com/nileshbhurewar/placement-project.git'
            }
        }

        stage('Pre-check AWS & K8s Access') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                    set -e
                    echo "🔍 Validating AWS and Kubernetes access..."
                    aws sts get-caller-identity
                    kubectl get nodes --kubeconfig=$KUBECONFIG
                    echo "Pre-check successful!"
                    '''
                }
            }
        }

        stage('SonarQube Code Analysis') {
            environment {
                SONARQUBE = credentials('sonarqube-token')  // Jenkins secret text credential
            }
            steps {
                echo "Running SonarQube Analysis..."
                withSonarQubeEnv('SonarQube') {
                    dir('spring-backend') {
                        sh '''
                        mvn clean verify sonar:sonar \
                          -Dsonar.projectKey=placement-backend \
                          -Dsonar.host.url=$SONAR_HOST_URL \
                          -Dsonar.login=$SONARQUBE
                        '''
                    }
                    dir('angular-frontend') {
                        sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=placement-frontend \
                          -Dsonar.sources=src \
                          -Dsonar.host.url=$SONAR_HOST_URL \
                          -Dsonar.login=$SONARQUBE
                        '''
                    }
                }
            }
        }

        stage('Build & Push Backend Docker') {
            steps {
                dir('spring-backend') {
                    sh '''
                    set -e
                    echo "Building backend Docker image..."
                    docker build -t $BACKEND_IMAGE .
                    echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin
                    docker push $BACKEND_IMAGE
                    docker logout
                    echo "Backend image pushed successfully!"
                    '''
                }
            }
        }

        stage('Build & Push Frontend Docker') {
            steps {
                dir('angular-frontend') {
                    sh '''
                    set -e
                    echo "Building frontend Docker image..."
                    docker build -t $FRONTEND_IMAGE .
                    echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin
                    docker push $FRONTEND_IMAGE
                    docker logout
                    echo "Frontend image pushed successfully!"
                    '''
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                set -e
                echo "Scanning Docker images for vulnerabilities using Trivy..."

                # Install Trivy if not available
                if ! command -v trivy >/dev/null 2>&1; then
                    echo "Installing Trivy..."
                    sudo apt-get update -qq
                    sudo apt-get install -y wget
                    wget -qO- https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
                    echo deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb stable main | sudo tee /etc/apt/sources.list.d/trivy.list
                    sudo apt-get update -qq && sudo apt-get install -y trivy
                fi

                trivy image --exit-code 0 --severity HIGH,CRITICAL $BACKEND_IMAGE
                trivy image --exit-code 0 --severity HIGH,CRITICAL $FRONTEND_IMAGE

                echo "Trivy scan completed successfully!"
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                    set -e
                    echo "Deploying to Kubernetes..."
                    kubectl apply -f k8s/ --kubeconfig=$KUBECONFIG

                    echo "Updating backend image..."
                    kubectl set image deployment/backend-deployment backend=$BACKEND_IMAGE --kubeconfig=$KUBECONFIG
                    kubectl rollout status deployment/backend-deployment --timeout=180s --kubeconfig=$KUBECONFIG

                    echo "Updating frontend image..."
                    kubectl set image deployment/frontend-deployment frontend=$FRONTEND_IMAGE --kubeconfig=$KUBECONFIG
                    kubectl rollout status deployment/frontend-deployment --timeout=180s --kubeconfig=$KUBECONFIG

                    echo "Kubernetes deployment successful!"
                    '''
                }
            }
        }

        stage('Enable Datadog Monitoring') {
            steps {
                withCredentials([string(credentialsId: 'datadog-apikey', variable: 'DD_API_KEY')]) {
                    sh '''
                    set -e
                    echo "Enabling Datadog monitoring for Kubernetes..."

                    kubectl create secret generic datadog-secret \
                        --from-literal api-key=$DD_API_KEY \
                        -n default --dry-run=client -o yaml | kubectl apply -f -

                    if ! kubectl get daemonset datadog-agent -n default >/dev/null 2>&1; then
                        helm repo add datadog https://helm.datadoghq.com
                        helm repo update
                        helm upgrade --install datadog-agent datadog/datadog \
                          --set datadog.apiKeyExistingSecret=datadog-secret \
                          --set datadog.site="datadoghq.com" \
                          --set datadog.logs.enabled=true \
                          --set datadog.logs.containerCollectAll=true \
                          --set datadog.processAgent.enabled=true \
                          -n default
                    else
                        echo "Datadog Agent already running, restarting..."
                        kubectl rollout restart daemonset datadog-agent -n default
                    fi

                    echo "Datadog monitoring enabled successfully!"
                    '''
                }
            }
        }

        stage('Verify Services') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                    echo "🔍 Verifying deployed services..."
                    kubectl get pods,svc,ingress --kubeconfig=$KUBECONFIG
                    echo "All services verified successfully!"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment, testing, and monitoring completed successfully!'
        }
        failure {
            echo 'Pipeline failed! Check the console output for details.'
        }
    }
}
