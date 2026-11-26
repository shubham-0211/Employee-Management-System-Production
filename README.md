# Employee Management System – EC2 Deployment Guide

## 1. Project Overview

Production deployment of the Employee Management System on AWS EC2.

| Component | Technology |
|---|---|
| Backend | Java 17, Spring Boot |
| Build Tool | Maven 3.8.4 |
| Frontend | Angular 22 |
| Runtime | Node.js 24.22.3, npm 11.19.1 |
| Database | MySQL 8.0.46 |
| Web Server | Nginx 1.30.7 |
| Operating System | Amazon Linux 2023 |
| Cloud | AWS EC2 |
| Source Control | Git and GitHub |

## 2. Required Applications

The following applications must be available on the EC2 instance:

- Java 17 (Amazon Corretto)
- Apache Maven 3.8.4
- Node.js 24.22.3
- npm 11.19.1
- MySQL 8.0.46
- Nginx 1.30.7
- Git

No installation instructions are included in this document.

## 3. Repository Structure

```text
Employee-Management-System-Production/
│
├── employee-backend/
├── employee-frontend/
├── database/
│   ├── schema.sql
│   └── seed-admin.sql
│
├── deployment/
│   └── nginx/
│       ├── nginx.conf
│       └── employee-management.conf
│
└── README.md
```

## 4. EC2 Deployment Details

| Setting | Value |
|---|---|
| AWS Region | ap-south-1 |
| Operating System | Amazon Linux 2023 |
| Project Directory | /home/ec2-user/Employee-Management-System-Production |
| Backend Port | 8080 |
| Application Port | 80 |
| Database | employee_management |
| Database User | employee_app |

## 5. Clone Repository

**Execution location:** EC2 terminal. Start from `/home/ec2-user`.

```bash
cd /home/ec2-user

git clone https://github.com/shubham-0211/Employee-Management-System-Production.git

cd /home/ec2-user/Employee-Management-System-Production
```

Verify the repository:

**Execution location:** Repository root.

```bash
pwd
ls -la
```

Expected project directory:

```text
/home/ec2-user/Employee-Management-System-Production
```

## 6. Database Configuration

### 6.1 Create Database and User

**Execution location:** EC2 terminal. This can be run from any directory.

Connect to MySQL:

```bash
sudo mysql
```

Execute:

```sql
CREATE DATABASE IF NOT EXISTS employee_management
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'employee_app'@'localhost'
IDENTIFIED BY 'Shubham@1999';

ALTER USER 'employee_app'@'localhost'
IDENTIFIED BY 'Shubham@1999';

GRANT ALL PRIVILEGES ON employee_management.*
TO 'employee_app'@'localhost';

FLUSH PRIVILEGES;

EXIT;
```

### 6.2 Import Database Schema

**Execution location:** EC2 terminal, repository root.

Navigate to the repository root:

```bash
cd /home/ec2-user/Employee-Management-System-Production
```

Verify the schema file:

```bash
ls -l database/schema.sql
```

Import the database schema:

```bash
mysql -u employee_app -p employee_management < database/schema.sql
```

Enter the database user's password when prompted.

This creates the following tables:

- departments
- employees
- users

### 6.3 Create Initial Administrator Account

**Execution location:** EC2 terminal, repository root.

Verify the seed file:

```bash
ls -l database/seed-admin.sql
```

Import the initial administrator account:

```bash
mysql -u employee_app -p employee_management < database/seed-admin.sql
```

Enter the database user's password when prompted.

The seed script creates the initial administrator with the following details:

| Field | Value |
|---|---|
| Username | sysadmin |
| Email | shubham.ghongade@admin.com |
| Password | Shubham@1999 |
| Role | ADMIN |
| Status | ACTIVE |
| Employee ID | NULL |

The password is stored in the database as a BCrypt hash.

**Important seed behavior:**

- The script creates the administrator only when no administrator exists and the username and email are available.
- Running the script again does not overwrite an existing administrator account.
- The seed script is intended for initial database setup.
- Do not run it as a routine step during normal application deployments.

### 6.4 Verify Database Tables and Administrator

**Execution location:** EC2 terminal. This command can be run from any directory.

```bash
mysql -u employee_app -p employee_management
```

Execute:

```sql
SHOW TABLES;

SELECT
    id,
    username,
    email,
    role,
    status,
    employee_id
FROM users;
```

Verify that the initial administrator exists with:

