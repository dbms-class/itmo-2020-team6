# encoding: UTF-8

# Веб сервер
import cherrypy

from connect import parse_cmd_line
from connect import create_connection
from static import index


@cherrypy.expose
class App(object):
    def __init__(self, args):
        self.args = args

    @cherrypy.expose
    def start(self):
        return "Hello web app"

    @cherrypy.expose
    def index(self):
        return index()

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def register(self, sportsman, country, volunteer_id):
        with create_connection(self.args) as db:
            cur = db.cursor()
            if sportsman.isnumeric():
                cur.execute(f"UPDATE Sportsman SET delegation_id = '{country}', "
                            f"volunteer_id = {volunteer_id} "
                            f"WHERE card_id = {sportsman};")
            else:
                cur.execute(f"INSERT INTO Sportsman (name, volunteer_id, delegation_id) "
                            f"VALUES ('{sportsman}', {volunteer_id}, '{country}');")

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def countries(self):
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute("SELECT country FROM Delegation")
            countries = cur.fetchall()
            return [{"id": i + 1, "name": c[0]}
                    for i, c in enumerate(countries)]

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def volunteers(self):
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute("SELECT card_id, name FROM Volunteer")
            volunteers = cur.fetchall()
            return [{"id": v[0], "name": v[1]}
                    for v in volunteers]

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def volunteer_load(self, volunteer_id=None, sportsman_count=0, total_task_count=0):
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute("SELECT V.card_id, V.name, COALESCE(S.sportsman_count, 0) "
                        "FROM Volunteer V LEFT JOIN (SELECT volunteer_id, COUNT(*) sportsman_count FROM Sportsman GROUP BY volunteer_id) S "
                        "ON V.card_id = S.volunteer_id"
                        "WHERE S.sportsman_count >= {sportsman_count};")
            volunteers = cur.fetchall()
            return [{"volunteer_id": v[0],
                     "volunteer_name": v[1],
                     "sportsman_count": v[2],
                     "total_task_count": v[3],
                     "next_task_id": v[4],
                     "next_task_time": v[5]}
                    for v in volunteers]


cherrypy.config.update({
    'server.socket_host': '0.0.0.0',
    'server.socket_port': 8080,
})
cherrypy.quickstart(App(parse_cmd_line()))
