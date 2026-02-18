# daloRADIUS Docker Setup

This project provides a Dockerized daloRADIUS environment with MariaDB and FreeRADIUS, including multi-arch build support.

## Prerequisites

- Docker
- Docker Compose (v2 or later)

## Quick Start
1.  **Build and Run**:
    ```bash
    docker compose up -d --build
    ```
    This will:
    - Build the `daloradius` image (based on `php:8.2-apache`).
    - Build the `freeradius` image (based on official `freeradius-server` with SQL enabled).
    - Start MariaDB and initialize it with FreeRADIUS and daloRADIUS schemas.
    - Start all services.

2.  **Access daloRADIUS**:
    - URL: `http://localhost:8080`
    - Default Login: `administrator` / `radius`

3.  **Build Multi-Arch Image (Optional)**:
    If you want to push the daloRADIUS image to Docker Hub:
    ```bash
    ./build_and_push.sh
    ```
    *Make sure to edit the script with your Docker Hub username.*

## Configuration

- **Database**:
    - Data is persisted in `db_data` volume.
    - SQL schemas are loaded from `./initdb` on first run.

- daloRADIUS: 8080 (Mapped to 80 inside container)

## Running on Another Machine (e.g., Raspberry Pi)

To run this stack on another device (ARM64 or AMD64) **without cloning the repository**:

1.  **Create a folder** (e.g., `radius-server`) and enter it.
2.  **Create a `docker-compose.yml` file** with the following content:

    ```yaml
    services:
      db:
        image: mariadb:10.11
        restart: unless-stopped
        environment:
          MYSQL_ROOT_PASSWORD: rootpassword
          MYSQL_DATABASE: radius
          MYSQL_USER: radius
          MYSQL_PASSWORD: radius
          TZ: ${TZ:-UTC}
        volumes:
          - ./mysql-data:/var/lib/mysql
        healthcheck:
          test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-prootpassword"]
          interval: 5s
          timeout: 5s
          retries: 10

      daloradius:
        image: kopkop/daloradius:latest
        restart: unless-stopped
        ports:
          - "8080:80"
        environment:
          DB_HOST: db
          DB_USER: radius
          DB_PASS: radius
          DB_NAME: radius
          TZ: ${TZ:-UTC}
        depends_on:
          db:
            condition: service_healthy
        healthcheck:
          test: ["CMD", "test", "-f", "/tmp/db_initialized"]
          interval: 5s
          timeout: 5s
          retries: 40

      freeradius:
        image: kopkop/freeradius:latest
        restart: unless-stopped
        environment:
          MYSQL_HOST: db
          MYSQL_PORT: 3306
          MYSQL_USER: radius
          MYSQL_PASSWORD: radius
          MYSQL_DATABASE: radius
          TZ: ${TZ:-UTC}
        depends_on:
          db:
            condition: service_healthy
          daloradius:
            condition: service_healthy
        ports:
          - "1812:1812/udp"
          - "1813:1813/udp"
    ```

3.  **Run the stack**:
    ```bash
    docker compose up -d
    ```
    *Note: The `freeradius` service correctly waits for `daloradius` to finish the database initialization before it starts.*

## Management Tasks

### Adding a RADIUS Client (NAS / Switch / AP)
This setup enables SQL-based client management. You can add your hardware devices via the daloRADIUS Web UI:

1.  Log in to daloRADIUS (`http://localhost:8080`).
2.  Go to **Management** -> **NAS** -> **New NAS**.
3.  Fill in the details:
    - **NAS IP/Host**: The IP address of your switch or router.
    - **NAS Secret**: The shared secret (password) for your hardware.
    - **NAS Shortname**: A descriptive name (e.g., `Cisco-Core`).
    - **NAS Type**: Usually `other` or specific brand if listed.
4.  Click **Apply**.
5.  **Restart FreeRADIUS** to load the new client (FreeRADIUS in this setup reads clients on startup):
    ```bash
    docker compose restart freeradius
    ```
    *Note: If you add many clients, consider setting up `dynamic_clients` or using a reload command.*

## Directory Structure
- `daloradius/`: Source for daloRADIUS Docker image (Based on `php:8.2-apache`).
- `freeradius/`: Source for FreeRADIUS custom image (Based on `ubuntu:22.04` for multi-arch support).
- `initdb/`: SQL initialization scripts.
- `docker-compose.yml`: Service orchestration.
