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
    def volunteer_load(self, volunteer_id=None, sportsman_count=-1, total_task_count=-1):
        with create_connection(self.args) as db:
            cur = db.cursor()

            volunteer_filter = f"V.card_id = {volunteer_id}" if volunteer_id is not None else ""

            query = f"""
            SELECT  V.card_id,
                    V.name,
                    COALESCE(R.sportsman_count, 0),
                    COALESCE(R.total_task_count, 0),
                    R.next_task_id,
                    R.next_task_time::TEXT
            FROM Volunteer V LEFT JOIN
            (
                SELECT  COALESCE(S.id, T.id)            id,
                        COALESCE(S.sportsman_count, 0)  sportsman_count,
                        COALESCE(T.total_task_count, 0) total_task_count,
                        T.next_task_id                  next_task_id,
                        T.next_task_time                next_task_time
                FROM
                (
                    SELECT  volunteer_id    id,
                            COUNT(*)        sportsman_count
                    FROM Sportsman
                    GROUP BY volunteer_id
                ) S
                FULL JOIN
                (
                    SELECT  T2.volunteer_id      id,
                            T2.total_task_count  total_task_count,
                            T2.next_task_time    next_task_time,
                            T1.id                next_task_id
                    FROM Task T1
                    JOIN
                    (
                        SELECT  volunteer_id,
                                COUNT(*)        total_task_count,
                                MIN(task_date)  next_task_time
                        FROM Task
                        WHERE task_date >= now()
                        GROUP BY volunteer_id
                    ) T2
                    ON  T1.volunteer_id = T2.volunteer_id AND
                        T2.next_task_time = T1.task_date
                ) T
                ON S.id = T.id
            ) R
            ON V.card_id = R.id
            WHERE   COALESCE(R.sportsman_count, 0) >= {sportsman_count} AND
                    COALESCE(R.total_task_count, 0) >= {total_task_count}
                    {volunteer_filter}
            ;
            """

            cur.execute(query)
            volunteers = cur.fetchall()
            return [{"volunteer_id": v[0],
                     "volunteer_name": v[1],
                     "sportsman_count": v[2],
                     "total_task_count": v[3],
                     "next_task_id": v[4],
                     "next_task_time": v[5]}
                    for v in volunteers]

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def volunteer_unassigned(self, volunteer_id, task_ids):
        # TODO
        # 1. convert tuples for sql
        # 2. *
        # 3. volunteer's name

        with create_connection(self.args) as db:
            cur = db.cursor()

            tasks = tuple(map(int, task_ids.split(',')))

            query_volunteers = f'''WITH (SELECT delegation_id
                                        FROM Sportsman
                                        WHERE volunteer_id = {volunteer_id}) as PD
                                SELECT DISTINCT volunteer_id
                                FROM Sportsman
                                WHERE delegation_id IN PD;'''

            cur.execute(query_volunteers)
            possible_volunteers = cur.fetchall()

            query_sorted_tasks = f'''SELECT id, task_date
                                     FROM Task
                                     WHERE id IN {str(tasks)}
                                     ORDER BY task_date;'''

            cur.execute(query_sorted_tasks)
            sorted_tasks = cur.fetchall()

            volunteer_assigners = []

            for task_id, task_date in sorted_tasks:
                query_possible_changers = f'''
                SELECT volunteer_id
                FROM Volunteers
                WHERE volunteer_id IN {str(possible_volunteers)}
                    AND NOT EXISTS (SELECT task_date
                                    FROM Task
                                    WHERE task_date BETWEEN {task_date} - interval '1 hour'
                                                        AND {task_date} + interval '1 hour'
                                            AND Task.volunteer_id = Volunteers.volunteer_id);'''

                cur.execute(query_possible_changers)
                possible_changers = cur.fetchall()

                query_sort_by_task_count = f'''
                SELECT volunteer_id, COUNT(*) as cnt
                FROM Task
                WHERE vounteer_id IN {str(possible_changers)}
                      AND task_date > {task_date}
                GROUP BY volunteer_id
                ORDER BY cnt;'''

                cur.execute(query_sort_by_task_count)
                possible_changers = cur.fetchall()

                if possible_changers:
                    assigner = possible_changers[0][0]

                    query_update = f'''
                    UPDATE Task
                    SET volunteer_id = {assigner}
                    WHERE id = {task_id};'''

                    cur.execute(query_update)

                    volunteer_assigners.append({'task_id': task_id, 'new_volunteer_name': None, 'new_volnteer_id': assigner})

        return volunteer_assigners


cherrypy.config.update({
    'server.socket_host': '0.0.0.0',
    'server.socket_port': 8080,
})
cherrypy.quickstart(App(parse_cmd_line()))
