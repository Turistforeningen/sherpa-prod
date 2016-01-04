# Sherpa Database Containers

## Dependency Tree

```
postgres:9.3
`-- mdillon/postgis:9.3
    `-- turistforeningen/sherpa-postgres:latest
        `-- turistforeningen/sherpa-postgres-psql:latest
```

## Update

Update `turistforeningen/sherpa-postgres` and
`turistforeningen/sherpa-postgres-psql` on Docker Hub with the following
command:

```
$ db/push.sh
```
