#!/bin/bash
set -e

PGDATA="${PGDATA:-/var/lib/postgresql/data/pgdata}"
POSTGRES_INITDB_ARGS="${POSTGRES_INITDB_ARGS:-}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-$POSTGRES_USER}"
POSTGRES_TYPE="${POSTGRES_TYPE:-standalone}"
REPLICATION_USER="${REPLICATION_USER:-postgres}"
REPLICATION_MASTER="${REPLICATION_MASTER:-localhost}"
REPLICATION_PASSWORD="${REPLICATION_PASSWORD:-replication}"

export PGPASSWORD="$REPLICATION_PASSWORD"
if [ "$1" = 'init' ]; then
  echo "Creating PGDATA directory and permissions"
  mkdir -p "$PGDATA" \
    && chmod 700 "$PGDATA" \
    && chown -R postgres "$PGDATA"

  mkdir -p /run/postgresql \
    && chmod g+s /run/postgresql \
    && chown -R postgres /run/postgresql


  # look specifically for PG_VERSION, as it is expected in the DB dir
  if [ ! -s "$PGDATA/PG_VERSION" ]; then
    eval "gosu postgres initdb $POSTGRES_INITDB_ARGS"

    # check password first so we can output the warning before postgres
    # messes it up
    if [ "$POSTGRES_PASSWORD" ]; then
      pass="PASSWORD '$POSTGRES_PASSWORD'"
      authMethod=md5
    else
      echo "WARNING: No password has been set for the database. Set POSTGRES_PASSWORD"
      pass=
      authMethod=trust
    fi

    # internal start of server in order to allow set-up using psql-client
    # does not listen on external TCP/IP and waits until start finishes
    gosu postgres pg_ctl -D "$PGDATA" \
      -o "-c listen_addresses='localhost'" \
      -w start

    if [ "$POSTGRES_DB" != 'postgres' ]; then
      psql -v ON_ERROR_STOP=1 -U postgres -c "CREATE DATABASE $POSTGRES_DB ;"
    fi

    if [ "$POSTGRES_USER" = 'postgres' ]; then
      op='ALTER'
    else
      op='CREATE'
    fi
    psql -v ON_ERROR_STOP=1 -U postgres -c "$op USER \"$POSTGRES_USER\" WITH SUPERUSER $pass ;"

 psql -v ON_ERROR_STOP=1 -U postgres -c "CREATE USER admin WITH SUPERUSER LOGIN PASSWORD 'admin' ;"
    psql -v ON_ERROR_STOP=1 -U postgres -c "CREATE DATABASE template_postgis;"

    psql -v ON_ERROR_STOP=1 -U postgres -c "UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';"

    psql -v ON_ERROR_STOP=1 -U postgres -d template_postgis -c "CREATE EXTENSION IF NOT EXISTS postgis;"
    psql -v ON_ERROR_STOP=1 -U postgres -d template_postgis -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;"
    psql -v ON_ERROR_STOP=1 -U postgres -d template_postgis -c "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;"
    psql -v ON_ERROR_STOP=1 -U postgres -d template_postgis -c "CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;"
    psql -v ON_ERROR_STOP=1 -U postgres -d template_postgis -c "CREATE EXTENSION IF NOT EXISTS amqp;"

    psql -v ON_ERROR_STOP=1 -U postgres -d postgres -c "CREATE ROLE $REPLICATION_USER REPLICATION LOGIN PASSWORD '$REPLICATION_PASSWORD';"


    gosu postgres pg_ctl -D "$PGDATA" -m fast -w stop
  fi

  if [ "$POSTGRES_TYPE" == "replica" ]; then
    if [ ! -s "$PGDATA/backup_label" ] && [ ! -s "$PGDATA/backup_label.old" ]; then
      echo "WARNING: Backup data not found, beginning pg_basebackup"

      # backup data directroy, create new empty one, set appropriate owner and permissions
      mv /var/lib/postgresql/data/pgdata /var/lib/postgresql/data/pgdata_old \
        && mkdir /var/lib/postgresql/data/pgdata \
        && chown postgres:postgres /var/lib/postgresql/data/pgdata \
        && chmod 700 /var/lib/postgresql/data/pgdata

      gosu postgres pg_basebackup --checkpoint=fast \
        -h "$REPLICATION_MASTER" \
        -U "$REPLICATION_USER" \
        -D "$PGDATA" \
        -vP \
        --xlog-method=stream \
        -w
    fi
  fi

elif [ "$1" = 'run' ]; then

  # echo "Copying SSH key and permissions"
  mkdir /root/.ssh \
    && cp /opt/ssh-secret/ssh-privatekey /root/.ssh/ \
    && chmod 600 /root/.ssh/ssh-privatekey

  # set appropriate owner and permissions for the configMap directory
  chmod 600 /opt/pgdata/* \
    && chown postgres:postgres /opt/pgdata/*

  # copy our templated config values from config map into the PGDATA
  rm $PGDATA/postgresql.conf \
    && rm $PGDATA/pg_hba.conf \
    && cp -p /opt/pgdata/*.conf "$PGDATA"


  echo 'Starting postgres'
  gosu postgres pg_ctl -D "$PGDATA" \
      -o "-c listen_addresses='*'" \
      -w start

  # keep pod alive and allow for interactive service stop/start/restart following config changes
  tail -f /dev/null
fi
