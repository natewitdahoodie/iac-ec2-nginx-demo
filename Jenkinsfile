pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Terraform Init') {
      steps { sh 'terraform init' }
    }

    stage('Terraform Plan') {
      steps { sh 'terraform plan' }
    }

    stage('Approve Apply') {
      when { branch 'main' }
      steps {
        input message: "Deploy EC2 nginx from Terraform? (Apply)"
      }
    }

    stage('Terraform Apply') {
      when { branch 'main' }
      steps { sh 'terraform apply -auto-approve' }
    }

    stage('Show Outputs') {
      when { branch 'main' }
      steps {
        sh 'terraform output'
      }
    }
  }
}
