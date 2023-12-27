# Docker and Kubernetes Practical Guide

## Docker Images and Containers: The Core Building Blocks

### Images & Containers

Containers: Running unit of software.

Images: Contains code / required tools needed at runtime.

For example, in NodeApp the image is the NodeApp Code + NodeJS Environment and the container is each instance of this running application. It is important to remember the Docker environment is isolated from the local environment.

Use `docker ps -a` to view all created containers.

Use `docker ps` to view all running containers.

Use `docker stop {container-name}` to stop a running container.

### NodeApp Docker Project

Scenario: We have a Node app that we'd like to Dockerize and share with others.

#### Understanding our Dockerfile

1. Create `Dockerfile`

   This file will contain the setup instructions for our own image. Typically, you begin with the `FROM` keyword which specifies we are building on top of pre-built image.

   There is a distinction here between DockerHub images and local images that are cached.

2. Specify what local files should go into our image.

   ```Dockerfile
   WORKDIR /app
   # This tells Docker to consider this defined path when running commands.
   ```

   ```Dockerfile
   COPY . .
   # This tells Docker to copy everything from the host file system and store them in this location inside the image. (root)
   ```

3. Expose any ports from Docker to the local system

   ```Dockerfile
   EXPOSE 80
   ```

   This is only added for documentation purposes, there is no actual port being shared between Docker and the local system unless specifically commanded.

4. List commands to run when a container is started from the image.

   ```Dockerfile
   CMD ["node", "server.js"]
   ```

#### Using our Dockerfile

1. Run `docker build .` or `docker build {path-to-dockerfile}` to build a custom image.
2. Run `docker run XXXXXX` (container ID)
3. Run `docker run -p 3000:80 {docker-name}` to tell Docker under which local port the internal Docker port should be accessed through.

### Read Only Images

Going back to our NodeApp, we decide to change some aspects of our code. If we re-run `docker run -p 3000:80 {docker-id}` after stopping the container, we won't see these changes applied.

In order to get the new code changes, for now, we need to re-build our custom Docker image.

1. Run `docker build .`
2. Run `docker run -p 3000:80 {docker-name}`

### Understanding Image Layers

Image layers will give us the opportunity to optimize our custom image builds and leverage caches and other Docker features.

The "layer based architecture" comes from each instruction being cached and leveraged to improve image building speeds.

Remember: "Only the instructions where a change is present and any there-after are re-evaluated from scratch."

This is why, we refactored our Dockerfile to be the following:

```Dockerfile
FROM node

WORKDIR /app

# Explicitly copy package.json since we don't expect this to change often.
COPY package.json /app

# Do not re-execute node install
RUN npm install

# Capture source code changes (anything that is NOT packages.json)
COPY . /app

EXPOSE 80

CMD ["node", "server.js"]
```
