# vim:set ft=dockerfile:
FROM debian:jessie

ARG KEYSERVER_ADDR=ha.pool.sks-keyservers.net
ARG ARTIFACTORY_IP=10.40.232.52

# explicitly set user/group IDs
RUN groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver $KEYSERVER_ADDR --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y --auto-remove ca-certificates wget

# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8


RUN set -ex; \
# pub   4096R/ACCC4CF8 2011-10-13 [expires: 2019-07-02]
#       Key fingerprint = B97B 0AFC AA1A 47F0 44F2  44A0 7FCC 7D46 ACCC 4CF8
# uid                  PostgreSQL Debian Repository
	key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver $KEYSERVER_ADDR --recv-keys "$key"; \
	gpg --export "$key" > /etc/apt/trusted.gpg.d/postgres.gpg; \
	rm -r "$GNUPGHOME"; \
	apt-key list

ENV PG_MAJOR 9.5

RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update \
	&& apt-get install -y postgresql-common \
	&& sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
	&& apt-get install -y \
		postgresql-$PG_MAJOR \
		postgresql-contrib-$PG_MAJOR \
	&& rm -rf /var/lib/apt/lists/*

# make the sample config easier to munge (and "correct by default")
RUN mv -v /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample /usr/share/postgresql/ \
	&& ln -sv ../postgresql.conf.sample /usr/share/postgresql/$PG_MAJOR/ \
	&& sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample

RUN mkdir -p /var/run/postgresql \
	&& chown -R postgres /var/run/postgresql

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV PGDATA /var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

### Installing pg_amqp dependencies
RUN apt-get -y update \
	&& apt-get -y install git postgresql-server-dev-$PG_MAJOR make gcc
WORKDIR /tmp
RUN git clone https://github.com/omniti-labs/pg_amqp.git
WORKDIR /tmp/pg_amqp
RUN make \
	&& make install \
	&& make clean
WORKDIR /
###

### Installing PostGIS dependencies
ENV POSTGIS_MAJOR 2.3

RUN apt-get update \
      && apt-get install -y --no-install-recommends \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
           postgis \
					 wget \
					 ssh \
					 rsync \
      && rm -rf /var/lib/apt/lists/*


### apt-get cleanup
RUN apt-get purge -y --auto-remove git make gcc postgresql-server-dev-$PG_MAJOR
###

### Symlink PostGIS dependencies
RUN ln -s /usr/lib/postgresql/$PG_MAJOR/lib/postgis-$POSTGIS_MAJOR.so /usr/lib/postgresql/$PG_MAJOR/lib/postgis-2.0.so \
	&& ln -s /usr/lib/postgresql/$PG_MAJOR/lib/rtpostgis-$POSTGIS_MAJOR.so /usr/lib/postgresql/$PG_MAJOR/lib/rtpostgis-2.0.so \
	&& ln -s /usr/lib/postgresql/$PG_MAJOR/lib/postgis_topology-$POSTGIS_MAJOR.so /usr/lib/postgresql/$PG_MAJOR/lib/postgis_topology-2.0.so
###


RUN rm -rf /var/lib/apt/lists/*

RUN export TERM=xterm

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5432
CMD ["run"]
