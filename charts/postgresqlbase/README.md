# PostgreSQL Helm Chart
PostgreSQL is a powerful, open source object-relational database system. It has more than 15 years of active development and a proven architecture that has earned it a strong reputation for reliability, data integrity, and correctness.

## Introduction
This chart installs N number of [postgresql](http://postgresql.org) nodes on a [kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites
Kubernetes 1.4+ with Alpha APIs enabled(required for k8s petsets)
PV provisioner support in the underlying infrastructure

## Installing the Chart
To install the chart with the release name `foo-release`:

```bash
$ helm install postgresql --name foo-release
```

This command will deploy two postgres nodes on the kubernetes cluster with in the default configuration.
To test out the newly created postgres nodes, connect to a working postgres node by creating a postgres client:

```bash
$ kubectl run -it --rm --image postgres pg-client --restart=Never /bin/sh
```

You will be in a working shell on the client. Connect to a postgres node and create some sample data by running:

```bash
$ psql -h postgresdb-<0|1>.postgres -U postgres
$ CREATE TABLE demo_table0 (did integer, name varchar(40))
```

You should be able to execute the above commands successfully if the postgres nodes were created correctly.

## Uninstalling the Chart
To delete/uninstall the `foo-release` deployment:

```bash
$ helm delete foo-release
```

This command will remove all associated resources from the kubernetes cluster
## Configuration
The following tables lists the configurable parameters of the postgresql chart and their default values.

| Parameter                  | Description                        | Default                                                    |
| -----------------------    | ---------------------------------- | ---------------------------------------------------------- |
| `name`                 | Name of release.                 | Most recent release                                        |
| `namespace`        | Name for the namespace      | `default`                                                      |
| `imagePullPolicy`                | Container image pull policy.    | `ifNotPresent`                                                      |
| `image.postgres.imageName`            | Postgres image name.         | `postgres`                                                      |
| `image.postgres.imageTag`            | Postgres image tag.   | `9.4`                                                      |
| `conatiner.ports.postgres.containerPort`      | Postgres container port.      | 5432                                                       |
| `replicas`         | Number of postgres nodes to run    | 2                                                      |
| `resources.cpu` | Container CPUs to use.    | 100m                                                    |
| `resources.memory`   | Memory size of container.          | 512Mi                                              |
| `resources.persistence.storageClass` | Persistence storage class    | generic                                                    |
| `resources.persistence.accessModes` | Persistence access modes(list)    | ReadWriteOnce                                                    |
| `resources.persistence.size` | Size of persistent volume claim    | 100Gi                                                    |
| `credentials.masterPassword` | Postgres master password    | ardberg                                                    |
| `credentials.userPassword` | Postgres user password    | lagavulin                                                    |
