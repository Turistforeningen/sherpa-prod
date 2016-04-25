FROM python:3.5

# Install dependencies
RUN apt-get -y update
RUN apt-get -y --no-install-recommends install cron wget git
RUN wget -qO- https://get.docker.com/builds/`uname -s`/`uname -m`/docker-1.9.1 > /usr/local/bin/docker
RUN chmod +x /usr/local/bin/docker

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
