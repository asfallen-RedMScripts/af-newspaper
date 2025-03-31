CREATE TABLE IF NOT EXISTS `newspaper` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `title` varchar(5000) NOT NULL DEFAULT '',
  `body` varchar(5000) NOT NULL DEFAULT '',
  `date` varchar(50) NOT NULL DEFAULT '',
  `image` varchar(250) DEFAULT NULL,
  `publisher` varchar(250) NOT NULL DEFAULT 'af-newspaper',
  `version` int(10) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;


CREATE TABLE IF NOT EXISTS `newspaper_lookup` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item_id` varchar(50) NOT NULL,
  `newspaper_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `newspaper_id` (`newspaper_id`),
  CONSTRAINT `newspaper_lookup_ibfk_1` FOREIGN KEY (`newspaper_id`) REFERENCES `newspaper` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

