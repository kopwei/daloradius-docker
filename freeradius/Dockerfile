FROM ubuntu:22.04

# Install FreeRADIUS and dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    freeradius \
    freeradius-mysql \
    freeradius-utils \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Configure Timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Enable SQL module and configure it to use environment variables
# In Debian/Ubuntu, modules are in /etc/freeradius/3.0/mods-available
# and enabled in /etc/freeradius/3.0/mods-enabled
RUN ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql \
    && sed -i 's/driver = "rlm_sql_null"/driver = "rlm_sql_mysql"/' /etc/freeradius/3.0/mods-available/sql \
    && sed -i 's/dialect = "sqlite"/dialect = "mysql"/' /etc/freeradius/3.0/mods-available/sql \
    && sed -i 's/^.*server = "localhost".*$/\tserver = "$ENV{MYSQL_HOST}"/' /etc/freeradius/3.0/mods-available/sql \
    && sed -i 's/^.*port = 3306.*$/\tport = $ENV{MYSQL_PORT}/' /etc/freeradius/3.0/mods-available/sql \
    && sed -i 's/^.*login = "radius".*$/\tlogin = "$ENV{MYSQL_USER}"/' /etc/freeradius/3.0/mods-available/sql \
    && sed -i 's/^.*password = "radpass".*$/\tpassword = "$ENV{MYSQL_PASSWORD}"/' /etc/freeradius/3.0/mods-available/sql \
    && sed -i 's/^.*radius_db = "radius".*$/\tradius_db = "$ENV{MYSQL_DATABASE}"/' /etc/freeradius/3.0/mods-available/sql \
    && sed -i 's/^.*read_clients = yes.*$/\tread_clients = yes/' /etc/freeradius/3.0/mods-available/sql \
    # Disable TLS for sensitive SQL connections if not configured
    && sed -i '/tls {/,/}/s/^/#/' /etc/freeradius/3.0/mods-available/sql

# Run FreeRADIUS in foreground
CMD ["freeradius", "-X"]
