import 'package:cached_network_image/cached_network_image.dart';
import 'package:divar_app/models/ad.dart';
import 'package:divar_app/models/comment.dart';
import 'package:divar_app/screens/ad_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/comment_provider.dart';
import '../widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> categories = [
    {'id': null, 'name': 'همه', 'icon': Icons.all_inclusive},
    {'id': 'REAL_ESTATE', 'name': 'املاک', 'icon': Icons.home},
    {'id': 'VEHICLE', 'name': 'وسایل نقلیه', 'icon': Icons.directions_car},
    {'id': 'DIGITAL', 'name': 'لوازم الکترونیکی', 'icon': Icons.devices},
    {'id': 'HOME', 'name': 'لوازم خانگی', 'icon': Icons.kitchen},
    {'id': 'SERVICES', 'name': 'خدمات', 'icon': Icons.build},
    {'id': 'PERSONAL', 'name': 'وسایل شخصی', 'icon': Icons.backpack},
    {
      'id': 'ENTERTAINMENT',
      'name': 'سرگرمی و فراغت',
      'icon': Icons.sports_soccer
    },
  ];

  int _selectedIndex = 0; // Track the selected tab

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('HomeScreen initState: Fetching initial ads');
      final adProvider = Provider.of<AdProvider>(context, listen: false);
      if (adProvider.ads.isEmpty) {
        adProvider.fetchAds(
          provinceId: adProvider.selectedProvinceId,
          cityId: adProvider.selectedCityId,
          adType: adProvider.adType,
        );
      }
      // Fetch user's comments if on comments tab
      if (_selectedIndex == 3) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final commentProvider =
            Provider.of<CommentProvider>(context, listen: false);
        if (authProvider.phoneNumber != null) {
          commentProvider.fetchUserComments(authProvider.phoneNumber!);
        }
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Stay on HomeScreen (Ads List)
        break;
      case 1:
        Navigator.pushNamed(context, '/my_ads');
        break;
      case 2:
        Navigator.pushNamed(context, '/post_ad');
        break;
      case 3:
        // My Comments tab
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final commentProvider =
            Provider.of<CommentProvider>(context, listen: false);
        if (authProvider.phoneNumber == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لطفاً ابتدا وارد شوید')),
          );
          Navigator.pushNamed(context, '/auth');
        } else {
          commentProvider.fetchUserComments(authProvider.phoneNumber!);
        }
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final chipWidth =
        (screenWidth - 32 - 16) / 3; // 32 for padding, 16 for spacing

    return Scaffold(
      appBar: const CustomAppBar(),
      body: _selectedIndex == 3
          ? _buildMyCommentsTab(context)
          : Consumer<AdProvider>(
              builder: (context, adProvider, child) {
                print(
                    'HomeScreen Consumer rebuilt: ads=${adProvider.ads.length}, '
                    'provinceId=${adProvider.selectedProvinceId}, '
                    'cityId=${adProvider.selectedCityId}, '
                    'adType=${adProvider.adType}');
                return Column(
                  children: [
                    // Category Filter
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          final isSelected =
                              adProvider.adType == category['id'];
                          return SizedBox(
                            width: chipWidth,
                            child: ChoiceChip(
                              label: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.red
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      category['icon'],
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        category['name'],
                                        style: TextStyle(
                                          fontFamily: 'Vazir',
                                          fontSize: 12,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.red,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Colors.transparent,
                              backgroundColor: Colors.transparent,
                              showCheckmark: false,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  print('Selected category: ${category['id']}');
                                  adProvider.setFilters(
                                    adType: category['id'] as String?,
                                    provinceId: adProvider.selectedProvinceId,
                                    cityId: adProvider.selectedCityId,
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Ads List
                    Expanded(
                      child: adProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : adProvider.errorMessage != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          size: 64, color: Colors.red),
                                      const SizedBox(height: 16),
                                      Text(
                                        adProvider.errorMessage!,
                                        style: const TextStyle(
                                            fontSize: 16, fontFamily: 'Vazir'),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          adProvider.fetchAds(
                                            provinceId:
                                                adProvider.selectedProvinceId,
                                            cityId: adProvider.selectedCityId,
                                            adType: adProvider.adType,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        child: const Text('تلاش مجدد',
                                            style:
                                                TextStyle(fontFamily: 'Vazir')),
                                      ),
                                    ],
                                  ),
                                )
                              : adProvider.ads.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.inbox,
                                              size: 64, color: Colors.grey),
                                          SizedBox(height: 16),
                                          Text(
                                            'هیچ آگهی یافت نشد',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Vazir',
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: adProvider.ads.length,
                                      itemBuilder: (context, index) {
                                        final ad = adProvider.ads[index];
                                        return Card(
                                          elevation: 4,
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              print(
                                                  'Navigating to AdDetailsScreen for ad: ${ad.adId}');
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const AdDetailsScreen(),
                                                  settings: RouteSettings(
                                                      arguments: ad),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              height: 120,
                                              padding: const EdgeInsets.all(4),
                                              child: Row(
                                                children: [
                                                  // Image (Right)
                                                  Container(
                                                    width: 100,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color: Colors.grey[200],
                                                    ),
                                                    child: ad.imageUrls
                                                            .isNotEmpty
                                                        ? ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            child:
                                                                CachedNetworkImage(
                                                              imageUrl: ad
                                                                  .imageUrls
                                                                  .first,
                                                              fit: BoxFit.cover,
                                                              placeholder: (context,
                                                                      url) =>
                                                                  const Center(
                                                                      child:
                                                                          CircularProgressIndicator()),
                                                              errorWidget:
                                                                  (context, url,
                                                                          error) =>
                                                                      Icon(
                                                                ad.adType ==
                                                                        'REAL_ESTATE'
                                                                    ? Icons.home
                                                                    : Icons
                                                                        .directions_car,
                                                                size: 50,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          )
                                                        : Icon(
                                                            ad.adType ==
                                                                    'REAL_ESTATE'
                                                                ? Icons.home
                                                                : Icons
                                                                    .directions_car,
                                                            size: 50,
                                                            color: Colors.grey,
                                                          ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  // Text Info (Left)
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        // Title
                                                        Flexible(
                                                          child: Text(
                                                            ad.title,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontFamily:
                                                                  'Vazir',
                                                            ),
                                                    
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        // Ad Type
                                                        Text(
                                                          'نوع: ${ad.adType == 'REAL_ESTATE' ? 'املاک' : ad.adType == 'VEHICLE' ? 'خودرو' : 'سایر'}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 10,
                                                            fontFamily: 'Vazir',
                                                          ),
                                                          
                                                        ),
                                                        // Price
                                                        Text(
                                                          _getPriceText(ad),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 10,
                                                            fontFamily: 'Vazir',
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                        // Details and Location
                                                        Flexible(
                                                          child: Text(
                                                            '${_getDetailsText(ad)} | مکان: ${ad.provinceName ?? 'نامشخص'}، ${ad.cityName ?? 'نامشخص'}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 10,
                                                              fontFamily:
                                                                  'Vazir',
                                                            ),
                                                            
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontFamily: 'Vazir', fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontFamily: 'Vazir', fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'خانه',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'آگهی‌های من',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'ثبت آگهی',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.comment),
            label: 'کامنت‌های من',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'پروفایل',
          ),
        ],
      ),
    );
  }

  Widget _buildMyCommentsTab(BuildContext context) {
    return Consumer2<CommentProvider, AdProvider>(
      builder: (context, commentProvider, adProvider, child) {
        if (commentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (commentProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  commentProvider.errorMessage!,
                  style: const TextStyle(fontSize: 16, fontFamily: 'Vazir'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    if (authProvider.phoneNumber != null) {
                      commentProvider
                          .fetchUserComments(authProvider.phoneNumber!);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('تلاش مجدد',
                      style: TextStyle(fontFamily: 'Vazir')),
                ),
              ],
            ),
          );
        }
        if (commentProvider.userComments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.comment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'هنوز کامنتی ثبت نکرده‌اید',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazir',
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: commentProvider.userComments.length,
          itemBuilder: (context, index) {
            final comment = commentProvider.userComments[index];
            final ad = adProvider.getAdById(comment.adId);
            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: ad != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdDetailsScreen(),
                            settings: RouteSettings(arguments: ad),
                          ),
                        );
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Comment Content
                      Text(
                        comment.content,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Vazir',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Ad Title
                      Text(
                        'آگهی: ${ad?.title ?? 'آگهی حذف شده'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Vazir',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Date
                      Text(
                        'تاریخ: ${DateFormat('yyyy-MM-dd HH:mm').format(comment.createdAt)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'Vazir',
                          color: Colors.grey,
                        ),
                      ),
                      // Category
                      Text(
                        'دسته‌بندی: ${ad != null ? _getCategoryName(ad.adType) : 'نامشخص'}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'Vazir',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  String _getPriceText(Ad ad) {
    if (ad.adType == 'REAL_ESTATE') {
      if (ad.realEstateType == 'RENT') {
        final depositText = ad.deposit != null ? '${ad.deposit}' : 'توافقی';
        final rentText = ad.monthlyRent != null ? '${ad.monthlyRent}' : 'توافقی';
        return 'ودیعه: $depositText تومان | اجاره: $rentText تومان';
      } else if (ad.realEstateType == 'SALE' && ad.totalPrice != null) {
        return 'قیمت کل: ${ad.totalPrice} تومان';
      }
      return 'قیمت: توافقی';
    } else if (ad.adType == 'VEHICLE' && ad.price != null) {
      return 'قیمت: ${ad.price} تومان';
    } else if (ad.price != null) {
      return 'قیمت: ${ad.price} تومان';
    }
    return 'قیمت: توافقی';
  }

  String _getDetailsText(Ad ad) {
    if (ad.adType == 'REAL_ESTATE' && ad.area != null) {
      String details = 'متراژ: ${ad.area} متر';
      if (ad.realEstateType != null) {
        details += ' | نوع: ${ad.realEstateType == 'SALE' ? 'فروش' : 'اجاره'}';
      }
      return details;
    } else if (ad.adType == 'VEHICLE' && ad.brand != null && ad.model != null) {
      String details = 'خودرو: ${ad.brand} ${ad.model}';
      if (ad.mileage != null) {
        details += ' | کارکرد: ${ad.mileage} کیلومتر';
      }
      return details;
    }
    return 'جزئیات: نامشخص';
  }

  String _getCategoryName(String? adType) {
    switch (adType) {
      case 'REAL_ESTATE':
        return 'املاک';
      case 'VEHICLE':
        return 'خودرو';
      case 'DIGITAL':
        return 'لوازم الکترونیکی';
      case 'HOME':
        return 'لوازم خانگی';
      case 'SERVICES':
        return 'خدمات';
      case 'PERSONAL':
        return 'وسایل شخصی';
      case 'ENTERTAINMENT':
        return 'سرگرمی و فراغت';
      default:
        return 'سایر';
    }
  }
}