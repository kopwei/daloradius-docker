FROM ubuntu:22.04

# Install FreeRADIUS and dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    freeradius \
    freeradius-mysql \
    freeradius-utils \
    && rm -rf /var/lib/apt/lists/*

# Enable SQL module
# In Debian/Ubuntu, modules are in /etc/freeradius/3.0/mods-available
# and enabled in /etc/freeradius/3.0/mods-enabled
RUN ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql

# Configure SQL module to use environment variables
# FreeRADIUS 3.x uses $ENV{VAR} to access environment variables.
RUN sed -i 's/driver = "rlm_sql_null"/driver = "rlm_sql_mysql"/' /etc/freeradius/3.0/mods-available/sql && \
    sed -i 's/server = "localhost"/server = "$ENV{MYSQL_HOST}"/' /etc/freeradius/3.0/mods-available/sql && \
    sed -i 's/port = 3306/port = "$ENV{MYSQL_PORT}"/' /etc/freeradius/3.0/mods-available/sql && \
    sed -i 's/login = "radius"/login = "$ENV{MYSQL_USER}"/' /etc/freeradius/3.0/mods-available/sql && \
    sed -i 's/password = "radpass"/password = "$ENV{MYSQL_PASSWORD}"/' /etc/freeradius/3.0/mods-available/sql && \
    sed -i 's/radius_db = "radius"/radius_db = "$ENV{MYSQL_DATABASE}"/' /etc/freeradius/3.0/mods-available/sql && \
    # Disable TLS in SQL module (default config expects certs that don't exist)
    sed -i '/tls {/,/}/s/\(.*\)/#&/' /etc/freeradius/3.0/mods-available/sql

# Run FreeRADIUS in foreground
CMD ["freeradius", "-X"]
