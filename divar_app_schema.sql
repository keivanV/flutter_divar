-- MySQL dump 10.13  Distrib 8.0.42, for Win64 (x86_64)
--
-- Host: localhost    Database: divar_app
-- ------------------------------------------------------
-- Server version	8.0.42

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `active_devices`
--

DROP TABLE IF EXISTS `active_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `active_devices` (
  `device_id` int NOT NULL AUTO_INCREMENT,
  `user_phone_number` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `device_token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `last_active` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`device_id`),
  KEY `user_phone_number` (`user_phone_number`),
  CONSTRAINT `active_devices_ibfk_1` FOREIGN KEY (`user_phone_number`) REFERENCES `users` (`phone_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `active_devices`
--

LOCK TABLES `active_devices` WRITE;
/*!40000 ALTER TABLE `active_devices` DISABLE KEYS */;
/*!40000 ALTER TABLE `active_devices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ad_images`
--

DROP TABLE IF EXISTS `ad_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ad_images` (
  `image_id` int NOT NULL AUTO_INCREMENT,
  `ad_id` int NOT NULL,
  `image_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  PRIMARY KEY (`image_id`),
  KEY `ad_id` (`ad_id`),
  CONSTRAINT `ad_images_ibfk_1` FOREIGN KEY (`ad_id`) REFERENCES `advertisements` (`ad_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=59 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ad_images`
--

LOCK TABLES `ad_images` WRITE;
/*!40000 ALTER TABLE `ad_images` DISABLE KEYS */;
INSERT INTO `ad_images` VALUES (43,43,'http://localhost:5000/uploads/1748203166936-380507148.jpg'),(54,54,'http://localhost:5000/uploads/1748212582268-750145285.jpg'),(55,55,'http://localhost:5000/uploads/1748212662460-305145998.jpg'),(56,56,'http://localhost:5000/uploads/1748213112826-414043851.jpg'),(57,57,'http://localhost:5000/uploads/1748213156168-719564230.jpg'),(58,58,'http://localhost:5000/uploads/1748213203558-845328248.jpg');
/*!40000 ALTER TABLE `ad_images` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `admins`
--

DROP TABLE IF EXISTS `admins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admins` (
  `admin_id` int NOT NULL AUTO_INCREMENT,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`admin_id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admins`
--

LOCK TABLES `admins` WRITE;
/*!40000 ALTER TABLE `admins` DISABLE KEYS */;
INSERT INTO `admins` VALUES (1,'$2b$10$9PyLuMcy4F3bIF2uLavTRebuzFF.6gE80mv6HSZUWKbiOlMsyHgOu','2025-05-25 22:16:53','admin');
/*!40000 ALTER TABLE `admins` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `advertisements`
--

DROP TABLE IF EXISTS `advertisements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `advertisements` (
  `ad_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `ad_type` enum('REAL_ESTATE','VEHICLE','DIGITAL','HOME','SERVICES','PERSONAL','ENTERTAINMENT') CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `status` enum('PENDING','APPROVED','REJECTED') CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL DEFAULT 'PENDING',
  `owner_phone_number` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `province_id` int NOT NULL,
  `city_id` int NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `price` bigint DEFAULT NULL,
  PRIMARY KEY (`ad_id`),
  KEY `idx_advertisements_ad_type` (`ad_type`),
  KEY `idx_advertisements_province_id` (`province_id`),
  KEY `idx_advertisements_city_id` (`city_id`),
  KEY `idx_advertisements_owner_phone` (`owner_phone_number`),
  CONSTRAINT `advertisements_ibfk_1` FOREIGN KEY (`owner_phone_number`) REFERENCES `users` (`phone_number`) ON DELETE CASCADE,
  CONSTRAINT `advertisements_ibfk_2` FOREIGN KEY (`province_id`) REFERENCES `provinces` (`province_id`) ON DELETE RESTRICT,
  CONSTRAINT `advertisements_ibfk_3` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=59 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `advertisements`
--

LOCK TABLES `advertisements` WRITE;
/*!40000 ALTER TABLE `advertisements` DISABLE KEYS */;
INSERT INTO `advertisements` VALUES (43,'bbb','VEHICLE','PENDING','09120212280',1,1,'bb','2025-05-25 19:59:26',122212),(54,'fds','VEHICLE','PENDING','09120212280',1,1,'fdsf','2025-05-25 22:36:22',2500),(55,'99','REAL_ESTATE','PENDING','09120212280',1,1,'99','2025-05-25 22:37:42',120),(56,'ew','REAL_ESTATE','PENDING','09120212280',1,1,'rew','2025-05-25 22:45:12',12222),(57,'231','REAL_ESTATE','PENDING','09120212280',1,1,'213','2025-05-25 22:45:56',2222222222),(58,'nh','VEHICLE','PENDING','09120212280',1,1,'nh','2025-05-25 22:46:43',123132);
/*!40000 ALTER TABLE `advertisements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bookmarks`
--

DROP TABLE IF EXISTS `bookmarks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bookmarks` (
  `bookmark_id` int NOT NULL AUTO_INCREMENT,
  `user_phone_number` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `ad_id` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`bookmark_id`),
  UNIQUE KEY `user_phone_number` (`user_phone_number`,`ad_id`),
  KEY `ad_id` (`ad_id`),
  KEY `idx_bookmarks_user_phone` (`user_phone_number`),
  CONSTRAINT `bookmarks_ibfk_1` FOREIGN KEY (`user_phone_number`) REFERENCES `users` (`phone_number`) ON DELETE CASCADE,
  CONSTRAINT `bookmarks_ibfk_2` FOREIGN KEY (`ad_id`) REFERENCES `advertisements` (`ad_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bookmarks`
--

LOCK TABLES `bookmarks` WRITE;
/*!40000 ALTER TABLE `bookmarks` DISABLE KEYS */;
INSERT INTO `bookmarks` VALUES (22,'09120212280',57,'2025-05-25 22:46:10'),(23,'09120212280',58,'2025-05-26 12:13:24');
/*!40000 ALTER TABLE `bookmarks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cities`
--

DROP TABLE IF EXISTS `cities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cities` (
  `city_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `province_id` int NOT NULL,
  PRIMARY KEY (`city_id`),
  UNIQUE KEY `name` (`name`,`province_id`),
  KEY `province_id` (`province_id`),
  CONSTRAINT `cities_ibfk_1` FOREIGN KEY (`province_id`) REFERENCES `provinces` (`province_id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=94 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cities`
--

LOCK TABLES `cities` WRITE;
/*!40000 ALTER TABLE `cities` DISABLE KEYS */;
INSERT INTO `cities` VALUES (47,'Abadan',16),(36,'Abdanan',12),(92,'Abhar',31),(46,'Ahvaz',16),(27,'Aliabad-e Katul',9),(57,'Aligudarz',19),(69,'Alvand',23),(62,'Amol',21),(58,'Arak',20),(4,'Ardabil',2),(90,'Ardakan',30),(63,'Babol',21),(31,'Bandar Abbas',11),(23,'Bandar Anzali',8),(14,'Bandar Ganaveh',5),(82,'Birjand',28),(64,'Bojnurd',22),(15,'Borazjan',5),(17,'Borujen',6),(56,'Borujerd',19),(13,'Bushehr',5),(78,'Damghan',26),(51,'Dehdasht',17),(35,'Dehloran',12),(48,'Dezful',16),(50,'Dogonbadan',17),(66,'Esfarayen',22),(44,'Eslamabad-e Gharb',15),(18,'Farsan',6),(26,'Gonbad-e Kavus',9),(25,'Gorgan',9),(28,'Hamadan',10),(34,'Ilam',12),(81,'Iranshahr',27),(37,'Isfahan',13),(71,'Jafariyeh',24),(45,'Kangavar',15),(1,'Karaj',1),(38,'Kashan',13),(21,'Kazerun',7),(40,'Kerman',14),(43,'Kermanshah',15),(60,'Khomeyn',20),(39,'Khomeyni Shahr',13),(55,'Khorramabad',19),(93,'Khorramdarreh',31),(11,'Khoy',4),(24,'Lahijan',8),(29,'Malayer',10),(8,'Maragheh',3),(9,'Marand',3),(54,'Marivan',18),(20,'Marvdasht',7),(73,'Mashhad',25),(5,'Meshgin Shahr',2),(89,'Meybod',30),(12,'Miandoab',4),(32,'Minab',11),(30,'Nahavand',10),(2,'Nazarabad',1),(74,'Neyshabur',25),(6,'Parsabad',2),(72,'Qanavat',24),(83,'Qayen',28),(67,'Qazvin',23),(33,'Qeshm',11),(70,'Qom',24),(42,'Rafsanjan',14),(22,'Rasht',8),(87,'Rey',29),(75,'Sabzevar',25),(52,'Sanandaj',18),(53,'Saqqez',18),(61,'Sari',21),(59,'Saveh',20),(3,'Savojbolagh',1),(76,'Semnan',26),(16,'Shahrekord',6),(77,'Shahroud',26),(19,'Shiraz',7),(65,'Shirvan',22),(41,'Sirjan',14),(84,'Tabas',28),(7,'Tabriz',3),(68,'Takestan',23),(85,'Tehran',29),(10,'Urmia',4),(86,'Varamin',29),(49,'Yasuj',17),(88,'Yazd',30),(80,'Zabol',27),(79,'Zahedan',27),(91,'Zanjan',31);
/*!40000 ALTER TABLE `cities` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comments` (
  `comment_id` int NOT NULL AUTO_INCREMENT,
  `ad_id` int NOT NULL,
  `user_phone_number` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`comment_id`),
  KEY `ad_id` (`ad_id`),
  KEY `user_phone_number` (`user_phone_number`),
  CONSTRAINT `comments_ibfk_1` FOREIGN KEY (`ad_id`) REFERENCES `advertisements` (`ad_id`) ON DELETE CASCADE,
  CONSTRAINT `comments_ibfk_2` FOREIGN KEY (`user_phone_number`) REFERENCES `users` (`phone_number`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comments`
--

LOCK TABLES `comments` WRITE;
/*!40000 ALTER TABLE `comments` DISABLE KEYS */;
INSERT INTO `comments` VALUES (2,54,'09120212280','dsfdfsdfsd','2025-05-25 22:47:31'),(3,57,'09120212280','sdadasdadss','2025-05-25 22:47:50'),(4,56,'09120212280','ssssssssssssssssssssssssss','2025-05-25 22:47:56'),(5,55,'09120212280','sssssssssssssssssssss','2025-05-25 22:48:03'),(6,58,'09120212280','fffffffffffffffffffffffff','2025-05-25 22:48:26'),(7,43,'09120212280','fdsfsfds','2025-05-25 22:48:33'),(9,58,'09120212280','quick 2','2025-05-26 08:09:37'),(10,58,'09120212280','ffggffgfdgdf','2025-05-26 09:42:47'),(11,58,'09120212280','ds','2025-05-26 09:48:57'),(12,58,'09120212280','ewfdfsfsd','2025-05-26 10:10:24');
/*!40000 ALTER TABLE `comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `provinces`
--

DROP TABLE IF EXISTS `provinces`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `provinces` (
  `province_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  PRIMARY KEY (`province_id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `provinces`
--

LOCK TABLES `provinces` WRITE;
/*!40000 ALTER TABLE `provinces` DISABLE KEYS */;
INSERT INTO `provinces` VALUES (1,'Alborz'),(2,'Ardabil'),(3,'Azerbaijan East'),(4,'Azerbaijan West'),(5,'Bushehr'),(6,'Chaharmahal and Bakhtiari'),(7,'Fars'),(8,'Gilan'),(9,'Golestan'),(10,'Hamadan'),(11,'Hormozgan'),(12,'Ilam'),(13,'Isfahan'),(14,'Kerman'),(15,'Kermanshah'),(16,'Khuzestan'),(17,'Kohgiluyeh and Boyer-Ahmad'),(18,'Kurdistan'),(19,'Lorestan'),(20,'Markazi'),(21,'Mazandaran'),(22,'North Khorasan'),(23,'Qazvin'),(24,'Qom'),(25,'Razavi Khorasan'),(26,'Semnan'),(27,'Sistan and Baluchestan'),(28,'South Khorasan'),(29,'Tehran'),(30,'Yazd'),(31,'Zanjan');
/*!40000 ALTER TABLE `provinces` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `real_estate_ads`
--

DROP TABLE IF EXISTS `real_estate_ads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `real_estate_ads` (
  `ad_id` int NOT NULL,
  `real_estate_type` enum('SALE','RENT') CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `area` int NOT NULL,
  `construction_year` int DEFAULT NULL,
  `rooms` int NOT NULL,
  `has_parking` tinyint(1) NOT NULL DEFAULT '0',
  `has_storage` tinyint(1) NOT NULL DEFAULT '0',
  `has_balcony` tinyint(1) NOT NULL DEFAULT '0',
  `deposit` int DEFAULT NULL,
  `monthly_rent` int DEFAULT NULL,
  `floor` int NOT NULL,
  `total_price` bigint DEFAULT NULL,
  `price_per_meter` bigint DEFAULT NULL,
  PRIMARY KEY (`ad_id`),
  CONSTRAINT `real_estate_ads_ibfk_1` FOREIGN KEY (`ad_id`) REFERENCES `advertisements` (`ad_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `real_estate_ads`
--

LOCK TABLES `real_estate_ads` WRITE;
/*!40000 ALTER TABLE `real_estate_ads` DISABLE KEYS */;
INSERT INTO `real_estate_ads` VALUES (55,'RENT',1400,1400,2,1,1,0,120,10,2,0,NULL),(56,'RENT',140,1400,1,1,0,0,12222,121,1,NULL,NULL),(57,'SALE',123,1400,12,1,1,1,NULL,NULL,2,2222222222,118);
/*!40000 ALTER TABLE `real_estate_ads` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recent_visits`
--

DROP TABLE IF EXISTS `recent_visits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recent_visits` (
  `visit_id` int NOT NULL AUTO_INCREMENT,
  `user_phone_number` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `ad_id` int NOT NULL,
  `visited_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`visit_id`),
  KEY `ad_id` (`ad_id`),
  KEY `idx_recent_visits_user_phone` (`user_phone_number`),
  CONSTRAINT `recent_visits_ibfk_1` FOREIGN KEY (`user_phone_number`) REFERENCES `users` (`phone_number`) ON DELETE CASCADE,
  CONSTRAINT `recent_visits_ibfk_2` FOREIGN KEY (`ad_id`) REFERENCES `advertisements` (`ad_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recent_visits`
--

LOCK TABLES `recent_visits` WRITE;
/*!40000 ALTER TABLE `recent_visits` DISABLE KEYS */;
/*!40000 ALTER TABLE `recent_visits` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `phone_number` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `first_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `last_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `province_id` int NOT NULL,
  `city_id` int NOT NULL,
  `account_level` enum('LEVEL_1','LEVEL_2','LEVEL_3') CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL DEFAULT 'LEVEL_1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`phone_number`),
  UNIQUE KEY `nickname` (`nickname`),
  KEY `province_id` (`province_id`),
  KEY `city_id` (`city_id`),
  CONSTRAINT `users_ibfk_1` FOREIGN KEY (`province_id`) REFERENCES `provinces` (`province_id`) ON DELETE RESTRICT,
  CONSTRAINT `users_ibfk_2` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('09120212280','کیوان','وفایی','کیوی',1,1,'LEVEL_1','2025-05-25 19:53:50');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vehicle_ads`
--

DROP TABLE IF EXISTS `vehicle_ads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vehicle_ads` (
  `ad_id` int NOT NULL,
  `mileage` int NOT NULL,
  `color` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `brand` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `model` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `gearbox` enum('MANUAL','AUTOMATIC') CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `engine_status` enum('HEALTHY','NEEDS_REPAIR') CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `chassis_status` enum('HEALTHY','IMPACTED') CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `body_status` enum('HEALTHY','MINOR_SCRATCH','ACCIDENTED') CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci NOT NULL,
  `base_price` bigint DEFAULT NULL,
  PRIMARY KEY (`ad_id`),
  CONSTRAINT `vehicle_ads_ibfk_1` FOREIGN KEY (`ad_id`) REFERENCES `advertisements` (`ad_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vehicle_ads`
--

LOCK TABLES `vehicle_ads` WRITE;
/*!40000 ALTER TABLE `vehicle_ads` DISABLE KEYS */;
INSERT INTO `vehicle_ads` VALUES (43,122,'2312','sa','1400','MANUAL','HEALTHY','HEALTHY','HEALTHY',122212),(54,21,'231','saipa','1400','MANUAL','HEALTHY','HEALTHY','MINOR_SCRATCH',2500),(58,32,'23','dsf','1400','MANUAL','HEALTHY','HEALTHY','HEALTHY',123132);
/*!40000 ALTER TABLE `vehicle_ads` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-05-26  5:22:52
