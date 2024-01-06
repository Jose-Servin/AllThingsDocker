# Managing Data and Working with Volumes

## Understanding Data Categories

1. Application Data

   - Example: Code + Environment
   - Written and provided by the developer.
   - Added to the image and container in the build phase.
   - "Fixed": can't be changed once an image is built.
   - "Read Only", hence stored in Images.

2. Temporary App Data

   - Example: Entered user input.
   - Produced in running Containers.
   - Stored in memory or temp files.
   - Dynamic but can be cleared regularly.
   - "Read + Write" temporary, hence stored in Containers.

3. Permanent App Data

   - Example: user accounts.
   - Produced in running Containers.
   - Stored in files or a database.
   - Must not be lost if the container stops/restarts.
   - "Read + Write" permanent, stored with Containers and Volumes.

## Demo App Introduction

The `../DataVolumes` app demonstrates how the local file system and Container file system contain no connection. After we `docker build`, `docker run` and submit a feedback, we can visit the feedback.txt page ONLY in your container via port 3000. In our local system, the `../DataVolumes/feedback` folder remains empty.

### Understanding the Problem

After stopping our `feedback-app` container it will be removed because we used the `--rm` flag during our docker run command.

Now, if we create a new container without the `--rm` flag

```terminal
docker run -p 3000:80 -d --name feedback-app feedback-node
```

We will see that the `feedback/git.txt` page we submitted earlier does not exist in our Container's file system. This is because it's a totally new container. However, with this new container created without the `--rm` flag, if we submit feedback and stop/restart the container we will see the feedback still exists. The main problem still remains the same, if we delete a container we loose the data submitted.

## Introducing Volumes

- Volumes are folders on your host machine hard driver which are mounted ("made available", mapped) into Containers. They are managed by Docker.

- (host) `/some-path` <---> `/app/user-data` (Container)

- Volumes persist if a Container shuts-down. If a container (re-)starts and mounts a volume, any data inside of that volume is available in the container.

- This means, Containers can read and write data to Volumes.

### Anonymous Volumes

```Dockerfile
# Dockerfile
VOLUMES ["/app/feedback"]
```

- remove using `docker volume prune`.
- here we are specifying the different paths inside of our container we want to persist.
- We chose `/app/feedback` because this is where our permanent feedback files are stored.
- And it's `/app` because that's the `WORKDIR` we defined; this is where our source code was copied into as specified in our Dockerfile.
- Anonymous volumes are created and deleted with Containers
- Leveraged to solve conflicts that occur with volume/bind mount declaration.
- A good way to declare what data is managed inside of the Container vs what becomes present on the host file system.

### Named Volumes

- NOT tied to a specific container.
- Used to shared data between Containers.

1. Build a new image with the `volumes` tag; not required. We did this to differentiate between images.

   ```terminal
   docker build -t feedback-node:volumes  .
   ```

2. Specify the volume during the docker run

   ```terminal
   docker run
   -p 3000:80 (port mapping)

   -d --rm (detached and remove container when stopped)

   --name feedback-app (name the container)

   -v feedback:/app/feedback (create a named volume called 'feedback' that maps to '/app/feedback')

   feedback-node:volumes (use this image)
   ```

3. In your Application submit data you want to save.
4. Run `docker stop feedback-app` container.

5. View volumes using `docker volume ls`
6. Run `docker run` again to see the data persisted even after the container was stopped/removed.

In both instances, Docker will setup a folder/path on your host machine, exact location is unknown to the dev. However, this is managed via the `docker volumes` command.

### Read Only Volumes

Looking back at our volume bind mount exercise, we did the following:

1. Added a named volume called feedback.

2. Added a Bind Mount to capture "real time changes"

3. Added an anonymous volume to tell Docker there are certain parts in its internal file system which should NOT be overwritten from "outside."

However, if we look closely at what the bind mount is actually doing we see that we need to be more explicit and NOT allow the Container to write into the `/app` folder. Only we, the developer, should be able to change them on our host system.

We can enforce this by converting our bind mount into a read-only volume. By default, volumes are read-write but we can restrict this.

```terminal
docker run -d --rm -p 3000:80 --name feedback-app

-v feedback:/app/feedback

(^ Name Volume called feedback)

-v "/Users/joseservin/AllThingsDocker/DataVolumes:/app:ro"

(^ Read Only Volume)

-v /app/node_modules

(^ Anonymous volume; anonymous because it has no name: declared)

feedback-node:volumes
```

