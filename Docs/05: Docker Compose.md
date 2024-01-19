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

## MongoDB Docker Compose

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

## Backend Docker Compose

Now, for the backend and frontend since we used a Dockerfile to create our images, we must make sure this image is pre-built before we can just call it with `image: {image-name}`. Or we can specify the build commands using `build:` and provide a relative path to the Dockerfile location.

```docker-compose
  backend:
    build: ./backend
```

We can be more specific with the `context` command.

```docker-compose
  backend:
    context: ./backend
    dockerfile: dockerfile-dev
```

The original terminal command for our backend was:

```terminal
docker run --name goals-backend --rm -d -p 80:80 \
  --network goals-net \
  -v logs:/app/logs \
  -v "/Users/joseservin/AllThingsDocker/04_MultiContainerApp/backend:/app" \
  -v /app/node_modules \
  -e MONGODB_USERNAME=servin \
  goals-node
```

And is made simpler using a docker-compose file:

```docker-compose
version: "3.8"
services:
  mongodb:
    image: "mongo"
    volumes:
      - data:/data/db
    env_file:
      - ./env/mongo.env
  backend:
    build: ./backend
    ports:
      - "80:80"
    volumes:
      - logs:/app/logs # named volume used to capture logs
      - ./backend:/app # Bind mount without absolute path
      - /app/node_modules # anonymous volume used to prevent node_modules override
    env_file:
      - ./env/backend.env
    depends_on:
      - mongodb
  # frontend:
volumes:
  data:
  logs:
```

```terminal
Network 04_multicontainerapp_default         Created
 ✔ Volume "04_multicontainerapp_data"        Created
 ✔ Volume "04_multicontainerapp_logs"        Created
 ✔ Container 04_multicontainerapp-mongodb-1  Started
 ✔ Container 04_multicontainerapp-backend-1  Started
```

## Frontend Docker Compose

Our original terminal command was:

```terminal
docker run --name goals-frontend \
--rm -d -p 3000:3000 -it \
-v "/Users/joseservin/AllThingsDocker/04_MultiContainerApp/frontend/src:/app/src" \
goals-react
```

One option for specifying the `interactive` mode required is to use

```docker-compose
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend/src:/app/src # Bind mount for live code changes
    stdin_open: true
    tty: true
```

Our complete frontend docker compose file looks like this

```docker-compose
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend/src:/app/src # Bind mount for live code changes
    stdin_open: true
    tty: true
    depends_on:
      - backend
```

## Running our application

After finishing our Docker Compose file with all 3 services, we can run `docker-compose up -d` and view our SPA.

```terminal
CONTAINER ID   IMAGE                           COMMAND                  CREATED          STATUS          PORTS                    NAMES
7bb35e0dd0af   04_multicontainerapp-frontend   "docker-entrypoint.s…"   56 seconds ago   Up 54 seconds   0.0.0.0:3000->3000/tcp   04_multicontainerapp-frontend-1
e211ffb66358   04_multicontainerapp-backend    "docker-entrypoint.s…"   57 seconds ago   Up 55 seconds   0.0.0.0:80->80/tcp       04_multicontainerapp-backend-1
b64782b6c1a5   mongo                           "docker-entrypoint.s…"   57 seconds ago   Up 55 seconds   27017/tcp                04_multicontainerapp-mongodb-1
```

We can verify our data persists by starting our SPA, adding a goal, `docker-compose down` and then restarting our SPA.

## Notes on Images and Container Names

By default, docker will use built images and not rebuild every time we run `docker-compose`. But, we can for it to build a new image each time we run the docker compose command by using the `--build` flag.

`docker-compose up --build -d`

We can also simply build images by using the `docker-compose build` command and not start a container. The `docker-compose up` command includes this build but again, will use "pre-built" images if one exists.

1. `docker-compose build`
2. `docker-compose up -d`

Or

1. `docker-compose up --build -d`

As for container names, we saw how Docker will use default "random" names for our container `04_multicontainerapp-backend`, `04_multicontainerapp-frontend-1` etc.

We can use the `container-name` configuration to specify a container name of our choosing.

```docker-compose
version: "3.8"
services:
  mongodb:
    image: "mongo"
    container-name: mongodb
    volumes:
      - data:/data/db
    env_file:
      - ./env/mongo.env
```
