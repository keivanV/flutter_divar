import 'package:divar_app/models/ad.dart';
import 'package:divar_app/models/comment.dart';
import 'package:divar_app/screens/ad_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/comment_provider.dart';

class MyCommentsScreen extends StatefulWidget {
  final String phoneNumber;

  const MyCommentsScreen({super.key, required this.phoneNumber});

  @override
  _MyCommentsScreenState createState() => _MyCommentsScreenState();
}

class _MyCommentsScreenState extends State<MyCommentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final commentProvider = Provider.of<CommentProvider>(context, listen: false);
      final adProvider = Provider.of<AdProvider>(context, listen: false);
      print('Fetching comments for phoneNumber: ${widget.phoneNumber}');
      commentProvider.fetchUserComments(widget.phoneNumber).then((_) {
        // استخراج adIds از کامنت‌ها
        final adIds = commentProvider.userComments
            .map((comment) => comment.adId)
            .toSet()
            .toList();
        if (adIds.isNotEmpty) {
          print('Fetching ads for adIds: $adIds');
          adProvider.fetchCommentRelatedAds(adIds);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کامنت‌های من'),
      ),
      body: Consumer2<CommentProvider, AdProvider>(
        builder: (context, commentProvider, adProvider, child) {
          if (commentProvider.isLoading || adProvider.isLoading) {
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
                            .fetchUserComments(authProvider.phoneNumber!)
                            .then((_) {
                          final adIds = commentProvider.userComments
                              .map((comment) => comment.adId)
                              .toSet()
                              .toList();
                          if (adIds.isNotEmpty) {
                            print('Retrying fetch ads for adIds: $adIds');
                            adProvider.fetchCommentRelatedAds(adIds);
                          }
                        });
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
              final ad = adProvider.getAdById(comment.adId) ??
                  Ad(
                    adId: comment.adId,
                    title: 'آگهی حذف شده',
                    description: '',
                    adType: '',
                    price: 0,
                    provinceId: 0,
                    cityId: 0,
                    ownerPhoneNumber: '',
                    createdAt: DateTime.now(), status: '', imageUrls: [],
                  );
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: ad.title != 'آگهی حذف شده'
                      ? () {
                          print(
                              'Navigating to AdDetailsScreen for ad: ${ad.adId}');
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
                          'آگهی: ${ad.title}',
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
                          'دسته‌بندی: ${_getCategoryName(ad.adType)}',
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
      ),
    );
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