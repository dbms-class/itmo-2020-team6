-- Волонтёры(FK(идентификатор карточки), контактный телефон) 
-- Id карточек волонтеров начинаются с 1e6 + 1, чтобы не было коллизий с id карточек спортсменов
-- Волонтёр однозначно определяется номером телефона
CREATE TABLE Volunteer(
  card_id INT PRIMARY KEY, 
  phone TEXT UNIQUE,
  CHECK (card_id > 1e6)
);

-- Руководитель(имя, PK(контактный телефон))
-- Руководитель однозначно определяется по номеру телефона.
CREATE TABLE Leader(
  name TEXT, 
  phone TEXT PRIMARY KEY
);

-- Адрес(PK(id), улица, номер дома)
-- Адресс это просто название улицы и номер дома. На адресс ссылаться здание (Building).
CREATE TABLE Address(
  id SERIAL PRIMARY KEY,
  street TEXT,
  house INT
);

-- Предназначения(PK(id), предназначение)
-- Предназначение конкретного объекта на территории деревни
CREATE TABLE Purpose(
  id INT PRIMARY KEY,
  purpose TEXT UNIQUE
);

-- Объекты(PK(id), FK(id адреса), предназначение, собственное имя)
-- Подразумевается, что по одному адресу могут располагаться несколько объектов
CREATE TABLE Building(
  id SERIAL PRIMARY KEY, 
  address_id INT REFERENCES Address(id), 
  purpose_id INT REFERENCES Purpose(id),
  name TEXT
);

-- Спортсмены(имя, пол, рост, вес, возраст, PK(идентификатор карточки), FK(id объекта))
-- За каждым спортсменом закреплён волонтёр 
-- Карточки уникальны и однозначно определяют человека
-- Номера карточек спортсменов не превышают 1е6, чтобы не было пересечения с волонтёрами
-- Каждый спортсмен где-то живёт
CREATE TABLE Sportsman(
  name TEXT, 
  gender TEXT, 
  height INT, 
  age INT, 
  card_id INT PRIMARY KEY,
  volunteer_id INT REFERENCES Volunteer(card_id),
  building_id INT REFERENCES Building(id),
  CHECK (card_id <= 1e6)
);

-- Делегация(PK(страна), FK(контактный телефон руководителя), FK(id объекта))
-- Делегация имеет одного руководителя, который идентифицируется по номеру телефона
-- У каждой делегации есть один штаб в каком-то здании
CREATE TABLE DELEGATION(
  country TEXT PRIMARY KEY,
  leader_phone TEXT REFERENCES Leader(phone),
  building_id INT REFERENCES Building(id)
);

-- Виды спорта(PK(id), название спорта)
CREATE TABLE Sports(
  id INT PRIMARY KEY,
  name TEXT UNIQUE
);

-- Соревнования(PK(id), вид спорта, дата-время, FK(id объекта))
-- Соревнование по какому-либо виду спорта, проводимое в рамках олимпийских игр
-- В одно время в одном здании может проводиться только одно соревнование
CREATE TABLE Competition (
  id INT PRIMARY KEY,
  sport_id INT REFERENCES Sports(id),
  competition_date TIMESTAMP,
  building_id INT REFERENCES Building(id),
  UNIQUE (competition_date, building_id)
);

-- Участники(PK(FK(id спортсмена), FK(id соревнования)), занятое место)
-- Участники конкретного соревнования, с информацией о результатах выступления
CREATE TABLE Participant(
  sportsman_id INT REFERENCES Sportsman(card_id),
  competition_id INT REFERENCES Competition(id),
  place TEXT NOT NULL,
  PRIMARY KEY (sportsman_id, competition_id)
);

-- Транспорт(PK(регистрационный номер), вместимость)
-- Транспорт, предоставляемый для выполнения волонтёрского задания 
-- Однозначно определяется регистрационным номером
CREATE TABLE Transport(
  reg_n TEXT PRIMARY KEY,
  capacity INT,
  CHECK (capacity > 0)
);

-- Задания(PK(id), FK(id карточнки волонтёра), дата-время, описание)
-- За каждым заданием закреплён один волонтёр, у волонтёра может быть несколько заданий 
-- К заданию может быть прикреплено транспортное средство
-- Нельзя, чтобы в одно время к одному транспорту относилось несколько заданий 
CREATE TABLE Task (
  id INT PRIMARY KEY,
  volunteer_id INT REFERENCES Volunteer(card_id),
  task_date TIMESTAMP,
  transport_id TEXT NULL REFERENCES Transport(reg_n),
  task_description TEXT,
  UNIQUE (task_date, transport_id)
);
 