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

            volunteer_filter = f"AND R.volunteer_id = {volunteer_id}" if volunteer_id is not None else ""

            query = f"""
            SELECT  R.volunteer_id,
                    R.volunteer_name,
                    R.sportsman_count,
                    R.total_task_count,
                    Task.id next_task_id,
                    (R.next_task_time::TIMESTAMP(0))::TEXT
            FROM
            (
                SELECT  V.card_id volunteer_id,
                        V.name volunteer_name,
                        COUNT(DISTINCT S.card_id) sportsman_count,
                        COUNT(DISTINCT T.id) total_task_count,
                        MIN(T.task_date) next_task_time
                FROM Volunteer V 
                LEFT JOIN Sportsman S ON V.card_id = S.volunteer_id
                LEFT JOIN Task T ON V.card_id = T.volunteer_id
                WHERE T.task_date >= now()
                GROUP BY V.card_id
            ) R
            LEFT JOIN Task  ON R.volunteer_id = Task.volunteer_id 
                            AND R.next_task_time = Task.task_date
            WHERE   R.sportsman_count >= {sportsman_count} AND
                    R.total_task_count >= {total_task_count}
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
        with create_connection(self.args) as db:
            cur = db.cursor()

            if task_ids == '*':
                query_get_all_tasks = f'''
                SELECT id
                FROM Task
                WHERE volunteer_id = {volunteer_id};'''

                cur.execute(query_get_all_tasks)
                tasks = cur.fetchall()
                tasks = [str(item[0]) for item in tasks]
            else:
                tasks = task_ids.split(',')

            # Находим id волонтеров, которые прикреплены к спортсмену из тех же делегаций
            query_volunteers = f'''
            WITH PD as (SELECT delegation_id
                        FROM Sportsman
                        WHERE volunteer_id = {volunteer_id})
                SELECT DISTINCT volunteer_id
                FROM Sportsman
                WHERE delegation_id IN (SELECT * FROM PD) AND volunteer_id != {volunteer_id};'''

            cur.execute(query_volunteers)
            possible_volunteers = cur.fetchall()
            possible_volunteers = [str(item) for sublist in possible_volunteers for item in sublist]

            if not possible_volunteers:
                return []

            # Узнаем даты переданных заданий 
            query_sorted_tasks = f'''
            SELECT id, (task_date::TIMESTAMP(0))::TEXT
            FROM Task
            WHERE id IN ({','.join(tasks)})
            ORDER BY task_date;'''

            cur.execute(query_sorted_tasks)
            sorted_tasks = cur.fetchall()

            volunteer_assigners = []

            for task_id, task_date in sorted_tasks:
                # Достаем волонтеров, у которых нет задач в интервале +- час от текущего задания
                query_possible_changers = f'''
                SELECT card_id
                FROM Volunteer
                WHERE card_id IN ({','.join(possible_volunteers)})
                    AND NOT EXISTS (SELECT task_date
                                    FROM Task
                                    WHERE task_date BETWEEN \'{task_date}\'::DATE - interval '1 hour'
                                                        AND \'{task_date}\'::DATE + interval '1 hour'
                                            AND Task.volunteer_id = Volunteer.card_id);'''

                cur.execute(query_possible_changers)
                possible_changers = cur.fetchall()
                possible_changers = [str(item) for sublist in possible_changers for item in sublist]

                # Если никого не нашли, то оставляем задачу у прогульщика
                if not possible_changers:
                    continue

                # Сортируем волонтеров по количеству заданий
                query_sort_by_task_count = f'''
                SELECT v.card_id, v.name, COUNT(*) as cnt
                FROM Volunteer v LEFT JOIN Task t ON v.card_id = t.volunteer_id 
                WHERE v.card_id IN ({','.join(possible_changers)})
                      AND t.task_date > '{task_date}'::DATE OR t.task_date IS NULL
                GROUP BY v.card_id
                ORDER BY cnt;'''

                cur.execute(query_sort_by_task_count)
                possible_changers = cur.fetchall()

                if possible_changers:
                    assigner_id, assigner_name, _ = possible_changers[0]

                    # Для задания обновляем значение в таблице на сменщика
                    query_update = f'''
                    UPDATE Task
                    SET volunteer_id = {assigner_id}
                    WHERE id = {task_id};'''

                    cur.execute(query_update)

                    volunteer_assigners.append(
                        {'task_id': task_id, 'new_volunteer_name': assigner_name, 'new_volunteer_id': assigner_id})

        return volunteer_assigners


cherrypy.config.update({
    'server.socket_host': '0.0.0.0',
    'server.socket_port': 8080,
})
cherrypy.quickstart(App(parse_cmd_line()))
