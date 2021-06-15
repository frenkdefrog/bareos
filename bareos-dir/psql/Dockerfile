FROM ubuntu:20.04
LABEL org.opencontainers.image.authors="lorinc.andras@samma.hu"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG="C"
WORKDIR /tmp

COPY bareos-database-common.conf /etc/dbconfig-common/bareos-database-common.conf
COPY config /etc/dbconfig-common/config

RUN rm -f /etc/localtime \
  && ln -s /usr/share/zoneinfo/Europe/Budapest /etc/localtime \
  && echo "Europe/Budapest" > /etc/timezone \
  && apt-get update \
  && apt-get -y dist-upgrade \
  && apt-get -y install language-pack-en language-pack-hu curl gnupg2\
  && curl http://download.bareos.org/bareos/release/20/xUbuntu_20.04/Release.key | apt-key add - \
  && echo "deb http://download.bareos.org/bareos/release/20/xUbuntu_20.04/ ./" > /etc/apt/sources.list.d/bareos.list \
  && apt-get update \
  && apt-get -y install --no-install-recommends bareos-director bareos-database-postgresql bareos-bconsole dbconfig-pgsql ssmtp \
  && rm -f /etc/bareos/.rndpwd \
  && rm -f /etc/bareos/bconsole.conf \
  && rm -rf /etc/bareos/bareos-dir.d/* \
  && apt-get -y purge curl \
  && apt-get --purge -y autoremove

COPY bareos-dir.sh /usr/local/sbin/

#  CMD ["/usr/local/sbin/bareos-dir.sh"]
