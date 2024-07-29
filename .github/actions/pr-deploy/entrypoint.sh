#!/bin/bash

if [ -n "$SSH_PRIVATE_KEY" ]; then
    echo "$SSH_PRIVATE_KEY" > private_key.pem
    chmod 600 private_key.pem
    SSH_CMD="ssh -i private_key.pem -o StrictHostKeyChecking=no -p $PORT $USERNAME@$HOST"
else
    SSH_CMD="sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no -p $PORT $USERNAME@$HOST"
fi

$SSH_CMD << EOF
    TIMESTAMP=$(date "+%Y%m%d%H%M%S")  
    REPO_DIR="${GITHUB_REPOSITORY##*/}-${GITHUB_HEAD_REF}"
    REPO_NAME=${GITHUB_REPOSITORY##*/}
    FREE_PORT=$(python3 -c 'import socket; s = socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
    IMAGE_NAME="${GITHUB_HEAD_REF}\${TIMESTAMP}"
    INITIAL_DIR=\$(pwd)

    echo "Cloning started..."
    git clone --single-branch --branch $GITHUB_HEAD_REF $GITHUB_SERVER_URL/$GITHUB_REPOSITORY.git
    mv \$REPO_NAME temp
    cd temp

    if [[ ! -d "$DIR" ]]; then
    echo "Directory not found: $DIR, please check the directory path."
    exit 1
    fi

    echo "Navigating into the provided directory $DIR"
    cd $DIR
    
    if [ -n "$DOCKERFILE" ]; then
    if [ ! -f "$DOCKERFILE" ]; then
        echo "Dockerfile not found in the specified path: $DOCKERFILE"
        exit 1
    fi
    echo "Dockerfile detected. Building and deploying using Dockerfile..."
    sudo docker build --label branch=${GITHUB_HEAD_REF} -t \$IMAGE_NAME .
    sudo docker run -d --label branch=${GITHUB_HEAD_REF} -p \$FREE_PORT:$EXPOSED_PORT \$IMAGE_NAME
    elif [[ -n "$DOCKER_COMPOSE_FILE" ]]; then
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        echo "Docker compose file not found in the specified path: $DOCKER_COMPOSE_FILE"
        exit 1;
    fi
    echo "docker-compose.yml detected. Building and deploying using Docker Compose..."
    sudo docker-compose up -d --build
    fi

    echo "DEPLOYMENT URL: http://$HOST/\$FREE_PORT"
    echo "INITIAL DIR: \$INITIAL_DIR"
    cd \$INITIAL_DIR
    rm -rf temp

    # Set up tunneling using Serveo with a random high-numbered port
    nohup ssh -tt -o StrictHostKeyChecking=no -R 80:142.93.15.92:\$FREE_PORT serveo.net > serveo_output.log 2>&1 &
    sleep 30
    SERVEO_URL=$(grep -oP 'Forwarding.*?https://\K[^ ]+' serveo_output.log | tail -n 1)
    echo "Deployment URL: \$SERVEO_URL"

EOF

if [ -n "$SSH_PRIVATE_KEY" ]; then
    sudo rm private_key.pem
fi