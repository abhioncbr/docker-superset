# docker-superset
This is a repository for building [Docker](https://www.docker.com/) container of [Apache Superset]((https://superset.incubator.apache.org/tutorial.html)).

[<img src="https://cloud.githubusercontent.com/assets/130878/20946612/49a8a25c-bbc0-11e6-8314-10bef902af51.png" alt="Superset" width="500"/>](https://superset.incubator.apache.org/tutorial.html)

[![CircleCI](https://circleci.com/gh/abhioncbr/docker-superset/tree/master.svg?style=svg)](https://circleci.com/gh/abhioncbr/docker-superset/tree/master)

* For understanding & knowing more about Superset, please follow [Official website]((https://superset.incubator.apache.org/tutorial.html)) and [![Join the chat at https://gitter.im/airbnb/superset](https://badges.gitter.im/apache/incubator-superset.svg)](https://gitter.im/airbnb/superset?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
* Similarly, for Docker follow [curated list of resources](https://github.com/veggiemonk/awesome-docker).

## Superset components stack
- Enhanced/Modified version of the docker container of [apache-superset](https://github.com/apache/incubator-superset/tree/master/contrib/docker).
- Superset version: Notation for representing version `X.YY.ZZzzz` which means either [0.29.rc4] or [0.28.0]
- Backend database: mysql
- SqlLabs query async mode: Celery
- Task queue & query cache: Redis

## Superset ports
- superset portal port: 8088
- superset celery flower: 5555

## How to run
* General commands -
    * first pull a docker-superset image from [docker-hub](https://hub.docker.com/r/abhioncbr/docker-superset/)
        ```shell
        docker pull abhioncbr/docker-superset:<tag>
        ```
        
    * starting a superset image as a `superset` container in a local mode using `docker-compose`:
        ```shell
        cd docker-files/ && SUPERSET_ENV=local docker-compose up -d
        ```
        
    * starting a superset image as a `superset` container in a prod mode using `docker-compose`:
        ```shell
        cd docker-files/ && SUPERSET_ENV=prod docker-compose up -d
        ```
