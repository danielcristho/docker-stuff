import flask
import json
import mariadb

app = flask.Flask(__name__)
app.config["DEBUG"] = True

# DB configuration
config = {
    'host': '127.0.0.1',
    'port': 3306,
    'user': 'root',
    'password': 'DBdemo123_',
    'database': 'data'
}

@app.route('/api/people', methods=['GET'])
def index():
   #  create connection TO MariaDB
   conn = mariadb.connect(**config)
   # create a connection cursor
   cur = conn.cursor()
   # execute a SQL statement
   cur.execute("select * from people")

   # serialize results into JSON
   row_headers=[x[0] for x in cur.description]
   rv = cur.fetchall()
   json_data=[]
   for result in rv:
        json_data.append(dict(zip(row_headers,
                                  result)))
   # return the results!
   return json.dumps(json_data)

app.run()