import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../providers/ad_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/comment_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String? _selectedAdType;
  final List<String> _adTypes = [
    'ALL',
    'VEHICLE',
    'REAL_ESTATE',
    'DIGITAL',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      print('initState: Fetching initial data');
      adminProvider.fetchUsersCount(context);
      adminProvider.fetchAdsCount(context, adType: _selectedAdType);
      adminProvider.fetchCommentsCount(context, adType: _selectedAdType);
      adminProvider.fetchTopCommentedAd(context);
      Provider.of<AdProvider>(context, listen: false).fetchAds();
      // Fetch all comments to calculate comment counts
      Provider.of<CommentProvider>(context, listen: false)
          .fetchComments(null, offset: 0);
    });
  }

  // Dialog to display and delete comments
  void _showCommentsDialog(BuildContext context, int adId, String adTitle) {
    // Fetch comments when the dialog is created
    final commentProvider =
        Provider.of<CommentProvider>(context, listen: false);
    print('Opening dialog for adId: $adId, title: $adTitle');
    commentProvider.fetchCommentsByAdId(adId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'کامنت‌های آگهی: $adTitle',
            style: const TextStyle(
                fontFamily: 'Vazir', fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer<CommentProvider>(
              builder: (context, commentProvider, child) {
                if (commentProvider.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.red));
                }
                if (commentProvider.errorMessage != null) {
                  print('Dialog error: ${commentProvider.errorMessage}');
                  return Text(
                    commentProvider.errorMessage!,
                    style:
                        const TextStyle(fontFamily: 'Vazir', color: Colors.red),
                    textDirection: TextDirection.rtl,
                  );
                }
                if (commentProvider.comments.isEmpty) {
                  print('Dialog: No comments found for adId: $adId');
                  return const Text(
                    'هیچ کامنتی یافت نشد',
                    style: TextStyle(fontFamily: 'Vazir', color: Colors.grey),
                    textDirection: TextDirection.rtl,
                  );
                }
                print(
                    'Dialog: Loaded ${commentProvider.comments.length} comments');
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: commentProvider.comments.length,
                  itemBuilder: (context, index) {
                    final comment = commentProvider.comments[index];
                    return ListTile(
                      title: Text(
                        comment.content,
                        style: const TextStyle(fontFamily: 'Vazir'),
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'کاربر: ${comment.userPhoneNumber}',
                        style: const TextStyle(
                            fontFamily: 'Vazir', color: Colors.grey),
                        textDirection: TextDirection.rtl,
                      ),
                      trailing: IconButton(
                        icon: const FaIcon(FontAwesomeIcons.trash,
                            color: Colors.red),
                        onPressed: () async {
                          final adminProvider = Provider.of<AdminProvider>(
                              context,
                              listen: false);
                          final commentProvider = Provider.of<CommentProvider>(
                              context,
                              listen: false);
                          final adProvider =
                              Provider.of<AdProvider>(context, listen: false);

                          final success = await adminProvider.deleteComment(
                              context, comment.commentId);
                          if (success && context.mounted) {
                            // Refresh all relevant data
                            await Future.wait([
                              commentProvider.fetchCommentsByAdId(adId),
                              commentProvider.fetchComments(null, offset: 0),
                              adProvider.fetchAds(),
                              adminProvider.fetchTopCommentedAd(context),
                              adminProvider.fetchCommentsCount(context,
                                  adType: _selectedAdType),
                              adminProvider.fetchAdsCount(context,
                                  adType: _selectedAdType),
                            ]);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'کامنت حذف شد',
                                    style: TextStyle(fontFamily: 'Vazir'),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  adminProvider.errorMessage ?? 'خطا در حذف',
                                  style: const TextStyle(fontFamily: 'Vazir'),
                                  textDirection: TextDirection.rtl,
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'بستن',
                style: TextStyle(fontFamily: 'Vazir', color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Calculate comment count for an ad
  int _getCommentCountForAd(int adId, CommentProvider commentProvider) {
    return commentProvider.comments
        .where((comment) => comment.adId == adId)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('پنل ادمین',
            style: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[700],
        elevation: 0,
        actions: [
          IconButton(
            icon:
                const FaIcon(FontAwesomeIcons.signOutAlt, color: Colors.white),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
          ),
        ],
      ),
      body: Consumer3<AdminProvider, AdProvider, CommentProvider>(
        builder: (context, adminProvider, adProvider, commentProvider, child) {
          if (adminProvider.isLoading || commentProvider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.red));
          }
          if (adminProvider.errorMessage != null) {
            return Center(
              child: Text(
                adminProvider.errorMessage!,
                style: const TextStyle(
                    fontFamily: 'Vazir', fontSize: 16, color: Colors.red),
                textDirection: TextDirection.rtl,
              ),
            );
          }
          if (commentProvider.errorMessage != null) {
            return Center(
              child: Text(
                commentProvider.errorMessage!,
                style: const TextStyle(
                    fontFamily: 'Vazir', fontSize: 16, color: Colors.red),
                textDirection: TextDirection.rtl,
              ),
            );
          }
          final filteredAds =
              _selectedAdType == null || _selectedAdType == 'ALL'
                  ? adProvider.ads
                  : adProvider.ads
                      .where((ad) => ad.adType == _selectedAdType)
                      .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildSummaryCard(
                                title: 'تعداد کاربران',
                                value:
                                    adminProvider.totalUsers?.toString() ?? '0',
                                icon: FontAwesomeIcons.users,
                                color: Colors.red[600]!,
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryCard(
                                title: 'تعداد آگهی‌ها',
                                value: adminProvider.adsCount
                                    .fold<int>(
                                        0,
                                        (sum, item) =>
                                            sum +
                                            ((item['count'] as num?)?.toInt() ??
                                                0))
                                    .toString(),
                                icon: FontAwesomeIcons.ad,
                                color: Colors.blue[600]!,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              _buildSummaryCard(
                                title: 'تعداد کامنت‌ها',
                                value: adminProvider.commentsCount
                                    .fold<int>(
                                        0,
                                        (sum, item) =>
                                            sum +
                                            ((item['count'] as num?)?.toInt() ??
                                                0))
                                    .toString(),
                                icon: FontAwesomeIcons.comments,
                                color: Colors.green[600]!,
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryCard(
                                title: 'آگهی پرنظر',
                                value: adminProvider
                                        .topCommentedAd?['comment_count']
                                        ?.toString() ??
                                    '0',
                                icon: FontAwesomeIcons.star,
                                color: Colors.purple[600]!,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2)
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: _selectedAdType,
                    hint: const Text(
                      'فیلتر نوع آگهی',
                      style: TextStyle(fontFamily: 'Vazir', color: Colors.grey),
                      textDirection: TextDirection.rtl,
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _adTypes.map((type) {
                      return DropdownMenuItem(
                        value: type == 'ALL' ? null : type,
                        child: Text(
                          type == 'ALL' ? 'همه' : _getCategoryName(type),
                          style: const TextStyle(fontFamily: 'Vazir'),
                          textDirection: TextDirection.rtl,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAdType = value;
                      });
                      adminProvider.fetchAdsCount(context, adType: value);
                      adminProvider.fetchCommentsCount(context, adType: value);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'تعداد آگهی‌ها',
                  children: adminProvider.adsCount.isEmpty
                      ? [
                          const Text(
                            'هیچ آگهی‌ای یافت نشد',
                            style: TextStyle(
                                fontFamily: 'Vazir', color: Colors.grey),
                            textDirection: TextDirection.rtl,
                          ),
                        ]
                      : adminProvider.adsCount.map((count) {
                          return ListTile(
                            leading: Icon(FontAwesomeIcons.ad,
                                color: Colors.blue[600]),
                            title: Text(
                              _getCategoryName(count['ad_type']),
                              style: const TextStyle(fontFamily: 'Vazir'),
                              textDirection: TextDirection.rtl,
                            ),
                            trailing: Text(
                              count['count'].toString(),
                              style: const TextStyle(
                                  fontFamily: 'Vazir',
                                  fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'تعداد کامنت‌ها',
                  children: adminProvider.commentsCount.isEmpty
                      ? [
                          const Text(
                            'هیچ کامنتی یافت نشد',
                            style: TextStyle(
                                fontFamily: 'Vazir', color: Colors.grey),
                            textDirection: TextDirection.rtl,
                          ),
                        ]
                      : adminProvider.commentsCount.map((count) {
                          return ListTile(
                            leading: Icon(FontAwesomeIcons.comments,
                                color: Colors.green[600]),
                            title: Text(
                              _getCategoryName(count['ad_type']),
                              style: const TextStyle(fontFamily: 'Vazir'),
                              textDirection: TextDirection.rtl,
                            ),
                            trailing: Text(
                              count['count'].toString(),
                              style: const TextStyle(
                                  fontFamily: 'Vazir',
                                  fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'آگهی با بیشترین کامنت',
                  children: [
                    if (adminProvider.topCommentedAd != null &&
                        adminProvider.topCommentedAd!.isNotEmpty)
                      ListTile(
                        leading: Icon(FontAwesomeIcons.star,
                            color: Colors.purple[600]),
                        title: Text(
                          adminProvider.topCommentedAd!['title'] ?? 'نامشخص',
                          style: const TextStyle(fontFamily: 'Vazir'),
                          textDirection: TextDirection.rtl,
                        ),
                        subtitle: Text(
                          'تعداد کامنت: ${adminProvider.topCommentedAd!['comment_count']}',
                          style: const TextStyle(
                              fontFamily: 'Vazir', color: Colors.grey),
                          textDirection: TextDirection.rtl,
                        ),
                      )
                    else
                      const Text(
                        'هیچ آگهی‌ای یافت نشد',
                        style:
                            TextStyle(fontFamily: 'Vazir', color: Colors.grey),
                        textDirection: TextDirection.rtl,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'حذف آگهی‌ها',
                  children: filteredAds.isEmpty
                      ? [
                          const Text(
                            'هیچ آگهی‌ای یافت نشد',
                            style: TextStyle(
                                fontFamily: 'Vazir', color: Colors.grey),
                            textDirection: TextDirection.rtl,
                          ),
                        ]
                      : filteredAds.map((ad) {
                          return ListTile(
                            leading:
                                const Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              ad.title,
                              style: const TextStyle(fontFamily: 'Vazir'),
                              textDirection: TextDirection.rtl,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _getCategoryName(ad.adType),
                                  style: const TextStyle(
                                      fontFamily: 'Vazir', color: Colors.grey),
                                  textDirection: TextDirection.rtl,
                                ),
                                Text(
                                  'تعداد کامنت‌ها: ${_getCommentCountForAd(ad.adId, commentProvider)}',
                                  style: const TextStyle(
                                      fontFamily: 'Vazir', color: Colors.grey),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const FaIcon(FontAwesomeIcons.trash,
                                  color: Colors.red),
                              onPressed: () async {
                                final adminProvider =
                                    Provider.of<AdminProvider>(context,
                                        listen: false);
                                final commentProvider =
                                    Provider.of<CommentProvider>(context,
                                        listen: false);
                                final adProvider = Provider.of<AdProvider>(
                                    context,
                                    listen: false);

                                final success = await adminProvider.deleteAd(
                                    context, ad.adId);
                                if (success && context.mounted) {
                                  // Refresh all relevant data
                                  await Future.wait([
                                    adProvider.fetchAds(),
                                    commentProvider.fetchComments(null,
                                        offset: 0),
                                    adminProvider.fetchTopCommentedAd(context),
                                    adminProvider.fetchAdsCount(context,
                                        adType: _selectedAdType),
                                    adminProvider.fetchCommentsCount(context,
                                        adType: _selectedAdType),
                                  ]);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'آگهی حذف شد',
                                          style: TextStyle(fontFamily: 'Vazir'),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        adminProvider.errorMessage ??
                                            'خطا در حذف',
                                        style: const TextStyle(
                                            fontFamily: 'Vazir'),
                                        textDirection: TextDirection.rtl,
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                            onTap: () {
                              // _showCommentsDialog(context, ad.adId, ad.title);
                            },
                          );
                        }).toList(),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'حذف کامنت‌ها',
                  children: [
                    if (commentProvider.isLoading)
                      const Center(
                          child: CircularProgressIndicator(color: Colors.red))
                    else if (commentProvider.errorMessage != null)
                      Text(
                        commentProvider.errorMessage!,
                        style: const TextStyle(
                            fontFamily: 'Vazir', color: Colors.red),
                        textDirection: TextDirection.rtl,
                      )
                    else if (commentProvider.comments.isEmpty)
                      const Text(
                        'هیچ کامنتی یافت نشد',
                        style:
                            TextStyle(fontFamily: 'Vazir', color: Colors.grey),
                        textDirection: TextDirection.rtl,
                      )
                    else
                      ...commentProvider.comments.map((comment) {
                        final ad = adProvider.getAdById(comment.adId);
                        return ListTile(
                          leading:
                              const Icon(Icons.comment, color: Colors.blue),
                          title: Text(
                            comment.content,
                            style: const TextStyle(fontFamily: 'Vazir'),
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'آگهی: ${ad?.title ?? 'آگهی حذف شده'}',
                            style: const TextStyle(
                                fontFamily: 'Vazir', color: Colors.grey),
                            textDirection: TextDirection.rtl,
                          ),
                          trailing: IconButton(
                            icon: const FaIcon(FontAwesomeIcons.trash,
                                color: Colors.red),
                            onPressed: () async {
                              final adminProvider = Provider.of<AdminProvider>(
                                  context,
                                  listen: false);
                              final commentProvider =
                                  Provider.of<CommentProvider>(context,
                                      listen: false);
                              final adProvider = Provider.of<AdProvider>(
                                  context,
                                  listen: false);

                              final success = await adminProvider.deleteComment(
                                  context, comment.commentId);
                              if (success && context.mounted) {
                                // Refresh all relevant data
                                await Future.wait([
                                  commentProvider.fetchComments(null,
                                      offset: 0),
                                  adProvider.fetchAds(),
                                  adminProvider.fetchTopCommentedAd(context),
                                  adminProvider.fetchCommentsCount(context,
                                      adType: _selectedAdType),
                                  adminProvider.fetchAdsCount(context,
                                      adType: _selectedAdType),
                                ]);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'کامنت حذف شد',
                                        style: TextStyle(fontFamily: 'Vazir'),
                                        textDirection: TextDirection.rtl,
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      adminProvider.errorMessage ??
                                          'خطا در حذف',
                                      style:
                                          const TextStyle(fontFamily: 'Vazir'),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 1)
        ],
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
                fontFamily: 'Vazir', fontSize: 12, fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2)
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Vazir',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }

  String _getCategoryName(String adType) {
    switch (adType) {
      case 'VEHICLE':
        return 'خودرو';
      case 'REAL_ESTATE':
        return 'املاک';
      case 'DIGITAL':
        return 'لوازم الکترونیکی';
      case 'OTHER':
        return 'سایر';
      default:
        return 'ناشناخته';
    }
  }
}
