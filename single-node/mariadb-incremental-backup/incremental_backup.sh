#!/bin/bash

eval $(awk 'BEGIN { FS="=" } !/^#/ && NF==2 { gsub(/"/, "\\\"", $2); print "export " $1 "=\"" $2 "\"" }' .env)

docker-compose down -v
docker-compose up --build -d

DB_HOST=10.0.2.10

while ! mysqladmin ping -h $DB_HOST --silent; do
	sleep 1
done

echo "Connected to Database: $DB_HOST"

# Grant privileges
priv_stmt="GRANT ALL ON *.* TO '$MARIADB_USER'@'%'; FLUSH PRIVILEGES;"

docker exec mariadb_incremental sh -c "mysql -u root -e \"$priv_stmt\""

# Do full backup
full_backup="mariabackup --backup --target-dir=/var/mariadb/backup/ --user=$MARIADB_USER --password=$MARIADB_PASSWORD"

docker exec mariadb_incremental sh -c "$full_backup"

# # Do incremental backup
# mariabackup --backup \
#     --target-dir=/var/mariadb/inc1/ \
#     --incremental-basedir=/var/mariadb/backup/ \
#     --user=$MARIADB_USER --password=$MARIADB_PASSWORD


