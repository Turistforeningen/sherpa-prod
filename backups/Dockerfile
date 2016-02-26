FROM python:2.7

# Install docker and docker-compose
RUN apt-get -y update
RUN apt-get -y --no-install-recommends install cron wget git
RUN wget -qO- https://get.docker.com/builds/`uname -s`/`uname -m`/docker-1.9.1 > /usr/local/bin/docker
RUN wget -qO- https://github.com/docker/compose/releases/download/1.2.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker*
RUN ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
RUN ln -s /usr/local/bin/python /usr/bin/python

# Work in the /backups directory
RUN mkdir /backups
WORKDIR /backups

# Set up codebase
RUN touch /backups/backups.log
COPY requirements.txt /backups/
RUN pip install -r /backups/requirements.txt
COPY backups.py /backups/
RUN chmod +x /backups/backups.py
COPY secrets/settings.py /backups/

# Install the crontab
COPY crontab /backups/
RUN cat /backups/crontab | crontab && rm /backups/crontab
