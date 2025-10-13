
# 🧩 Placement Project – DevOps Infrastructure Automation

## 📘 Overview
The **Placement Project** is a full-stack web application built with **Angular (frontend)** and **Spring Boot (backend)**, deployed using a fully automated **DevOps pipeline**.  
The entire infrastructure is provisioned through **Terraform**, configured using **Ansible**, and deployed on **AWS EKS (Kubernetes)** with **RDS** as the database.  
Continuous Integration and Deployment are managed via **Jenkins**, and **Datadog** is integrated for monitoring the EKS cluster.

This project demonstrates **end-to-end automation** — from infrastructure provisioning to monitoring — ensuring scalability, maintainability, and cost efficiency.

---

## 🗂️ Folder Structure

```
placement-project-main
├── Jenkinsfile
├── angular-frontend
│   ├── Dockerfile
│   ├── angular.json
│   ├── karma.conf.js
│   ├── package-lock.json
│   ├── package.json
│   ├── src
│   ├── tsconfig.app.json
│   ├── tsconfig.json
│   └── tsconfig.spec.json
├── k8s
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   └── ingress.yaml
├── spring-backend
│   ├── Dockerfile
│   ├── mvnw
│   ├── mvnw.cmd
│   ├── pom.xml
│   └── src
├── springbackend.sql
└── terraform
    ├── ansible
    ├── ec2
    ├── eks
    ├── main-key
    ├── main-key.pub
    ├── main.tf
    ├── rds
    └── vpc
```

---

## ⚙️ Tools & Technologies Used

| Tool / Technology | Purpose |
|--------------------|----------|
| **Terraform** | Infrastructure as Code (IaC) – used to create a custom VPC, EC2 master instance, EKS cluster, and RDS database. |
| **Ansible** | Configuration management – installs required tools (Docker, Jenkins, AWS CLI, kubectl, Datadog agent) on the master instance. |
| **Jenkins** | CI/CD automation – builds and deploys backend & frontend Docker images to EKS, triggers pipelines on code updates. |
| **EKS (Elastic Kubernetes Service)** | Hosts the containerized application for high availability and scalability. |
| **RDS (Relational Database Service)** | Provides a managed MySQL database for the Spring Boot backend. |
| **Datadog** | Monitors EKS cluster resources, application health, and logs through integrated dashboards. |
| **Angular** | Frontend user interface for placement management. |
| **Spring Boot** | Backend REST API that communicates with the database and serves the frontend. |
| **Docker** | Containerizes frontend and backend applications for consistent deployment. |

---

## 🧩 Pre-requisites

| Requirement | Description |
|--------------|-------------|
| **AWS Account** | Needed to host infrastructure (VPC, EKS, RDS). |
| **Terraform Installed** | To create AWS resources automatically. |
| **Ansible Installed** | To configure the master instance with required tools. |
| **Docker Installed** | To build and push container images. |
| **Jenkins Installed** | To automate CI/CD workflows. |
| **kubectl & AWS CLI** | To interact with EKS cluster and AWS services. |
| **Datadog Account** | For performance and log monitoring. |

---

## 🚀 Workflow Overview

### 1️⃣ Infrastructure Provisioning – *Terraform*
- Defines and deploys the entire infrastructure:
  - Custom **VPC**
  - **EC2 master instance**
  - **EKS cluster** for Kubernetes
  - **RDS MySQL database**
- Outputs connection details for Ansible and Jenkins.

### 2️⃣ Configuration Management – *Ansible*
- Connects to the EC2 master instance using the Terraform-generated key.
- Installs:
  - Docker  
  - Jenkins  
  - AWS CLI  
  - kubectl  
  - Datadog agent  
- Ensures the environment is ready for CI/CD.

### 3️⃣ Continuous Integration – *Jenkins*
- Jenkinsfile automates the pipeline:
  1. Pulls code from GitHub.
  2. Builds Docker images for frontend and backend.
  3. Pushes images to DockerHub or ECR.
  4. Applies Kubernetes manifests (`k8s/` directory) to deploy on EKS.
  5. Triggers Datadog monitoring integration.

