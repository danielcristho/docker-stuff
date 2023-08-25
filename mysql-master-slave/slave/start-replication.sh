#!/bin/bash

# Reference: https://github.com/thomasvs/mysql-replication-start/blob/master/mysql-replication-start.sh

usage() { echo "Usage: $0 -u REPLICA_USER -p REPLICA_PASS -m MASTER_HOST" 1>&2; exit 1; }

# Default values
ROOT_USER=root
ROOT_PASS=M54if0IhQgc1

REPLICA_USER=$ROOT_USER
REPLICA_PASS=$ROOT_PASS

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

##
# Start MySQL Replication
##

echo "Starting MySQL Replication..."

# Wait until the master server is reachable
while ! mysqladmin ping -h $MASTER_HOST --silent; do
	sleep 1
done

echo "Connected to Master: $MASTER_HOST"

# Create a dump of the master's databases
echo "Dumping master databases to $DUMP_FILE"
mysqldump -u $ROOT_USER -p$ROOT_PASS -h $MASTER_HOST --all-databases --master-data --single-transaction --flush-logs --events > $DUMP_FILE

# Stop the slave on the target host (if it's running)
echo "Stopping slave on the target host..."
mysql -u $ROOT_USER -p$ROOT_PASS -e "STOP SLAVE;" || true

# Import the master dump into the target host
echo "Importing master dump into the target host..."
mysql -u $ROOT_USER -p$ROOT_PASS < $DUMP_FILE

# Get the master log file and position
echo "Getting master log file and position..."
log_file=$(mysql -u $ROOT_USER -p$ROOT_PASS -h $MASTER_HOST -e "SHOW MASTER STATUS\G" | awk '/File:/{print $2}')
pos=$(mysql -u $ROOT_USER -p$ROOT_PASS -h $MASTER_HOST -e "SHOW MASTER STATUS\G" | awk '/Position:/{print $2}')

# Set up the slave on the target host
echo "Setting up the slave on the target host..."
mysql -u $ROOT_USER -p$ROOT_PASS -e "RESET SLAVE;"
mysql -u $ROOT_USER -p$ROOT_PASS -e "CHANGE MASTER TO MASTER_HOST='$MASTER_HOST', MASTER_USER='$REPLICA_USER', MASTER_PASSWORD='$REPLICA_PASS', MASTER_LOG_FILE='$log_file', MASTER_LOG_POS=$pos;"

# Start the slave on the target host
echo "Starting the slave on the target host..."
mysql -u $ROOT_USER -p$ROOT_PASS -e "START SLAVE;"

# Check if replication started successfully
slave_status=$(mysql -u $ROOT_USER -p$ROOT_PASS -e "SHOW SLAVE STATUS\G")
if echo "$slave_status" | grep -q "Slave_IO_Running: Yes" && echo "$slave_status" | grep -q "Slave_SQL_Running: Yes"; then
    echo "Replication started successfully."
else
    echo "Error starting replication. Check slave status for more details:"
    echo "$slave_status"
fi