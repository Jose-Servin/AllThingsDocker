# Networking:(Cross-) Container Communication

As far a docker best practices, it is highly recommended we break up our application services by container. That is, each container should do ONE job.

App --> App Container

Database for App --> SQL Database Container

## Container to WWW Connection

Scenario 1: The scenario here is we have an application that is running in a docker container. We also have an "outside" API `some-api.com/` that we'd like to send a GET request from inside the container. So the main action here is sending a request from our container to the world wide web.

Specifically, our `Networking/` project is a Node application that is sending an API call to `https://swapi.dev/api/films`.

## Container to Local Host Machine Communication

Scenario 2: Our Node Application would also need to communication with a local Postgres DB that is running on the host machine. For example, my local Postgres DB contains the super-store data that our app would like to read.

In the Node app implementation, the DB is MongoDB.

## Container to Container Communication

Scenario 3: Our Node app container would like to communicate with another container we have set up that contains a dockerized SQL Database.
