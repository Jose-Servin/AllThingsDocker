# Working with Utility Containers

## Utility Containers - Why?

Utility Containers are not both app + environment, instead they are simple containers that set up our environments by running commands like `docker run mynpm init`. These type of containers can be used to execute/append custom commands.

For this scenario, we are starting with an empty directory for our project. Previously, we received started code that was the result of setting up a Node application project; running `npn init`. But what if we don't have node installed locally?

## Running commands in Containers

One way of doing this is by using the `docker exec` command. So, if we want a node app started in a new container that's running node we can run

```terminal
docker exec -it {node-container-name} npm init
```

But this isn't that useful, the project gets set up inside of the containers file system so our local system is still without the necessary starter files.

Also note that the container shuts down after executing the passed commands so we need a way to save the started files in our local system.

## Building our first Utility Containers

We first build a lightweight Node image that can be used by the developer to run any command.

```Dockerfile
FROM node:14-alpine

WORKDIR /app
```

Here we didn't define a `CMD [""]` variable because we, the developer would like to send any command to this utility container. So instead, we pass the command in the `docker run` command.

```terminal
docker build -t node-utils .
```

Now, to build that connection between container file system and local host file system and capture all necessary started code, we use a bind mount.

```terminal
docker run -it \
-v "/Users/joseservin/AllThingsDocker/06_UtilityContainer:/app" \
node-utils \
npm init
```

After running this command, we'll see the `package.json` file show up in our local host file system.

## Utilizing ENTRYPOINT

Now, we'd like to limit the commands we send to this utility container by making sure they are `npm` commands and/or they are prepended with `npm`.

To do this, we use the `ENTRYPOINT [""]` command, to ensure any command we are sending is an actual npm command.

```dockerfile
FROM node:14-alpine

WORKDIR /app

ENTRYPOINT [ "npm" ]
```

Next, we re-build our `node-utils` image and run a new container, but this time only passing `init` as the command.

```terminal
docker run -it \
-v "/Users/joseservin/AllThingsDocker/06_UtilityContainer:/app" \
node-utils \
init
```

We could now add some dependencies like `express` by using the following command.

```terminal
docker run -it \
-v "/Users/joseservin/AllThingsDocker/06_UtilityContainer:/app" \
node-utils \
install express --save
```

This will create the `package-lock.json` file AND the `node_modules` file in our local system.

## Docker Compose + Utility Containers

We first take our `docker run` command and create a `docker-compose` file translation.

```docker-compose
version: "3.8"
services:
  npm:
    build: ./ # Build the Dockerfile
    stdin_open: true # replacing the -it flag
    tty: true
    volumes:
      - ./:/app
```

However, when running this docker compose file with `docker-compose up` we run into a couple of issues, the main one is we can't pass our `init` or `install` npm commands.

This is because `docker-compose up` is really just to start up services/applications. We must instead use `docker-compose run` which allows us to run a single service from our `docker-compose` file plus any command that should be appended after our entry point.

```terminal
docker-compose run npm init
```

```terminal
docker-compose run {service} {command}
```

Note that after executing these commands, our container will stop but is not removed. We can remove these containers by using

```terminal
docker-compose run --rm npm init
```

Finally we verify our `package.json` file is created and exists in our local host file system.

```json
{
  "name": "test-compose",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC"
}
```

As well as saving the express dependency by running

```terminal
docker-compose run --rm npm install express --save
```
