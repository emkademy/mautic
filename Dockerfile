# v6.0.7
FROM mautic/mautic:6.0.7-apache

WORKDIR /var/www/html

# Install Amazon SES plugin and its AWS SDK dependency directly into the image
ENV COMPOSER_HOME=/tmp/composer \
    COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
 && docker-php-ext-install -j"$(nproc)" gd \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "$COMPOSER_HOME" \
 && composer require etailors/mautic-amazon-ses:^1.0 -W --no-interaction --no-progress \
 && composer install --no-dev --no-interaction --no-progress --optimize-autoloader \
 && composer clear-cache \
 && rm -rf var/cache/* \
 && chown -R www-data:www-data vendor var \
 && if [ -d plugins ]; then chown -R www-data:www-data plugins; fi \
 && if [ -d docroot/plugins ]; then chown -R www-data:www-data docroot/plugins; fi

# Branding overrides (Twig templates + static assets)
# Copy all branded themes (system + custom) at once
COPY branding/themes/ /var/www/html/docroot/themes/
COPY mautic/media/images/ /var/www/html/docroot/media/images/
# Also place favicon at web root so landing pages (which often omit <link rel="icon">) use the branded icon
COPY mautic/media/images/favicon.ico /var/www/html/docroot/favicon.ico

# Ensure writable dirs are owned by www-data (important for first-run volume population).
# Note: cache/plugin reload happens at runtime in the mautic_init service (needs DB + config).
RUN mkdir -p /var/www/html/var/cache /var/www/html/var/logs /var/www/html/var/tmp \
 && rm -rf /var/www/html/var/cache/* /var/www/html/var/tmp/* \
 && chown -R www-data:www-data /var/www/html/var /var/www/html/docroot/themes /var/www/html/docroot/media/images
