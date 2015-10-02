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
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `borough` enum('1','2','3','4','5') DEFAULT NULL,
  `date` date DEFAULT NULL,
  `address` varchar(256) DEFAULT NULL,
  `apt` varchar(8) DEFAULT NULL,
  `zip` int(5) unsigned zerofill DEFAULT NULL,
  `neighborhood` varchar(64) DEFAULT NULL,
  `buildingclasscat` varchar(3) DEFAULT NULL,
  `buildingclass` varchar(3) DEFAULT NULL,
  `taxclass` varchar(2) DEFAULT NULL,
  `block` smallint(5) unsigned DEFAULT NULL,
  `lot` smallint(5) unsigned DEFAULT NULL,
  `resunits` smallint(5) unsigned DEFAULT NULL,
  `comunits` smallint(5) unsigned DEFAULT NULL,
  `ttlunits` smallint(5) unsigned DEFAULT NULL,
  `land_sf` int(10) unsigned DEFAULT NULL,
  `gross_sf` int(10) unsigned DEFAULT NULL,
  `yearbuilt` smallint(4) unsigned DEFAULT NULL,
  `price` int(10) unsigned DEFAULT NULL,
  `easement` binary(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `price` (`price`),
  KEY `BBL` (`borough`,`block`,`lot`)
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
    ('05','TAX CLASS 1 VACANT LAND'),
    ('06','TAX CLASS 1 - OTHER'),
    ('21','OFFICE BUILDINGS'),
    ('32','HOSPITAL AND HEALTH FACILITIES'),
    ('04','TAX CLASS 1 CONDOS'),
    ('22','STORE BUILDINGS'),
    ('07','RENTALS - WALKUP APARTMENTS'),
    ('10','COOPS - ELEVATOR APARTMENTS'),
    ('13','CONDOS - ELEVATOR APARTMENTS'),
    ('25','LUXURY HOTELS'),
    ('27','FACTORIES'),
    ('30','WAREHOUSES'),
    ('31','COMMERCIAL VACANT LAND'),
    ('03','THREE FAMILY HOMES'),
    ('29','COMMERCIAL GARAGES'),
    ('41','TAX CLASS 4 - OTHER'),
    ('14','RENTALS - 4-10 UNIT'),
    ('08','RENTALS - ELEVATOR APARTMENTS'),
    ('12','CONDOS - WALKUP APARTMENTS'),
    ('37','RELIGIOUS FACILITIES'),
    ('09','COOPS - WALKUP APARTMENTS'),
    ('33','EDUCATIONAL FACILITIES'),
    ('36','OUTDOOR RECREATIONAL FACILITIES'),
    ('11','SPECIAL CONDO BILLING LOTS'),
    ('34','THEATRES'),
    ('15','CONDOS - 2-10 UNIT RESIDENTIAL'),
    ('16','CONDOS - 2-10 UNIT WITH COMMERCIAL UNIT'),
    ('26','OTHER HOTELS'),
    ('28','COMMERCIAL CONDOS'),
    ('38','ASYLUMS AND HOMES'),
    ('18','TAX CLASS 3 - UTILITY PROPERTIES'),
    ('35','INDOOR PUBLIC AND CULTURAL FACILITIES'),
    ('11A','CONDO-RENTALS'),
    ('17','CONDOPS'),
    ('40','SELECTED GOVERNMENTAL FACILITIES'),
    ('23','LOFT BUILDINGS'),
    ('24','TAX CLASS 4 - UTILITY BUREAU PROPERTIES');

INSERT INTO `tax_class` (`id`, `name`)
VALUES
    (1,'residential up to 3 units, condos under three stories'),
    ('2A','residential rental, 4-6 units'),
    ('2B','residential rental, 7-10 units'),
    ('2C','residential condo or coop, 2-10 units'),
    (2,'residential, 11 units or more'),
    (3,'utility'),
    (4,'commercial or industrial');
