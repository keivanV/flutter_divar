import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:divar_app/models/ad.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../screens/ad_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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

  int _selectedIndex = 0;
  AnimationController? _cardAnimationController;
  AnimationController? _textAnimationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _blinkAnimation;
  Animation<Color?>? _colorAnimation;
  int? _promoAdIndex;

  @override
  void initState() {
    super.initState();
    // Initialize card animation controller for promotional ad
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController!, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _cardAnimationController!, curve: Curves.easeOut),
    );
    _cardAnimationController!.forward();

    // Initialize text animation controller for blinking and color change
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
          parent: _textAnimationController!, curve: Curves.easeInOut),
    );
    _colorAnimation = ColorTweenSequence([
      ColorTweenSequenceItem(
        tween: ColorTween(begin: Colors.white, end: Colors.yellow),
        weight: 0.5,
      ),
      ColorTweenSequenceItem(
        tween: ColorTween(begin: Colors.yellow, end: Colors.red),
        weight: 0.25,
      ),
      ColorTweenSequenceItem(
        tween: ColorTween(begin: Colors.red, end: Colors.white),
        weight: 0.25,
      ),
    ]).animate(_textAnimationController!);

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
      // Set random index for promotional ad
      setState(() {
        _promoAdIndex = Random().nextInt(adProvider.ads.length + 1);
      });
    });
  }

  @override
  void dispose() {
    _cardAnimationController?.dispose();
    _textAnimationController?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, '/my_ads');
        break;
      case 2:
        Navigator.pushNamed(context, '/post_ad');
        break;
      case 3:
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
      body: Consumer<AdProvider>(
        builder: (context, adProvider, child) {
          print('HomeScreen Consumer rebuilt: ads=${adProvider.ads.length}, '
              'provinceId=${adProvider.selectedProvinceId}, '
              'cityId=${adProvider.selectedCityId}, '
              'adType=${adProvider.adType}');
          // Update promo ad index when ads list changes
          if (_promoAdIndex == null || _promoAdIndex! > adProvider.ads.length) {
            _promoAdIndex = Random().nextInt(adProvider.ads.length + 1);
          }
          return Column(
            children: [
              // Category Filter
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    final isSelected = adProvider.adType == category['id'];
                    return SizedBox(
                      width: chipWidth,
                      child: ChoiceChip(
                        label: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.red : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category['icon'],
                                size: 16,
                                color: isSelected ? Colors.white : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  category['name'],
                                  style: TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 12,
                                    color:
                                        isSelected ? Colors.white : Colors.red,
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
                                      provinceId: adProvider.selectedProvinceId,
                                      cityId: adProvider.selectedCityId,
                                      adType: adProvider.adType,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text('تلاش مجدد',
                                      style: TextStyle(fontFamily: 'Vazir')),
                                ),
                              ],
                            ),
                          )
                        : adProvider.ads.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                itemCount: adProvider.ads.length +
                                    1, // +1 for promo ad
                                itemBuilder: (context, index) {
                                  if (index == _promoAdIndex) {
                                    // Promotional Ad
                                    if (_fadeAnimation == null ||
                                        _slideAnimation == null ||
                                        _blinkAnimation == null ||
                                        _colorAnimation == null) {
                                      return const SizedBox
                                          .shrink(); // Skip rendering if animations not ready
                                    }
                                    return FadeTransition(
                                      opacity: _fadeAnimation!,
                                      child: SlideTransition(
                                        position: _slideAnimation!,
                                        child: Card(
                                          elevation: 4,
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            side: const BorderSide(
                                                color: Colors.redAccent,
                                                width: 2),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              print('Tapped on promotional ad');
                                              // Placeholder for future navigation or action
                                            },
                                            child: Container(
                                              height: 120,
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Colors.redAccent,
                                                    Colors.orangeAccent
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
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
                                                      color: Colors.white,
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: CachedNetworkImage(
                                                        imageUrl:
                                                            'https://via.placeholder.com/100',
                                                        fit: BoxFit.cover,
                                                        placeholder: (context,
                                                                url) =>
                                                            const Center(
                                                                child:
                                                                    CircularProgressIndicator()),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            const Icon(
                                                          Icons.star,
                                                          size: 50,
                                                          color: Colors.yellow,
                                                        ),
                                                      ),
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
                                                        // Title with color change
                                                        Flexible(
                                                          child:
                                                              AnimatedBuilder(
                                                            animation:
                                                                _colorAnimation!,
                                                            builder: (context,
                                                                child) {
                                                              return Text(
                                                                'آگهی تبلیغاتی ویژه',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontFamily:
                                                                      'Vazir',
                                                                  color:
                                                                      _colorAnimation!
                                                                          .value,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        // Ad Type
                                                        const Text(
                                                          'نوع: تبلیغ',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontFamily: 'Vazir',
                                                            color:
                                                                Colors.white70,
                                                          ),
                                                        ),
                                                        // Price with blinking
                                                        AnimatedBuilder(
                                                          animation:
                                                              _blinkAnimation!,
                                                          builder:
                                                              (context, child) {
                                                            return Opacity(
                                                              opacity:
                                                                  _blinkAnimation!
                                                                      .value,
                                                              child: const Text(
                                                                'پیشنهاد ویژه!',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 10,
                                                                  fontFamily:
                                                                      'Vazir',
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        // Details and Location
                                                        const Flexible(
                                                          child: Text(
                                                            'جزئیات: پیشنهادات شگفت‌انگیز | مکان: سراسر ایران',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontFamily:
                                                                  'Vazir',
                                                              color: Colors
                                                                  .white70,
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
                                        ),
                                      ),
                                    );
                                  }
                                  // Regular Ads
                                  final adIndex = index < _promoAdIndex!
                                      ? index
                                      : index - 1;
                                  final ad = adProvider.ads[adIndex];
                                  return Card(
                                    elevation: 4,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                            settings:
                                                RouteSettings(arguments: ad),
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
                                                    BorderRadius.circular(8),
                                                color: Colors.grey[200],
                                              ),
                                              child: ad.imageUrls.isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: CachedNetworkImage(
                                                        imageUrl:
                                                            ad.imageUrls.first,
                                                        fit: BoxFit.cover,
                                                        placeholder: (context,
                                                                url) =>
                                                            const Center(
                                                                child:
                                                                    CircularProgressIndicator()),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Icon(
                                                          _getIconForAdType(
                                                              ad.adType),
                                                          size: 50,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    )
                                                  : Icon(
                                                      _getIconForAdType(
                                                          ad.adType),
                                                      size: 50,
                                                      color: Colors.grey,
                                                    ),
                                            ),
                                            const SizedBox(width: 4),
                                            // Text Info (Left)
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  // Title
                                                  Flexible(
                                                    child: Text(
                                                      ad.title,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Vazir',
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  // Ad Type
                                                  Text(
                                                    'نوع: ${_getCategoryName(ad.adType)}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontFamily: 'Vazir',
                                                    ),
                                                  ),
                                                  // Price
                                                  Text(
                                                    _getPriceText(ad),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontFamily: 'Vazir',
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  // Details and Location
                                                  Flexible(
                                                    child: Text(
                                                      '${_getDetailsText(ad)} | مکان: ${ad.provinceName ?? 'نامشخص'}، ${ad.cityName ?? 'نامشخص'}',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontFamily: 'Vazir',
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
            icon: Icon(Icons.person),
            label: 'پروفایل',
          ),
        ],
      ),
    );
  }

  String _getPriceText(Ad ad) {
    final numberFormatter = NumberFormat('#,###', 'fa_IR');
    if (ad.adType == 'REAL_ESTATE') {
      if (ad.realEstateType == 'RENT') {
        final depositText = ad.deposit != null
            ? '${numberFormatter.format(ad.deposit)}'
            : 'توافقی';
        final rentText = ad.monthlyRent != null
            ? '${numberFormatter.format(ad.monthlyRent)}'
            : 'توافقی';
        return 'ودیعه: $depositText تومان | اجاره: $rentText تومان';
      } else if (ad.realEstateType == 'SALE' && ad.totalPrice != null) {
        return 'قیمت کل: ${numberFormatter.format(ad.totalPrice)} تومان';
      }
      return 'قیمت: توافقی';
    } else if (ad.adType == 'VEHICLE' && ad.basePrice != null) {
      return 'قیمت: ${numberFormatter.format(ad.basePrice)} تومان';
    } else if (ad.adType == 'SERVICES' && ad.price != null) {
      return 'هزینه: ${numberFormatter.format(ad.price)} تومان';
    } else if (ad.price != null) {
      return 'قیمت: ${numberFormatter.format(ad.price)} تومان';
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
    } else if (['DIGITAL', 'HOME', 'PERSONAL', 'ENTERTAINMENT']
        .contains(ad.adType)) {
      String details = '';
      if (ad.brand != null && ad.model != null) {
        details += 'محصول: ${ad.brand} ${ad.model}';
      } else if (ad.brand != null) {
        details += 'برند: ${ad.brand}';
      }
      return details.isNotEmpty ? details : 'جزئیات: نامشخص';
    } else if (ad.adType == 'SERVICES') {
      return ad.description.isNotEmpty
          ? 'توضیحات: ${ad.description}'
          : 'جزئیات: نامشخص';
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

  IconData _getIconForAdType(String adType) {
    switch (adType) {
      case 'REAL_ESTATE':
        return Icons.home;
      case 'VEHICLE':
        return Icons.directions_car;
      case 'DIGITAL':
        return Icons.devices;
      case 'HOME':
        return Icons.kitchen;
      case 'SERVICES':
        return Icons.build;
      case 'PERSONAL':
        return Icons.backpack;
      case 'ENTERTAINMENT':
        return Icons.sports_soccer;
      default:
        return Icons.category;
    }
  }
}

// Helper class for ColorTweenSequence
class ColorTweenSequence extends TweenSequence<Color?> {
  ColorTweenSequence(List<ColorTweenSequenceItem> items) : super(items);
}

class ColorTweenSequenceItem extends TweenSequenceItem<Color?> {
  ColorTweenSequenceItem({
    required ColorTween tween,
    required double weight,
  }) : super(tween: tween, weight: weight);
}
