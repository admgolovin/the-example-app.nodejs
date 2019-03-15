def branch
def revision
def registryIp

pipeline {

    agent {
        kubernetes {
            label 'build-service-pod'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    job: build-service
spec:
  containers:
  - name: jnlp
    image: jenkins/jnlp-slave:alpine
    volumeMounts:
    - mountPath: /home/jenkins
      name: workspace-volume
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-cd85g
      readOnly: true
    resources:  
      requests:
        ephemeral-storage: "100Mi"
      limits:
        ephemeral-storage: "2Gi"
  - name: helm-cli
    image: linkyard/docker-helm
    command: ["cat"]
    tty: true
  - name: docker
    image: docker:18.09.2
    command: ["cat"]
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
    resources:
      limits:
        ephemeral-storage: "2Gi"
      requests:
        ephemeral-storage: "100Mi"

  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock

"""
        }
    }
    options {
        skipDefaultCheckout true
    }


    stages ('Tests'){

        stage ('checkout') {
            steps{
                script{
                    print "Checkout stage is launched"
                    def mycommit = checkout scm
                    for (val in mycommit) {
                        print "key = ${val.key}, value = ${val.value}"
                    }
                    revision = sh(script: 'git log -1 --format=\'%h.%ad\' --date=format:%Y%m%d-%H%M | cat', returnStdout: true).trim()

                }
            }
        }
        stage ('build and push artifact') {
            steps {
                container('docker') {
                    script {
                        registryIp= "818353068367.dkr.ecr.eu-central-1.amazonaws.com/tony"
                        sh "docker build . -t ${registryIp}:${revision} --build-arg REVISION=${revision}"
                        docker.withRegistry("https://818353068367.dkr.ecr.eu-central-1.amazonaws.com", "ecr:eu-central-1:antons-aws") {
                            sh "docker push ${registryIp}:${revision}"
                        }   
                    }
                }
            }
        }
        stage ('Deploy art'){
          steps{
            container('helm-cli'){
              script {
                sh "ls -a"
                currentSlot = sh(script: "helm get values --all js_app the-example-app.nodejs/js_app | grep 'productionSlot:' | cut -d ' ' -f2 | tr -d '[:space:]'", returnStdout: true).trim()
                if (currentSlot == "blue") {
                    newSlot="green"
                    tagVar="image.deploy_green"
                  } 
                else if (currentSlot == "green") {
                    newSlot="blue"
                    tagVar="image.deploy_blue"
                } 
                else {
                    sh "helm install -n js_app the-example-app.nodejs/js_app --set image.deploy_blue=${revision},blue.enabled=true"
                    return
                  }
                        
                sh "helm upgrade js_app the-example-app.nodejs/js_app  --set ${tagVar}=${revision},${newSlot}.enabled=true --reuse-values"
                
                userInput = input(message: 'Switch productionSlot? y\\n', parameters: [[$class: 'TextParameterDefinition', defaultValue: 'uat', description: 'Environment', name: 'env']])
                        
                if (userInput == "y") {
                    sh "helm upgrade js_app the-example-app.nodejs/js_app  --set productionSlot=${newSlot} --reuse-values"
                }
                userInput = input(message: 'Delete old deployment? y\\n', parameters: [[$class: 'TextParameterDefinition', defaultValue: 'uat', description: 'Environment', name: 'env']])
                
                if (userInput == "y") {
                    sh "helm upgrade js_app the-example-app.nodejs/js_app  --set ${currentSlot}.enabled=false --reuse-values"
                  }
              }
            }
          }
        }
    }
}
