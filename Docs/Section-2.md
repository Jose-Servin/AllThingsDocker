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

We will see that the `feedback/git.txt` page we submitted earlier does not exist in our Container's file system. This is because it's a totally new container.

However, with this new container created without the `--rm` flag, if we submit feedback and stop/restart the container we will see the feedback still exists.

## Introducing Volumes

- Volumes are folders on your host machine hard driver which are mounted ("made available", mapped) into Containers.

- (host) `/some-path` <---> `/app/user-data` (Container)

- Volumes persist if a Container shuts-down. If a container (re-)starts and mounts a volume, any data inside of that volume is available in the container.

- This means, Containers can read and write data to Volumes.

### Two Types of External Data Storages

#### Volumes: Managed by Docker

1. Anonymous Volumes

   ```Dockerfile
   # Dockerfile
   VOLUMES ["/app/feedback"]
   ```

   - remove using `docker volume prune`.

2. Named Volumes

   1. Create a new image with the `volumes` tag

      ```terminal
      docker build -t feedback-node:volumes  .
      ```

   2. Specify the volume during the docker run

      ```terminal
      docker run -p 3000:80 -d --rm --name feedback-app -v feedback:/app/feedback feedback-node:volumes
      ```

   3. Apply changes to your app/submit data you want to save.
   4. Run `docker stop feedback-app` container.

   5. View volumes using `docker volume ls`
   6. Run `docker run` again to see the data persisted even after the container was stopped/removed.

In both instances, Docker will setup a folder/path on your host machine, exact location is unknown to the dev. However, this is managed via the `docker volumes` command.

#### Bind Mounts managed by the user
