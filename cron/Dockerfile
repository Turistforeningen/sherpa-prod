FROM ubuntu:14.04

# Set the correct timezone so that cronjobs run when expected
RUN ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime

# Install docker and docker-compose
RUN apt-get -y update
RUN apt-get -y --no-install-recommends install cron wget git
RUN wget --no-check-certificate -qO- https://get.docker.com/ | sh
RUN wget -qO- https://github.com/docker/compose/releases/download/1.2.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose
RUN ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Work in the /cron directory
RUN mkdir /cron
WORKDIR /cron

# Clone sherpa-prod and add a read-only remote URL to the sherpa submodule
RUN git clone https://github.com/Turistforeningen/sherpa-prod.git /cron/sherpa-prod
RUN sed -i "s/git@github.com:Turistforeningen\/sherpa.git/https:\/\/github.com\/Turistforeningen\/sherpa.git/g" /cron/sherpa-prod/.gitmodules
RUN cd /cron/sherpa-prod && git submodule update --init sherpa

# Add cron tools
COPY pull.sh /cron/pull.sh
COPY sha.sh /cron/sha.sh
COPY run-sherpa.sh /cron/run-sherpa.sh
RUN chmod +x /cron/pull.sh /cron/sha.sh /cron/run-sherpa.sh

# We have bigger plans for log aggregation, but for now, log all crontab output to this file
RUN touch /cron/logfile

# Install the crontab
COPY crontab /cron/crontab
RUN cat /cron/crontab | crontab && rm /cron/crontab
