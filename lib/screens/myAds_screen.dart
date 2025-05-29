import 'package:cached_network_image/cached_network_image.dart';
import 'package:divar_app/screens/edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../models/ad.dart';

class MyAdsScreen extends StatefulWidget {
  final String phoneNumber;

  const MyAdsScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _MyAdsScreenState createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  final Map<String, String> _categoryNames = {
    'REAL_ESTATE': 'املاک',
    'VEHICLE': 'وسایل نقلیه',
    'DIGITAL': 'لوازم الکترونیکی',
    'HOME': 'لوازم خانگی',
    'SERVICES': 'خدمات',
    'PERSONAL': 'وسایل شخصی',
    'ENTERTAINMENT': 'سرگرمی و فراغت',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Fetching user ads for MyAdsScreen: ${widget.phoneNumber}');
      Provider.of<AdProvider>(context, listen: false)
          .fetchUserAds(widget.phoneNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('آگهی‌های من', style: TextStyle(fontFamily: 'Vazir')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('Refreshing ads for phoneNumber: ${widget.phoneNumber}');
              Provider.of<AdProvider>(context, listen: false)
                  .fetchUserAds(widget.phoneNumber);
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.red,
      ),
      body: Consumer<AdProvider>(
        builder: (context, adProvider, child) {
          print('Building MyAdsScreen with ${adProvider.userAds.length} ads');
          if (adProvider.isLoading) {
            return _buildLoadingState();
          }
          if (adProvider.errorMessage != null) {
            return _buildErrorState(context, adProvider);
          }
          if (adProvider.userAds.isEmpty) {
            return _buildEmptyState();
          }
          return _buildAdList(context, adProvider.userAds);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 100,
                color: Colors.grey[300],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 150, height: 16, color: Colors.grey[300]),
                    const SizedBox(height: 4),
                    Container(width: 100, height: 14, color: Colors.grey[300]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AdProvider adProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'خطا: ${adProvider.errorMessage}',
            style: const TextStyle(fontSize: 16, fontFamily: 'Vazir'),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              adProvider.fetchUserAds(widget.phoneNumber);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'تلاش مجدد',
              style: TextStyle(fontFamily: 'Vazir', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'هیچ آگهی یافت نشد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Vazir',
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          const Text(
            'آگهی جدیدی اضافه کنید!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: 'Vazir',
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildAdList(BuildContext context, List<Ad> ads) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: ads.length,
      itemBuilder: (context, index) {
        final ad = ads[index];
        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ad.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: ad.imageUrls.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Icon(
                                ad.adType == 'REAL_ESTATE'
                                    ? Icons.home
                                    : ad.adType == 'VEHICLE'
                                        ? Icons.directions_car
                                        : Icons.category,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Icon(
                            ad.adType == 'REAL_ESTATE'
                                ? Icons.home
                                : ad.adType == 'VEHICLE'
                                    ? Icons.directions_car
                                    : Icons.category,
                            size: 50,
                            color: Colors.grey,
                          ),
                  ),
                  const SizedBox(width: 4),
                  // Text Info (Left)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Title
                        Flexible(
                          child: Text(
                            ad.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Vazir',
                            ),
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Ad Type
                        Text(
                          'نوع: ${_categoryNames[ad.adType] ?? 'نامشخص'}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'Vazir',
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        // Price
                        Text(
                          _getPriceText(ad),
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'Vazir',
                            color: Colors.red,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        // Details and Location
                        Flexible(
                          child: Text(
                            '${_getDetailsText(ad)} | مکان: ${ad.provinceName ?? 'نامشخص'}، ${ad.cityName ?? 'نامشخص'}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'Vazir',
                            ),
                            textDirection: RegExp(r'^[a-zA-Z\s]+$')
                                    .hasMatch(ad.provinceName ?? '')
                                ? TextDirection.ltr
                                : TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildActionButton(
                              icon: Icons.edit,
                              color: Colors.blue,
                              onPressed: () {
                                print(
                                    'Navigating to EditAdScreen for ad: ${ad.adId}');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditAdScreen(
                                      ad: ad,
                                      phoneNumber: widget.phoneNumber,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            _buildActionButton(
                              icon: Icons.delete,
                              color: Colors.red,
                              onPressed: () async {
                                print('Initiating delete for ad: ${ad.adId}');
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('حذف آگهی',
                                        style: TextStyle(fontFamily: 'Vazir')),
                                    content: Text(
                                      'آیا مطمئن هستید که می‌خواهید آگهی "${ad.title}" را حذف کنید؟',
                                      style:
                                          const TextStyle(fontFamily: 'Vazir'),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('خیر',
                                            style:
                                                TextStyle(fontFamily: 'Vazir')),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('بله',
                                            style:
                                                TextStyle(fontFamily: 'Vazir')),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  print(
                                      'Deleting ad from MyAdsScreen: ${ad.adId}');
                                  await Provider.of<AdProvider>(context,
                                          listen: false)
                                      .deleteAd(ad.adId, widget.phoneNumber);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'آگهی "${ad.title}" با موفقیت حذف شد',
                                          style: const TextStyle(
                                              fontFamily: 'Vazir'),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
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
    );
  }

  String _getPriceText(Ad ad) {
    if (ad.adType == 'REAL_ESTATE') {
      if (ad.realEstateType == 'RENT') {
        final depositText = ad.deposit != null ? '${ad.deposit}' : 'توافقی';
        final rentText =
            ad.monthlyRent != null ? '${ad.monthlyRent}' : 'توافقی';
        return 'ودیعه: $depositText تومان | اجاره: $rentText تومان';
      } else if (ad.realEstateType == 'SALE' && ad.totalPrice != null) {
        return 'قیمت کل: ${ad.totalPrice} تومان';
      }
      return 'قیمت: توافقی';
    } else if (ad.adType == 'VEHICLE' && ad.basePrice != null) {
      return 'قیمت: ${ad.basePrice} تومان';
    } else if (['DIGITAL', 'HOME', 'PERSONAL', 'ENTERTAINMENT', 'SERVICES']
            .contains(ad.adType) &&
        ad.price != null) {
      return 'قیمت: ${ad.price} تومان';
    }
    return 'قیمت: توافقی';
  }

  String _getDetailsText(Ad ad) {
    if (ad.adType == 'REAL_ESTATE') {
      String details = '';
      if (ad.area != null) {
        details += 'متراژ: ${ad.area} متر';
      }
      if (ad.realEstateType != null) {
        details += details.isNotEmpty ? ' | ' : '';
        details += 'نوع: ${ad.realEstateType == 'SALE' ? 'فروش' : 'اجاره'}';
      }
      if (ad.rooms != null) {
        details += details.isNotEmpty ? ' | ' : '';
        details += 'اتاق: ${ad.rooms}';
      }
      return details.isNotEmpty ? details : 'آگهی: ${ad.title}';
    } else if (ad.adType == 'VEHICLE') {
      String details = '';
      if (ad.brand != null && ad.model != null) {
        details += 'خودرو: ${ad.brand} ${ad.model}';
      } else if (ad.brand != null) {
        details += 'برند: ${ad.brand}';
      } else if (ad.model != null) {
        details += 'مدل: ${ad.model}';
      }
      if (ad.mileage != null) {
        details += details.isNotEmpty ? ' | ' : '';
        details += 'کارکرد: ${ad.mileage} کیلومتر';
      }
      return details.isNotEmpty ? details : 'آگهی: ${ad.title}';
    } else if (['DIGITAL', 'HOME', 'PERSONAL', 'ENTERTAINMENT']
        .contains(ad.adType)) {
      String details = '';
      if (ad.brand != null && ad.model != null) {
        details += 'محصول: ${ad.brand} ${ad.model}';
      } else if (ad.brand != null) {
        details += 'برند: ${ad.brand}';
      } else if (ad.model != null) {
        details += 'مدل: ${ad.model}';
      }
      if (ad.itemCondition != null) {
        details += details.isNotEmpty ? ' | ' : '';
        details += 'وضعیت: ${ad.itemCondition == 'NEW' ? 'نو' : 'کارکرده'}';
      }
      return details.isNotEmpty ? details : 'آگهی: ${ad.title}';
    } else if (ad.adType == 'SERVICES') {
      String details = '';
      if (ad.serviceType != null) {
        details += 'خدمت: ${ad.serviceType}';
      }
      if (ad.serviceDuration != null) {
        details += details.isNotEmpty ? ' | ' : '';
        details += 'مدت: ${ad.serviceDuration}';
      }
      return details.isNotEmpty ? details : 'آگهی: ${ad.title}';
    }
    return 'آگهی: ${ad.title}';
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
