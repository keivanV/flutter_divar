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
  `user_phone_number` varchar(11) COLLATE utf8mb4_persian_ci NOT NULL,
  `device_token` varchar(255) COLLATE utf8mb4_persian_ci NOT NULL,
  `last_active` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`device_id`),
  KEY `user_phone_number` (`user_phone_number`),
  CONSTRAINT `active_devices_ibfk_1` FOREIGN KEY (`user_phone_number`) REFERENCES `users` (`phone_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ad_images`
--

DROP TABLE IF EXISTS `ad_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ad_images` (
  `image_id` int NOT NULL AUTO_INCREMENT,
  `ad_id` int NOT NULL,
  `image_url` varchar(255) COLLATE utf8mb4_persian_ci NOT NULL,
  PRIMARY KEY (`image_id`),
  KEY `ad_id` (`ad_id`),
  CONSTRAINT `ad_images_ibfk_1` FOREIGN KEY (`ad_id`) REFERENCES `advertisements` (`ad_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `advertisements`
--

DROP TABLE IF EXISTS `advertisements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `advertisements` (
  `ad_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(100) COLLATE utf8mb4_persian_ci NOT NULL,
  `ad_type` enum('REAL_ESTATE','VEHICLE','DIGITAL','HOME','SERVICES','PERSONAL','ENTERTAINMENT') COLLATE utf8mb4_persian_ci NOT NULL,
  `status` enum('PENDING','APPROVED','REJECTED') COLLATE utf8mb4_persian_ci NOT NULL DEFAULT 'PENDING',
  `owner_phone_number` varchar(11) COLLATE utf8mb4_persian_ci NOT NULL,
  `province_id` int NOT NULL,
  `city_id` int NOT NULL,
  `description` text COLLATE utf8mb4_persian_ci NOT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bookmarks`
--

DROP TABLE IF EXISTS `bookmarks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bookmarks` (
  `bookmark_id` int NOT NULL AUTO_INCREMENT,
  `user_phone_number` varchar(11) COLLATE utf8mb4_persian_ci NOT NULL,
  `ad_id` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`bookmark_id`),
  UNIQUE KEY `user_phone_number` (`user_phone_number`,`ad_id`),
  KEY `ad_id` (`ad_id`),
  KEY `idx_bookmarks_user_phone` (`user_phone_number`),
  CONSTRAINT `bookmarks_ibfk_1` FOREIGN KEY (`user_phone_number`) REFERENCES `users` (`phone_number`) ON DELETE CASCADE,
  CONSTRAINT `bookmarks_ibfk_2` FOREIGN KEY (`ad_id`) REFERENCES `advertisements` (`ad_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cities`
--

DROP TABLE IF EXISTS `cities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cities` (
  `city_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `province_id` int NOT NULL,
  PRIMARY KEY (`city_id`),
  UNIQUE KEY `name` (`name`,`province_id`),
  KEY `province_id` (`province_id`),
  CONSTRAINT `cities_ibfk_1` FOREIGN KEY (`province_id`) REFERENCES `provinces` (`province_id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comments` (
  `comment_id` int NOT NULL AUTO_INCREMENT,
  `ad_id` int NOT NULL,
  `user_phone_number` varchar(11) COLLATE utf8mb4_persian_ci NOT NULL,
  `content` text COLLATE utf8mb4_persian_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`comment_id`),
  KEY `ad_id` (`ad_id`),
  KEY `user_phone_number` (`user_phone_number`),
  CONSTRAINT `comments_ibfk_1` FOREIGN KEY (`ad_id`) REFERENCES `advertisements` (`ad_id`) ON DELETE CASCADE,
  CONSTRAINT `comments_ibfk_2` FOREIGN KEY (`user_phone_number`) REFERENCES `users` (`phone_number`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `provinces`
--

DROP TABLE IF EXISTS `provinces`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `provinces` (
  `province_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE utf8mb4_persian_ci NOT NULL,
  PRIMARY KEY (`province_id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `real_estate_ads`
--

DROP TABLE IF EXISTS `real_estate_ads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `real_estate_ads` (
  `ad_id` int NOT NULL,
  `real_estate_type` enum('SALE','RENT') COLLATE utf8mb4_persian_ci NOT NULL,
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
-- Table structure for table `recent_visits`
--

DROP TABLE IF EXISTS `recent_visits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recent_visits` (
  `visit_id` int NOT NULL AUTO_INCREMENT,
  `user_phone_number` varchar(11) COLLATE utf8mb4_persian_ci NOT NULL,
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
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `phone_number` varchar(11) COLLATE utf8mb4_persian_ci NOT NULL,
  `first_name` varchar(50) COLLATE utf8mb4_persian_ci NOT NULL,
  `last_name` varchar(50) COLLATE utf8mb4_persian_ci NOT NULL,
  `nickname` varchar(50) COLLATE utf8mb4_persian_ci NOT NULL,
  `province_id` int NOT NULL,
  `city_id` int NOT NULL,
  `account_level` enum('LEVEL_1','LEVEL_2','LEVEL_3') COLLATE utf8mb4_persian_ci NOT NULL DEFAULT 'LEVEL_1',
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
-- Table structure for table `vehicle_ads`
--

DROP TABLE IF EXISTS `vehicle_ads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vehicle_ads` (
  `ad_id` int NOT NULL,
  `mileage` int NOT NULL,
  `color` varchar(50) COLLATE utf8mb4_persian_ci NOT NULL,
  `brand` varchar(50) COLLATE utf8mb4_persian_ci NOT NULL,
  `model` varchar(50) COLLATE utf8mb4_persian_ci NOT NULL,
  `gearbox` enum('MANUAL','AUTOMATIC') COLLATE utf8mb4_persian_ci NOT NULL,
  `engine_status` enum('HEALTHY','NEEDS_REPAIR') COLLATE utf8mb4_persian_ci NOT NULL,
  `chassis_status` enum('HEALTHY','IMPACTED') COLLATE utf8mb4_persian_ci NOT NULL,
  `body_status` enum('HEALTHY','MINOR_SCRATCH','ACCIDENTED') COLLATE utf8mb4_persian_ci NOT NULL,
  `base_price` bigint DEFAULT NULL,
  PRIMARY KEY (`ad_id`),
  CONSTRAINT `vehicle_ads_ibfk_1` FOREIGN KEY (`ad_id`) REFERENCES `advertisements` (`ad_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_persian_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-05-15 20:51:24