Now, we are specifically saying our Docker Container cannot write to `/app` or any of its subfolder. Only the host machine can.

But, for this specific app example, we do want/need to allow the Container to write to the `/app/temp` and `/app/feedback` folders since this is expressed in `server.js`. So, we will use the same logic we used with our anonymous volume and specific a more specific path. The `/app/feedback` volume was already declared in our named volume so we just need to add 1 more additional volume.

```terminal
docker run -d --rm -p 3000:80 --name feedback-app

-v feedback:/app/feedback

(^ Name Volume called feedback)

-v "/Users/joseservin/AllThingsDocker/DataVolumes:/app:ro"

(^ Read Only Volume)

-v /app/temp

(^ anonymous volume used to overwrite ro (read-only) permission for /app/temp)

-v /app/node_modules

(^ Anonymous volume; anonymous because it has no name: declared)

feedback-node:volumes

```

NOTE: the bind mount overriding must occur in the terminal, not in our Dockerfile.

## Introduction Bind Mounts

- The main difference between Volumes and Bind Mounts is that for Bind Mounts, we the developer, define the folder/path on our host machine.

- NOT tied to a Container.

- In terms of our NodeApp, we can place our source code in a Bind Mount and make our Container aware of this. That way, any source code changes can occur in "real-time" and not as a snap shot that happens during the build process.

- Great for persistent, editable data.

- Remember that Bind Mounts are for Containers not Images.

- Bind mounts Mac OS shortcut: `-v $(pwd):/app`

- Leverage Anonymous Volumes to solve Binding Mount conflicts.

### Setting up Bind Mounts

We add a Bind Mount with the same `-v` flag used for Volumes.

- We MUST use absolute paths.

- We must also ensure Docker has access to the parent folder of this absolute path; this can be handled via the Docker App --> Resources --> File Sharing.

```terminal

docker run -d -p 3000:80 --name feedback-app

-v feedback:/app/feedback

(^ Name Volume called feedback)

-v "/Users/joseservin/AllThingsDocker/DataVolumes:/app"

(^ Bind Mount)

feedback-node:volumes
```

However, running this command resulted in a crash...why? We can inspect the Container logs using `docker logs {container-name}`. Which shows us,

```terminal
docker logs feedback-app

node:internal/modules/cjs/loader:1146
  throw err;
  ^

Error: Cannot find module 'express'
Require stack:
- /app/server.js
    at Module._resolveFilename (node:internal/modules/cjs/loader:1143:15)
    at Module._load (node:internal/modules/cjs/loader:984:27)
    at Module.require (node:internal/modules/cjs/loader:1234:19)
    at require (node:internal/modules/helpers:176:18)
    at Object.<anonymous> (/app/server.js:5:17)
    at Module._compile (node:internal/modules/cjs/loader:1375:14)
    at Module._extensions..js (node:internal/modules/cjs/loader:1434:10)
    at Module.load (node:internal/modules/cjs/loader:1206:32)
    at Module._load (node:internal/modules/cjs/loader:1022:12)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:142:12) {
  code: 'MODULE_NOT_FOUND',
  requireStack: [ '/app/server.js' ]
}

Node.js v21.5.0
```

This failed because with the binding mount declaration, we are overwriting everything in our Container's `/app` with everything in our local folder (absolute path) which renders all of our `Dockerfile` instructions useless since they get overwritten by the bind mount.

The local folder does NOT have the `node_modules` folder with the dependencies our App needs.

```javascript
const express = require("express");
```

This `node_modules` folder DOES exist in our Container's file system; it is created via the `RUN npm install` command.

So, how do we solve this?

We need to tell Docker there are certain parts in its internal file system which should NOT be overwritten from "outside." (local) This is achieved by using an anonymous volume.

```terminal
docker run -d --rm -p 3000:80 --name feedback-app

-v feedback:/app/feedback

(^ Name Volume called feedback)

-v "/Users/joseservin/AllThingsDocker/DataVolumes:/app"

(^ Bind Mount)

-v /app/node_modules

(^ Anonymous volume; anonymous because it has no name: declared)

feedback-node:volumes
```

We could also declare this anonymous volume in our `Dockerfile`

