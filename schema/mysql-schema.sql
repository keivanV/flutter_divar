-- تنظیم کدگذاری کلاینت برای پشتیبانی از زبان فارسی
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET COLLATION_CONNECTION = 'utf8mb4_persian_ci';

-- حذف پایگاه داده قبلی (در صورت وجود) و ایجاد پایگاه داده جدید
DROP DATABASE IF EXISTS divar_app;
CREATE DATABASE divar_app
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_persian_ci;

USE divar_app;

-- حذف جداول قبلی به ترتیب معکوس وابستگی‌ها
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS recent_visits;
DROP TABLE IF EXISTS bookmarks;
DROP TABLE IF EXISTS vehicle_ads;
DROP TABLE IF EXISTS real_estate_ads;
DROP TABLE IF EXISTS ad_images;
DROP TABLE IF EXISTS advertisements;
DROP TABLE IF EXISTS active_devices;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS cities;
DROP TABLE IF EXISTS provinces;

-- جدول استان‌ها
CREATE TABLE provinces (
    province_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci;

-- جدول شهرها
CREATE TABLE cities (
    city_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    province_id INT NOT NULL,
    FOREIGN KEY (province_id) REFERENCES provinces(province_id) ON DELETE RESTRICT,
    UNIQUE (name, province_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci;

-- جدول کاربران
CREATE TABLE users (
    phone_number VARCHAR(11) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    nickname VARCHAR(50) NOT NULL UNIQUE,
    province_id INT NOT NULL,
    city_id INT NOT NULL,
    account_level ENUM('LEVEL_1', 'LEVEL_2', 'LEVEL_3') NOT NULL DEFAULT 'LEVEL_1',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (province_id) REFERENCES provinces(province_id) ON DELETE RESTRICT,
    FOREIGN KEY (city_id) REFERENCES cities(city_id) ON DELETE RESTRICT
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci;

-- جدول دستگاه‌های فعال کاربر
CREATE TABLE active_devices (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    user_phone_number VARCHAR(11) NOT NULL,
    device_token VARCHAR(255) NOT NULL,
    last_active TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_phone_number) REFERENCES users(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci;

-- جدول آگهی‌ها (ویژگی‌های عمومی)
CREATE TABLE advertisements (
    ad_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    ad_type ENUM('REAL_ESTATE', 'VEHICLE', 'DIGITAL', 'HOME', 'SERVICES', 'PERSONAL', 'ENTERTAINMENT') NOT NULL,
    status ENUM('PUBLISHED', 'UNDER_REVIEW') NOT NULL DEFAULT 'UNDER_REVIEW',
    owner_phone_number VARCHAR(11) NOT NULL,
    province_id INT NOT NULL,
    city_id INT NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_phone_number) REFERENCES users(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (province_id) REFERENCES provinces(province_id) ON DELETE RESTRICT,
    FOREIGN KEY (city_id) REFERENCES cities(city_id) ON DELETE RESTRICT
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci;

-- جدول عکس‌های آگهی
CREATE TABLE ad_images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    ad_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    FOREIGN KEY (ad_id) REFERENCES advertisements(ad_id) ON DELETE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci;

-- جدول آگهی‌های املاک (فروش و اجاره مسکونی)
CREATE TABLE real_estate_ads (
    ad_id INT PRIMARY KEY,
    real_estate_type ENUM('SALE', 'RENT') NOT NULL,
    area INT NOT NULL,
    construction_year INT NOT NULL,
    rooms INT NOT NULL,
    total_price BIGINT NOT NULL,
    price_per_meter BIGINT NOT NULL,
    has_parking BOOLEAN NOT NULL DEFAULT FALSE,
    has_storage BOOLEAN NOT NULL DEFAULT FALSE,
    has_balcony BOOLEAN NOT NULL DEFAULT FALSE,
    deposit BIGINT NOT NULL,
    monthly_rent BIGINT NOT NULL,
    floor INT NOT NULL,
    FOREIGN KEY (ad_id) REFERENCES advertisements(ad_id) ON DELETE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci;

-- جدول آگهی‌های وسایل نقلیه
CREATE TABLE vehicle_ads (
    ad_id INT PRIMARY KEY,
    mileage INT NOT NULL,
    model_year INT NOT NULL,
    color VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    gearbox ENUM('MANUAL', 'AUTOMATIC') NOT NULL,
    base_price BIGINT NOT NULL,
    engine_status ENUM('HEALTHY', 'NEEDS_REPAIR') NOT NULL,
    chassis_status ENUM('HEALTHY', 'IMPACTED') NOT NULL,
    body_status ENUM('HEALTHY', 'MINOR_SCRATCH', 'ACCIDENTED') NOT NULL,
    FOREIGN KEY (ad_id) REFERENCES advertisements(ad_id) ON DELETE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci;

-- جدول نشان‌شده‌ها
CREATE TABLE bookmarks (
    bookmark_id INT AUTO_INCREMENT PRIMARY KEY,
    user_phone_number VARCHAR(11) NOT NULL,
    ad_id INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_phone_number) REFERENCES users(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (ad_id) REFERENCES advertisements(ad_id) ON DELETE CASCADE,
    UNIQUE (user_phone_number, ad_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci;

-- جدول بازدیدهای اخیر
CREATE TABLE recent_visits (
    visit_id INT AUTO_INCREMENT PRIMARY KEY,
    user_phone_number VARCHAR(11) NOT NULL,
    ad_id INT NOT NULL,
    visited_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_phone_number) REFERENCES users(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (ad_id) REFERENCES advertisements(ad_id) ON DELETE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci;

-- جدول کامنت‌ها
CREATE TABLE comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    ad_id INT NOT NULL,
    user_phone_number VARCHAR(11) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ad_id) REFERENCES advertisements(ad_id) ON DELETE CASCADE,
    FOREIGN KEY (user_phone_number) REFERENCES users(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_persian_ci;

-- نمایه‌ها برای بهبود عملکرد جست‌جو و فیلتر
CREATE INDEX idx_advertisements_ad_type ON advertisements(ad_type);
CREATE INDEX idx_advertisements_province_id ON advertisements(province_id);
CREATE INDEX idx_advertisements_city_id ON advertisements(city_id);
CREATE INDEX idx_advertisements_owner_phone ON advertisements(owner_phone_number);
CREATE INDEX idx_bookmarks_user_phone ON bookmarks(user_phone_number);
CREATE INDEX idx_recent_visits_user_phone ON recent_visits(user_phone_number);

-- درج داده‌های نمونه برای استان‌ها و شهرها (با نام‌های انگلیسی)
INSERT INTO provinces (name) VALUES
    ('Tehran'),
    ('Isfahan'),
    ('Fars'),
    ('Khuzestan'),
    ('Mazandaran');

INSERT INTO cities (name, province_id) VALUES
    ('Tehran', 1),
    ('Karaj', 1),
    ('Isfahan', 2),
    ('Kashan', 2),
    ('Shiraz', 3),
    ('Marvdasht', 3),
    ('Ahvaz', 4),
    ('Dezful', 4),
    ('Sari', 5),
    ('Babol', 5);