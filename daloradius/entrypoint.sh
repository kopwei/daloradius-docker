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
# This is a basic check. In a production environment, you might want more robust migration handling.
echo "Waiting for database..."
until mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" --skip-ssl -e "select 1" > /dev/null 2>&1; do
  echo "Database not ready, waiting..."
  sleep 2
done

# Check if tables exist. If not, print a message (initialization should be handled by MariaDB initdb)
TABLE_COUNT=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" --skip-ssl -e "SHOW TABLES LIKE 'operators_acl';" | grep -c "operators_acl")

if [ "$TABLE_COUNT" -eq 0 ]; then
    echo "Warning: daloRADIUS tables not found."
    # Optional: Try to import if available in common locations
    if [ -f "/var/www/html/contrib/db/fr2-mysql-daloradius-and-freeradius.sql" ]; then
         echo "Attempting import from /var/www/html/contrib/db/fr2-mysql-daloradius-and-freeradius.sql"
         mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" --skip-ssl < /var/www/html/contrib/db/fr2-mysql-daloradius-and-freeradius.sql
    elif [ -f "/var/www/html/contrib/db/mysql-daloradius.sql" ]; then
         echo "Attempting import from /var/www/html/contrib/db/mysql-daloradius.sql"
         mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" --skip-ssl < /var/www/html/contrib/db/mysql-daloradius.sql
    fi
else
    echo "Database appears to be initialized."
fi

exec "$@"
