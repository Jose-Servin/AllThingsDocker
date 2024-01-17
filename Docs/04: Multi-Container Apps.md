# Multi-Container Applications

## App Introduction

For this project, we have a frontend, backend and Database SPA that we'll be Dockerizing and setting up Container communication.

Here we note that the frontend React is running on one server and the Backend Node is running on another.

### Docker Requirements

Database

- Data must persists: Goals submitted by user
- Access should be limited (user auth)

Backend

- Data must persist: `../04: MultiContainerApp/backend/logs`
- Live source code changes

Frontend

- Live source code changes

## Dockerizing The MongoDB Service

Here, we will setup a MongoDB Container but since our backend is not in a Container yet, we need to ensure the MongoDB Container can communicate with our local backend code. To do this, we set up the Mongo Container with a specified port to communicated.

```terminal
docker run --name mongodb --rm -d -p 27017:27017 mongo
```

Now, we `cd backend` and start our backend services using `node app.js`.

We can confirm connection by examining the mongoDB logs

```terminal
docker logs mongodb

{"t":{"$date":"2024-01-12T15:57:02.521+00:00"},"s":"I",  "c":"CONTROL",  "id":23285,   "ctx":"main","msg":"Automatically disabling TLS 1.0, to force-enable TLS 1.0 specify --sslDisabledProtocols 'none'"}
{"t":{"$date":"2024-01-12T15:57:02.524+00:00"},"s":"I",  "c":"NETWORK",  "id":4915701, "ctx":"main","msg":"Initialized wire specification","attr":{"spec":{"incomingExternalClient":{"minWireVersion":0,"maxWireVersion":21},"incomingInternalClient":{"minWireVersion":0,"maxWireVersion":21},"outgoing":{"minWireVersion":6,"maxWireVersion":21},"isInternalClient":true}}}
{"t":{"$date":"2024-01-12T15:57:02.526+00:00"},"s":"I",  "c":"NETWORK",  "id":4648601, "ctx":"main","msg":"Implicit TCP FastOpen unavailable. If TCP FastOpen is required, set tcpFastOpenServer, tcpFastOpenClient, and tcpFastOpenQueueSize."}
{"t":{"$date":"2024-01-12T15:57:02.531+00:00"},"s":"I",  "c":"REPL",     "id":5123008, "ctx":"main","msg":"Successfully registered PrimaryOnlyService","attr":{"service":"TenantMigrationDonorService","namespace":"config.tenantMigrationDonors"}}
```

## Dockerizing the Backend

We begin first by creating our backend `Dockerfile`, building a `goals-node` image and running a container named `goals-backend`. However, this container crashes due to the app.js code attempting to connect to the `localhost`. The `localhost` is now inside of a container, which means we need to use `host.docker.internal`.

```javascript
mongoose.connect(
  "mongodb://host.docker.internal:27017/course-goals",
  {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  },
  (err) => {
    if (err) {
      console.error("FAILED TO CONNECT TO MONGODB");
      console.error(err);
    } else {
      console.log("CONNECTED TO MONGODB");
      app.listen(80);
    }
  }
);
```

Now, we re-build the image and run the container again.

```terminal
docker run --name goals-backend --rm goals-node
CONNECTED TO MONGODB
```

But now that we have our MongoDB in a container and our backend Node in a Container, our frontend React cannot communicate with the backend. This will cause a new error we need to fix. This is due to our backend Node container not publishing its ports for the frontend.

```terminal
Failed to Load: ERR_CONNECTION_REFUSED
```

We first stop our `goals-backend` container and re-run our `run` command and declare the exposed ports.

```terminal
docker run --name goals-backend --rm -d -p 80:80  goals-node
```

## Dockerizing the Frontend

We first create a Dockerfile for our `/frontend` code and build a new image.

```terminal
docker build -t goals-react .
```

Next, we set up a new container

```terminal
docker run --name goals-frontend --rm -d -p 3000:3000 -it goals-react
```

So now, we have our 3 app components in separate containers

```terminal
CONTAINER ID   IMAGE         COMMAND                  CREATED              STATUS              PORTS                      NAMES
5e649c07fea7   goals-react   "docker-entrypoint.s…"   2 seconds ago        Up 2 seconds        0.0.0.0:3000->3000/tcp     goals-frontend
dbec584e8988   goals-node    "docker-entrypoint.s…"   52 seconds ago       Up 52 seconds       0.0.0.0:80->80/tcp         goals-backend
0fb06364a9b8   mongo         "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:27017->27017/tcp   mongodb
```

Note, during container building, we encountered some issues with our Node version, we had to specify Node:16 in order to solve all package issues.

