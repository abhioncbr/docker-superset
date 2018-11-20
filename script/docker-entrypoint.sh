#!/usr/bin/env bash

# VERSION 1.0 (apache-superset version:0.29.rc4)
# AUTHOR: Abhishek Sharma<abhioncbr@yahoo.com>
# DESCRIPTION: apache superset docker container entrypoint file
# Modified/Revamped version of the https://github.com/apache/incubator-superset/blob/master/contrib/docker/docker-init.sh

set -eo pipefail

# common function to check if string is null or empty
is_empty_string () {
   PARAM=$1
   local output=true
   if [ ! -z "$PARAM" -a "$PARAM" != " " ]; then
      local output=false
      echo here
   fi
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

        echo apache-superset is initialized. Happy superset exploration!
    else
        echo apache-superset is already initialized.
    fi
}

# start of the script
if is_empty_string $SUPERSET_ENV; then
    args=("$@")
    SUPERSET_ENV=${args[0]}
    if is_empty_string $SUPERSET_ENV; then
        NODE_TYPE=${args[1]}
        DB_URL==${args[2]}
        REDIS_URL==${args[3]}
    fi
fi

# initializing the superset[should only be run for the first time of environment setup.]
initialize_superset

if [ "$SUPERSET_ENV" == "local" ]; then
    # Start superset worker for SQL Lab
    celery worker --app=superset.sql_lab:celery_app --pool=gevent -Ofair -n worker1 &
    celery flower --app=superset.sql_lab:celery_app &

    # Start the dev web server
    flask run -p 8088 --with-threads --reload --debugger --host=0.0.0.0
elif [ "$SUPERSET_ENV" == "prod" ]; then
    # Start superset worker for SQL Lab
    celery worker --app=superset.sql_lab:celery_app --pool=gevent -Ofair -nworker1 &
    celery worker --app=superset.sql_lab:celery_app --pool=gevent -Ofair -nworker2 &
    celery flower --app=superset.sql_lab:celery_app &

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
    superset --help
fi