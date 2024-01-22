FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

COPY src . 

# installing php extensions
RUN docker-php-ext-install pdo pdo_mysql

# Give container permission to files
RUN chown -R www-data:www-data /var/www/html