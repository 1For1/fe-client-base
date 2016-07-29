#!groovy

import groovy.json.JsonOutput

// Get all Causes for the current build
//def causes = currentBuild.rawBuild.getCauses()
//def specificCause = currentBuild.rawBuild.getCause(hudson.model.Cause$UserIdCause)

//echo "Cause: ${causes}"
//echo "SpecificCause: ${specificCause}"

stage 'DockerBuild'
slackSend color: 'blue', message: "ORG: ${env.JOB_NAME} #${env.BUILD_NUMBER} - Starting Docker Build"
node ('docker-cmd'){
    //env.PATH = "${tool 'Maven 3'}/bin:${env.PATH}"

    checkout scm

    sh "echo Working on BRANCH ${env.BRANCH_NAME} for ${env.BUILD_NUMBER}"

    dockerlogin()
    dockerbuild("oneforone/web-app-base:${env.BRANCH_NAME}.${env.BUILD_NUMBER}")
}

stage 'DockerHub'
slackSend color: 'green', message: "ORG: ${env.JOB_NAME} #${env.BUILD_NUMBER} - Pushing to Docker"
node('docker-cmd') {
    dockerlogin()
    dockerpush("oneforone/web-app-base:${env.BRANCH_NAME}.${env.BUILD_NUMBER}")

}

switch ( env.BRANCH_NAME ) {
    case "master":
        stage 'DockerLatest'
        node('docker-cmd') {
            slackSend color: 'blue', message: "ORG: ${env.JOB_NAME} #${env.BUILD_NUMBER} - Removing latest tag"

            dockerlogin()

            // Erase
            dockerrmi('oneforone/web-app-base:latest')

            // Tag
            dockertag("oneforone/web-app-base:${env.BRANCH_NAME}.${env.BUILD_NUMBER}","oneforone/web-app-base:latest")

            // Push
            slackSend color: 'blue', message: "ORG: ${env.JOB_NAME} #${env.BUILD_NUMBER} - Pushing :latest"
            dockerpush('oneforone/web-app-base:latest')

            //docker -H tcp://10.1.10.210:5001 pull oneforone/backend:latest
        }

        stage 'Sleep'
        sleep 30

        stage 'Downstream'
        slackSend color: 'blue', message: "ORG: ${env.JOB_NAME} #${env.BUILD_NUMBER} - Building Downstream"

        try {
            build '/GitHub-Organization/web-app/master'
        } catch (err) {

        }
        break

    default:
        echo "Branch is not master.  Skipping tagging and push.  BRANCH: ${env.BRANCH_NAME}"
}


// Functions


// Docker functions
def dockerlogin() {

    retry (3) {
        timeout(60) {
                sh "docker -H tcp://10.1.10.210:5001 login -e ${env.DOCKER_EMAIL} -u ${env.DOCKER_USER} -p ${env.DOCKER_PASSWD} registry.1for.one:5000"
        }
    }
    sh "cat ~/.docker/config.json"

}

def dockerbuild(label) {
    sh "docker -H tcp://10.1.10.210:5001 build -t registry.1for.one:5000/${label} ."
}
def dockerstop(vm) {
    sh "docker -H tcp://10.1.10.210:5001 stop ${vm} || echo stop ${vm} failed"
}

def dockerrmi(vm) {
    sh "docker -H tcp://10.1.10.210:5001 rmi -f registry.1for.one:5000/${vm} || echo RMI Failed"
}


def dockertag(label_old, label_new) {
    sh "docker -H tcp://10.1.10.210:5001 tag -f registry.1for.one:5000/${label_old} registry.1for.one:5000/${label_new}"
}

def dockerpush(image) {
    sh "docker -H tcp://10.1.10.210:5001 push registry.1for.one:5000/${image}"
}

def dockerrm(vm) {
    sh "docker -H tcp://10.1.10.210:5001 rm -f ${vm} || echo RMI Failed"
}
