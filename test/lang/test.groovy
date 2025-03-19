// {{TEST}}
pipeline { // {{CONTEXT}}

    agent { // {{CONTEXT}}
        label "docker"


        // {{CURSOR}}
    } // {{POPCONTEXT}}

    options { // {{CONTEXT}}
        ansiColor('xterm')
        timeout(time: 60, unit: 'MINUTES')
        timestamps()

        // {{CURSOR}}
    } // {{POPCONTEXT}}

    environment { // {{CONTEXT}}

        // Kubernetes deploy (default)
        KUBERNETES_CONFIG = 'kube.yaml'
        KUBERNETES_ENV="test"
        KUBERNETES_NAMESPACE="namspace-test"

        // Docker
        HOME = "$WORKSPACE"
        DOCKER_WORKSPACE = "/workdir" // {{CURSOR}}

        GIT_COMMIT = sh( // {{CONTEXT}}
            script: "printf \$(git rev-parse --short HEAD)",
            returnStdout: true

            // {{CURSOR}}
        ) // {{POPCONTEXT}}
        GIT_BRANCH = sh(
            script: "printf \$(git rev-parse --abbrev-ref HEAD)",
            returnStdout: true
        )

        GIT_TAG = sh( // {{CONTEXT}}
            script: "git tag --points-at ${env.GIT_COMMIT}",
            returnStdout: true



        // {{CURSOR}}






        )?.trim() // {{POPCONTEXT}}

        TAG_NAME = "${GIT_TAG}"



        // {{CURSOR}}



    } // {{POPCONTEXT}}

    stages { // {{CONTEXT}}

        stage ('Checkout') { // {{CONTEXT}}

            steps { // {{CONTEXT}}

                checkout scm
                sh 'git rev-parse --abbrev-ref HEAD'
                sh 'git rev-parse --short HEAD'
                sh 'echo ${GIT_COMMIT}'
                sh 'echo ${GIT_BRANCH}'
                stash name: "source" // {{CURSOR}}

                script { // {{CONTEXT}}
                    env.VERSION = env.TAG_NAME  // will be NULL when empty
                    sh "echo 'Found version ${env.VERSION}'"




                    // {{CURSOR}}








                } // {{POPCONTEXT}}







                // {{CURSOR}}




            } // steps

        } // Checkout

    } // stages

} // pipeline

