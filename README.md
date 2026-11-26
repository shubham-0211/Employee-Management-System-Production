
# Employee Management System – EC2 Deployment Guide

## 1. Project Overview

Production deployment of the Employee Management System on AWS EC2.

| Component | Technology |
|---|---|
| Backend | Java 17, Spring Boot |
| Build Tool | Maven 3.8.4 |
| Frontend | Angular 22 |
| Runtime | Node.js 24.22.3, npm 11.19.1 |
| Database | MariaDB 10.5.29 |
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
- MariaDB 10.5.29
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
│   └── schema.sql
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

```bash
cd /home/ec2-user

git clone https://github.com/shubham-0211/Employee-Management-System-Production.git

cd Employee-Management-System-Production
```

## 6. Database Configuration

### Create Database and User

Connect to MariaDB:

```bash
sudo mariadb
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

### Import Database Schema

From the repository root:

```bash
mariadb -u employee_app -p employee_management < database/schema.sql
```

Enter the database user's password when prompted.

### Verify Database Tables

```bash
mariadb -u employee_app -p employee_management
```

Execute:

```sql
SHOW TABLES;
```

Expected tables:

- departments
- employees
- users

Exit:

```sql
EXIT;
```

## 7. Backend Configuration

Configuration file:

```text
employee-backend/src/main/resources/application.properties
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

The complete configuration is maintained in the repository.

### Build Backend

```bash
cd employee-backend

mvn clean package -DskipTests
```

Generated JAR:

```text
target/employee-backend-0.0.1-SNAPSHOT.jar
```

### Start Backend

```bash
java -jar target/employee-backend-0.0.1-SNAPSHOT.jar
```

Keep the terminal running.

### Verify Backend

```bash
curl http://localhost:8080/actuator/health
```

Expected result:

```json
{"groups":["liveness","readiness"],"status":"UP"}
```

## 8. Frontend Build

Open another SSH terminal.

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
dist/employee-frontend/browser
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

### Copy Configuration Files

Run from the repository root:

```bash
sudo cp deployment/nginx/nginx.conf /etc/nginx/nginx.conf

sudo cp deployment/nginx/employee-management.conf /etc/nginx/conf.d/employee-management.conf
```

### Modify Configuration Files

Main configuration:

```bash
sudo vi /etc/nginx/nginx.conf
```

EMS application configuration:

```bash
sudo vi /etc/nginx/conf.d/employee-management.conf
```

### Nginx Configuration Responsibilities

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

### Set Directory Permission

Allow Nginx to access the application files:

```bash
sudo chmod 711 /home/ec2-user
```

### Test and Reload Nginx

```bash
sudo nginx -t
```

If the configuration test succeeds:

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
| 3306 | MariaDB | Not publicly exposed |

## 11. Final Application Verification

### Verify Frontend

```bash
curl -I http://localhost
```

Expected HTTP response:

```text
HTTP/1.1 200 OK
```

### Verify Backend Through Nginx

```bash
curl http://localhost/actuator/health
```

Expected:

```json
{"groups":["liveness","readiness"],"status":"UP"}
```

### Verify in Browser

Open:

```text
http://<EC2-PUBLIC-IP>
```

The EMS login page should appear.

Log in using the configured administrator account.

## 12. Future Deployment Updates

After making changes and pushing them to GitHub, update EC2:

```bash
cd /home/ec2-user/Employee-Management-System-Production

git pull origin main
```

### Rebuild Backend

```bash
cd employee-backend

mvn clean package -DskipTests
```

Stop the currently running backend process and start the newly built JAR:

```bash
java -jar target/employee-backend-0.0.1-SNAPSHOT.jar
```

### Rebuild Frontend

In another terminal:

```bash
cd /home/ec2-user/Employee-Management-System-Production/employee-frontend

npm ci

npm run build
```

### Apply Nginx Changes

Only when Nginx configuration changes:

```bash
cd /home/ec2-user/Employee-Management-System-Production

sudo cp deployment/nginx/nginx.conf /etc/nginx/nginx.conf

sudo cp deployment/nginx/employee-management.conf /etc/nginx/conf.d/employee-management.conf

sudo nginx -t

sudo systemctl reload nginx
```

## 13. Important Deployment Notes

- Backend currently runs manually using `java -jar`.
- No systemd service is configured for Spring Boot.
- Backend must be started manually after a reboot or process termination.
- Nginx serves Angular static files.
- Backend APIs are accessed through Nginx reverse proxy.
- Current deployment uses HTTP on port 80.
- HTTPS is not configured.
- MariaDB and Spring Boot backend ports should not be publicly exposed.
