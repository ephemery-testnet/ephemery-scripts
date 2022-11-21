#!/bin/bash

setup_docker() {
  # install docker
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

setup_pgsql() {
  # setup database server
  echo "listen_addresses = '*'" >> /etc/postgresql/13/main/postgresql.conf
  echo "host all all 172.17.0.0/16 trust" >> /etc/postgresql/13/main/pg_hba.conf

  pg_ctlcluster 13 main start
  service postgresql restart
}

setup_pgsql_user() {
  # create credentials & database
  db_password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16 ; echo '')
  sudo -u postgres bash -c "cd ~ && createuser $1"
  sudo -u postgres bash -c "cd ~ && createdb $1 -O $1"
  echo "alter user $1 with password '$db_password'" | sudo -u postgres bash -c "cd ~ && psql $1"
  echo "$db_password" > $2
}