- Username: `sysadmin`
- Role: `ADMIN`
- Status: `ACTIVE`

Exit MySQL:

```sql
EXIT;
```

## 7. Backend Configuration

Configuration file:

```text
/home/ec2-user/Employee-Management-System-Production/employee-backend/src/main/resources/application.properties
```

This file contains:

- Database connection settings
- JPA configuration
- Actuator configuration
- JWT secret and expiration
- Initial administrator bootstrap settings

Important settings:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/employee_management
spring.datasource.username=employee_app
spring.jpa.hibernate.ddl-auto=validate

app.jwt.expiration-ms=900000

app.admin.bootstrap-enabled=false
```

The initial administrator is created through `database/seed-admin.sql`.

The application-level administrator bootstrap remains disabled.

### 7.1 Build Backend

**Execution location:** EC2 terminal, backend directory.

```bash
cd /home/ec2-user/Employee-Management-System-Production/employee-backend
```

Build the application:

```bash
mvn clean package -DskipTests
```

Generated JAR:

```text
/home/ec2-user/Employee-Management-System-Production/employee-backend/target/employee-backend-0.0.1-SNAPSHOT.jar
```

### 7.2 Start Backend

**Execution location:** EC2 terminal, backend directory.

```bash
cd /home/ec2-user/Employee-Management-System-Production/employee-backend

