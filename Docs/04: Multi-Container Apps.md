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
