#!/bin/bash

source .env

docker-compose down -v
rm -rf ./master/data/*
rm -rf ./slave/data/*
docker-compose up --build -d

MASTER_HOST=10.0.1.10
SLAVE_HOST=10.0.1.11

while ! mysqladmin ping -h $MASTER_HOST --silent; do
	sleep 1
done

echo "Connected to Master: $MASTER_HOST"

priv_stmt="CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD'; GRANT REPLICATION SLAVE ON *.* TO '$MYSQL_USER'@'%'; FLUSH PRIVILEGES;"
docker exec mysql_master sh -c "mysql -u root -e \"$priv_stmt\""

MS_STATUS=$(docker exec mysql_master sh -c 'mysql -u root -e "SHOW MASTER STATUS\G"')
CURRENT_LOG=$(echo "$MS_STATUS" | grep "File:" | awk '{print $2}')
CURRENT_POS=$(echo "$MS_STATUS" | grep "Position:" | awk '{print $2}')

while ! mysqladmin ping -h $SLAVE_HOST --silent; do
	sleep 1
done

echo "Connected to Slave: $SLAVE_HOST"

docker exec mysql_slave sh -c "mysql -u root -e 'STOP REPLICA'"

start_slave_stmt="CHANGE MASTER TO MASTER_HOST='$MASTER_HOST',MASTER_USER='$MYSQL_USER',MASTER_PASSWORD='$MYSQL_PASSWORD',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS,MASTER_CONNECT_RETRY=10; START SLAVE;"
docker exec mysql_slave sh -c "mysql -u root -e \"$start_slave_stmt\""

docker exec mysql_slave sh -c "mysql -u root -e 'SHOW SLAVE STATUS\G'"