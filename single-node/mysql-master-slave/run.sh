#!/bin/bash

# Reference: https://github.com/thomasvs/mysql-replication-start/blob/master/mysql-replication-start.sh

# Load environment variables
source .env

usage() { echo "Usage: $0 -u REPLICA_USER -p REPLICA_PASS -m MASTER_HOST" 1>&2; exit 1; }

# Default values
MYSQL_USER=$MYSQL_USER
MYSQL_PASS=$MYSQL_PASSWORD

REPLICA_USER=$MYSQL_USER
REPLICA_PASS=$MYSQL_PASSWORD

MASTER_HOST=10.0.1.10

DUMP_FILE="/tmp/master_dump.sql"

# Override through options
while getopts ":u:p:m:" o; do
    case "${o}" in
        u)
            REPLICA_USER=${OPTARG}
            ;;
        p)
            REPLICA_PASS=${OPTARG}
            ;;
        m)
            MASTER_HOST=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# Check if mandatory options are provided
if [[ -z $REPLICA_USER || -z $REPLICA_PASS || -z $MASTER_HOST ]]; then
    usage
fi

# Cleanup old data and restart Docker containers
rm -rf ./master/data/*
rm -rf ./slave/data/*

docker-compose down -v
docker-compose up --build -d

until docker exec mysql-master sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql-master database connection..."
    sleep 4
done

# Create replica user and grant privileges
priv_stmt="CREATE USER '$REPLICA_USER'@'%' IDENTIFIED BY '$REPLICA_PASS'; GRANT REPLICATION SLAVE ON *.* TO '$REPLICA_USER'@'%'; FLUSH PRIVILEGES;"
docker exec mysql-master sh -c "export MYSQL_PWD=111; mysql -u root -e \"$priv_stmt\""

# Start MySQL Replication
echo "Starting MySQL Replication..."

# Create a dump of the master's databases
echo "Dumping master databases to $DUMP_FILE"
mysqldump -u $MYSQL_USER -p$MYSQL_PASS -h $MASTER_HOST --all-databases --master-data --single-transaction --flush-logs --events > $DUMP_FILE

# Stop the slave on the target host (if it's running)
echo "Stopping slave on the target host..."
mysql -u $MYSQL_USER -p$MYSQL_PASS -e "STOP SLAVE;" || true

# Import the master dump into the target host
echo "Importing master dump into the target host..."
mysql -u $MYSQL_USER -p$MYSQL_PASS < $DUMP_FILE

# Get the master log file and position
echo "Getting master log file and position..."
log_file=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -h $MASTER_HOST -e "SHOW MASTER STATUS\G" | awk '/File:/{print $2}')
pos=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -h $MASTER_HOST -e "SHOW MASTER STATUS\G" | awk '/Position:/{print $2}')

# Set up the slave on the target host
echo "Setting up the slave on the target host..."
mysql -u $MYSQL_USER -p$MYSQL_PASS -e "RESET SLAVE;"
mysql -u $MYSQL_USER -p$MYSQL_PASS -e "CHANGE MASTER TO MASTER_HOST='$MASTER_HOST', MASTER_USER='$REPLICA_USER', MASTER_PASSWORD='$REPLICA_PASS', MASTER_LOG_FILE='$log_file', MASTER_LOG_POS=$pos;"

# Start the slave on the target host
echo "Starting the slave on the target host..."
mysql -u $MYSQL_USER -p$MYSQL_PASS -e "START SLAVE;"

# Check if replication started successfully
slave_status=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -e "SHOW SLAVE STATUS\G")
if echo "$slave_status" | grep -q "Slave_IO_Running: Yes" && echo "$slave_status" | grep -q "Slave_SQL_Running: Yes"; then
    echo "Replication started successfully."
else
    echo "Error starting replication. Check slave status for more details:"
    echo "$slave_status"
fi