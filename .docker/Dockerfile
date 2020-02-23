FROM php:7.4-apache

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	    curl \
        libfreetype6-dev \
        libxml2-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        zlib1g-dev \
        git-core \
        wget \
        unzip \
        netcat \
        net-tools \
        openssl \
	# Install PHP extensions.
	&& docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        opcache \
        pdo_mysql \
        intl \
    && pecl install APCu \
    && docker-php-ext-enable apcu \
    # Add composer.
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
	# Configure apache.
	&& a2enmod rewrite
RUN composer global require hirak/prestissimo
# Add custom php.ini.
ADD ./php.ini /usr/local/etc/php/conf.d/z99-additional-php.ini
# Add vhost.
ADD ./vhost.conf /etc/apache2/sites-enabled/000-default.conf
# Set www-data as owner.
RUN chown -R www-data:www-data /var/www/html
# Clean up.
RUN apt-get clean \
    && apt-get -y purge \
        libfreetype6-dev \
        libxml2-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* /usr/src/*
# Configure volumes.
VOLUME /var/www/html
