FROM python:3

# Set the correct timezone so that cronjobs run when expected
RUN ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime

# Install cron, aws cli
RUN apt-get -y update
RUN apt-get -y --no-install-recommends install cron
RUN pip install awscli

# Set up app dir
RUN mkdir /app
WORKDIR /app

# Copy secrets to be sourced (note that cron doesn't inherit env)
COPY secrets/aws-credentials.env /app/

# Install crontab
COPY crontab /app/
RUN cat /app/crontab | crontab && rm /app/crontab

# Install s3-sync app
RUN touch /app/s3-sync.log
COPY s3-sync.sh /app/
