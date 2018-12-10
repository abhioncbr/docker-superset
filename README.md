# docker-superset
Repository for building [Docker](https://www.docker.com/) container of [Apache Superset](https://superset.incubator.apache.org/tutorial.html).

[<img src="https://cloud.githubusercontent.com/assets/130878/20946612/49a8a25c-bbc0-11e6-8314-10bef902af51.png" alt="Superset" width="500"/>](https://superset.incubator.apache.org/tutorial.html)

[![CircleCI](https://circleci.com/gh/abhioncbr/docker-superset/tree/master.svg?style=svg)](https://circleci.com/gh/abhioncbr/docker-superset/tree/master)

* For understanding & knowing more about Superset, please follow [Official website]((https://superset.incubator.apache.org/tutorial.html)) and [![Join the chat at https://gitter.im/airbnb/superset](https://badges.gitter.im/apache/incubator-superset.svg)](https://gitter.im/airbnb/superset?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
* Similarly, for Docker follow [curated list of resources](https://github.com/veggiemonk/awesome-docker).

## Superset components stack
- Enhanced/Modified version of the docker container of [apache-superset](https://github.com/apache/incubator-superset/tree/master/contrib/docker).
- Superset version: Notation for representing version `X.YY.ZZzzz` which means either [0.29.0rc4] or [0.28.1] or [0.28.0]
- Backend database: MySQL
- SqlLabs query async mode: Celery
- Task queue & query cache: Redis
- BigQuery and Hive packages are installed.

## Superset ports
- superset portal port: 8088
- superset celery flower: 5555

## Silent features of the docker image
- multiple ways to start a container, i.e. either by using `docker-compose` or by using `docker run` command.
- superset all components, i.e. web application, celery worker, celery flower UI can run in the same container or different containers.
- container first run sets required database along with examples and the Fabmanager user account with credentials `username: admin & password: admin`.
- superset config file i.e [superset_config.py](config/superset_config.py) should be mounted to the container. No need to rebuild image for changing configurations. 
- the default configuration uses MySQL as database and Redis as a cache & celery broker.
- starting container using `docker-compose` will start three containers. `mysql5.7` as the database, `redis3.4` as a cache & celery broker and superset container.
    * expects multiple environment variables defined in [docker-compose.yml](docker-files/docker-compose.yml) file. Among them, `SUPERSET_ENV` should be provided while starting the container.
    * permissible value of `SUPERSET_ENV` can be either `local` or `prod`.
    * in `local` mode one celery worker and superset flask-based superset web application run.
    * in `prod` mode two celery workers and Gunicorn based superset web application run.
 - starting container using `docker run` can be a used for complete distributed setup, requires database & Redis URL for startup.
    * single or multiple server(using load balancer) container can be spawned. In the server, Gunicorn based superset web application runs. 
    * multiple celery workers container running on same or different machines. In worker, celery worker & flower UI runs. 

## How to build the image
   * [DockerFile](docker-files/Dockerfile) uses `superset-version` as a `build-arg`, for example: `0.28.0` or `0.29.0rc4`
   * build image using `docker build` command
        ```shell
        docker build -t abhioncbr/docker-superset:<version-tag> --build-arg SUPERSET_VERSION=<superset-version> -f ~/docker-superset/docker-files/Dockerfile .
        ```
## How to run
* General commands -
    * first pull a docker-superset image from [docker-hub](https://hub.docker.com/r/abhioncbr/docker-superset/)
        ```shell
        docker pull abhioncbr/docker-superset:<tag>
        ```
        
    * starting a superset image as a `superset` container in a local mode using `docker-compose`:
        ```shell
        cd docker-files/ && SUPERSET_ENV=local SUPERSET_VERSION=<version-tag> docker-compose up -d
        ```
        
    * starting a superset image as a `superset` container in a prod mode using `docker-compose`:
        ```shell
        cd docker-files/ && SUPERSET_ENV=prod SUPERSET_VERSION=<version-tag> docker-compose up -d
        ```

    * starting a superset image as a `server` container using `docker run`:
        ```shell
        docker run -p 8088:8088 -v config:/home/superset/config/ abhioncbr/docker-superset:<tag> cluster server <db_url> <redis_url>
        ```        
    * starting a superset image as a `worker` container using `docker run`:
        ```shell
        docker run -p 5555:5555 -v config:/home/superset/config/ abhioncbr/docker-superset:<tag> cluster worker <db_url> 
        <redis_url>
        ```    
       
    [<img src="docker-superset_execution.png" alt="Superset">](docker-superset_execution.png)   
         
## Distributed execution of superset
* As mentioned above, docker image of superset can be leveraged to run in complete distributed run
    * load-balancer in front for routing the request from the client to one server container.
    * multiple docker-superset container in `server` mode for serving the UI of the superset.
    * multiple docker-superset containers in `worker` mode for executing the SQL queries in an async mode using celery executor.
    * centralised Redis container or Redis-cluster for serving as cache layer and celery task queues for workers.
    * centralised superset metadata database.
* Image below depicts the docker-superset distributed platform:
    [<img src="distributed-superset-setup.png" alt="Distributed-Superset">](distributed-superset-setup.png)   
