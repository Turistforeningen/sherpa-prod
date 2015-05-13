FROM mdillon/postgis:9.3

RUN apt-get update
RUN apt-get install --assume-yes --no-install-recommends openssh-client

# Add locale
# RUN echo "nb_NO.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
RUN localedef -i nb_NO -c -f UTF-8 -A /usr/share/locale/locale.alias nb_NO.UTF-8
ENV LANG nb_NO.utf8

# Add import script
ADD import-prod.sh /import-prod.sh
RUN chmod a+x /import-prod.sh

# Add init script
ADD initdb-sherpa.sh /docker-entrypoint-initdb.d/sherpa.sh

