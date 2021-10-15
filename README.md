# Mariadb, Python & Docker
### Docker
```
$ docker run -p 3306:3306 -d --name mariadatabase -e MARIADB_ROOT_PASSWORD=DBdemo123_ mariadb/server:10.4
# install mariadb-client and dependency
$ wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
$ echo "fc84b8954141ed3c59ac7a1adfc8051c93171bae7ba34d7f9aeecd3b148f1527 mariadb_repo_setup" \
    | sha256sum -c -
$ chmod +x mariadb_repo_setup
$ sudo apt-get update
$ sudo apt-get install mariadb-client
$ sudo apt-get install libmariadb3 libmariadb-dev
#try to connect
$ mariadb --host 127.0.0.1 -P 3306 --user root -pDBdemo123_
```
### Mariadb
```
> CREATE DATABASE data;
> CREATE TABLE data.people (name VARCHAR(50));
> INSERT INTO data.people VALUES ('Franklin'), ('Michael Santana'), ('Trevour');
> EXIT;
```
### Python
```
#db connection information
config = {
    'host': '127.0.0.1',
    'port': 3306,
    'user': 'root',
    'password': 'DBdemo123_',
    'database': 'data'
}
```

