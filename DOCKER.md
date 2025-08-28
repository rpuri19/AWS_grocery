# 📦 Docker Deployment Guide  
This guide explains how to run the application both **locally** and on **AWS EC2**.

---

# 🚀 Part 1: Local Deployment  
Instructions to set up and run the application on your local machine.

## 🐳 **Step 1: Install Docker**

Follow this guide to install Docker on your machine
🐳 [Docker Installation Guide](https://www.notion.so/1b89418319f380a989d6ec6b39f863ce?pvs=21)

Now you shuld be able to run docker commands. Try:

```jsx
docker ps
```

This should return you running containers (none at the moment). 

## 📄 **Step 2: Create a `Dockerfile`**

A **Dockerfile** is a script that tells Docker how to build your application’s container. Create a new file named **`Dockerfile`** inside your backend folder and add the following content:

```
# Use the official Python image as a base
FROM python:3.9

# Set the working directory inside the container
WORKDIR /app

# Copy the application files into the container
COPY . .

# Ensure the .env file is copied
COPY .env .env

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Run the application
CMD ["python", "run.py"]
```

## 🔧 **Step 3: Configure `.env` for Docker**

Since we already have **PostgreSQL running on our local system**, we don’t need to install another instance inside the container. Instead, we use **`host.docker.internal`** to connect the container to the existing database.

### 📄 **Example `.env` File for Docker**

Make sure to replace the <Your-token> and <grocery_test> placeholders!

```
JWT_SECRET_KEY=<Your-token>
POSTGRES_USER=grocery_user
POSTGRES_PASSWORD=<grocery_test>
POSTGRES_DB=grocerymate_db
POSTGRES_HOST=host.docker.internal
POSTGRES_URI=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}
```

## 🚀 **Step 4: Build and Run the Docker Container**

### **1️⃣ Build the Docker Image**

Run the following command inside the project folder (where the Dockerfile is located):

```
docker build -t grocerymate .
```

### **2️⃣ Run the Container**

Once the image is built, start a container using:

```
docker run -it -p 5000:5000 grocerymate
```

### 🔍 **What This Does:**

- `it` → Runs the container in **interactive mode** (so we can see logs).
- `p 5000:5000` → Maps **port 5000 on your machine** to **port 5000 inside the container** (so the app is accessible).
- `grocerymate` → The name of the **Docker image** we built.

✅ Once the container is running, open your browser and visit:

```
http://localhost:5000
```

---

# 🌐 Part 2: AWS EC2 Deployment  
Steps to deploy and run the application on an AWS EC2 instance.

## Step 1. Launch an EC2 Instance

Launch and connect to the instance via SSH:
```
ssh -i /path/to/your-key.pem ec2-user@your-ec2-public-dns
```

## Step 2. Install Docker on EC2
```
sudo yum update -y
sudo yum install -y docker
```
After installing, start the Docker service and ensure it runs on boot:
```
sudo service docker start
sudo systemctl enable docker
```
Verify that Docker is running by running:
```
sudo systemctl status docker
```
If the service is inactive (dead), restart it:
```
sudo systemctl restart docker
```
By default, Docker requires root privileges. To allow your (ec2-user) to run Docker commands without sudo, add it to the docker group
```
sudo usermod -aG docker ec2-user
```

Note: After adding ec2-user to the Docker group, log out and back in to avoid sudo with Docker commands.

## ✅ Step 3: **Ensure Your Forked Repository is Up-to-Date**
Ensure your local clone is up to date with your GitHub fork. Also confirm that your **Dockerfile** and **.env** File is Present Before Building the Docker Image.

### **Updating the `.env` File for EC2 Deployment**

Update your `.env` file as follows (also replace the password <grocery_test>):

```
echo "POSTGRES_HOST=localhost" >> .env
echo "POSTGRES_URI=postgresql://grocery_user:<grocery_test>@localhost:5432/grocerymate_db" >> .env
```
# ✅ Step 4: **Build the Docker Image**

Now, use the `docker build` command to create the image:

```
docker build -t grocerymate .
```
To check that the image was built successfully, run:

```
docker images
```

You should see `grocerymate` listed in the output.

# **✅ Step 5: Run the Application in Docker**
Make sure to replace <your_grocery_password> with your password.

```
docker run --network host \
  -e POSTGRES_HOST=localhost \
  -e POSTGRES_URI=postgresql://grocery_user:<your_grocery_password>@localhost:5432/grocerymate_db \
  grocerymate
```

After running the container, you can check if it’s running properly:
```
docker ps
```
Verify Deployment:

Visit your instance's public IP with the designated port (e.g., http://your-ec2-public-ip:5000).






