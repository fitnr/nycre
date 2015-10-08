DROP TABLE IF EXISTS `borough`;

CREATE TABLE `borough` (
  `id` int(1) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(9) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `building_class_category`;

CREATE TABLE `building_class_category` (
  `id` varchar(3) NOT NULL DEFAULT '',
  `name` varchar(64) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `building_class`;

CREATE TABLE `building_class` (
  `id` varchar(3) NOT NULL DEFAULT '',
  `name` varchar(64) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `tax_class`;

CREATE TABLE `tax_class` (
  `id` varchar(3) NOT NULL DEFAULT '',
  `name` varchar(64) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Not dropping the sales table because you might have stuff if it!
CREATE TABLE IF NOT EXISTS `sales` (
  `bbl` bigint(22) unsigned NOT NULL,
  `borough` enum('1','2','3','4','5') DEFAULT NULL,
  `block` smallint(5) unsigned DEFAULT NULL,
  `lot` smallint(5) unsigned DEFAULT NULL,
  `date` date DEFAULT NULL,
  `address` varchar(256) DEFAULT NULL,
  `apt` varchar(8) DEFAULT NULL,
  `zip` int(5) unsigned zerofill DEFAULT NULL,
  `neighborhood` varchar(64) DEFAULT NULL,
  `buildingclasscat` varchar(3) DEFAULT NULL,
  `buildingclass` varchar(3) DEFAULT NULL,
  `taxclass` varchar(2) DEFAULT NULL,
  `resunits` smallint(5) unsigned DEFAULT NULL,
  `comunits` smallint(5) unsigned DEFAULT NULL,
  `ttlunits` smallint(5) unsigned DEFAULT NULL,
  `land_sf` int(10) unsigned DEFAULT NULL,
  `gross_sf` int(10) unsigned DEFAULT NULL,
  `yearbuilt` smallint(4) unsigned DEFAULT NULL,
  `price` int(10) unsigned DEFAULT NULL,
  `easement` binary(1) DEFAULT NULL,
  KEY `price` (`price`),
  KEY `date` (`date`),
  KEY `BBL` (`bbl`),
  KEY `BB` (`borough`, `block`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO `borough` (`id`, `name`)
VALUES
    (1,'Manhattan'),
    (2,'Bronx'),
    (3,'Brooklyn'),
    (4,'Queens'),
    (5,'Richmond');

INSERT INTO `building_class_category` (`id`, `name`)
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
    ('39','TRANSPORTATION FACILITIES'),
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
    

INSERT INTO `tax_class` (`id`, `name`)
VALUES
    (1,'residential up to 3 units, condos under three stories'),
    ('2A','residential rental, 4-6 units'),
    ('2B','residential rental, 7-10 units'),
    ('2C','residential condo or coop, 2-10 units'),
    (2,'residential, 11 units or more'),
    (3,'utility'),
    (4,'commercial or industrial');
