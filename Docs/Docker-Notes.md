# Docker and Kubernetes Practical Guide

## Images & Containers

Containers: Running unit of software.

Images: Contains code / required tools needed at runtime.

For example, in NodeApp the image is the NodeApp Code + NodeJS Environment and the container is each instance of this running application. It is important to remember the Docker environment is isolated from the local environment.

Use `docker ps -a` to view all created containers.

Use `docker ps` to view all running containers.

Use `docker stop {container-name}` to stop a running container.

### NodeApp Docker Project

Scenario: We have a Node app that we'd like to Dockerize and share with others.

### Understanding our Dockerfile

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

### Using our Dockerfile

1. Run `docker build .` or `docker build {path-to-dockerfile}` to build a custom image.
2. Run `docker run XXXXXX` (container ID)
3. Run `docker run -p 3000:80 {docker-name}` to tell Docker under which local port the internal Docker port should be accessed through.

## Read Only Images

Going back to our NodeApp, we decide to change some aspects of our code. If we re-run `docker run -p 3000:80 {docker-id}` after stopping the container, we won't see these changes applied.

In order to get the new code changes, for now, we need to re-build our custom Docker image.

1. Run `docker build .`
2. Run `docker run -p 3000:80 {docker-name}`

## Understanding Image Layers

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

## Stopping & Restarting Containers

Remember that by default, `docker run` will create a new container from our defined image; and we do this to capture any source code changes. If nothing has changed, we can instead restart a container using `docker start {container-name/id}`.

```terminal
# docker ps -a

CONTAINER ID   IMAGE                 COMMAND                  CREATED        STATUS                      PORTS     NAMES
5da21d832754   43786fbbab1f          "docker-entrypoint.s…"   2 days ago     Exited (137) 32 hours ago             inspiring_elbakyan
7079af454abd   43786fbbab1f          "docker-entrypoint.s…"   2 days ago     Exited (137) 32 hours ago             loving_moore
53650f1f0310   node                  "docker-entrypoint.s…"   2 days ago     Exited (0) 33 hours ago               peaceful_ride
4276fb930681   quay.io/minio/minio   "/usr/bin/docker-ent…"   6 months ago   Exited (2) 6 months ago               minio
```

### Attached and Detached Containers

When restarting a container, we see the terminal executing the docker command and not hanging.

- The container is running in the background when the terminal is given back control. (Attached Mode)
- The container is running in the foreground when the terminal hangs. (Detached Mode)

This has to do with the docker command defaults, `docker start` defaults to detached mode but `docker run` defaults to attached mode.

We can `docker run -p 3000:80 -d {container-id}` to specify detached mode.

- Detached mode allows us to use one terminal for all commands.

We can `docker attach {container-name}` to attach to a detached container. Or we can `docker start -a {container-name}`

- Attached mode allows us to listen to the output of our Container.

If our primary use-case is to view logs, we can instead use `docker logs {container-name}` to view all logs. Or `docker logs -f {container-name}` to "follow" the container i.e attach mode.

## Entering Interactive Mode

We do NOT have to always create some sort of web-server with Docker, we can use it for any dev work, for example running a `.py` script.

1. `docker build .`
2. `docker run {docker-id}`

```terminal
╰─ docker run d571ba13c1f31de82051377f88630ef4207c4d069c1eb0b6a47c98cfb3221f59

Please enter the min number: Traceback (most recent call last):
  File "/app/rng.py", line 3, in <module>
    min_number = int(input('Please enter the min number: '))
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
EOFError: EOF when reading a line
```

We see this error because even though we are attached, we cannot enter/interact with the container and provide the necessary inputs it needs. So instead, we need to use the `-it` flag.

If we want to restart a container in attached mode and listen to the docker terminal we use `docker start -a -i {container-name}`.

## Deleting Images & Containers

### Deleting Containers

1. `docker rm {container-name} {container-name}...`
2. `docker container prune` will remove all stopped containers at once.

### Deleting Images

Images can only be removed when the container they are used for is removed. A stopped container that uses the node image is technically still dependent on node and can start back up at any time so the node image cannot be removed.

1. `docker images` will list all images we have.
2. `docker rmi {image-id}` will remove the image and any layers associated with that image.
3. `docker image prune` will remove all un-used images.

### Removing Stopped Containers Automatically

- Achieved via the `--rm` flag.

So now, if we go back to our NodeApp project, we can use the `docker run -p 3000:80 -d -rm {image-id}`.

- `-p` opens the ports.
- `-d` detached head.
- `--rm` remove container when it exits.

And once we stop the container `docker stop {container-name}` we will no longer see this container under `docker ps -a`.

Automatically stopping a container makes sense when we use servers, because we need to stop and rebuild the container to capture source code changes so this helps keep our docker container list un-cluttered.

### Inspecting Images

1. `docker image inspect {image-id}`

## Copying Files Into and From a Container

- `docker cp` allows us to copy into or out of a container.

Scenario: we have a running container for our NodeApp, in detached state. We added `../NodeApp/dummy/secret.txt` and would like to copy this into our running container.

```terminal
docker cp dummy/.jovial_mayer:copyTest
Successfully copied 2.56kB to jovial_mayer:/copyTest
```

To check if this was copied to our container, we delete `secret.txt` locally and copy from the container to our local system now.

```terminal
docker cp jovial_mayer:/copyTest/secret.txt dummy
Successfully copied 2.56kB to /Users/joseservin/AllThingsDocker/NodeApp/dummy
```

### When/Why Copy?

- A good example is copying Docker log files into our local system for further processing.