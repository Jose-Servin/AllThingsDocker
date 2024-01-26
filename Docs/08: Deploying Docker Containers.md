# Deploying Docker Containers

## From Deployment to Production

General rules to follow when moving from development to Production:

1. Bind Mounts should not be used in Production.
2. Containerized apps might need a build step (e.g React Apps)
3. Multi-Container projects might need to be split (or should be split) across multiple hosts/remote machines.
4. We'll see how the trade-offs between control and responsibility might be worth it.

## Bind Mounts Explained

### Development

- Containers should encapsulate the runtime environment but not necessarily the code.
- Use "Bind Mounts" to provide your local host project files to the running container.
- Allows for instant updates without restarting the Container.

### Production

- Containers should work standalone, you should NOT have source code on your remote machine.
- The image and Container is the single source of truth. Simply building and running will be everything the user needs.
- We use COPY to copy a code snapshot into the image.
- This ensures the image can run without any extra configuration or code.

## Deployment Example: Manual Deployment to AWS

We will first start with a very simple standalone NodeJS App. The deployment approach used here will be to "Install Docker on a remote host (e.g via SSH), push and pull image, run container based on image on remote host."

The source code for this simple app can be found in `../08_SimpleNodeApp`.

![image info](../Images/SimpleNodeApp.drawio.png)

So with this architecture, the first thing we need is a Docker hosting provider. For this example, we will be using a AWS EC2 Instance.

### Deploying Locally

We fist deploy locally to see what the app looks like and to review the Docker build and run commands.

First we build a new image from our `Dockerfile`.

```terminal
docker build -t simple-node-dep .
```

Next we run a Container using this `simple-node-dep` (dep = deployment).

```terminal
docker run -d --rm --name simple-node-app -p 80:80 simple-node-dep
```

Here we named our Container `simple-node-app` and ensured we exposed the ports.

Finally, we visit `localhost` and see our application.

### Deploying to AWS

EC2 is an Amazon service that allows us to spin up and manage our own remote machines.

The general steps we will follow to get our Docker app up and running in our EC2 are:

1. Create and launch an EC2 instance, create VPC and security group.
2. Configure security group to expose all required ports to WWW.
3. Connect to instance via SSH (Secure Shell), install Docker and run Container.

We first created out EC2 instance on AWS and connect via SSH. Open the terminal and navigate to the root where our `.pem` file is located.

```terminal
chmod 400 "DockerDemoKey.pem"
```

```terminal
ssh -i "DockerDemoKey.pem" ec2-user@ec2-52-91-219-175.compute-1.amazonaws.com
```

Note that each time we stop and start our EC2 this `ssh` command will change.

Next, we install Docker on the virtual machine using these commands.

```terminal
sudo yum update -y
sudo yum -y install docker
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo systemctl enable docker
docker --version
```

With docker installed in our EC2, we will next focus on brining our image to this remote machine.

There are two option here:

1. Deploy Source Code and build image in EC2. (Unnecessary Complexity)
   - `docker build` in remote machine.
   - `docker run` in remote machine.
2. Deploy built image. (Via DockerHub)
   - `docker run` in remote machine.

We will go with option 2.

To do this, we set up a new Docker Hub Repo called `simple-node-app`.

Next, we build our image locally

```terminal
docker build -t simple-node-dep .
```

And tag this newly created image.

```terminal
docker tag simple-node-dep joseservin/simple-node-app
```

Finally, push to DockerHub.

```terminal
docker login
docker push joseservin/simple-node-app
```

Now that this is on DockerHub, the next step is to run this image from our remote machine. To do this, we go back to the terminal that is connected to our EC2 and run

```terminal
[ec2-user@ip-172-31-23-89 ~]$
```

```terminal
docker run -d --rm -p 80:80 joseservin/simple-node-app
```

We can verify our container is running in our EC2 by

```terminal
docker ps

CONTAINER ID   IMAGE                        COMMAND                  CREATED         STATUS         PORTS                               NAMES
eae476b7a19d   joseservin/simple-node-app   "docker-entrypoint.s…"   2 minutes ago   Up 2 minutes   0.0.0.0:80->80/tcp, :::80->80/tcp   agitated_faraday
```

Now that this is set up, we will test to see if our app is up and running.

To do this, we go to the AWS EC2 instance page and note the `IPv4 Public IP` however, we cannot simply connect to this IP due to AWS security features. This is why we have to create a security group.

In AWS, we select `Security Groups` and note the lates one created by our EC2 called `launch-wizard-1`. This group controls what traffic is allowed on our EC2.

Note here that the Outbound rule is allowing `All Traffic`, this is why we were able to connect to DockerHub and run a Container from inside of our EC2.

Inbound rules are different, here we see only port `22` is open (the ssh port). We need to allow `http` traffic so we can view our running node app; specifically `http` port 80. We do this by ADDING a new Inbound Rule, selecting http and saving the rule. Make sure we don't remove the SSH rule.

Finally, we go back to the EC2 instance page on AWS and connect to the IPv4 address via Chrome.

```terminal
52.91.219.175
```

### Updating Code

We first make a dummy change on our local `welcome.html` which won't be reflected in our remote machine IPv4 address.

To bring these changes to the remote server we:

1. Rebuild image locally
2. Push to Docker Hub again
3. Run a new container using this updated image in our remote server.

```terminal
docker build -t simple-node-dep .
```

```terminal
docker tag simple-node-dep joseservin/simple-node-app
```

```terminal
docker login
docker push joseservin/simple-node-app
```

In our EC2 connected terminal we first stop the running container

```terminal
[ec2-user@ip-172-31-23-89 ~]$
```

```terminal
docker stop {container-name}
```

Here we need to `docker pull` first so that Docker uses this newly pushed image instead of the cached local one.

```terminal
docker pull joseservin/simple-node-app
```

```terminal
docker run -d --rm -p 80:80 joseservin/simple-node-app
```

And now if we visit our IPv4 address, we will see our code changes.

Finally, to end this deployment setup, we stop the docker container running on our EC2, exit the connection and stop or terminate this EC2 instance on AWS.

### Disadvantages to this approach

The approach detailed about is very "do-it-yourself" heavy, we the user had to configure our EC2, connect to it, install docker etc.

In this approach, we fully own the remote machine and are responsible for it and it's security. We also have to manage the network, firewall and other updating aspects. This means, there are lots of opportunities to mess up and running the `ssh` command can become cumbersome to new devs.

In summary, the approach used above is a full control approach where the developer must know AWS and how to configure everything from beginning to end.

## Deployment Example: Managed Services

In this approach, we will move to a managed remote machine (AWS ECS) to run our container service. With this approach, creation, management and updating of our remote machine is handled automatically and monitoring and scaling is simplified. This is great if we are just concerned with deploying our app/container and can give up some set up control.

For this example, we will be setting up an AWS ECS Cluster. Essentially, this cluster will replace our Docker commands so the configuration part is how we define what command this cluster should run.

Stopping.....Udemy video is outdated.

Vide Instructions can be found [here](https://www.youtube.com/watch?v=YDNSItBN15w&t=1037s&ab_channel=BeABetterDev)
