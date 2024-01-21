FROM php:7.4-fpm-alpine

WORKDIR /var/www/html

# installing php extensions
RUN docker-php-ext-install pdo pdo_mysql