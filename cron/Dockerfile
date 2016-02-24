FROM python:3.5

# Set the correct timezone so that cronjobs run when expected
RUN ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime

# Requirements:
# - git: To pull down sherpa-prod and sherpa
# - docker-compose: To run commands in the deployed sherpa containers
# - raven-bash: To notify of errors in cronjobs
RUN apt-get -y update
RUN apt-get -y --no-install-recommends install cron wget git
RUN pip install docker-compose==1.6.2 raven-bash==0.1.1

# Work in the /cron directory
RUN mkdir /cron
WORKDIR /cron

# Clone sherpa-prod and the sherpa submodule
RUN git clone https://github.com/Turistforeningen/sherpa-prod.git /cron/sherpa-prod
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
