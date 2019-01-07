# VERSION 1.0 (apache-superset version:0.29.rc4)
# AUTHOR: Abhishek Sharma<abhioncbr@yahoo.com>
# DESCRIPTION: docker apache superset container
# BUILD: docker build --rm -t docker-apache-superset:0.28.1 -f docker-files/DockerFile .
# Modified/revamped version of the https://github.com/apache/incubator-superset/blob/master/contrib/docker/Dockerfile

FROM python:3.6
MAINTAINER Abhishek Sharma <abhioncbr@yahoo.com>

# Build argument[version of apache-superset to be build: pass value while building image]
ARG SUPERSET_VERSION

ENV SUPERSET_HOME=/home/superset/
ENV SUPERSET_DOWNLOAD_URL=https://github.com/apache/incubator-superset/archive/$SUPERSET_VERSION.tar.gz

# Add a normal superset group & user
# Change group & user id as per your requirement.
RUN groupadd -g 5006 superset
RUN useradd --create-home --no-log-init --uid 5004 --gid 5006 --home ${SUPERSET_HOME} --shell /bin/bash superset

# Configure environment
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update -y
# Install dependencies to fix `curl https support error` and `elaying package configuration warning`
RUN apt-get install -y apt-transport-https apt-utils

# Install common useful packages
RUN apt-get install -y vim less curl netcat postgresql-client mysql-client redis-tools

#docker build was failing because of cryptography package failure wirl libssl-dev.
#instead of libssl-dev it is not set to `libssl1.0-dev`
RUN apt-get update -y && apt-get install -y build-essential libssl1.0-dev \
    libffi-dev python3-dev libsasl2-dev libldap2-dev libxi-dev

# Install nodejs for custom build
# https://github.com/apache/incubator-superset/blob/master/docs/installation.rst#making-your-own-build
# https://nodejs.org/en/download/package-manager/
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -; \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list; \
    apt-get update; \
    apt-get install -y yarn

WORKDIR $SUPERSET_HOME

# Download & install superset 0.29.rc4 version
RUN wget -O superset.tar.gz $SUPERSET_DOWNLOAD_URL
RUN tar -xzf superset.tar.gz -C $SUPERSET_HOME --strip-components=1 && rm superset.tar.gz

RUN mkdir -p /home/superset/.cache
RUN mkdir -p /home/superset/config
RUN pip install --upgrade setuptools pip
RUN pip install -r requirements.txt
RUN pip install -r requirements-dev.txt
RUN pip install -e .

COPY docker-files/database-dependencies.txt .
RUN pip install -r database-dependencies.txt

ENV PATH=${SUPERSET_HOME}/superset/bin:$PATH \
    PYTHONPATH=${SUPERSET_HOME}superset/:${SUPERSET_HOME}config/:$PYTHONPATH

# Install superset python packages
# RUN pip install --install-option="--prefix=$SUPERSET_HOME" superset==$SUPERSET_VERSION

COPY script/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat

# copy superset_condfig.py file
COPY config/superset_config.py ${SUPERSET_HOME}config/

RUN chown -R superset:superset $SUPERSET_HOME

USER superset

RUN cd superset/assets && yarn
RUN cd superset/assets && npm run build

HEALTHCHECK CMD ["curl", "-f", "http://localhost:8088/health"]
ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 8088 5555

