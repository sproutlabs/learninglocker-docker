FROM php:5.6-apache

ENV DEBIAN_FRONTEND=noninteractive

# Enable Apache rewrite and expires mods
RUN a2enmod rewrite expires

# Required for mongoDB
#RUN apt-key adv --keyserver "keyserver.ubuntu.com" --recv '7F0CEB10' && \
#	echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee #/etc/apt/sources.list.d/mongodb.list

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 && \
echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list


# Update and install system/php/python/aws packages (see README.md for more)
RUN apt-get update
RUN apt-get install -yq \
	curl \
	git \
        groff \
        python \
        python-pip \
        jq \
	openssl \
	libmcrypt-dev \
	libssl-dev \
	libpng12-dev \
	zlib1g-dev \
	libjpeg-dev \
	vim

# Install AWS cli/s3cmd
RUN pip install awscli s3cmd

# Install mongo client
RUN apt-get install -yq mongodb-org-shell
RUN echo "mongodb-org-shell hold" | dpkg --set-selections

# Clear apt-get cache
RUN rm -rf /var/lib/apt/lists/*

# Install the PHP extensions we need
RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr
RUN docker-php-ext-install gd opcache zip mcrypt mbstring

# Install PHP pecl mongo
COPY bin/* /usr/local/bin/
RUN docker-php-pecl-install mongo

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set recommended PHP.ini settings
# See https://secure.php.net/manual/en/opcache.installation.php
RUN { \
	echo 'opcache.memory_consumption=128'; \
	echo 'opcache.interned_strings_buffer=8'; \
	echo 'opcache.max_accelerated_files=4000'; \
	echo 'opcache.revalidate_freq=60'; \
	echo 'opcache.fast_shutdown=1'; \
	echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini


# Setup apache and SSL
COPY apache2.conf /etc/apache2/apache2.conf
RUN rm /etc/apache2/sites-enabled/000-default.conf
COPY docker-entrypoint.sh /entrypoint.sh

# Download and install Learning Locker
# Upstream tarballs include ./learninglocker-v1.11.0/ so this gives us /var/www/html
RUN mkdir -p /var/www/html


WORKDIR /tmp

RUN curl -L -o learninglocker.tar.gz `curl -s https://api.github.com/repos/LearningLocker/learninglocker/releases/latest | jq --raw-output '.tarball_url'`\
	&& tar -xzf learninglocker.tar.gz -C /var/www/html --strip-components=1 \
	&& rm learninglocker.tar.gz \
	&& chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html
RUN composer install
RUN chown -R www-data:www-data /var/www/html
EXPOSE 80

# grr, ENTRYPOINT resets CMD now
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
