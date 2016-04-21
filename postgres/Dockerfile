FROM mdillon/postgis:9.3

# Add locale
RUN localedef -i nb_NO -c -f UTF-8 -A /usr/share/locale/locale.alias nb_NO.UTF-8
ENV LANG nb_NO.utf8

# Copy export db script
COPY export.sh /export.sh
RUN chmod a+x /export.sh
