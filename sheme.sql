-- Бытовуха

-- Волонтёры(FK(идентификатор карточки), контактный телефон)  CHECK (card_id > 1e6)
CREATE TABLE Volunteer(
  card_id INT PRIMARY KEY, 
  phone TEXT UNIUQE,
  CHECK (card_id > 1e6)
);

-- Спортсмены(имя, пол, рост, вес, возраст, PK(идентификатор карточки), FK(id объекта))
CREATE TABLE Sportsman(
  name TEXT, 
  gender TEXT, 
  height INT, 
  age INT, 
  card_id INT PRIMARY KEY,
  volunteer_id INT FOREIGN KEY REFERENCES Volunteer(card_id),
  CHECK (card_id <= 1e6)
);

-- Руководитель(имя, PK(контактный телефон))
CREATE TABLE Leader(
  name TEXT, 
  phone TEXT PRIMARY KEY
);

-- Делегация(PK(страна), FK(контактный телефон руководителя), FK(id объекта))
CREATE TABLE DELEGATION(
  country TEXT PRIMARY KEY,
  leader_phone TEXT FOREIGN KEY REFERENCES Leader(leader_phone),
  building_id INT FOREIGN KEY REFERENCES Building(building_id)
);

-- Объекты(PK(id), FK(id адреса), предназначение, собственное имя)
CREATE TABLE Building(
  id SERIAL PRIMARY KEY, 
  address_id INT FOREIGN KEY REFERENCES Address(id), 
  purpose_id INT FOREIGN KEY REFERENCES Purpose(id),
  name TEXT
);

-- Предназначения(PK(id), предназначение)
CREATE TABLE Purpose(
  id INT PRIMARY KEY,
  purpose TEXT UNIQUE
);

-- Адрес(PK(id), улица, номер дома)
CREATE TABLE Address(
  id SERIAL PRIMARY KEY,
  street TEXT,
  house INT
);

-- Виды спорта(PK(id), название спорта)
CREATE TABLE Sports(
  id INT PRIMARY KEY,
  name TEXT UNIQUE
);

-- Соревнования(PK(id), вид спорта, дата-время, FK(id объекта))
CREATE TABLE Competitions (
  id INT PRIMARY KEY,
  sport_id INT FOREIGN KEY REFERENCES Sports(id),
  competition_date DATETIME,
  building_id FOREIGN KEY REFERENCES Building(id),
  UNIQUE (competition_date, building_id)
);

-- Участники(PK(FK(id спортсмена), FK(id соревнования)), занятое место)
CREATE TABLE Participant(
  sportsman_id INT FOREIGN KEY REFERENCES Sportsman(card_id),
  competition_id INT FOREIGN KEY REFERENCES Competitions(id),
  place TEXT NOT NULL,
  PRIMARY KEY (sportsman_id, competition_id)
);

-- Задания(PK(id), FK(id карточнки волонётра), дата-время, описание)
CREATE TABLE Task (
  id INT PRIMARY KEY,
  volunteer_id INT FOREIGN KEY REFERENCES Volunteer(id),
  task_date DATETIME,
  transport_id TEXT NULL,
  task_description TEXT,
  FOREIGN KEY (transport_id) REFERENCES Transport(reg_n),
  UNIQUE (task_date, transport_id)
);

-- Транспорт(PK(регистрационный номер), вместимость)
CREATE TABLE Transport(
  reg_n TEXT PRIMARY KEY,
  capacity INT,
  CHECK (capacity > 0)
);

-- -- Задание_транспорт(PK(FK(регистрационный номер), FK(id задания))) ?? время 
-- CREATE TABLE TaskTransport(
--   reg_number TEXT FOREIGN KEY REFERENCES Transport(reg_number),
--   task_id INT FOREIGN KEY REFERENCES Task(id)
-- )