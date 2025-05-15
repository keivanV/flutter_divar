import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/ad.dart';
import '../providers/auth_provider.dart';
import '../providers/bookmark_provider.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  _BookmarksScreenState createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final phoneNumber = authProvider.phoneNumber;
      if (phoneNumber != null) {
        print('Fetching bookmarks for BookmarksScreen: $phoneNumber');
        Provider.of<BookmarkProvider>(context, listen: false)
            .fetchBookmarks(phoneNumber)
            .then((_) {
          // Ensure bookmarks are synced for AdDetailsScreen
          final ad = ModalRoute.of(context)?.settings.arguments as Ad?;
          if (ad != null && ad.adId != null) {
            Provider.of<BookmarkProvider>(context, listen: false)
                .isBookmarked(phoneNumber, ad.adId!)
                .then((isBookmarked) {
              if (mounted) {
                setState(() {});
              }
            });
          }
        });
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    });
  }

  Future<void> _removeBookmark(Ad ad) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookmarkProvider =
        Provider.of<BookmarkProvider>(context, listen: false);
    if (ad.bookmarkId == null || authProvider.phoneNumber == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف نشان'),
        content: Text(
            'آیا مطمئن هستید که می‌خواهید "${ad.title}" را از نشان‌ها حذف کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('خیر'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('بله'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await bookmarkProvider.removeBookmark(ad.bookmarkId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${ad.title}" از نشان‌ها حذف شد')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا در حذف نشان: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final phoneNumber = authProvider.phoneNumber;

    if (phoneNumber == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('نشان‌شده‌ها'),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, bookmarkProvider, child) {
          if (bookmarkProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (bookmarkProvider.errorMessage != null) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('خطا: ${bookmarkProvider.errorMessage}'),
            );
          }
          if (bookmarkProvider.bookmarkedAds.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'هیچ آگهی نشان‌شده‌ای یافت نشد',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarkProvider.bookmarkedAds.length,
            itemBuilder: (context, index) {
              final ad = bookmarkProvider.bookmarkedAds[index];
              final numberFormatter = NumberFormat('#,###', 'fa_IR');
              final formattedPrice = ad.adType == 'VEHICLE'
                  ? (ad.basePrice != null && ad.basePrice! > 0
                      ? '${numberFormatter.format(ad.basePrice!)} تومان'
                      : 'قیمت توافقی')
                  : (ad.totalPrice != null && ad.totalPrice! > 0
                      ? '${numberFormatter.format(ad.totalPrice!)} تومان'
                      : ad.price != null && ad.price! > 0
                          ? '${numberFormatter.format(ad.price!)} تومان'
                          : 'قیمت توافقی');

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/ad_details',
                      arguments: ad,
                    );
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12)),
                        child: ad.imageUrls.isNotEmpty
                            ? Image.network(
                                ad.imageUrls[0],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedPrice,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${ad.provinceName ?? 'نامشخص'}، ${ad.cityName ?? 'نامشخص'}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeBookmark(ad),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
