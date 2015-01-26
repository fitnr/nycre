DROP TABLE `borough`;

CREATE TABLE `borough` (
  `id` int(1) unsigned NOT NULL AUTO_INCREMENT,
  `borough` varchar(9) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

DROP TABLE `building_category`;

CREATE TABLE `building_category` (
  `id` varchar(3) NOT NULL DEFAULT '',
  `category` varchar(128) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `sales` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `borough` enum('1','2','3','4','5') DEFAULT NULL,
  `neighborhood` varchar(64) DEFAULT NULL,
  `bldgcatid` varchar(3) DEFAULT NULL,
  `taxclass` varchar(3) DEFAULT NULL,
  `block` smallint(5) unsigned DEFAULT NULL,
  `lot` smallint(5) unsigned DEFAULT NULL,
  `easement` binary(1) DEFAULT NULL,
  `bldgclass` varchar(3) DEFAULT NULL,
  `address` varchar(256) DEFAULT NULL,
  `apt` varchar(5) DEFAULT NULL,
  `zipcode` int(5) unsigned zerofill DEFAULT NULL,
  `res_units` smallint(5) unsigned DEFAULT NULL,
  `com_units` smallint(5) unsigned DEFAULT NULL,
  `ttl_units` smallint(5) unsigned DEFAULT NULL,
  `land_sf` int(10) unsigned DEFAULT NULL,
  `gross_sf` int(10) unsigned DEFAULT NULL,
  `yearbuilt` smallint(4) unsigned DEFAULT NULL,
  `price` int(10) unsigned DEFAULT NULL,
  `date` date DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=84185 DEFAULT CHARSET=utf8;

LOCK TABLES `borough` WRITE;
/*!40000 ALTER TABLE `borough` DISABLE KEYS */;

INSERT INTO `borough` (`id`, `name`)
VALUES
    (1,'Manhattan'),
    (2,'Bronx'),
    (3,'Brooklyn'),
    (4,'Queens'),
    (5,'Richmond');

/*!40000 ALTER TABLE `borough` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `building_class_category` WRITE;
/*!40000 ALTER TABLE `building_class_category` DISABLE KEYS */;

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

/*!40000 ALTER TABLE `building_class_category` ENABLE KEYS */;
UNLOCK TABLES;

