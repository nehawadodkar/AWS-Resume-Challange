# Deploying a Node.js Analytics App to AWS ECS Fargate

This document outlines the steps taken to containerize a Node.js (Express.js) application and deploy it to AWS ECS Fargate with a public endpoint via an Application Load Balancer (ALB). The app collects basic analytics (IP address, timestamp, user-agent, etc.) and stores them in a DynamoDB table.

---

## 🛠️ Project Summary

* **App Purpose**: Collect visit data on a webpage and log it to DynamoDB.
* **Tech Stack**: Node.js (Express), Docker, AWS ECR, ECS Fargate, ALB, DynamoDB
* **Deployment Type**: Serverless containerized backend with public access

---

## ✅ Step-by-Step Setup

### 1. Create the Express.js App

* Build a simple Express app that receives POST requests to `/log-visit` and logs data to DynamoDB.
* Collects: IP address, timestamp, user agent, and referrer.

```js
const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
```

### 2. Dockerize the App

* Create a `Dockerfile` to containerize the app.
* Example:

```Dockerfile
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]
```

* Build and test locally:

```bash
docker build -t analytics-app .
docker run -p 3000:3000 analytics-app
```

### 3. Push Image to Amazon ECR

* Create a new ECR repository.
* Authenticate and push:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

docker tag analytics-app <repo-uri>:latest
docker push <repo-uri>:latest
```

---

### 4. Create ECS Cluster (Fargate)

* Go to **ECS > Clusters** and create a new cluster using the **Fargate** launch type.

### 5. Create Task Definition

* Define a new **Fargate Task Definition**:

  * Use the pushed ECR image.
  * Set port mappings (container port 3000).
  * Define environment variables if needed (e.g., `DYNAMODB_TABLE`).
  * Attach an **IAM Task Role** with DynamoDB write permissions.

### 6. Create a Service

* In the ECS Cluster, create a **Service**:

  * Use the created task definition.
  * Set number of desired tasks (e.g., 1).
  * Choose **Application Load Balancer**.

### 7. Set Up ALB and Target Group

* ALB handles incoming traffic and routes it to your ECS tasks.
* Create a **Target Group** (type: IP or Fargate-compatible) and attach it to your ECS service.
* Define a listener on the ALB (typically port 80 or 443).

### 8. Configure Security Groups

* ALB Security Group:

  * Allow **inbound** HTTP (port 80) or HTTPS (port 443).
* ECS Task Security Group:

  * Allow inbound traffic **from the ALB SG** on port 3000.

### 9. Set Up DynamoDB Table

* Create a table named `VisitAnalytics` (or your choice).
* Primary key: `id` (a composite of timestamp and IP address).
* Grant permissions via IAM role attached to ECS Task.

---

## 🔐 IAM Role Permissions

Attach a role to the ECS Task with a policy like:

```json
{
  "Effect": "Allow",
  "Action": ["dynamodb:PutItem"],
  "Resource": "arn:aws:dynamodb:us-east-1:<account-id>:table/VisitAnalytics"
}
```

---

## 🧼 Cleanup (To Avoid Charges)

If you're done experimenting:

* Stop or delete ECS Service (to avoid ALB and compute charges).
* Delete ALB and Target Group.
* Delete ECR images and repository.
* Delete the DynamoDB table.
* Optionally, delete the ECS cluster.

> ✅ Tip: Document IAM roles and SG settings in this repo or AWS console before deleting to avoid forgetting how things were configured.

---

## 🧠 Notes

* ALB ensures the service is reachable via the internet.
* ECS handles scaling and task health.
* Fargate removes the need to manage EC2 instances.
* Security Groups act as firewalls controlling traffic.
* Target Groups route traffic from ALB to your running tasks.

---

## 📎 References

* [AWS ECS Fargate Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/what-is-fargate.html)
* [AWS Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)
* [Amazon DynamoDB](https://docs.aws.amazon.com/dynamodb/index.html)

---

Feel free to fork, clone, and adapt these steps for your own learning projects. Happy building! 🚀
