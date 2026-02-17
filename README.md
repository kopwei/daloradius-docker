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

- **Ports**:
    - FreeRADIUS: 1812/udp, 1813/udp
    - daloRADIUS: 8080 (Mapped to 80 inside container)

## Directory Structure
- `daloradius/`: Source for daloRADIUS Docker image (Based on `php:8.2-apache`).
- `freeradius/`: Source for FreeRADIUS custom image (Based on `ubuntu:22.04` for multi-arch support).
- `initdb/`: SQL initialization scripts.
- `docker-compose.yml`: Service orchestration.
