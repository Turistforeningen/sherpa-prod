# Sherpa Production Setup

Production ready server setup for
[Sherpa](https://github.com/Turistforeningen/sherpa) – the django-based website
and CMS for the Norwegian Trekking Association (DNT).

![Container Overview](https://docs.google.com/drawings/d/1AglhUIGSYvYIivBPUaTNT7oO_Elh1rVmU8LIP4h6LnI/pub?w=754&h=212 "Container Overview")

## Stack

* [Docker](https://github.com/docker/docker) >= 1.6
* [Docker Compose](https://github.com/docker/compose) >= 1.2
* [HAProxy](https://registry.hub.docker.com/_/haproxy/) >= 1.5
* [Postgres](https://registry.hub.docker.com/_/postgres/) >= 9.1

## Structure

```
.
|-- db
|   |-- Dockerfile
|   `-- docker-compose.yml
|-- deploy.sh
|-- haproxy
|   |-- Dockerfile
|   `-- rebuild.sh
`-- sherpa
    |-- logs.sh
    `-- sherpa
        |-- Dockerfile
        `-- docker-compose.yml
```

## Deploy

### Soft

```
$ ./deploy.sh soft
```

### Hard

```
$ ./deploy.sh hard
```

## [MIT License](https://github.com/Turistforeningen/sherpa-prod/blob/master/LICENSE)
