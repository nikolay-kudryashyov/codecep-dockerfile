FROM php:7.2-cli

MAINTAINER Vage Zakaryan vagezakaryan@mail.ru

# Install required system packages
RUN apt-get update && \
    apt-get -y install \
            git \
            zlib1g-dev \
            libssl-dev \
        --no-install-recommends && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install --no-install-recommends -y \
        git curl wget sudo libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev libmcrypt-dev libxml2-dev libpq-dev libpq5 mysql-client libicu-dev \
        && docker-php-ext-configure \
        gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-install -j$(nproc) \
        mbstring zip gd xml pdo pdo_mysql soap mcrypt intl \
        && rm -r /var/lib/apt/lists/*

# Install php extensions
RUN docker-php-ext-install \
    bcmath \
    zip

# Install pecl extensions
RUN pecl install mongodb && \
    docker-php-ext-enable mongodb

# Configure php
RUN echo "date.timezone = UTC" >> /usr/local/etc/php/php.ini

# Install composer
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN curl -sS https://getcomposer.org/installer | php -- \
        --filename=composer \
        --install-dir=/usr/local/bin
RUN composer global require --optimize-autoloader \
        "hirak/prestissimo"

RUN curl -LsS http://codeception.com/codecept.phar -o /usr/local/bin/codecept
RUN chmod a+x /usr/local/bin/codecept

# Prepare application
WORKDIR /repo

# Install vendor
COPY ./composer.json /repo/composer.json
RUN composer install --prefer-dist --optimize-autoloader

# Add source-code
COPY . /repo

ENV PATH /repo:${PATH}
ENTRYPOINT ["codecept"]

# Prepare host-volume working directory
RUN mkdir /project
WORKDIR /project
