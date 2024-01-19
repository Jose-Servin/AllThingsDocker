# Docker Compose

This section will use the same `04_MultiContainerApp` but will be focused on creating elegant multi-container orchestration by cutting down the lengthy docker commands we were using.

## What is Docker Compose?

Docker compose is a tool that allows us to replace multiple `docker build` and `docker run` commands with one configuration file plus simple orchestration commands.

- Docker compose does not replace the `Dockerfile`.
- Docker compose does not replace Images or Containers.
- Docker compose is not suited for managing multiple containers on different hosts.

## Creating a Docker Compose file

Create a `docker-compose.yml` file in your root project directory.

Original Mongo DB Container Command

```terminal
docker run --name mongodb --rm -d \
    --network goals-net -v data:/data/db \
    -e MONGO_INITDB_ROOT_USERNAME=servin \
     -e MONGO_INITDB_ROOT_PASSWORD=secret \
    mongo
```

Docker Compose File

```docker-compose
version: "3.8"
services:
  mongodb:
    image: "mongo"
    volumes:
      - data:/data/db
    env_file:
      - ./env/mongo.env
  # backend:
  # frontend:
volumes:
  data:
```

```docker-compose
    environment:
      - MONGO_INITDB_ROOT_USERNAME=servin
      - MONGO_INITDB_ROOT_PASSWORD=secret
```

Note that by using Docker compose, Docker will automatically create a network for all the services detailed in the `docker-compose` file.

Also, named volumes should be specified at the bottom of our Docker-Compose file.

## Docker Compose Up & Down

To run our Docker Compose file, we navigate to it on our terminal and run `docker-compose up`. This will start our container is attached mode, we can use `docker-compose up -d` to start in detached mode.

```terminal
docker-compose up -d
[+] Running 1/1
 ✔ Container 04_multicontainerapp-mongodb-1  Started
```

Lastly, to stop all containers and services we use `docker-compose down`.

```terminal
docker-compose down
[+] Running 2/2
 ✔ Container 04_multicontainerapp-mongodb-1  Removed
 ✔ Network 04_multicontainerapp_default      Removed
```

To delete the volumes, we use `docker-compose down -v`.
