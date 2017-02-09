### Learning Locker LRS Docker container
This is fork of [`hongymagic/learninglocker`](https://gitlab.com/hongymagic/learninglocker) the main modifications are around removing the inbuilt SSL support (so you can use it behind a LB) and also the mongoDB user setup

This is a HTTP **application-only** container for [Learning Locker](http://learninglocker.net).
As such, link to a running mongoDB container or external mongoDB host is required.

#### Example usage

1. Create a mongoDB instance (example using docker container). [`mongodb`](https://hub.docker.com/_/mongodb/)

	```
	docker run -d --name db -p 27017:27017 -p 28017:28017  mongodb
	```

2. Create learning locker instance:

	```
	docker run \
		-d \
		--name web \
		--link db:mongo \
		-p 80:80 \
		sproutlabs/learninglocker:latest
	```

	This will run Learning Locker web application using the above mongoDB instance.

#### Environment variables

> Users of this container are **strongly encourage** to change **all non-optional** environment variables when running this container.

##### Required
There are a number of defaults for these in `docker-compose.yml` as well
- `LEARNINGLOCKER_DB_USER`: If authentication is enabled on mongo, the user to use
- `LEARNINGLOCKER_DB_PASSWORD`: If authentication is enabled on mongo, the password to use
- `LEARNINGLOCKER_DB_NAME`: Name of the database to create for learning locker. Defaults to `learninglocker`
- `APP_URL`: FQDN of the final URL, if missing defaults to `$HOSTNAME`
- `APP_SECRET_KEY`: [Encryption key](http://docs.learninglocker.net/installation/#configuration) used by learning locker. Defaults to `CHANGEME12345678`
- `SMTP_SERVER`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `EMAIL_FROM_NAME`, `EMAIL_FROM_ADDRESS`: Self explanatory, see [configuration page](http://docs.learninglocker.net/installation/#configuration) for more details

##### Optional

- `LEARNINGLOCKER_DB_HOST`: (_optional_) If not linking to another docker container, hostname of the mongoDB server
- `MONGO_WAIT_TIMEOUT`: (_optional_) Time to wait before mongo container becomes live. Defaults to 10 seconds
