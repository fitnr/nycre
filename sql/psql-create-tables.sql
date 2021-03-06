CREATE TABLE borough (
  id INTEGER,
  name varchar(9) DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE building_class_category (
  id varchar(3) DEFAULT '',
  name varchar(64),
  PRIMARY KEY (id)
);

CREATE TABLE building_class (
  id varchar(3) DEFAULT '',
  name varchar(64),
  PRIMARY KEY (id)
);

CREATE TABLE tax_class (
  id varchar(3) DEFAULT '',
  name varchar(64),
  PRIMARY KEY (id)
);

INSERT INTO borough (id, name)
VALUES
    (1,'Manhattan'),
    (2,'Bronx'),
    (3,'Brooklyn'),
    (4,'Queens'),
    (5,'Richmond');

INSERT INTO building_class_category (id, name)
VALUES
    ('01','ONE FAMILY HOMES'),
    ('02','TWO FAMILY HOMES'),
    ('03','THREE FAMILY HOMES'),
    ('04','TAX CLASS 1 CONDOS'),
    ('05','TAX CLASS 1 VACANT LAND'),
    ('06','TAX CLASS 1 - OTHER'),
    ('07','RENTALS - WALKUP APARTMENTS'),
    ('08','RENTALS - ELEVATOR APARTMENTS'),
    ('09','COOPS - WALKUP APARTMENTS'),
    ('10','COOPS - ELEVATOR APARTMENTS'),
    ('11','SPECIAL CONDO BILLING LOTS'),
    ('11A','CONDO-RENTALS'),
    ('12','CONDOS - WALKUP APARTMENTS'),
    ('13','CONDOS - ELEVATOR APARTMENTS'),
    ('14','RENTALS - 4-10 UNIT'),
    ('15','CONDOS - 2-10 UNIT RESIDENTIAL'),
    ('16','CONDOS - 2-10 UNIT WITH COMMERCIAL UNIT'),
    ('17','CONDO COOPS'),
    ('18','TAX CLASS 3 - UTILITY PROPERTIES'),
    ('21','OFFICE BUILDINGS'),
    ('22','STORE BUILDINGS'),
    ('23','LOFT BUILDINGS'),
    ('24','TAX CLASS 4 - UTILITY BUREAU PROPERTIES'),
    ('25','LUXURY HOTELS'),
    ('26','OTHER HOTELS'),
    ('27','FACTORIES'),
    ('28','COMMERCIAL CONDOS'),
    ('29','COMMERCIAL GARAGES'),
    ('30','WAREHOUSES'),
    ('31','COMMERCIAL VACANT LAND'),
    ('32','HOSPITAL AND HEALTH FACILITIES'),
    ('33','EDUCATIONAL FACILITIES'),
    ('34','THEATRES'),
    ('35','INDOOR PUBLIC AND CULTURAL FACILITIES'),
    ('36','OUTDOOR RECREATIONAL FACILITIES'),
    ('37','RELIGIOUS FACILITIES'),
    ('38','ASYLUMS AND HOMES'),
    ('39', 'TRANSPORTATION FACILITIES'),
    ('40','SELECTED GOVERNMENTAL FACILITIES'),
    ('41','TAX CLASS 4 - OTHER'),
    ('42','CONDO CULTURAL/MEDICAL/EDUCATIONAL/ETC'),
    ('43','CONDO OFFICE BUILDINGS'),
    ('44','CONDO PARKING'),
    ('45','CONDO HOTELS'),
    ('46','CONDO STORE BUILDINGS'),
    ('47','CONDO NON-BUSINESS STORAGE'),
    ('48','CONDO TERRACES/GARDENS/CABANAS'),
    ('49','CONDO WAREHOUSES/FACTORY/INDUS');

INSERT INTO tax_class (id, name)
VALUES
    (1,'residential up to 3 units, condos under three stories'),
    ('2A','residential rental, 4-6 units'),
    ('2B','residential rental, 7-10 units'),
    ('2C','residential condo or coop, 2-10 units'),
    (2,'residential, 11 units or more'),
    (3,'utility'),
    (4,'commercial or industrial');

-- Not dropping the sales table because you might have stuff if it!
CREATE TABLE IF NOT EXISTS sales (
  bbl BIGINT DEFAULT NULL,
  borough INTEGER DEFAULT NULL REFERENCES borough(id),
  block integer DEFAULT NULL,
  lot integer DEFAULT NULL,
  date date DEFAULT NULL,
  address varchar(256) DEFAULT NULL,
  apt varchar(128) DEFAULT NULL,
  zip varchar(5) DEFAULT NULL,
  neighborhood varchar(64) DEFAULT NULL,
  buildingclasscat varchar(3) DEFAULT NULL REFERENCES building_class_category(id),
  buildingclass varchar(3) DEFAULT NULL REFERENCES building_class(id),
  taxclass varchar(2) DEFAULT NULL REFERENCES tax_class(id),
  resunits integer DEFAULT NULL,
  comunits integer DEFAULT NULL,
  ttlunits integer DEFAULT NULL,
  land_sf bigint DEFAULT NULL,
  gross_sf bigint DEFAULT NULL,
  yearbuilt integer DEFAULT NULL,
  price bigint DEFAULT NULL,
  easement boolean DEFAULT NULL
);

CREATE INDEX price ON sales (price);

CREATE INDEX BBL ON sales (bbl);
CREATE INDEX BB ON sales (borough, block);

CREATE INDEX date ON sales (date);

DROP TABLE IF EXISTS sales_tmp;

CREATE TABLE sales_tmp (
  borough INTEGER DEFAULT NULL,
  neighborhood TEXT DEFAULT NULL,
  buildingclasscategory TEXT DEFAULT NULL,
  taxclassatpresent TEXT DEFAULT NULL,
  block TEXT DEFAULT NULL,
  lot TEXT DEFAULT NULL,
  easement TEXT DEFAULT NULL,
  buildingclassatpresent TEXT DEFAULT NULL,
  address TEXT DEFAULT NULL,
  apartmentnumber TEXT DEFAULT NULL,
  zipcode TEXT DEFAULT NULL,
  residentialunits TEXT DEFAULT NULL,
  commercialunits TEXT DEFAULT NULL,
  totalunits TEXT DEFAULT NULL,
  landsquarefeet TEXT DEFAULT NULL,
  grosssquarefeet TEXT DEFAULT NULL,
  yearbuilt INTEGER DEFAULT NULL,
  taxclassattimeofsale TEXT DEFAULT NULL,
  buildingclassattimeofsale TEXT DEFAULT NULL,
  saleprice TEXT DEFAULT NULL,
  saledate TEXT DEFAULT NULL
);
