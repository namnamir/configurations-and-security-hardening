# Docker Commands

## Basic
```bash
# build a docker image
# path can be local or remote
docker build -t IMAGE_NAME PATH_TO_IMAGE

# run a docker container
# from the image IMAGE_NAME and name it CONTAINER_NAME
# it would run the container on the port HOST_PORT and connects it to the port CONTAINER_PORT; i.e. -p 443:443
docker run --name CONTAINER_NAME --privileged -p HOST_PORT:CONTAINER_PORT IMAGE_NAME

# start a docker
docker start

# stop a docker
docker stop IMAGE_NAME

# get the list of the docker images
docker image ls

# get the list of the running containers
docker ps -a

# run a command on a specified container 
docker exec -ti CONTAINER_ID COMMAND

# for example: start bash in the container with a specified ID; it might be /bin/bash
docker exec -ti CONTAINER_ID /bin/sh

# exit the docker container, if you are in the bash
exit

# kill a docker container
docker kill CONTAINER_ID

# remove a docker container
docker rm CONTAINER_ID

# remove a docker image
docker rmi IMAGE_ID
```
