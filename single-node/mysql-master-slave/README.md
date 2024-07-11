# MySQL Master Slave Using Docker

## How to use

```bash
git clone https://github.com/danielcristho/docker-stuff.git && cd docker-stuff
```

```bash
cd single-node/mysql-master-slave
```

Create new environment file.

```bash
cp .env.example .env
```

Change the values as you want. Example:

```sh
MYSQL_DATABASE=docker_db
MYSQL_USER=docker_user
MYSQL_PASSWORD=docker_pass
MYSQL_ALLOW_EMPTY_PASSWORD=1
```

Run the `.sh` file.

```bash
bash run.sh
```

or

```bash
./run.sh
```

Make sure the containers is up. Then accessing the master and slave.

```bash
docker exec -it mysql_master mysql -u docker_user -pdocker_pass
```

```bash
docker exec -it mysql_slave mysql -u docker_user -pdocker_pass
```

Try to create new table, create new database or others modification to make sure the replication is running.
