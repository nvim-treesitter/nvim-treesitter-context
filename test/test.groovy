pipeline {

    agent {
        label "docker"
    }

    options {
        ansiColor('xterm')
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
    }

    environment {

        // Kubernetes deploy (default)
        KUBERNETES_CONFIG = 'kube.yaml'
        KUBERNETES_ENV="test"
        KUBERNETES_NAMESPACE="namspace-test"

        // Docker
        HOME = "$WORKSPACE"
        DOCKER_WORKSPACE = "/workdir"

        GIT_COMMIT = sh(
            script: "printf \$(git rev-parse --short HEAD)",
            returnStdout: true
        )
        GIT_BRANCH = sh(
            script: "printf \$(git rev-parse --abbrev-ref HEAD)",
            returnStdout: true
        )

        GIT_TAG = sh(
            script: "git tag --points-at ${env.GIT_COMMIT}",
            returnStdout: true



        // ...






        )?.trim()

        TAG_NAME = "${GIT_TAG}"



        // ....



    }

    stages {

        stage ('Checkout') {

            steps {

                checkout scm
                sh 'git rev-parse --abbrev-ref HEAD'
                sh 'git rev-parse --short HEAD'
                sh 'echo ${GIT_COMMIT}'
                sh 'echo ${GIT_BRANCH}'
                stash name: "source"

                script {
                    env.VERSION = env.TAG_NAME  // will be NULL when empty
                    sh "echo 'Found version ${env.VERSION}'"




                    // ...








                } // script







                // ...




            } // steps

        } // Checkout

    } // stages

} // pipeline

