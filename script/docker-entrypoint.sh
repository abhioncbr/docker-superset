#!/usr/bin/env bash

# VERSION 1.0 (apache-superset version:0.29.rc4)
# AUTHOR: Abhishek Sharma<abhioncbr@yahoo.com>
# DESCRIPTION: apache superset docker container entrypoint file
# Modified/Revamped version of the https://github.com/apache/incubator-superset/blob/master/contrib/docker/docker-init.sh

set -eo pipefail

# Color Code -- ANSI notation
NC='\033[0m' # No Color
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'

#
help(){
  echo
  echo -e "###########################################################################################################################################################################"
  echo -e "##****************************************************************** ${RED}Apache-Superset Docker Container.${NC} ******************************************************************##"
  echo -e "##                                                                                                                                                                       ##"
  echo -e "##**************************************************************** ${BLUE}Container can be started in two ways.${NC} ****************************************************************##"
  echo -e "## 1) Using ${RED}'docker-compose'${NC}                                                                                                                                             ##"
  echo -e "## First download apache-superset docker image from docker-hub using command ${GREEN}'docker pull abhioncbr/docker-superset:<tag>'${NC}                                               ##"
  echo -e "## Start container using command ${GREEN}'cd docker-files/ && SUPERSET_ENV=<ENV> docker-compose up -d'${NC}, where ${BLUE}ENV${NC} can be ${GREEN}'prod'${NC} or ${GREEN}'local'${NC}                                       ##"
  echo -e "##                                                                                                                                                                       ##"
  echo -e "##***********************************************************************************************************************************************************************##"
  echo -e "## 1) Using ${RED}'docker run'${NC}                                                                                                                                                 ##"
  echo -e "## First download apache-superset docker image from docker-hub using command ${GREEN}'docker pull abhioncbr/docker-superset:<tag>'${NC}                                               ##"
  echo -e "## Start ${BLUE}'server'${NC} container using command ${GREEN}'docker run -p 8088:8088 -v config:/home/superset/config/ abhioncbr/docker-superset:<tag> cluster server <db_url> <redis_url>'${NC} ##"
  echo -e "## Start ${BLUE}'worker'${NC} container using command ${GREEN}'docker run -p 5555:5555 -v config:/home/superset/config/ abhioncbr/docker-superset:<tag> cluster worker <db_url> <redis_url>'${NC} ##"
  echo -e "###########################################################################################################################################################################"
  echo
}

# common function to check if string is null or empty
is_empty_string () {
   PARAM=$1
   output=true
   if [ ! -z "$PARAM" -a "$PARAM" != " " ]; then
      output=false
   fi
   echo $output
}

# function to initialize apache-superset
initialize_superset () {
    USER_COUNT=$(fabmanager list-users --app superset | awk '/email/ {print}' | wc -l)
    if [ "$?" ==  0 ] && [ $USER_COUNT == 0 ]; then
        # Create an admin user (you will be prompted to set username, first and last name before setting a password)
        fabmanager create-admin --app superset --username admin --firstname apache --lastname superset --email apache-superset@fab.com --password admin

        # Initialize the database
        superset db upgrade

        # Load some data to play with
        superset load_examples

        # Create default roles and permissions
        superset init

        echo Initialized Apache-Superset. Happy Superset Exploration!
    else
        echo Apache-Superset Already Initialized.
    fi
}

# start of the script
echo Environment Variable: SUPERSET_ENV: $SUPERSET_ENV
if $(is_empty_string $SUPERSET_ENV); then
    args=("$@")
    echo Provided Script Arguments: $@
    if [[ $# -eq 0 ]]; then
        SUPERSET_ENV="local"

        INVOCATION_TYPE="OTHER"
        export INVOCATION_TYPE=$INVOCATION_TYPE
        echo "export INVOCATION_TYPE="$INVOCATION_TYPE>>~/.bashrc
        echo "INVOCATION_TYPE="$INVOCATION_TYPE>>~/.profile
        echo Environment Variable Exported: INVOCATION_TYPE: $INVOCATION_TYPE
    elif [[ $# -eq 4 ]]; then
        SUPERSET_ENV=${args[0]}
        NODE_TYPE=${args[1]}

        DB_URL=${args[2]}
        export DB_URL=$DB_URL
        echo "export DB_URL="$DB_URL>>~/.bashrc
        echo "DB_URL="$DB_URL>>~/.profile
        echo Environment Variable Exported: DB_URL: $DB_URL

        REDIS_URL=${args[3]}
        export REDIS_URL=$REDIS_URL
        echo "export REDIS_URL="$REDIS_URL>>~/.bashrc
        echo "REDIS_URL="$REDIS_URL>>~/.profile
        echo Environment Variable Exported: REDIS_URL: $REDIS_URL

        INVOCATION_TYPE="RUN"
        export INVOCATION_TYPE=$INVOCATION_TYPE
        echo "export INVOCATION_TYPE="$INVOCATION_TYPE>>~/.bashrc
        echo "INVOCATION_TYPE="$INVOCATION_TYPE>>~/.profile
        echo Environment Variable Exported: INVOCATION_TYPE: $INVOCATION_TYPE
    else
        help
       exit -1
    fi
else
     INVOCATION_TYPE="COMPOSE"
     export INVOCATION_TYPE=$INVOCATION_TYPE
     echo "export INVOCATION_TYPE="$INVOCATION_TYPE>>~/.bashrc
     echo "INVOCATION_TYPE="$INVOCATION_TYPE>>~/.profile
     echo Environment Variable Exported: INVOCATION_TYPE: $INVOCATION_TYPE
fi

# initializing the superset[should only be run for the first time of environment setup.]
echo Starting Initialization[if needed]
initialize_superset

echo Container deployment type: $SUPERSET_ENV
if [ "$SUPERSET_ENV" == "local" ]; then
    # Start superset worker for SQL Lab
    celery worker --app=superset.sql_lab:celery_app --pool=gevent -Ofair -n worker1 &
    celery flower --app=superset.sql_lab:celery_app &
    echo Started Celery worker and Flower UI.

    # Start the dev web server
    FLASK_APP=superset:app flask run -p 8088 --with-threads --reload --debugger --host=0.0.0.0
elif [ "$SUPERSET_ENV" == "prod" ]; then
    # Start superset worker for SQL Lab
    celery worker --app=superset.sql_lab:celery_app --pool=gevent -Ofair -nworker1 &
    celery worker --app=superset.sql_lab:celery_app --pool=gevent -Ofair -nworker2 &
    celery flower --app=superset.sql_lab:celery_app &
    echo Started Celery workers[worker1, worker2] and Flower UI.

    # Start the prod web server
    gunicorn -w 10 -k gevent --timeout 120 -b  0.0.0.0:8088 --limit-request-line 0 --limit-request-field_size 0 superset:app
elif [ "$SUPERSET_ENV" == "cluster" ] && [ "$NODE_TYPE" == "worker" ]; then
    # Start superset worker for SQL Lab
    celery flower --app=superset.sql_lab:celery_app &
    celery worker --app=superset.sql_lab:celery_app --pool=gevent -Ofair
elif [ "$SUPERSET_ENV" == "cluster" ] && [ "$NODE_TYPE" == "server" ]; then
    # Start the prod web server
    gunicorn -w 10 -k gevent --timeout 120 -b  0.0.0.0:8088 --limit-request-line 0 --limit-request-field_size 0 superset:app
else
    help
    exit -1
fi