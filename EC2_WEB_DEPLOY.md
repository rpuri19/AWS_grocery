# 🚀 **Steps to deploy the webapp on an EC2 Instance**

## 📝 **Overview**

This guide will walk you through **deploying the GroceryMate
application** on an existing **Amazon Linux EC2 instance**. It includes:

-   **Configuring EC2** (Security Groups, updates, and essential
    software)
-   **Setting up PostgreSQL** (Database creation and user setup)
-   **Running the application** (Backend configuration, virtual
    environment, and startup)


# 🔹 **Step 1: Configure EC2**

Before deploying the application, please ensure that the EC2 instance is properly configured.

## ✅ **Connect to the Instance**

Use SSH to connect to your EC2 instance via your local terminal:

    ssh -i /path/to/your-key.pem ec2-user@your-ec2-public-ip


## **Important Note: You Are Now Inside the EC2 Machine**

Once you have connected to your EC2 instance via SSH, your terminal is
now running **inside the EC2 machine**, **not your local computer**.

🔹 **What Does This Mean?**

-   **Completely Different Environment:** The EC2 instance has its own
    **operating system**, installed software, and network settings.
-   **Reinstall Everything:** Any **dependencies** (Docker, PostgreSQL,
    Python) that were installed on your local machine **are not
    available** on the EC2 machine---you need to install them again.
-   **Different Ports & IPs:** The EC2 instance has its **own network
    configuration**. Ports must be explicitly opened in **AWS Security
    Groups** for external access.
-   **File System Isolation:** Files on your local machine **do not
    exist** on the EC2 machine. You must transfer files manually if
    needed (e.g., using `scp`).

### An alternative way to connect to the EC2

Select your EC2 Instance and press on the button 'Connect':

In the tab 'EC2 Instance Connect' leave the settings as is and press on
'Connect' once again. A console will open in which you can continue with
the next steps.

## ✅ **Update the System**

Run the following command to update all installed packages:

    sudo yum update -y

🔹 This fetches and installs the latest security patches, updates core system libraries and ensures compatibility with the latest software versions.

## ✅ **Install Essential Software**

The application requires **Git** (Version control system), **Python** (for running the backend), **PostgreSQL** (the database system used by the application) and dependencies**.
Install them using:

    sudo yum install -y git python3 python3-pip postgresql15 postgresql15-server postgresql15-contrib

Verify installation:

    git --version
    python3 --version
    pip --version
    psql --version

## ✅ **Security Group Configuration**

Before accessing your application from a browser, you need to **allow
inbound traffic** to your EC2 instance by configuring **AWS Security
Groups**. Security Groups act as virtual firewalls that control network
traffic to and from your EC2 instance.

By default, EC2 instances **block all incoming traffic**, so we need to
allow traffic on **port 5000** (used by Flask).

### 🔹 **Steps to Configure Security Groups**