### 4️⃣ Deployment – *Kubernetes (EKS)*
- Uses the manifests from `k8s/` directory to:
  - Deploy backend and frontend pods.
  - Create services for internal/external communication.
  - Manage routing using an Ingress controller.

### 5️⃣ Monitoring – *Datadog*
- Datadog agents collect cluster and pod-level metrics.
- Visual dashboards track:
  - Pod CPU/memory usage
  - Application logs
  - Deployment status and alerts

---

## ⚠️ Common Errors Faced & Fixes

| Issue | Cause | Solution |
|--------|--------|-----------|
| `Error: VPC CIDR block overlap` | Incorrect CIDR configuration in Terraform | Adjust CIDR range to non-overlapping subnets. |
| `Ansible SSH permission denied` | Wrong SSH key or permissions | Use correct key from `main-key` and run `chmod 400`. |
| `Kubernetes pods in CrashLoopBackOff` | Incorrect environment variables or DB connection | Validate RDS credentials and update Kubernetes secrets. |
| `Datadog agent not reporting` | Misconfigured secret or cluster name | Recheck Datadog API key secret and Helm configuration. |
| `Jenkins build fails to connect EKS` | Missing kubeconfig on master instance | Ensure `aws eks update-kubeconfig` is executed post-Terraform. |

---

## 💰 Cost Optimization

- **Right-sized EC2 & EKS nodes:** Used t3/t4 instance families to reduce compute cost.
- **Single RDS instance:** Avoided multi-AZ setup for dev/test environment.
- **Automated shutdown schedules:** Terraform can integrate with AWS Lambda for non-working hours.
- **Datadog free tier:** Used minimal agent count to monitor critical resources.
- **Avoided fancy managed tools:** Focused on open-source solutions like Jenkins and Ansible to minimize SaaS expenses.

---

## 🏁 Conclusion

This project demonstrates how a **complete DevOps workflow** can be implemented using open-source tools and AWS services — from infrastructure creation to CI/CD and monitoring.  

By leveraging **Terraform**, **Ansible**, **Jenkins**, **EKS**, **RDS**, and **Datadog**, it ensures:
- Full automation  
- Improved reliability and scalability  
- Continuous delivery  
- Real-time visibility  
- Optimized cost  

This setup is production-ready and can be easily extended for multi-environment deployments (dev, staging, prod).

---

# Placement Project CI/CD Pipeline

This project implements a **full CI/CD pipeline** using **Jenkins**, **Docker**, **Kubernetes**, **SonarQube**, **Trivy**, and **Datadog** for monitoring.

The pipeline automates:

* Source code checkout
* Code analysis with SonarQube
* Docker image build and push to Docker Hub
* Vulnerability scanning with Trivy
* Deployment to Kubernetes (EKS)
* Datadog monitoring setup
* Verification of deployed services

---

## Jenkinsfile Explanation

Below is a detailed line-by-line explanation of the `Jenkinsfile` used in this project.

---

### 1️⃣ Pipeline Definition

```groovy
pipeline {
    agent any
```

* **pipeline { ... }**: Defines the Jenkins pipeline block.
* **agent any**: Runs the pipeline on any available Jenkins agent.

---

### 2️⃣ Environment Variables

```groovy
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub')
        DOCKERHUB_USERNAME = "${DOCKERHUB_CREDENTIALS_USR}"
        DOCKERHUB_PASSWORD = "${DOCKERHUB_CREDENTIALS_PSW}"
        BACKEND_IMAGE = "nileshbhurewar/spring-backend:latest"
        FRONTEND_IMAGE = "nileshbhurewar/angular-frontend:latest"
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
        PATH = "/usr/local/bin:/usr/bin:/bin:$PATH"
    }
```

* **DOCKERHUB_CREDENTIALS**: Jenkins secret for Docker Hub credentials.
* **DOCKERHUB_USERNAME / PASSWORD**: Used to login to Docker Hub.
* **BACKEND_IMAGE / FRONTEND_IMAGE**: Docker image names with `latest` tag.
* **KUBECONFIG**: Kubernetes configuration file location on Jenkins agent.
* **PATH**: Ensures shell commands like `kubectl` and `docker` are found.

