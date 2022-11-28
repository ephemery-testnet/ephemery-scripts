FROM debian:latest
RUN apt update && apt --assume-yes install curl wget jq

ENV DOCKER_VERSION='20.10.14'

RUN set -ex \
    && DOCKER_FILENAME=https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
    && curl -L ${DOCKER_FILENAME} | tar -C /usr/bin/ -xzf - --strip-components 1 docker/docker
COPY ./retention_docker.sh /opt/scripts/retention.sh  
RUN ls /opt/scripts
ENTRYPOINT [ "/opt/scripts/retention.sh" ] 