1.  **Navigate to AWS EC2 Console**:
    -   Go to [AWS EC2 Dashboard](https://console.aws.amazon.com/ec2).
    -   Click on **"Instances"** and select your running instance.
2.  **Find the Security Group**:
    -   Scroll down to the **"Security"** section.
    -   Click on the **Security Group ID** linked to your instance.
3.  **Edit Inbound Rules**:
    -   Click on **"Inbound Rules"** → **"Edit inbound rules"**.
    -   Click **"Add Rule"** and enter the following details:
        -   **Type**: Custom TCP
        -   **Port Range**: `5000`
        -   **Source**: `Your IP` (`0.0.0.0/0` for public access, use
            cautiously).
4.  **Save the Changes**.

# **🔹 Step 2: Creating the Database and User**

### **🔹 Why is This Step Needed?**

Before populating the database with application-specific data, we first
need to **create a database and a dedicated user**.

This step ensures that:

-   A **new database** is created to store application data (users,
    products, orders).
-   A **specific user** is assigned instead of using the default
    `postgres` user.
-   The user is granted **necessary privileges** to manage tables and
    data.

## ✅ **Start and Enable PostgreSQL**

    sudo /usr/bin/postgresql-setup --initdb
    sudo systemctl start postgresql
    sudo systemctl enable postgresql

Verify that PostgreSQL is running:

    sudo systemctl status postgresql

🔹 This **Initializes** the PostgreSQL database and **Starts** the PostgreSQL service.

## ✅ **Modify PostgreSQL Authentication (Important)**

By default, PostgreSQL uses **peer authentication**, which may cause
errors like:

    psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "grocery_user"

### ✅ **Step 1: Set the Password for `postgres` User**

Before modifying PostgreSQL authentication settings, we first need to
**manually set a password for the `postgres` user**. This is necessary
because **by default, PostgreSQL uses "peer authentication"**, which
means that the `postgres` user does not require a password when logging
in from the system user. 

Before switching to **password-based authentication (`md5`)**, we must first **set a password manually** so that we don't get locked out.

Since we are currently using **peer authentication**, we can log in as
the `postgres` system user without needing a password:

    sudo -i -u postgres psql -c "ALTER USER postgres WITH PASSWORD '<your_secure_password>';"

🔹 **Replace** `<your_secure_password>` with a strong password of your
choice.

### ✅ Step 2: switching to **password-based authentication**

Now that we have **set a password** for the `postgres` user, we need to
update PostgreSQL's authentication settings to allow password-based
authentication instead of the default **peer authentication**.

### 🔹 **Why Is This Step Needed?**

-   By default, PostgreSQL uses **peer authentication**, meaning it
    checks the operating system username instead of requiring a
    password.
-   This causes **authentication failures** when trying to connect
    remotely or from a different user.
-   Switching to **`md5` authentication** ensures PostgreSQL requires a
    **password** for access, which is necessary for cloud deployments
    and secure database connections.

1.  Modify PostgreSQL Authentication Configuration (`pg_hba.conf`)

    This file controls **how users authenticate** when connecting to
    PostgreSQL.

        sudo nano /var/lib/pgsql/data/pg_hba.conf

2.  Locate the following lines:

3.  **Change `peer` and `ident` to `md5` so authentication requires a
    password (All 6 entries you will have):**

        local   all             all                                     md5
        host    all             all             127.0.0.1/32            md5
        host    all             all             ::1/128                 md5

🔹 **What does this do?**

-   `local` → Ensures all local connections require **password
    authentication (`md5`)**.

-   `host` → Allows **remote connections** to authenticate using
    **passwords (`md5`)**.

    **Save the file and exit** (`CTRL + X`, then `Y`, then `Enter`).

    Now that we've updated authentication settings, we must restart the
    PostgreSQL service:

        sudo systemctl restart postgresql

    To confirm that PostgreSQL is now using **password-based
    authentication (`md5`)**, try logging in using the password you set
    earlier:

        psql -U postgres -h localhost

    type **exit** to exit

## ✅ **Create Database and User**

Now that authentication is set up correctly, we can create the
**database and user** directly from the shell without switching to the
`postgres` user or entering the PostgreSQL CLI.

### ✅ **Run the Following Commands in the Shell**

Instead of logging into the PostgreSQL shell, run the following commands
directly in your EC2 terminal:

-   **`CREATE DATABASE grocerymate_db;`** → Creates a **new database**
    named `grocerymate_db`, which will store application data.

        psql -U postgres -c "CREATE DATABASE grocerymate_db;"

-   **`CREATE USER grocery_user ...`** → Creates a **new user** named
    `grocery_user` with a secure password.

-   **Replace `<your_secure_password>`** with a strong password.

        psql -U postgres -c "CREATE USER grocery_user WITH ENCRYPTED PASSWORD '<your_secure_password>';"

-   **Grants full privileges** to `grocery_user` on the `grocerymate_db`
    database, allowing it to **manage tables and data**.

        psql -U postgres -c "ALTER USER grocery_user WITH SUPERUSER;"

## ✅ **Verify Database and User Creation**

To check if the database and user were created successfully, run:

    psql -U grocery_user -d grocerymate_db -h localhost -W

type **exit** to exit

-   **`U grocery_user`** → Logs in as `grocery_user`.
-   **`d grocerymate_db`** → Connects to the `grocerymate_db` database.
-   **`h localhost`** → Specifies that PostgreSQL is running on
    **localhost**.
-   **`W`** → Prompts for the password set earlier.

If successful, you will enter the **PostgreSQL interactive shell**,
confirming that the database and user were created properly.

# 🔹 **Step 3: Running the Application**

Now that the EC2 instance and PostgreSQL database are set up, it's time
to **deploy the application**

## ✅ **Clone Your Forked Repository**

Instead of cloning the main repository, **clone your own fork.**

1️⃣ **Find your forked repository on GitHub** (it should be under your
GitHub account).

2️⃣ **SSH into your EC2 instance and clone your forked repo**:

    git clone https://github.com/your-github-username/AWS_grocery.git
    cd AWS_grocery/backend


## ✅ **Set Up the Backend**

Follow the **Set Up Python Environment** step from the INSTALL_WEBAPP. \* Since
we are now working on a **dedicated EC2 instance**, there is **no need
to create a virtual environment (`venv`)**---we can run the application
using the system-installed Python.

## ✅ **Configure Environment Variables**

Follow the **Set Environment Variables** step from the INSTALL_WEBAPP.

## ✅ **Populate the Database**

Follow the **Populate the Database** step INSTALL_WEBAPP.

## ✅ **Run the Application**

Once everything is set up, start the application:

    python3 run.py

🔹 The application will now be running, and logs will be displayed in
the console.

## 🏁 **Final Verification**

1.  Open your browser and visit:

        http://your-ec2-public-ip:5000

If the application loads successfully, deployment is complete! 🎉

🚀 **The application is now successfully deployed on EC2!**
