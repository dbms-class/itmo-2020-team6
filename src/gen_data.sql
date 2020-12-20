-- ===============
INSERT INTO Sports(id, name) VALUES
    (1, 'Литрбол'),
    (2, 'Гандбол'),
    (3, 'Футбол'),
    (4, 'Теннис'),
    (5, 'ACM ICPC'),
    (6, 'Боди-арт'),
    (7, 'Hot Dog Eating'),
    (8, 'Метание карликов'),
    (9, 'Лыжные гонки'),
    (10, 'Триатлон'),
    (11, 'Фристайл (горнолыжка)'),
    (12, 'Фристайл (рэп)');


-- ===============
INSERT INTO Volunteer(card_id, name, phone)
select generate_series(1e6+1, 1e6+9),
    unnest(
        ARRAY [
            'John',
            'Paul',
            'Lebovski',
            'Mishel',
            'Ringo',
            'Sasha',
            'Kurt',
            'Brodski',
            'Courtney'
        ]),
    unnest(
        ARRAY [
            '0000',
            '0001',
            '0010',
            '0011',
            '0100',
            '0101',
            '0110',
            '0111',
            '1000'
        ]
    );

INSERT INTO Leader(name, phone) VALUES
    ('Edgar', '8-800-3353530'),
    ('Basis', '1456'),
    ('Anton', '6456'),
    ('Misha', '1427'),
    ('Merlin', '1556'),
    ('Artur', '1426');    


INSERT INTO Address(id, street, house) VALUES
    (1, 'Вёсельная', 93),
    (2, 'Карташихина', 13),
    (3, 'Наличная', 27),
    (4, 'Большой проспект Васильевского острова', 56),
    (5, '16-я В.О.линия', 11),
    (6, '15-я В.О. линия', 60),
    (7, 'Беринга', 27),
    (8, 'пр. Римского-Корсакова', 107),
    (9, 'Садовая', 94);

INSERT INTO Purpose(purpose) VALUES
    ('Рюмочная'),
    ('Бардель'),
    ('Лес (спорт-зал)'),
    ('Поляна (стадион)'),
    ('Озеро (местный каток)'),
    ('Колодец (местный бассейн)'),
    ('Лавочка'),
    ('Турнички');

WITH 
    BuildingNames AS (
        SELECT unnest(ARRAY [
            'ЖК Акисон',
            'ЖК Олимпийский',
            'Многофункциональный Спортивный Комплекс им. В.И. Алексеева',
            'Спорткомплекс "Политехник',
            'Спортивный Комплекс Газпром',
            'СПб ГАУ Дирекция по управлению спортивными сооружениями',
            'Центр физической культуры, спорта и здоровья Василеостровского района',
            'Динамит',
            'ФОК Газпром-Ветеранов'
        ]) as name
    )
insert into Building(address_id, purpose_id, name)
select (1 + ((select Count(*) from Address) - 1) * random()) :: INT,
       (1 + ((select Count(*) from Purpose) - 1) * random()) :: INT,
       name from BuildingNames;

insert into Building_Sport(sport_id, building_id)
select distinct
       (1 + ((select Count(*) from Sports) - 1) * random()) :: INT,
       (1 + ((select Count(*) from Building) - 1) * random()) :: INT
from generate_series(1, 15);

insert into Delegation(country, leader_phone, building_id) VALUES
    ('Neverland', '1456', (1 + ((select Count(*) from Building) - 1) * random()) :: INT),
    ('Camelot',   '1556', (1 + ((select Count(*) from Building) - 1) * random()) :: INT),
    ('Lamdaland', '8-800-3353530', (1 + ((select Count(*) from Building) - 1) * random()) :: INT),
    ('China',     '1427', (1 + ((select Count(*) from Building) - 1) * random()) :: INT);

insert into Sportsman
    (name,       sex,          height, weight, age, card_id, volunteer_id, building_id, delegation_id) VALUES
    ('Ice Kate', 'not stated', 194,    39,     17,  1,       1000007,
    (1 + ((select Count(*) from Building) - 1) * random()) :: INT,
    'Neverland'),
    ('Zhe Sloboda','male',     185,    81,     22,  2,       1000004,
    (1 + ((select Count(*) from Building) - 1) * random()) :: INT,
    'Lamdaland'),
    ('Serega Sokol','male',    183,    78,     22,  3,       1000001,
    (1 + ((select Count(*) from Building) - 1) * random()) :: INT,
    'China'),
    ('Ars Tereza', 'male',     178,    65,     22,  4,       1000005,
    (1 + ((select Count(*) from Building) - 1) * random()) :: INT,
    'Camelot'),
    ('Dm Barash', 'not stated', 190,   80,     18,  5,       1000009,
    (1 + ((select Count(*) from Building) - 1) * random()) :: INT,
    'Camelot');


insert into Transport(reg_n, capacity) VALUES
   ('666', 34),
   ('228', 4),
   ('018', 2),
   ('621', 1),
   ('432', 10),
   ('123', 5);


insert into Task(volunteer_id, task_date, transport_id, task_description)
select 1000001 + ((((select Count(*) from Volunteer) - 2) * random()) :: INT),
       ('5051-01-01'::DATE + random()* 10 * 60 * INTERVAL '1 MINUTE')::TIMESTAMP,
       (unnest(ARRAY['666', '228', '018', '621', '432', '123'])),
       (unnest(ARRAY['побрить подмыхи', 'сделать массаж', 'сгонять за пивом', 'принести хавчик', 'погладить кота', 'перевезти']))
       from generate_series(1, 10);

insert into Task
    (volunteer_id, task_date, transport_id, task_description) VALUES
    (1000009,
     ('2020-10-10'::DATE + random()* 10 * 60 * INTERVAL '1 MINUTE')::TIMESTAMP,
     228,
     'сварить кофе');

insert into Competition (sport_id, competition_date, building_id)
select
    sport_id,
    ('5051-01-01'::DATE + random()* 100 * 60 * INTERVAL '1 MINUTE')::TIMESTAMP,
    building_id
    from Building_Sport;

insert into Participant(sportsman_id, competition_id, place)
select distinct
    unnest(ARRAY[1, 2, 3, 4]),
    (1 + ((select Count(*) from Competition) - 1) * random()) :: INT,
    unnest(ARRAY[1, 2, 3, 4])
    from generate_series(1, 15);