Debugging can be found [here](https://stackoverflow.com/questions/69692842/error-message-error0308010cdigital-envelope-routinesunsupported)

But now, we can successfully see our React frontend SPA page if we visit `localhost:3000`.

## Adding Docker Networks

We can first start by seeing what networks have been established both by Docker and the user using `docker network ls`

```terminal
docker network ls

NETWORK ID     NAME            DRIVER    SCOPE
56df2fc1d8ba   bridge          bridge    local
8ac1dd1a48ad   favorites-net   bridge    local
0fe6520cbe19   host            host      local
af3eb2a5da5c   none            null      local
```

Next, we create a network that we'll leverage from this SPA application.

```terminal
docker network create goals-net
```

Now we can start up each container again and not have to worry about publishing ports because they will all be in the same network!

First, we start our database.

```terminal
docker run --name mongodb --rm -d --network goals-net mongo
```

Next, we make some source code changes to our backend code since our mongodb is now in a container with it's defined network. Before, this was `host.docker.internal`.

```javascript
mongoose.connect(
  "mongodb://mongodb:27017/course-goals",
  {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  },
  (err) => {
    if (err) {
      console.error("FAILED TO CONNECT TO MONGODB");
      console.error(err);
    } else {
      console.log("CONNECTED TO MONGODB");
      app.listen(80);
    }
  }
);
```

Now we rebuild the image and start up a new backend container using the network we established.

```terminal
docker build -t goals-node .
```

Here we make sure to publish port 80 for our frontend code, this is how the frontend will communicate with the backend services.

```terminal
docker run --name goals-backend --rm -d -p 80:80 --network goals-net goals-node
```

Lastly, for our front-end, we will keep the `localhost` referenced because we have to remember that this code runs on the browser. Our browser is able to distinguish what localhost we are referring to. This also means our frontend does NOT have to be in the same docker network so we simply build a new container.

```terminal
docker run --name goals-frontend --rm -d -p 3000:3000 -it goals-react
```

## Adding Data Volumes to MongoDB

Currently, if we submit a goal in our SPA the goal on persists as long as the mongodb container is up and running. We loose our input data if we stop the container and start a new one with the same image and in the same network.

```terminal
docker run --name mongodb --rm -d --network goals-net -v data:/data/db mongo
```

We found where the mongo db docker image stores it's data [here](https://hub.docker.com/_/mongo)

## Securing our MongoDB

Next, we'll declare some environment variables to add a layer of security to our mongodb.

```terminal
docker run --name mongodb --rm -d \
  --network goals-net -v data:/data/db \
  -e MONGO_INITDB_ROOT_USERNAME=servin \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  mongo
```

This will cause our Node code to fail resulting in a frontend error message from react because the backend is trying to connect to a now "secure" database without passing credentials.

This means, we now have to pass these credentials from our backend. We do this in our `app.js` backend file.

```javascript
mongoose.connect(
  "mongodb://servin:secret@mongodb:27017/course-goals?authSource=admin",
  {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  },
  (err) => {
    if (err) {
      console.error("FAILED TO CONNECT TO MONGODB");
      console.error(err);
    } else {
      console.log("CONNECTED TO MONGODB");
      app.listen(80);
    }
  }
);
```

We encountered an issue here with out volume mounts. We had to stop all containers, `docker volume rm data` and then restart the containers.

```text
The problem could be the volume and the fact that you created another user with different credentials before you changed them. Because of the volume, your database is still there and hence your old root user is still set up - i.e. your old credentials apply.
```

## Adding Data Volumes to our backend NodeJS

Here, the requirements were to capture the log files and have live code changes reflected.

```terminal
docker run --name goals-backend \
  --rm -d -p 80:80 --network goals-net \
  -v logs:/app/logs \
  -v "/Users/joseservin/AllThingsDocker/04_MultiContainerApp/backend:/app" \
  -v /app/node_modules \
  goals-node
```

`-v logs:/app/logs` This named volume is used to capture logs.

`-v "/Users/joseservin/AllThingsDocker/04_MultiContainerApp/backend:/app"` this bind mount is used to capture live code changes.

`-v :/app/node_modules` this anonymous volume is used to prevent our local host code from overriding the container's `node_modules` folder.

However, we run into another node related issue where the "live code" changes we thought we set up are not really being captured because our command `node app.js` is essentially taking a snapshot of our code and running our backend application.

What we want, is for our node server to restart every time our code changes to reflect the change. We do this by adding a dependency which will do this automatically for us.

`backend/package.json`

```json
 "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "start": "nodemon app.js"
  },
  ...
"devDependencies": {
    "nodemon": "^2.0.4"
  }
}
```

We then change our Dockerfile to start this script that utilizes nodemon.

```Dockerfile
CMD ["npm", "start"]
```

Now we can rebuild this image, start a new container for out backend and verify nodemon is picking up changes by viewing the logs.

```terminal
docker logs goals-backend

> backend@1.0.0 start
> nodemon app.js

[nodemon] 2.0.22
[nodemon] to restart at any time, enter `rs`
[nodemon] watching path(s): *.*
[nodemon] watching extensions: js,mjs,json
[nodemon] starting `node app.js`
CONNECTED TO MONGODB
[nodemon] restarting due to changes...
[nodemon] starting `node app.js`
CONNECTED TO MONGODB!
```

## Adding env variables to the backend

First we define in our dockerfile what environment variables are to be expected with their default values.

```docker
ENV MONGODB_USERNAME=root
ENV MONGODB_PASSWORD=secret
```

We then apply these environment variables in our source code

```javascript
mongoose.connect(
  `mongodb://${process.env.MONGODB_USERNAME}:${process.env.MONGODB_PASSWORD}@mongodb:27017/course-goals?authSource=admin`,
  {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  },
  (err) => {
    if (err) {
      console.error("FAILED TO CONNECT TO MONGODB");
      console.error(err);
    } else {
      console.log("CONNECTED TO MONGODB!");
      app.listen(80);
    }
  }
);
```

And lastly, we pass any environment variables at run time.

```terminal
docker run --name goals-backend --rm -d -p 80:80 \
  --network goals-net -v logs:/app/logs \
  -v "/Users/joseservin/AllThingsDocker/04_MultiContainerApp/backend:/app" \
  -v /app/node_modules \
  -e MONGODB_USERNAME=servin \
  goals-node
```

Again, we can check the logs and verify the connection was successful.