java -jar target/employee-backend-0.0.1-SNAPSHOT.jar
```

Keep the terminal running.

### 7.3 Verify Backend Directly

**Execution location:** A second EC2 SSH terminal. This can be run from any directory.

```bash
curl http://localhost:8080/actuator/health
```

Expected result:

```json
{"groups":["liveness","readiness"],"status":"UP"}
```

This confirms that Spring Boot and Actuator are working directly.

## 8. Frontend Build

**Execution location:** EC2 terminal, frontend directory.

Navigate to:

```bash
cd /home/ec2-user/Employee-Management-System-Production/employee-frontend
```

Install dependencies:

```bash
npm ci
```

Build Angular:

```bash
npm run build
```

Angular browser output:

```text
/home/ec2-user/Employee-Management-System-Production/employee-frontend/dist/employee-frontend/browser
```

The main entry file is:

```text
index.csr.html
```

Nginx serves these static browser files. Angular SSR is not used.

## 9. Nginx Configuration

The repository contains two Nginx configuration files.

| Repository File | EC2 Destination |
|---|---|
| deployment/nginx/nginx.conf | /etc/nginx/nginx.conf |
| deployment/nginx/employee-management.conf | /etc/nginx/conf.d/employee-management.conf |

### 9.1 Copy Configuration Files

**Execution location:** EC2 terminal, repository root.

```bash
cd /home/ec2-user/Employee-Management-System-Production
```

Copy the main Nginx configuration:

```bash
sudo cp deployment/nginx/nginx.conf /etc/nginx/nginx.conf
```

Copy the EMS application configuration:

```bash
sudo cp deployment/nginx/employee-management.conf /etc/nginx/conf.d/employee-management.conf
```

### 9.2 Verify Copied Files

**Execution location:** EC2 terminal. Any directory.

```bash
ls -l /etc/nginx/nginx.conf /etc/nginx/conf.d/employee-management.conf
```

Verify that the main configuration includes the conf.d directory:

```bash
sudo grep -n "conf.d" /etc/nginx/nginx.conf
```

The configuration must contain:

```nginx
include /etc/nginx/conf.d/*.conf;
```

### 9.3 Modify Configuration Files

**Execution location:** EC2 terminal. Any directory.

Main configuration:

```bash
sudo vi /etc/nginx/nginx.conf
```

EMS application configuration:

```bash
sudo vi /etc/nginx/conf.d/employee-management.conf
```

### 9.4 Nginx Configuration Responsibilities

**nginx.conf**

- Main Nginx configuration.
- Worker process settings.
- Logging settings.
- Includes application configurations from conf.d.

**employee-management.conf**

- Serves Angular frontend.
- Routes `/api/` requests to Spring Boot.
- Routes `/actuator/` requests to Spring Boot.
- Uses port 80 for HTTP traffic.

### 9.5 Set Directory Permission

Allow Nginx to access the application files.

**Execution location:** EC2 terminal. Any directory.

```bash
sudo chmod 711 /home/ec2-user
```

### 9.6 Verify Nginx Configuration

**Execution location:** EC2 terminal. Any directory.

Test the configuration:

```bash
sudo nginx -t
```

Expected result:

```text
nginx: configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Verify that the EMS application configuration is loaded:

```bash
sudo nginx -T
```

Confirm that the output contains:

- `/etc/nginx/conf.d/employee-management.conf`
- The Angular frontend root directory.
- The `/api/` reverse proxy location.
- The `/actuator/` reverse proxy location.

If the configuration test succeeds, reload Nginx:

```bash
sudo systemctl reload nginx
```

Check Nginx status:

```bash
sudo systemctl status nginx
```

## 10. AWS Security Group

Configure the following inbound rules:

| Port | Service | Access |
|---|---|---|
| 22 | SSH | Administrator IP |
| 80 | HTTP | Intended application users |
| 8080 | Spring Boot | Not publicly exposed |
| 3306 | MySQL | Not publicly exposed |

## 11. Final Application Verification

### 11.1 Verify Frontend

**Execution location:** EC2 terminal. Any directory.

```bash
curl -I http://localhost
```

Expected HTTP response:

```text
HTTP/1.1 200 OK
```

### 11.2 Verify Backend Directly

**Execution location:** EC2 terminal. Any directory.

```bash
curl http://localhost:8080/actuator/health
```

Expected:

```json
{"groups":["liveness","readiness"],"status":"UP"}
```

### 11.3 Verify Backend Through Nginx

**Execution location:** EC2 terminal. Any directory.

```bash
curl http://localhost/actuator/health
```

Expected:

```json
{"groups":["liveness","readiness"],"status":"UP"}
```

This confirms that Nginx successfully forwards the health-check request to Spring Boot.

### 11.4 Verify in Browser

Open:

```text
http://<EC2-PUBLIC-IP>
```

The EMS login page should appear.

Initial administrator login:

| Field | Value |
|---|---|
| Username | sysadmin |
| Password | Shubham@1999 |

## 12. Future Deployment Updates

After making changes and pushing them to GitHub, update EC2.

**Execution location:** EC2 terminal, repository root.

```bash
cd /home/ec2-user/Employee-Management-System-Production

git pull origin main
```

### 12.1 Rebuild Backend

**Execution location:** EC2 terminal, backend directory.

```bash
cd /home/ec2-user/Employee-Management-System-Production/employee-backend

mvn clean package -DskipTests
```

Stop the currently running backend process and start the newly built JAR:

```bash
java -jar target/employee-backend-0.0.1-SNAPSHOT.jar
```

### 12.2 Rebuild Frontend

**Execution location:** Another EC2 terminal, frontend directory.

```bash
cd /home/ec2-user/Employee-Management-System-Production/employee-frontend

npm ci

npm run build
```

### 12.3 Apply Nginx Changes

Only when Nginx configuration changes.

**Execution location:** EC2 terminal, repository root.

```bash
cd /home/ec2-user/Employee-Management-System-Production
```

Copy both files:

```bash
sudo cp deployment/nginx/nginx.conf /etc/nginx/nginx.conf

sudo cp deployment/nginx/employee-management.conf /etc/nginx/conf.d/employee-management.conf
```

Verify both copied files:

```bash
ls -l /etc/nginx/nginx.conf /etc/nginx/conf.d/employee-management.conf
```

Test configuration:

```bash
sudo nginx -t
```

Reload Nginx only if the test succeeds:

```bash
sudo systemctl reload nginx
```

### 12.4 Database Update Notes

- Do not re-import `database/schema.sql` during routine application deployments.
- Do not re-run `database/seed-admin.sql` during routine application deployments.
- For a completely new database, import the schema first and then the administrator seed.
- Existing administrator accounts are not overwritten by the seed script.

## 13. Important Deployment Notes

- Backend currently runs manually using `java -jar`.
- No systemd service is configured for Spring Boot.
- Backend must be started manually after a reboot or process termination.
- Nginx serves Angular static files.
- Backend APIs are accessed through Nginx reverse proxy.
- Current deployment uses HTTP on port 80.
- HTTPS is not configured.
- MySQL and Spring Boot backend ports should not be publicly exposed.
- Initial administrator creation is handled by `database/seed-admin.sql`.
- Application-level administrator bootstrap is disabled.
- After Nginx configuration changes, always test the configuration before reloading.
- Verify that both Nginx configuration files are copied to their correct destinations.
