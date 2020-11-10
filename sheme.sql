-- Волонтёры(FK(идентификатор карточки), контактный телефон) 
-- Id карточек волонтеров начинаются с 1e6 + 1, чтобы не было коллизий с id карточек спортсменов
-- Волонтёр однозначно определяется номером телефона
CREATE TABLE Volunteer(
  card_id INT PRIMARY KEY CHECK (card_id > 1e6), 
  phone TEXT NOT NULL UNIQUE
);

-- Руководитель(имя, PK(контактный телефон))
-- Руководитель однозначно определяется по номеру телефона.
CREATE TABLE Leader(
  name TEXT NOT NULL, 
  phone TEXT PRIMARY KEY
);

-- Адрес(PK(id), улица, номер дома)
-- Адресс это просто название улицы и номер дома. На адресс ссылаться здание (Building).
CREATE TABLE Address(
  id SERIAL PRIMARY KEY,
  street TEXT NOT NULL,
  house INT NOT NULL CHECK (house > 0)
);

-- Предназначения(PK(id), предназначение)
-- Предназначение конкретного объекта на территории деревни
CREATE TABLE Purpose(
  id INT PRIMARY KEY,
  purpose TEXT NOT NULL UNIQUE
);

-- Объекты(PK(id), FK(id адреса), предназначение, собственное имя)
-- Подразумевается, что по одному адресу могут располагаться несколько объектов
CREATE TABLE Building(
  id SERIAL PRIMARY KEY, 
  address_id INT NOT NULL REFERENCES Address(id), 
  purpose_id INT NOT NULL REFERENCES Purpose(id),
  name TEXT 
);

-- Виды спорта(PK(id), название спорта)
CREATE TABLE Sports(
  id INT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

-- Ассоциация объектов с видами спорта
CREATE TABLE Building_Sport(
  sport_id INT REFERENCES Sports(id),
  building_id INT REFERENCES Building(id),
  PRIMARY KEY (sport_id, building_id)
);

-- Делегация(PK(страна), FK(контактный телефон руководителя), FK(id объекта))
-- Делегация имеет одного руководителя, который идентифицируется по номеру телефона
-- У каждой делегации есть один штаб в каком-то здании
CREATE TABLE Delegation(
  country TEXT PRIMARY KEY,
  leader_phone TEXT REFERENCES Leader(phone),
  building_id INT REFERENCES Building(id)
);

CREATE TYPE SEX as ENUM ('male', 'female', 'not stated');
-- Спортсмены(имя, пол, рост, вес, возраст, PK(идентификатор карточки), FK(id объекта))
-- За каждым спортсменом закреплён волонтёр 
-- Карточки уникальны и однозначно определяют человека
-- Номера карточек спортсменов не превышают 1е6, чтобы не было пересечения с волонтёрами
-- Каждый спортсмен где-то живёт
CREATE TABLE Sportsman(
  name TEXT NOT NULL, 
  sex SEX NOT NULL DEFAULT 'not stated', 
  height INT NOT NULL CHECK (height > 0), 
  weight INT NOT NULL CHECK (weight > 0),
  age INT NOT NULL CHECK (age > 0), 
  card_id INT PRIMARY KEY CHECK (card_id <= 1e6),
  volunteer_id INT REFERENCES Volunteer(card_id),
  building_id INT REFERENCES Building(id),
  delegation_id TEXT REFERENCES Delegation(country)
);

-- Ассоциация спортсменов с видами спорта
-- CREATE TABLE Sportsman_Sport(
--   sport_id INT REFERENCES Sports(id),
--   sportsman_id INT REFERENCES Sportsman(card_id),
--   PRIMARY KEY (sport_id, sportsman_id)
-- );

-- Соревнования(PK(id), вид спорта, дата-время, FK(id объекта))
-- Соревнование по какому-либо виду спорта, проводимое в рамках олимпийских игр
-- В одно время в одном здании может проводиться только одно соревнование
CREATE TABLE Competition (
  id INT PRIMARY KEY,
  sport_id INT NOT NULL,
  competition_date TIMESTAMP NOT NULL,
  building_id INT NOT NULL,
  FOREIGN KEY (sport_id, building_id) REFERENCES Building_Sport(sport_id, building_id)
);

-- Участники(PK(FK(id спортсмена), FK(id соревнования)), занятое место)
-- Участники конкретного соревнования, с информацией о результатах выступления
CREATE TABLE Participant(
  sportsman_id INT REFERENCES Sportsman(card_id),
  competition_id INT REFERENCES Competition(id),
  place INT NOT NULL CHECK (place >= 0),
  PRIMARY KEY (sportsman_id, competition_id)
);

-- Транспорт(PK(регистрационный номер), вместимость)
-- Транспорт, предоставляемый для выполнения волонтёрского задания 
-- Однозначно определяется регистрационным номером
CREATE TABLE Transport(
  reg_n TEXT PRIMARY KEY,
  capacity INT NOT NULL CHECK (capacity > 0)
);

-- Задания(PK(id), FK(id карточнки волонтёра), дата-время, описание)
-- За каждым заданием закреплён один волонтёр, у волонтёра может быть несколько заданий 
-- К заданию может быть прикреплено транспортное средство
-- Нельзя, чтобы в одно время к одному транспорту относилось несколько заданий 
CREATE TABLE Task (
  id INT PRIMARY KEY,
  volunteer_id INT NOT NULL REFERENCES Volunteer(card_id),
  task_date TIMESTAMP NOT NULL,
  transport_id TEXT NULL REFERENCES Transport(reg_n),
  task_description TEXT,
  UNIQUE (task_date, transport_id)
);
 