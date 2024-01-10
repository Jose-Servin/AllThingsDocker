# Networking:(Cross-) Container Communication

As far a docker best practices, it is highly recommended we break up our application services by container. That is, each container should do ONE job.

App --> App Container

Database for App --> SQL Database Container

## Introducing our Demo App

Our `app.js` file is a web application that does not return HTML but rather sends GET requests to a third party API for data, saves this data in a mongoDB and allows the user to query the data.

Our application has 4 end points:

1. `GET /favorites`
   - Query data from MongoDB
2. `POST /favorites`
   - Save data to MongoDB
3. `GET /movies`
   - 3rd party app wrapper
4. `GET /people`
   - 3rd party app wrapper

The last two end points `/movies` and `/people` are wrappers for the 3rd part API that is being called. Essentially, our internal app `GET` request will then go and call this 3rd party API via another `GET` request to receive data.

## Container to WWW Connection

Scenario 1: The scenario here is we have an application that is running in a docker container. We also have an "outside" API `some-api.com/` that we'd like to send a GET request from inside the container. So the main action here is sending a request from our container to the world wide web. Specifically, our `Networking/` project is a Node application that is sending an API call to `https://swapi.dev/api/films`.

We first build a new image from our `Dockerfile` and run a container. Note that the MongoDB side of our app is NOT a part of this container. Yes, the MongoDB is being invoked in our `app.js` (trying to connect) but there is not docker instructions to set up MongoDB/ the installation is NOT a part of this container.

So to summarize, this container only contains our Node App and not our MongoDB.

After we attempt to run our container we see the following error.

`docker run --rm -p 3000:3000 --name favorites favorites-node`

```terminal
(node:1) [MONGODB DRIVER] Warning: Current Server Discovery and Monitoring engine is deprecated, and will be removed in a future version. To use the new Server Discover and Monitoring engine, pass option { useUnifiedTopology: true } to the MongoClient constructor.
(Use `node --trace-warnings ...` to show where the warning was created)
MongoNetworkError: failed to connect to server [localhost:27017] on first connect [Error: connect ECONNREFUSED 127.0.0.1:27017
    at TCPConnectWrap.afterConnect [as oncomplete] (node:net:1595:16) {
  name: 'MongoNetworkError'
}]
    at Pool.<anonymous> (/app/node_modules/mongodb/lib/core/topologies/server.js:441:11)
    at Pool.emit (node:events:519:28)
    at /app/node_modules/mongodb/lib/core/connection/pool.js:564:14
    at /app/node_modules/mongodb/lib/core/connection/pool.js:1000:11
    at /app/node_modules/mongodb/lib/core/connection/connect.js:32:7
    at callback (/app/node_modules/mongodb/lib/core/connection/connect.js:300:5)
    at Socket.<anonymous> (/app/node_modules/mongodb/lib/core/connection/connect.js:330:7)
    at Object.onceWrapper (node:events:634:26)
    at Socket.emit (node:events:519:28)
    at emitErrorNT (node:internal/streams/destroy:169:8)
    at emitErrorCloseNT (node:internal/streams/destroy:128:3)
    at process.processTicksAndRejections (node:internal/process/task_queues:82:21)

```

Which is from us trying to connect to the local host to establish the MongoDB connection.

```javascript
mongoose.connect(
  "mongodb://localhost:27017/swfavorites",
  { useNewUrlParser: true },
  (err) => {
    if (err) {
      console.log(err);
    } else {
      app.listen(3000);
    }
  }
);
```

So, to skip this DB connection setup we'll comment out the code and move the `app.listen()` instruction followed by a new image re-build.

```javascript
app.listen(3000);
// mongoose.connect(
//   "mongodb://localhost:27017/swfavorites",
//   { useNewUrlParser: true },
//   (err) => {
//     if (err) {
//       console.log(err);
//     } else {
//       app.listen(3000);
//     }
//   }
// );
```

```terminal
docker run -d --rm -p 3000:3000 --name favorites favorites-node
```

```terminal
docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED         STATUS         PORTS                    NAMES
91b08cb0a805   favorites-node   "docker-entrypoint.s…"   3 seconds ago   Up 2 seconds   0.0.0.0:3000->3000/tcp   favorites
```

Since we removed the MongoDB part of our app, GET and POST to `/favorites` won't work but `GET /movies` and `GET /people` still do.

This shows us that out of the box, containers CAN communicate with the World Wide Web (APIs) via http requests. There is no special configuration needed to achieve this communication.

## Container to Local Host Machine Communication

Scenario 2: Our Node Application would also need to communication with a local Postgres DB that is running on the host machine. For example, my local Postgres DB contains the super-store data that our app would like to read. In the Node app implementation, the DB is MongoDB.

For this example, we will need to have MongoDB locally but since I do not want to install this DB, I'll just walk through the steps implemented to get the `localhost` DB connection.

For this type of communication, container to local host, we just need to implement a code change.

Current source code:

```javascript
mongoose.connect(
  "mongodb://localhost:27017/swfavorites",
  { useNewUrlParser: true },
  (err) => {
    if (err) {
      console.log(err);
    } else {
      app.listen(3000);
    }
  }
);
```

Change needed:

```javascript
mongoose.connect(
  "mongodb://host.docker.internal:27017/swfavorites",
  { useNewUrlParser: true },
  (err) => {
    if (err) {
      console.log(err);
    } else {
      app.listen(3000);
    }
  }
);
```

`host.docker.internal` is a declaration understood by Docker which translated to the IP address of your host machine.

Now, we can rebuild the image and proceed as usual.

```terminal
docker build -t favorites-node .
```

```terminal
docker run -d --rm -p 3000:3000 --name favorites favorites-node
```

We can check that this MongoDB is live by adding a favorite and checking with postman that the `GET` `localhost:3000/favorites` call returns data. (done through the Postman UI)

`POST` `localhost:3000/favorites` (done through the Postman UI)

```JSON
{

  "name" : "A New Hope",
  "type" : "movie",
  "url" : "some-url.com/dev/v1/films"
}
```

## Container to Container Communication

Scenario 3: Our Node app container would like to communicate with another container we have set up that contains a dockerized SQL Database.