---

### 3️⃣ Checkout Source Code

```groovy
        stage('Checkout Code') {
            steps {
                echo "Checking out source code..."
                git branch: 'main', url: 'https://github.com/nileshbhurewar/placement-project.git'
            }
        }
```

* **stage('Checkout Code')**: Stage to pull the code from GitHub.
* **echo**: Prints a message in Jenkins console.
* **git ...**: Clones the `main` branch of the repository.

---

### 4️⃣ Pre-check AWS & Kubernetes Access

```groovy
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
```

* **withCredentials([...])**: Injects AWS credentials securely.
* **aws sts get-caller-identity**: Confirms AWS credentials.
* **kubectl get nodes**: Confirms connection to Kubernetes cluster.
* **set -e**: Stops execution if a command fails.

---

### 5️⃣ SonarQube Code Analysis

```groovy
        stage('SonarQube Code Analysis') {
            environment {
                SONARQUBE = credentials('sonarqube-token')
            }
            steps {
                echo "Running SonarQube Analysis..."
                withSonarQubeEnv('SonarQube') {
                    dir('spring-backend') { ... }
                    dir('angular-frontend') { ... }
                }
            }
        }
```

* **environment SONARQUBE**: Secret token for SonarQube.
* **withSonarQubeEnv('SonarQube')**: Configures SonarQube environment.
* **dir('spring-backend') / dir('angular-frontend')**: Changes working directory.
* **mvn clean verify sonar:sonar**: Backend analysis.
* **sonar-scanner**: Frontend analysis.

---

### 6️⃣ Build & Push Docker Images

```groovy
        stage('Build & Push Backend Docker') { ... }
        stage('Build & Push Frontend Docker') { ... }
```

* **docker build -t $BACKEND_IMAGE .**: Build backend Docker image.
* **docker login / push / logout**: Authenticate and push image to Docker Hub.
* Same process for frontend Docker image.

---

### 7️⃣ Trivy Image Scan

```groovy
        stage('Trivy Image Scan') { ... }
```

* **trivy image ...**: Scans Docker images for vulnerabilities.
* **--severity HIGH,CRITICAL**: Checks only high/critical vulnerabilities.
* Installs Trivy automatically if not present.

---

### 8️⃣ Deploy to Kubernetes

```groovy
        stage('Deploy to Kubernetes') { ... }
```

* **kubectl apply -f k8s/**: Deploys YAML manifests.
* **kubectl set image**: Updates deployment images.
* **kubectl rollout status**: Waits for pods to roll out successfully.

---

### 9️⃣ Enable Datadog Monitoring

```groovy
        stage('Enable Datadog Monitoring') { ... }
```

* **kubectl create secret generic datadog-secret**: Stores Datadog API key.
* **helm upgrade --install datadog-agent**: Installs/updates Datadog agent.
* **kubectl rollout restart**: Restarts agent if already running.

---

### 🔟 Verify Services

```groovy
        stage('Verify Services') { ... }
```

* **kubectl get pods,svc,ingress**: Lists all deployed Kubernetes resources.
* **echo**: Confirms successful verification.

---

### Post Actions

```groovy
    post {
        success {
            echo 'Deployment, testing, and monitoring completed successfully!'
        }
        failure {
            echo 'Pipeline failed! Check the console output for details.'
        }
    }
```

* **success**: Runs if the pipeline succeeds.
* **failure**: Runs if the pipeline fails.
* Prints messages to the Jenkins console.

---

✅ **Summary**

This pipeline automates the **entire CI/CD lifecycle** for the Placement Project:

* Code checkout
* Static code analysis
* Docker image build & push
* Security scanning
* Kubernetes deployment
* Datadog monitoring
* Verification

It ensures **continuous integration, deployment, security, and observability** for the project.


## 👨‍💻 Author
**Nilesh Bhurewar**  