```Dockerfile
FROM node

WORKDIR /app

COPY package.json /app

RUN npm install

COPY . /app

EXPOSE 80

VOLUME ["/app/node_modules"]

CMD ["node", "server.js"]
```

How is this solving the issue?

Docker will solve any volume/bind mounts clashes by going with the more specific path. So our `-v "/Users/joseservin/AllThingsDocker/DataVolumes:/app"` is clashing with `-v /app/node_modules`, but `-v /app/node_modules` wins because it's more specific.

We are still binding to `/app` but inside of our Container, `/app/node_modules` will NOT be overwritten. Our Container is essentially overriding the non-existent local `node_modules` folder that we are binding with the one it created via the `npm install` command.

Now if we apply a change to our source code, we see the change applied immediately.

## Managing Docker Volumes

With our app up and running, we can used `docker volume --help` to take a look at all the commands we can use with this instruction.

`docker volume ls` will show us our named volume and anonymous volumes. We won't see our bind mount because that is something WE manage, not Docker. Also note, here we see our anonymous volumes because the container is currently running. If we stop the container and then `docker volume ls` we'd only see the named volume since the anonymous volumes are removed when the container is removed.

```terminal
docker volume ls

DRIVER    VOLUME NAME
local     9c127e9db967
local     96cc6e8dd989
local     feedback
```

`docker volumen inspect {volume-name}` provides various data points about our volume.

```terminal
docker volume inspect feedback
[
    {
        "CreatedAt": "2023-12-31T21:27:18Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/feedback/_data",
        "Name": "feedback",
        "Options": null,
        "Scope": "local"
    }
]
```

`docker volume rm {volume-name}` will remove a volume and error if the volume is currently being used. In our example, if we remove the `feedback` volume, we will loose all `/app/feedback/.txt` that was submitted via our application.

`docker volume prune` will remove all unused volumes.

## COPY vs Bind Mounts

The question here is why do we specify `COPY . . ` in our Dockerfile if we overwrite these instructions with our bind mount in order to see real time changes.

The answer has to do with where in the dev stage we are at. We are using a bind mount because we are still developing. Once our application is ready to be deployed we won't be using a bind mount. In production, we want that snapshot to exist since changes to our source code SHOULD not happen in the production dev stage.

## Dockerignore

We can restrict what gets copied via the `COPY` command in our Dockerfile by using a `.dockerignore` file.

For example, here we are ignoring the `node_modules` folder that might exist locally to again, insure we are not overriding the Container's `node_module` folder but this time, we are doing it to avoid using outdated node modules.

```.dockerignore
node_modules
```

## Working with Environment variables - ENV & ARG

Docker supports build-time ARGuments and runtime ENViornment variables. These 2 options let us dynamically build an image or run a container.

ARG

- Available inside of Dockerfile but NOT accessible in CMD or application code.

ENV

- Available inside of Dockerfile and application code.

### Example using ENV

Currently, the port we are listening on is `app.listen(80);`, however we want to make this dynamic. Node specifically allows us to access environment variables by using `process.env.{variable}`, and with Docker we set this `{variable}`. So our hard coded port becomes `app.listen(process.env.PORT);`.

```dockerfile
COPY . /app

ENV PORT 80

EXPOSE $PORT

CMD ["node", "server.js"]
```

We can now build a new image and run using

```terminal
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v "/Users/joseservin/AllThingsDocker/DataVolumes:/app:ro" -v /app/temp -v /app/node_modules feedback-node:env
```

We can also, change the PORT variable value in the terminal and not have to rebuild a new image to capture this PORT change.

- `--env PORT=8000`

- `--e PORT=8000`

```terminal
docker run -d --rm -p 3000:8000 --env PORT=8000
--name feedback-app
-v feedback:/app/feedback
-v "/Users/joseservin/AllThingsDocker/DataVolumes:/app:ro"
-v /app/temp
-v /app/node_modules
feedback-node:env
```

### .env file example

We can organize our environment variables by using a `.env` file and pointing to it when we run our Docker commands via the `--env-file` flag.

```.env
PORT=8000
```

```terminal
docker run -d --rm -p 3000:8000 --env-file ./.env
--name feedback-app
-v feedback:/app/feedback
-v "/Users/joseservin/AllThingsDocker/DataVolumes:/app:ro"
-v /app/temp
-v /app/node_modules
feedback-node:envs
```

### Example Using Build Arguments (ARG)
