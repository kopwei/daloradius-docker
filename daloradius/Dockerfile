FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    mariadb-client \
    libpng-dev \
    libzip-dev \
    unzip \
    libonig-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Docker PHP extensions
RUN docker-php-ext-install \
    gd \
    mysqli \
    pdo_mysql \
    curl \
    mbstring \
    xml \
    zip

# Install fonts for JpGraph
RUN apt-get update && apt-get install -y \
    fonts-liberation \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP for production (suppress deprecation warnings on UI)
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
    echo "error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT" >> /usr/local/etc/php/conf.d/error_reporting.ini && \
    echo "display_errors = Off" >> /usr/local/etc/php/conf.d/error_reporting.ini

# Install PEAR packages
RUN pear channel-update pear.php.net && \
    pear install DB Mail Mail_Mime \
    Mail_Mime

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Clone daloRADIUS
WORKDIR /var/www/html
RUN git clone https://github.com/lirantal/daloradius.git . && \
    chown -R www-data:www-data /var/www/html

# Update Apache DocumentRoot to point to 'app' directory where daloRADIUS lives
# (Reverted wrong change pointing to /app)

# Configure JpGraph to use installed fonts
# Find all jpg-config.inc.php files and update TTF_DIR to point to where we will symlink standard fonts
RUN find /var/www/html/app -name "jpg-config.inc.php" -exec sed -i "s|define('TTF_DIR','/usr/share/fonts/truetype/');|define('TTF_DIR','/usr/share/fonts/truetype/custom/');|g" {} +

# Create custom font directory and symlinks for JpGraph standard fonts (Arial, Verdana, etc.)
# JpGraph defaults to these specific filenames, so we map Liberation fonts to them.
RUN mkdir -p /usr/share/fonts/truetype/custom && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf /usr/share/fonts/truetype/custom/arial.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf /usr/share/fonts/truetype/custom/arialbd.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Italic.ttf /usr/share/fonts/truetype/custom/ariali.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-BoldItalic.ttf /usr/share/fonts/truetype/custom/arialbi.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf /usr/share/fonts/truetype/custom/verdana.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf /usr/share/fonts/truetype/custom/verdanab.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Italic.ttf /usr/share/fonts/truetype/custom/verdanai.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-BoldItalic.ttf /usr/share/fonts/truetype/custom/verdanaz.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf /usr/share/fonts/truetype/custom/courier.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf /usr/share/fonts/truetype/custom/courierb.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationMono-Italic.ttf /usr/share/fonts/truetype/custom/courieri.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationMono-BoldItalic.ttf /usr/share/fonts/truetype/custom/courierbi.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf /usr/share/fonts/truetype/custom/times.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf /usr/share/fonts/truetype/custom/timesbd.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSerif-Italic.ttf /usr/share/fonts/truetype/custom/timesi.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSerif-BoldItalic.ttf /usr/share/fonts/truetype/custom/timesbi.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf /usr/share/fonts/truetype/custom/georgia.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf /usr/share/fonts/truetype/custom/georgiab.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Italic.ttf /usr/share/fonts/truetype/custom/georgiai.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-BoldItalic.ttf /usr/share/fonts/truetype/custom/georgiaz.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf /usr/share/fonts/truetype/custom/trebuc.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf /usr/share/fonts/truetype/custom/trebucbd.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-Italic.ttf /usr/share/fonts/truetype/custom/trebucit.ttf && \
    ln -s /usr/share/fonts/truetype/liberation/LiberationSans-BoldItalic.ttf /usr/share/fonts/truetype/custom/trebucbi.ttf



# Create a redirect index.php since the repository's index.php seems to be missing or we want to force redirect
RUN echo '<?php header("Location: app/operators/login.php"); exit; ?>' > /var/www/html/index.php

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
