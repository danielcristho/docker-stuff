# Reference from: https://github.com/vbabak/docker-mysql-master-slave/blob/master/build.sh

#!/bin/bash

if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo ".env file not found!"
    exit 1
fi

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

priv_stmt="GRANT REPLICATION SLAVE ON *.* TO '$MYSQL_USER'@'%'; FLUSH PRIVILEGES;"
docker exec mysql_master sh -c "mysql -u root -e \"$priv_stmt\""

MS_STATUS=$(docker exec mysql_master sh -c 'mysql -u root -e "SHOW MASTER STATUS\G"')
CURRENT_LOG=$(echo "$MS_STATUS" | grep "File:" | awk '{print $2}')
CURRENT_POS=$(echo "$MS_STATUS" | grep "Position:" | awk '{print $2}')
echo "Master status: $MS_STATUS"

while ! mysqladmin ping -h $SLAVE_HOST --silent; do
	sleep 1
done

echo "Connected to Slave: $SLAVE_HOST"

priv_stmt="GRANT REPLICATION SLAVE ON *.* TO '$MYSQL_USER'@'%'; FLUSH PRIVILEGES;"
docker exec mysql_slave sh -c "mysql -u root -e \"$priv_stmt\""

docker exec mysql_slave sh -c "mysql -u root -e 'STOP SLAVE;'"

start_slave_stmt="CHANGE MASTER TO MASTER_HOST='$MASTER_HOST',
	MASTER_USER='$MYSQL_USER',
	MASTER_PASSWORD='$MYSQL_PASSWORD',
	MASTER_LOG_FILE='$CURRENT_LOG',
	MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"

echo "Executing: $start_slave_stmt"
docker exec mysql_slave sh -c "mysql -u root --execute=\"$start_slave_stmt\""

docker exec mysql_slave sh -c "mysql -u root -e 'SHOW SLAVE STATUS\G'"
