FROM turistforeningen/sherpa-postgres:latest

# Install AWS cli
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    xz-utils \
    python-pip \
  && pip install -U awscli

# Copy import db script
COPY import.sh /import.sh
RUN chmod a+x /import.sh

# Copy psql shell script
COPY shell.sh /shell.sh
RUN chmod a+x /shell.sh
