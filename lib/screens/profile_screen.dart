import 'package:divar_app/screens/myAds_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'bookmarks_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  Future<void> _loadUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phoneNumber = authProvider.phoneNumber;
    print('Loading profile for phoneNumber: $phoneNumber');
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      try {
        final profile = await _apiService.fetchUserProfile(phoneNumber);
        setState(() {
          _userProfile = profile;
        });
        print('Loaded profile: $_userProfile');
      } catch (e) {
        print('Error loading profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری پروفایل: $e')),
        );
      }
    } else {
      print('No phoneNumber, redirecting to auth');
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final phoneNumber = authProvider.phoneNumber;
        print('Building ProfileScreen with phoneNumber: $phoneNumber');

        // Show loading or redirect if not logged in
        if (phoneNumber == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('لطفاً وارد حساب کاربری خود شوید'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/auth', (route) => false);
                    },
                    child: const Text('ورود'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('پروفایل'),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(phoneNumber, authProvider),
                  const SizedBox(height: 16),
                  _buildSectionCard([
                    _buildInfoRow(
                      context,
                      icon: FontAwesomeIcons.userShield,
                      text:
                          'سطح اکانت: ${_userProfile?['account_level'] ?? 'در حال بارگذاری...'}',
                      iconColor: Colors.amber,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Text('حساب کاربری',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _buildSectionCard([
                    _buildProfileItem(
                        context, 'آگهی‌های من', FontAwesomeIcons.list, () {
                      final navPhoneNumber = authProvider.phoneNumber;
                      if (navPhoneNumber != null) {
                        print(
                            'Navigating to MyAdsScreen with phoneNumber: $navPhoneNumber');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MyAdsScreen(phoneNumber: navPhoneNumber),
                          ),
                        );
                      } else {
                        print(
                            'Cannot navigate to MyAdsScreen: phoneNumber is null');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('لطفاً ابتدا وارد شوید')),
                        );
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/auth', (route) => false);
                      }
                    }),
                    _buildProfileItem(
                        context, 'نشان‌ها', FontAwesomeIcons.bookmark, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookmarksScreen(),
                        ),
                      );
                    }),
                    _buildProfileItem(
                        context, 'بازدیدهای اخیر', FontAwesomeIcons.clock, () {
                      // TODO: Navigate to Recent Visits
                    }),
                    _buildProfileItem(
                        context, 'دستگاه‌های فعال', FontAwesomeIcons.mobile,
                        () {
                      // TODO: Navigate to Active Devices
                    }),
                    _buildProfileItem(context, 'تنظیمات', FontAwesomeIcons.gear,
                        () {
                      // TODO: Navigate to Settings
                    }),
                  ]),
                  const SizedBox(height: 24),
                  Text('اطلاعات و پشتیبانی',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _buildSectionCard([
                    _buildProfileItem(context, 'مقابله با مزاحمت و کلاهبرداری',
                        FontAwesomeIcons.shield, () {
                      // TODO: Navigate
                    }),
                    _buildProfileItem(
                        context, 'اتاق خبر', FontAwesomeIcons.newspaper, () {
                      // TODO: Navigate
                    }),
                    _buildProfileItem(
                        context, 'پشتیبانی و قوانین', FontAwesomeIcons.headset,
                        () {
                      // TODO: Navigate
                    }),
                    _buildProfileItem(
                        context, 'درباره دیوار', FontAwesomeIcons.infoCircle,
                        () {
                      // TODO: Navigate
                    }),
                    _buildProfileItem(context, 'پیگیری درخواست‌های پشتیبانی',
                        FontAwesomeIcons.ticket, () {
                      // TODO: Navigate
                    }),
                  ]),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'نسخه 1.0.0',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String phoneNumber, AuthProvider authProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'شما با شماره $phoneNumber وارد شدید.',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                print('Logging out phoneNumber: $phoneNumber');
                await authProvider.logout();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/auth', (route) => false);
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label:
                  const Text('خروج', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildProfileItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_left),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon,
      required String text,
      Color iconColor = Colors.blue}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(text),
    );
  }
}
