#!/bin/bash
set -e

# Default values
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-3306}
DB_USER=${DB_USER:-radius}
DB_PASS=${DB_PASS:-radius}
DB_NAME=${DB_NAME:-radius}

# New path based on master branch structure
CONFIG_FILE="/var/www/html/app/common/includes/daloradius.conf.php"
SAMPLE_FILE="/var/www/html/app/common/includes/daloradius.conf.php.sample"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating daloRADIUS configuration..."
    if [ -f "$SAMPLE_FILE" ]; then
        cp "$SAMPLE_FILE" "$CONFIG_FILE"
    else
        echo "Error: Sample config file not found at $SAMPLE_FILE"
        exit 1
    fi

    # Update database configuration
    sed -i "s/configValues\['CONFIG_DB_HOST'\] = '.*';/configValues['CONFIG_DB_HOST'] = '$DB_HOST';/" "$CONFIG_FILE"
    sed -i "s/configValues\['CONFIG_DB_PORT'\] = '.*';/configValues['CONFIG_DB_PORT'] = '$DB_PORT';/" "$CONFIG_FILE"
    sed -i "s/configValues\['CONFIG_DB_USER'\] = '.*';/configValues['CONFIG_DB_USER'] = '$DB_USER';/" "$CONFIG_FILE"
    sed -i "s/configValues\['CONFIG_DB_PASS'\] = '.*';/configValues['CONFIG_DB_PASS'] = '$DB_PASS';/" "$CONFIG_FILE"
    sed -i "s/configValues\['CONFIG_DB_NAME'\] = '.*';/configValues['CONFIG_DB_NAME'] = '$DB_NAME';/" "$CONFIG_FILE"
    sed -i "s/configValues\['CONFIG_DB_PASS'\] = '.*';/configValues['CONFIG_DB_PASS'] = '$DB_PASS';/" "$CONFIG_FILE"
    sed -i "s/configValues\['CONFIG_DB_NAME'\] = '.*';/configValues['CONFIG_DB_NAME'] = '$DB_NAME';/" "$CONFIG_FILE"
fi

# Ensure web server user owns the config file
chown www-data:www-data "$CONFIG_FILE"

# Check if we need to initialize the database
echo "Waiting for database '$DB_NAME' at $DB_HOST:$DB_PORT..."
MAX_RETRIES=60
COUNT=0
until mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" --skip-ssl -e "select 1" > /dev/null 2>&1; do
  COUNT=$((COUNT+1))
  if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "Error: Database '$DB_NAME' not ready after $MAX_RETRIES retries. Exiting."
    # Try one last time without the DB name to see if the server is at least up
    if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" --skip-ssl -e "select 1" > /dev/null 2>&1; then
        echo "Note: Database server is UP, but database '$DB_NAME' does not exist yet."
    fi
    exit 1
  fi
  echo "Database '$DB_NAME' not ready (attempt $COUNT/$MAX_RETRIES), waiting..."
  sleep 2
done

echo "Database '$DB_NAME' is ready. checking for daloRADIUS tables..."
if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" --skip-ssl -e "DESCRIBE operators_acl" > /dev/null 2>&1; then
    echo "Found 'operators_acl' table. Skipping initialization."
    TABLE_EXISTS=1
else
    echo "Table 'operators_acl' not found. Starting initialization..."
    TABLE_EXISTS=0
fi

if [ "$TABLE_EXISTS" -eq 0 ]; then
    # Import FreeRADIUS schema first
    if [ -f "/var/www/html/contrib/db/fr3-mariadb-freeradius.sql" ]; then
         echo "Importing FreeRADIUS schema from /var/www/html/contrib/db/fr3-mariadb-freeradius.sql..."
         mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" --skip-ssl < /var/www/html/contrib/db/fr3-mariadb-freeradius.sql
    fi

    # Import daloRADIUS schema
    if [ -f "/var/www/html/contrib/db/mariadb-daloradius.sql" ]; then
         echo "Importing daloRADIUS schema from /var/www/html/contrib/db/mariadb-daloradius.sql..."
         mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" --skip-ssl < /var/www/html/contrib/db/mariadb-daloradius.sql
    elif [ -f "/var/www/html/contrib/db/mysql-daloradius.sql" ]; then
         echo "Importing daloRADIUS schema from /var/www/html/contrib/db/mysql-daloradius.sql..."
         mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" --skip-ssl < /var/www/html/contrib/db/mysql-daloradius.sql
    fi
    echo "Database initialization completed."
fi

# Create a flag file to signal that the database is ready for other containers
touch /tmp/db_initialized

echo "Starting daloRADIUS..."
exec "$@"
