FROM python:2.7

# Install docker and docker-compose
RUN apt-get -y update
RUN apt-get -y --no-install-recommends install cron wget git
RUN wget --no-check-certificate -qO- https://get.docker.com/ | sh
RUN wget -qO- https://github.com/docker/compose/releases/download/1.2.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose
RUN ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Work in the /backups directory
RUN mkdir /backups
WORKDIR /backups

# Set up codebase
COPY backups.py /backups/
COPY requirements.txt /backups/
COPY private-data/* /backups/
RUN chmod +x /backups/backups.py
RUN pip install -r /backups/requirements.txt
RUN touch /backups/backups.log

# Install the crontab
COPY crontab /backups/
RUN cat /backups/crontab | crontab && rm /backups/crontab
