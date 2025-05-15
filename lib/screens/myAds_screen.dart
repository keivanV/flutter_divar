import 'package:cached_network_image/cached_network_image.dart';
import 'package:divar_app/screens/edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
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
        title: const Text('آگهی‌های من'),
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
        backgroundColor: Theme.of(context).primaryColor,
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
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 100,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Container(width: 200, height: 20, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Container(width: 100, height: 16, color: Colors.grey[300]),
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
          Text('خطا: ${adProvider.errorMessage}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              adProvider.fetchUserAds(widget.phoneNumber);
            },
            child: const Text('تلاش مجدد'),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'آگهی جدیدی اضافه کنید!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAdList(BuildContext context, List<Ad> ads) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ads.length,
      itemBuilder: (context, index) {
        final ad = ads[index];
        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCarousel(ad),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ad.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'نوع: ${ad.adType == 'REAL_ESTATE' ? 'املاک' : 'خودرو'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (ad.price != null)
                        Text(
                          'قیمت: ${ad.price!.toStringAsFixed(0)} تومان',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
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
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.delete,
                            color: Colors.red,
                            onPressed: () async {
                              print('Initiating delete for ad: ${ad.adId}');
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('حذف آگهی'),
                                  content: Text(
                                      'آیا مطمئن هستید که می‌خواهید آگهی "${ad.title}" را حذف کنید؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('خیر'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('بله'),
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
                                          'آگهی "${ad.title}" با موفقیت حذف شد'),
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
        );
      },
    );
  }

  Widget _buildImageCarousel(Ad ad) {
    return ad.imageUrls.isNotEmpty
        ? SizedBox(
            height: 200,
            child: Swiper(
              autoplay: ad.imageUrls.length > 1,
              itemCount: ad.imageUrls.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: ad.imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Icon(
                    ad.adType == 'REAL_ESTATE'
                        ? Icons.home
                        : Icons.directions_car,
                    size: 100,
                    color: Colors.grey,
                  ),
                );
              },
              pagination: const SwiperPagination(
                alignment: Alignment.bottomCenter,
                builder: DotSwiperPaginationBuilder(
                  activeColor: Colors.blue,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : Container(
            height: 200,
            color: Colors.grey[200],
            child: Icon(
              ad.adType == 'REAL_ESTATE' ? Icons.home : Icons.directions_car,
              size: 100,
              color: Colors.grey,
            ),
          );
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
