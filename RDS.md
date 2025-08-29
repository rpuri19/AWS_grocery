# **Deploying Application with RDS (From Local PostgreSQL to AWS RDS)**

## ✅ **Overview**

This guide walks you through **switching your application’s database from a locally hosted PostgreSQL instance to AWS RDS**.

Before proceeding, ensure that you have **already created an RDS instance** running **PostgreSQL** ,your RDS instance is **private**, **EC2 instance** is in the same **VPC** as your RDS and has **security group rules allowing access**.

---

# 🛠️ **Step 1: Test the Connection from EC2 to RDS**

Before switching the application to use RDS, please ensure that the **RDS instance is private** and **only our EC2 instance** can communicate with it.

### ✅ **Update Security Groups**

Make sure that your **RDS security group** allows incoming connections **only from your EC2 instance**:

1. Find the **security group attached to your RDS instance**.
2. Add an **inbound rule**:
    - **Type**: PostgreSQL
    - **Port**: `5432`
    - **Source**: Select **Custom** and add the **security group of your EC2 instance**.

### ✅ **Verify Connection from EC2**

On your **EC2 instance**, test the database connection:

```
psql -h <your-rds-endpoint> -U <your-db-username> -d <your-db-name>
```

If the connection is successful, you should see the PostgreSQL prompt.

If **authentication fails**, verify your **database username and password**.

After connecting to your database, make sure to exit the database to be able to prompt commands to your EC2 instance instead of your database again before you go on  with Step 2.

# 🛢️ **Step 2: Populate RDS with Application Data**

Since our **local database** already contains data, we need to **copy it to RDS**.


- The RDS database starts **empty**, so we must **create the schema** and **import application data**.
- This step ensures that all **users, products, and orders** are correctly transferred.

## ✅ **Create the Database and User in RDS**

Before importing data, create the necessary **database and user** on RDS.

```
psql -h <your-rds-endpoint> -U postgres -c "CREATE DATABASE grocerymate_db;" #If this is not already created when you did the RDS
psql -h <your-rds-endpoint> -U postgres -c "CREATE USER grocery_user WITH ENCRYPTED PASSWORD '<your-password>';"
```

Enter your DB to grant permissions:

```
psql -h <your-rds-endpoint> -U postgres -d <your-db-name>
```

**Grant Permissions:** 

```
GRANT USAGE, CREATE ON SCHEMA public TO grocery_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO grocery_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO grocery_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO grocery_user;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO grocery_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO grocery_user;
```

Verify User and Schema Permissions:

```
\dn+ public # Should show grocery_user=UC/pg_database_owner
\ddp # Should show grocery_user with table/sequence privileges

```

After connecting to your database, make sure to exit the database to be able to prompt commands to your EC2 instance instead of your database again before you go on with the next step.

## ✅ **Populate RDS with Application Data**

Since the **RDS database is initially empty**, we need to **populate it with predefined application data** from a SQL file. This file contains the necessary **schema (tables, columns, constraints)** and **sample data** for products, users, and orders.

Run the following command on **EC2** to execute the SQL file and populate the database:

```
psql -h <your-rds-endpoint> -U grocery_user -d grocerymate_db -f backend/app/sqlite_dump_clean.sql
```

### ✅ **Verify That Data Was Inserted Successfully**

To check if the database has been correctly populated, **list all tables**:

```
psql -h <your-rds-endpoint> -U grocery_user -d grocerymate_db -c "\dt"
```

To inspect whether data was inserted into key tables, run:

```
psql -h <your-rds-endpoint> -U grocery_user -d grocerymate_db -c "SELECT * FROM users;"
psql -h <your-rds-endpoint> -U grocery_user -d grocerymate_db -c "SELECT * FROM products;"
```
This retrieves and displays rows from the **`users`** and **`products`** tables. Confirms that test data was successfully loaded into the RDS instance.

If you see **rows of data**, the setup is complete! ✅


# ⚙️ **Step 3: Configure Application to Use RDS**

Now that our database is set up on **AWS RDS**, we need to **update the application to connect to it**. Since we are running our application inside a **Docker container**, we will pass the **updated RDS connection settings** as environment variables.

### ✅ **Setting Environment Variables for RDS Connection**

There are **two ways** to configure environment variables for the database connection inside Docker:

1. **Modify the `.env` file**
    - This is useful for local development where you want persistent settings.
    - The application reads values from `.env` automatically.
2. **Pass environment variables at runtime using `e` flags in `docker run`**
    - This is **preferred** when running on **EC2 or in different environments**.
    - This method allows us to **override settings dynamically** without modifying files.

💡 **You can choose whichever method works best for you.**

However, for this guide, we will **only demonstrate the `-e` flag approach**, as it ensures flexibility.

### ✅ **Run the Docker Container with RDS Configuration Using `e` Flags**

```
docker run --network host \
  -e POSTGRES_USER=grocery_user \
  -e POSTGRES_PASSWORD=<your-password> \
  -e POSTGRES_DB=grocerymate_db \
  -e POSTGRES_HOST=<your-rds-endpoint> \
  -e POSTGRES_URI=postgresql://grocery_user:grocery_test@<your-rds-endpoint>:5432/grocerymate_db \
  -p 5000:5000 grocerymate
```

# 🚀 **Step 4: Restart the Application**

If you already have a running container, stop and remove it before running the new one:

```
docker stop grocerymate  # Stop the running container
docker rm grocerymate    # Remove the old container
docker run --network host \
  -e POSTGRES_USER=grocery_user \
  -e POSTGRES_PASSWORD=<your-password> \
  -e POSTGRES_DB=grocerymate_db \
  -e POSTGRES_HOST=<your-rds-endpoint> \
  -e POSTGRES_URI=postgresql://grocery_user:grocery_test@<your-rds-endpoint>:5432/grocerymate_db \
  -p 5000:5000 grocerymate
```

🔹 **What Happens Now?**

- The application **no longer uses local PostgreSQL**.
- It now **connects to AWS RDS** for database operations.
- Any **new users, products, and transactions** are stored in **RDS**.


with this the application is successfully **migrated from a local PostgreSQL database to AWS RDS**! 🚀