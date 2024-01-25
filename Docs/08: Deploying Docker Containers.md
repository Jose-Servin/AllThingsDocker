# Deploying Docker Containers

## From Deployment to Production

General rules to follow when moving from development to Production:

1. Bind Mounts should not be used in Production.
2. Containerized apps might need a build step (e.g React Apps)
3. Multi-Container projects might need to be split (or should be split) across multiple hosts/remote machines.
4. We'll see how the trade-offs between control and responsibility might be worth it.

## Bind Mounts in Production

## Deployment Example: Basic Node App

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
