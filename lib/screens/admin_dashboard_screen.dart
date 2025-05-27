import 'package:divar_app/models/ad.dart';
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
    'REAL_ESTATE',
    'VEHICLE',
    'DIGITAL',
    'HOME',
    'SERVICES',
    'PERSONAL',
    'ENTERTAINMENT',
  ];
  int _displayLimit = 20; // Initial number of ads to display
  bool _isLoadingMore = false;
  bool _isFetchingAds = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.fetchUsersCount(context);
      adminProvider.fetchAdsCount(context, adType: _selectedAdType);
      adminProvider.fetchCommentsCount(context, adType: _selectedAdType);
      adminProvider.fetchTopCommentedAd(context);

      final adProvider = Provider.of<AdProvider>(context, listen: false);
      final commentProvider =
          Provider.of<CommentProvider>(context, listen: false);
      print('Fetching all ads with no filters...');
      adProvider
          .fetchAds(adType: null, provinceId: null, cityId: null, sortBy: null)
          .then((_) {
        print('Initial ads fetched: ${adProvider.ads.length}');
        final adTypes = adProvider.ads.map((ad) => ad.adType).toSet();
        print('Initial ad types: $adTypes');
      });
      commentProvider.fetchComments(null, offset: 0).then((_) {
        final adIds = commentProvider.comments
            .map((comment) => comment.adId)
            .toSet()
            .toList();
        print('Fetching ads for ${adIds.length} commented ad IDs...');
        for (var adId in adIds) {
          adProvider.fetchAdById(adId);
        }
      });
    });
  }

  // Dialog to display and delete comments
  void _showCommentsDialog(BuildContext context, int adId, String adTitle) {
    if (adId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'شناسه آگهی نامعتبر است',
            style: TextStyle(fontFamily: 'Vazir'),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    print('Opening comments dialog for adId: $adId');
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
                commentProvider.fetchCommentsByAdId(adId);
                if (commentProvider.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.red));
                }
                if (commentProvider.errorMessage != null) {
                  return Text(
                    commentProvider.errorMessage!,
                    style:
                        const TextStyle(fontFamily: 'Vazir', color: Colors.red),
                    textDirection: TextDirection.rtl,
                  );
                }
                if (commentProvider.comments.isEmpty) {
                  return const Text(
                    'هیچ کامنتی یافت نشد',
                    style: TextStyle(fontFamily: 'Vazir', color: Colors.grey),
                    textDirection: TextDirection.rtl,
                  );
                }
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
                          if (success) {
                            await Future.wait([
                              commentProvider.fetchCommentsByAdId(adId),
                              commentProvider.fetchComments(null, offset: 0),
                              adProvider.fetchAds(
                                  adType: _selectedAdType,
                                  provinceId: null,
                                  cityId: null,
                                  sortBy: null),
                              adminProvider.fetchTopCommentedAd(context),
                              adminProvider.fetchCommentsCount(context,
                                  adType: _selectedAdType),
                              adminProvider.fetchAdsCount(context,
                                  adType: _selectedAdType),
                            ]);
                            final adIds = commentProvider.comments
                                .map((c) => c.adId)
                                .toSet()
                                .toList();
                            for (var adId in adIds) {
                              adProvider.fetchAdById(adId);
                            }
                            if (mounted) {
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
                          } else {
                            if (mounted) {
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

  void _loadMoreAds() {
    setState(() {
      _displayLimit += 20;
      print('Loading more ads, new limit: $_displayLimit');
    });
  }

  void _refreshAllAds() async {
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    setState(() {
      _displayLimit = 20;
      _selectedAdType = null;
      _isFetchingAds = true;
      print('Refreshing all ads...');
    });
    await adProvider.fetchAds(
        adType: null, provinceId: null, cityId: null, sortBy: null);
    setState(() {
      _isFetchingAds = false;
    });
    print('Ads refreshed: ${adProvider.ads.length}');
    final adTypes = adProvider.ads.map((ad) => ad.adType).toSet();
    print('Ad types after refresh: $adTypes');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لیست آگهی‌ها به‌روزرسانی شد',
            style: TextStyle(fontFamily: 'Vazir'),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
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
          if (adminProvider.isLoading ||
              adProvider.isLoading ||
              _isFetchingAds) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.red));
          }
          if (adminProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    adminProvider.errorMessage!,
                    style: const TextStyle(
                        fontFamily: 'Vazir', fontSize: 16, color: Colors.red),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshAllAds,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'تلاش مجدد',
                      style: TextStyle(fontFamily: 'Vazir'),
                    ),
                  ),
                ],
              ),
            );
          }
          if (adProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    adProvider.errorMessage!,
                    style: const TextStyle(
                        fontFamily: 'Vazir', fontSize: 16, color: Colors.red),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshAllAds,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'تلاش مجدد',
                      style: TextStyle(fontFamily: 'Vazir'),
                    ),
                  ),
                ],
              ),
            );
          }
          final filteredAds = _selectedAdType == null ||
                  _selectedAdType == 'ALL'
              ? adProvider.ads
              : adProvider.ads
                  .where((ad) =>
                      ad.adType == _selectedAdType ||
                      (ad.adType == 'SERVICE' && _selectedAdType == 'SERVICES'))
                  .toList();
          print('Total ads available: ${adProvider.ads.length}');
          print(
              'Filtered ads for ${_selectedAdType ?? 'ALL'}: ${filteredAds.length}');
          final adTypes = adProvider.ads.map((ad) => ad.adType).toSet();
          print('Ad types in list: $adTypes');

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
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
                            style: TextStyle(
                                fontFamily: 'Vazir', color: Colors.grey),
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
                          onChanged: (value) async {
                            setState(() {
                              _selectedAdType = value;
                              _displayLimit = 20;
                              _isFetchingAds = true;
                              print('Filter changed to: $value');
                            });
                            final adProvider =
                                Provider.of<AdProvider>(context, listen: false);
                            await adProvider.fetchAds(
                                adType: value,
                                provinceId: null,
                                cityId: null,
                                sortBy: null);
                            adminProvider.fetchAdsCount(context, adType: value);
                            adminProvider.fetchCommentsCount(context,
                                adType: value);
                            setState(() {
                              _isFetchingAds = false;
                            });
                            print(
                                'Ads fetched for $value: ${adProvider.ads.length}');
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _refreshAllAds,
                      icon: const FaIcon(FontAwesomeIcons.sync, size: 16),
                      label: const Text(
                        'نمایش همه آگهی‌ها',
                        style: TextStyle(fontFamily: 'Vazir'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
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
                  children: [
                    if (filteredAds.isEmpty)
                      Column(
                        children: [
                          const Text(
                            'هیچ آگهی‌ای یافت نشد',
                            style: TextStyle(
                                fontFamily: 'Vazir', color: Colors.grey),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _isFetchingAds = true;
                              });
                              await Provider.of<AdProvider>(context,
                                      listen: false)
                                  .fetchAds(
                                      adType: _selectedAdType,
                                      provinceId: null,
                                      cityId: null,
                                      sortBy: null);
                              setState(() {
                                _isFetchingAds = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'تلاش مجدد برای بارگذاری آگهی‌ها',
                              style: TextStyle(fontFamily: 'Vazir'),
                            ),
                          ),
                        ],
                      )
                    else
                      ...filteredAds.take(_displayLimit).map((ad) {
                        return ListTile(
                          leading: Icon(FontAwesomeIcons.ad,
                              color: Colors.blue[600]),
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
                              final adminProvider = Provider.of<AdminProvider>(
                                  context,
                                  listen: false);
                              final commentProvider =
                                  Provider.of<CommentProvider>(context,
                                      listen: false);
                              final adProvider = Provider.of<AdProvider>(
                                  context,
                                  listen: false);

                              final success = await adminProvider.deleteAd(
                                  context, ad.adId);
                              if (success) {
                                await Future.wait([
                                  adProvider.fetchAds(
                                      adType: _selectedAdType,
                                      provinceId: null,
                                      cityId: null,
                                      sortBy: null),
                                  commentProvider.fetchComments(null,
                                      offset: 0),
                                  adminProvider.fetchTopCommentedAd(context),
                                  adminProvider.fetchAdsCount(context,
                                      adType: _selectedAdType),
                                  adminProvider.fetchCommentsCount(context,
                                      adType: _selectedAdType),
                                ]);
                                final adIds = commentProvider.comments
                                    .map((c) => c.adId)
                                    .toSet()
                                    .toList();
                                for (var adId in adIds) {
                                  adProvider.fetchAdById(adId);
                                }
                                if (mounted) {
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
                              } else {
                                if (mounted) {
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
                              }
                            },
                          ),
                          onTap: () {
                            _showCommentsDialog(context, ad.adId, ad.title);
                          },
                        );
                      }).toList(),
                    if (filteredAds.length > _displayLimit)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: _isLoadingMore
                              ? const CircularProgressIndicator(
                                  color: Colors.red)
                              : ElevatedButton(
                                  onPressed: _loadMoreAds,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[700],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text(
                                    'نمایش آگهی‌های بیشتر',
                                    style: TextStyle(fontFamily: 'Vazir'),
                                  ),
                                ),
                        ),
                      ),
                  ],
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
                          subtitle: FutureBuilder(
                            future: ad == null
                                ? Provider.of<AdProvider>(context,
                                        listen: false)
                                    .fetchAdById(comment.adId)
                                : Future.value(ad),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text(
                                  'در حال بارگذاری...',
                                  style: TextStyle(
                                      fontFamily: 'Vazir', color: Colors.grey),
                                  textDirection: TextDirection.rtl,
                                );
                              }
                              final fetchedAd = snapshot.data as Ad?;
                              return Text(
                                'آگهی: ${fetchedAd?.title ?? 'آگهی حذف شده یا یافت نشد'}',
                                style: const TextStyle(
                                    fontFamily: 'Vazir', color: Colors.grey),
                                textDirection: TextDirection.rtl,
                              );
                            },
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
                              if (success) {
                                await Future.wait([
                                  commentProvider.fetchComments(null,
                                      offset: 0),
                                  adProvider.fetchAds(
                                      adType: _selectedAdType,
                                      provinceId: null,
                                      cityId: null,
                                      sortBy: null),
                                  adminProvider.fetchTopCommentedAd(context),
                                  adminProvider.fetchCommentsCount(context,
                                      adType: _selectedAdType),
                                  adminProvider.fetchAdsCount(context,
                                      adType: _selectedAdType),
                                ]);
                                final adIds = commentProvider.comments
                                    .map((c) => c.adId)
                                    .toSet()
                                    .toList();
                                for (var adId in adIds) {
                                  adProvider.fetchAdById(adId);
                                }
                                if (mounted) {
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
                              } else {
                                if (mounted) {
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

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
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
      case 'SERVICE':
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
