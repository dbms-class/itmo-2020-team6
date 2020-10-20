-- Бытовуха

-- Волонтёры(FK(идентификатор карточки), контактный телефон)  CHECK (card_id > 1e6)
CREATE TABLE Volunteer(
  card_id INT PRIMARY KEY, 
  phone TEXT UNIQUE,
  CHECK (card_id > 1e6)
);

-- Спортсмены(имя, пол, рост, вес, возраст, PK(идентификатор карточки), FK(id объекта))
CREATE TABLE Sportsman(
  name TEXT, 
  gender TEXT, 
  height INT, 
  age INT, 
  card_id INT PRIMARY KEY,
  volunteer_id INT REFERENCES Volunteer(card_id),
  CHECK (card_id <= 1e6)
);

-- Руководитель(имя, PK(контактный телефон))
CREATE TABLE Leader(
  name TEXT, 
  phone TEXT PRIMARY KEY
);

-- Адрес(PK(id), улица, номер дома)
CREATE TABLE Address(
  id SERIAL PRIMARY KEY,
  street TEXT,
  house INT
);

-- Предназначения(PK(id), предназначение)
CREATE TABLE Purpose(
  id INT PRIMARY KEY,
  purpose TEXT UNIQUE
);

-- Объекты(PK(id), FK(id адреса), предназначение, собственное имя)
CREATE TABLE Building(
  id SERIAL PRIMARY KEY, 
  address_id INT REFERENCES Address(id), 
  purpose_id INT REFERENCES Purpose(id),
  name TEXT
);

-- Делегация(PK(страна), FK(контактный телефон руководителя), FK(id объекта))
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
CREATE TABLE Competition (
  id INT PRIMARY KEY,
  sport_id INT REFERENCES Sports(id),
  competition_date TIMESTAMP,
  building_id INT REFERENCES Building(id),
  UNIQUE (competition_date, building_id)
);

-- Участники(PK(FK(id спортсмена), FK(id соревнования)), занятое место)
CREATE TABLE Participant(
  sportsman_id INT REFERENCES Sportsman(card_id),
  competition_id INT REFERENCES Competition(id),
  place TEXT NOT NULL,
  PRIMARY KEY (sportsman_id, competition_id)
);

-- Транспорт(PK(регистрационный номер), вместимость)
CREATE TABLE Transport(
  reg_n TEXT PRIMARY KEY,
  capacity INT,
  CHECK (capacity > 0)
);

-- Задания(PK(id), FK(id карточнки волонётра), дата-время, описание)
CREATE TABLE Task (
  id INT PRIMARY KEY,
  volunteer_id INT REFERENCES Volunteer(card_id),
  task_date TIMESTAMP,
  transport_id TEXT NULL REFERENCES Transport(reg_n),
  task_description TEXT,
  UNIQUE (task_date, transport_id)
);

-- -- Задание_транспорт(PK(FK(регистрационный номер), FK(id задания))) ?? время 
-- CREATE TABLE TaskTransport(
--   reg_number TEXT REFERENCES Transport(reg_number),
--   task_id INT REFERENCES Task(id)
-- )