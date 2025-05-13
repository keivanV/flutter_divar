import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const String apiBaseUrl = 'http://localhost:5000/api';

// دسته‌بندی‌ها
const List<Map<String, dynamic>> categories = [
  {'name': 'املاک', 'icon': FontAwesomeIcons.house},
  {'name': 'وسایل نقلیه', 'icon': FontAwesomeIcons.car},
  {'name': 'دیجیتال', 'icon': FontAwesomeIcons.mobile},
  {'name': 'خانه', 'icon': FontAwesomeIcons.couch},
  {'name': 'خدمات', 'icon': FontAwesomeIcons.hammer},
  {'name': 'شخصی', 'icon': FontAwesomeIcons.shirt},
  {'name': 'سرگرمی', 'icon': FontAwesomeIcons.gamepad},
];

// تب‌های ناوبری
const List<Map<String, dynamic>> navItems = [
  {'name': 'آگهی‌ها', 'icon': FontAwesomeIcons.list},
  {'name': 'نشان‌ها', 'icon': FontAwesomeIcons.bookmark},
  {'name': 'ثبت آگهی', 'icon': FontAwesomeIcons.plusCircle},
  {'name': 'پروفایل', 'icon': FontAwesomeIcons.user},
];
