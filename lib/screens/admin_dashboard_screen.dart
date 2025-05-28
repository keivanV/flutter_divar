import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ad.dart';
import '../providers/admin_provider.dart';
import '../providers/ad_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/comment_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:timezone/timezone.dart' as tz;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String? _selectedAdType;
  int _displayLimit = 20;
  bool _isLoadingMore = false;
  bool _isFetchingAds = false;
  String _selectedTimePeriod = 'day';
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final adProvider = Provider.of<AdProvider>(context, listen: false);
      final commentProvider =
          Provider.of<CommentProvider>(context, listen: false);

      adminProvider.fetchUsersCount(context, timePeriod: _selectedTimePeriod);
      adminProvider.fetchAdsCount(context,
          adType: null, timePeriod: _selectedTimePeriod);
      adminProvider.fetchCommentsCount(context, adType: null);

      adProvider
          .fetchAds(
        adType: null,
        provinceId: null,
        cityId: null,
        sortBy: null,
      )
          .then((_) {
        setState(() {
          _selectedAdType = 'REAL_ESTATE';
        });
      });

      commentProvider.fetchComments(null, offset: 0).then((_) {
        final adIds = commentProvider.comments
            .map((comment) => comment.adId)
            .toSet()
            .toList();
        for (var adId in adIds) {
          adProvider.fetchAdById(adId);
        }
      });
    });
  }

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          'کامنت‌های آگهی: $adTitle',
          style: const TextStyle(
            fontFamily: 'Vazir',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          textDirection: TextDirection.rtl,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<CommentProvider>(
            builder: (context, commentProvider, child) {
              commentProvider.fetchCommentsByAdId(adId);
              if (commentProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (commentProvider.errorMessage != null) {
                return Text(
                  commentProvider.errorMessage!,
                  style: const TextStyle(
                    fontFamily: 'Vazir',
                    color: Colors.red,
                  ),
                  textDirection: TextDirection.rtl,
                );
              }
              if (commentProvider.comments.isEmpty) {
                return const Text(
                  'هیچ کامنت یافت نشد',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    color: Colors.grey,
                  ),
                  textDirection: TextDirection.rtl,
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: commentProvider.comments.length,
                itemBuilder: (context, index) {
                  final comment = commentProvider.comments[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        comment.content,
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
                        ),
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'کاربر: ${comment.userPhoneNumber}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      trailing: IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.trash,
                          color: Colors.red,
                          size: 18,
                        ),
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
                                sortBy: null,
                              ),
                              adminProvider.fetchCommentsCount(context,
                                  adType: _selectedAdType),
                              adminProvider.fetchAdsCount(context,
                                  adType: _selectedAdType,
                                  timePeriod: _selectedTimePeriod),
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
                                        'خطا در حذف کامنت',
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
              style: TextStyle(
                fontFamily: 'Vazir',
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getCommentCountForAd(int adId, CommentProvider commentProvider) {
    return commentProvider.comments
        .where((comment) => comment.adId == adId)
        .length;
  }

  void _loadMoreAds() {
    setState(() {
      _displayLimit += 20;
    });
  }

  void _filterAdsByCategory(String adType) async {
    setState(() {
      _selectedAdType = adType;
      _displayLimit = 20;
      _isFetchingAds = true;
    });
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    try {
      await adProvider.fetchAds(
        adType: adType,
        provinceId: null,
        cityId: null,
        sortBy: null,
      );
      await Future.wait([
        adminProvider.fetchAdsCount(context,
            adType: null, timePeriod: _selectedTimePeriod),
        adminProvider.fetchCommentsCount(context, adType: adType),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگذاری آگهی‌ها: $e',
              style: const TextStyle(fontFamily: 'Vazir'),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isFetchingAds = false;
      });
    }
  }

  void _updateTimePeriod(String? newPeriod) {
    if (newPeriod != null && newPeriod != _selectedTimePeriod) {
      setState(() {
        _selectedTimePeriod = newPeriod;
      });
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.fetchUsersCount(context, timePeriod: _selectedTimePeriod);
      adminProvider.fetchAdsCount(context,
          adType: null, timePeriod: _selectedTimePeriod);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'پنل ادمین',
          style: TextStyle(
            fontFamily: 'Vazir',
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[800]!, Colors.red[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.rightFromBracket,
              color: Colors.white,
              size: 20,
            ),
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
            return const Center(child: CircularProgressIndicator());
          }
          if (adminProvider.errorMessage != null ||
              adProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    adminProvider.errorMessage ??
                        adProvider.errorMessage ??
                        'خطا',
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _filterAdsByCategory('REAL_ESTATE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'تلاش مجدد',
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          final filteredAds = adProvider.ads
              .where((ad) =>
                  ad.adType == (_selectedAdType ?? 'REAL_ESTATE') ||
                  (ad.adType == 'SERVICES' &&
                      (_selectedAdType ?? 'REAL_ESTATE') == 'SERVICES'))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  title: 'آمار',
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: _selectedTimePeriod,
                          items: const [
                            DropdownMenuItem(
                              value: 'day',
                              child: Text('روزانه'),
                            ),
                            DropdownMenuItem(
                              value: 'week',
                              child: Text('هفتگی'),
                            ),
                            DropdownMenuItem(
                              value: 'month',
                              child: Text('ماهانه'),
                            ),
                          ],
                          onChanged: _updateTimePeriod,
                          style: const TextStyle(
                            fontFamily: 'Vazir',
                            color: Colors.black87,
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        ToggleButtons(
                          isSelected: [
                            _selectedTabIndex == 0,
                            _selectedTabIndex == 1,
                          ],
                          onPressed: (index) {
                            setState(() {
                              _selectedTabIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          selectedColor: Colors.white,
                          fillColor: Colors.red[800],
                          color: Colors.black87,
                          constraints: const BoxConstraints(
                            minHeight: 40,
                            minWidth: 100,
                          ),
                          children: const [
                            Text(
                              'کاربران',
                              style: TextStyle(fontFamily: 'Vazir'),
                            ),
                            Text(
                              'آگهی‌ها',
                              style: TextStyle(fontFamily: 'Vazir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: adminProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : (adminProvider.userStats.isEmpty &&
                                      _selectedTabIndex == 0) ||
                                  (adminProvider.adStats.isEmpty &&
                                      _selectedTabIndex == 1)
                              ? const Center(
                                  child: Text(
                                    'داده‌ای برای نمایش وجود ندارد',
                                    style: TextStyle(
                                      fontFamily: 'Vazir',
                                      color: Colors.grey,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                )
                              : LineChart(
                                  LineChartData(
                                    lineBarsData: _buildLineData(
                                        adminProvider, _selectedTabIndex),
                                    maxY: _calculateMaxY(
                                        adminProvider, _selectedTabIndex),
                                    minY: 0,
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (value) =>
                                          FlLine(
                                        color: Colors.grey[300]!,
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                _getDateLabel(
                                                    value.toInt(),
                                                    _selectedTimePeriod,
                                                    adminProvider),
                                                style: const TextStyle(
                                                  fontFamily: 'Vazir',
                                                  fontSize: 12,
                                                  color: Colors.black87,
                                                ),
                                                textDirection:
                                                    TextDirection.rtl,
                                              ),
                                            );
                                          },
                                          interval: _selectedTimePeriod == 'day'
                                              ? 2
                                              : 1,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                fontFamily: 'Vazir',
                                                fontSize: 12,
                                                color: Colors.black87,
                                              ),
                                              textDirection: TextDirection.rtl,
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            return LineTooltipItem(
                                              '${_selectedTabIndex == 0 ? 'کاربران' : 'آگهی‌ها'}\n${spot.y.toInt()}',
                                              const TextStyle(
                                                fontFamily: 'Vazir',
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'تعداد آگهی‌ها',
                  children: [
                    if (adminProvider.adsCount.isEmpty)
                      const Text(
                        'هیچ آگهی یافت نشد',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          color: Colors.grey,
                        ),
                        textDirection: TextDirection.rtl,
                      )
                    else ...[
                      SizedBox(
                        height: 250,
                        child: PieChart(
                          PieChartData(
                            sections: adminProvider.adsCount
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final count = entry.value;
                              return PieChartSectionData(
                                value: count['count'].toDouble(),
                                title:
                                    '${_getCategoryName(count['ad_type'])}\n${count['count']}',
                                color: [
                                  const Color(0xFFFF6F61),
                                  const Color(0xFF6B7280),
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF10B981),
                                  const Color(0xFFF59E0B),
                                  const Color(0xFF8B5CF6),
                                  const Color(0xFFEC4899),
                                ][index % 7],
                                radius: 100,
                                titleStyle: const TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                titlePositionPercentageOffset: 0.55,
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: adminProvider.adsCount.map((count) {
                          final adType = count['ad_type'] as String;
                          return Tooltip(
                            message: _getCategoryName(adType),
                            child: GestureDetector(
                              onTap: () => _filterAdsByCategory(adType),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: _selectedAdType == adType
                                      ? LinearGradient(
                                          colors: [
                                            Colors.red[700]!,
                                            Colors.red[500]!
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.grey[200]!,
                                            Colors.white
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: FaIcon(
                                    _getCategoryIcon(adType),
                                    color: _selectedAdType == adType
                                        ? Colors.white
                                        : Colors.grey[700],
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      ...adminProvider.adsCount.map((count) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              _getCategoryName(count['ad_type']),
                              style: const TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            trailing: Text(
                              count['count'].toString(),
                              style: const TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'تعداد کامنت‌ها',
                  children: adminProvider.commentsCount.isEmpty
                      ? [
                          const Text(
                            'هیچ کامنت یافت نشد',
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              color: Colors.grey,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ]
                      : adminProvider.commentsCount.map((count) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                FontAwesomeIcons.comments,
                                color: Colors.green[700],
                                size: 20,
                              ),
                              title: Text(
                                _getCategoryName(count['ad_type']),
                                style: const TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              trailing: Text(
                                count['count'].toString(),
                                style: const TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'حذف آگهی‌ها',
                  children: [
                    if (filteredAds.isEmpty)
                      Column(
                        children: [
                          const Text(
                            'هیچ آگهی یافت نشد',
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              color: Colors.grey,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _filterAdsByCategory('REAL_ESTATE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[800],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'تلاش مجدد برای بارگذاری آگهی‌ها',
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      ...filteredAds.take(_displayLimit).map((ad) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              FontAwesomeIcons.ad,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            title: Text(
                              ad.title,
                              style: const TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _getCategoryName(ad.adType),
                                  style: const TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                Text(
                                  'تعداد کامنت‌ها: ${_getCommentCountForAd(ad.adId, commentProvider)}',
                                  style: const TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.trash,
                                color: Colors.red,
                                size: 18,
                              ),
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

                                if (await adminProvider.deleteAd(
                                    context, ad.adId)) {
                                  await Future.wait([
                                    adProvider.fetchAds(
                                      adType: _selectedAdType,
                                      provinceId: null,
                                      cityId: null,
                                      sortBy: null,
                                    ),
                                    commentProvider.fetchComments(null,
                                        offset: 0),
                                    adminProvider.fetchAdsCount(context,
                                        adType: _selectedAdType,
                                        timePeriod: _selectedTimePeriod),
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
                          ),
                        );
                      }),
                    if (filteredAds.length > _displayLimit)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Center(
                          child: _isLoadingMore
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _loadMoreAds,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[800],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'نمایش آگهی‌های بیشتر',
                                    style: TextStyle(
                                      fontFamily: 'Vazir',
                                      fontSize: 16,
                                    ),
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
                      const Center(child: CircularProgressIndicator())
                    else if (commentProvider.errorMessage != null)
                      Text(
                        commentProvider.errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          color: Colors.red,
                        ),
                        textDirection: TextDirection.rtl,
                      )
                    else if (commentProvider.comments.isEmpty)
                      const Text(
                        'هیچ کامنت یافت نشد',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          color: Colors.grey,
                        ),
                        textDirection: TextDirection.rtl,
                      )
                    else
                      ...commentProvider.comments.map((comment) {
                        final ad = adProvider.getAdById(comment.adId);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              FontAwesomeIcons.comment,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            title: Text(
                              comment.content,
                              style: const TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textDirection: TextDirection.rtl,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: FutureBuilder(
                              future: ad == null
                                  ? Future.value(ad)
                                  : Provider.of<AdProvider>(context,
                                          listen: false)
                                      .fetchAdById(comment.adId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text(
                                    'در حال بارگذاری...',
                                    style: TextStyle(
                                      fontFamily: 'Vazir',
                                      color: Colors.grey,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  );
                                }
                                final fetchedAd = snapshot.data as Ad?;
                                return Text(
                                  'آگهی: ${fetchedAd?.title ?? 'آگهی حذف یا یافت نشد'}',
                                  style: const TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  textDirection: TextDirection.rtl,
                                );
                              },
                            ),
                            trailing: IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.trash,
                                color: Colors.red,
                                size: 18,
                              ),
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

                                if (await adminProvider.deleteComment(
                                    context, comment.commentId)) {
                                  await Future.wait([
                                    commentProvider.fetchComments(null,
                                        offset: 0),
                                    adProvider.fetchAds(
                                      adType: _selectedAdType,
                                      provinceId: null,
                                      cityId: null,
                                      sortBy: null,
                                    ),
                                    adminProvider.fetchCommentsCount(context,
                                        adType: _selectedAdType),
                                    adminProvider.fetchAdsCount(context,
                                        adType: _selectedAdType,
                                        timePeriod: _selectedTimePeriod),
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
                          ),
                        );
                      }),
                  ],
                ),
              ],
            ),
          );
        },
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Vazir',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          const Divider(height: 20, color: Colors.grey),
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
        return 'لوازم دیجیتال';
      case 'HOME':
        return 'لوازم خانگی';
      case 'SERVICES':
        return 'خدمات';
      case 'PERSONAL':
        return 'وسایل شخصی';
      case 'ENTERTAINMENT':
        return 'سرگرمی';
      default:
        return 'سایر';
    }
  }

  IconData _getCategoryIcon(String adType) {
    switch (adType) {
      case 'REAL_ESTATE':
        return FontAwesomeIcons.house;
      case 'VEHICLE':
        return FontAwesomeIcons.car;
      case 'DIGITAL':
        return FontAwesomeIcons.laptop;
      case 'HOME':
        return FontAwesomeIcons.couch;
      case 'SERVICES':
        return FontAwesomeIcons.tools;
      case 'PERSONAL':
        return FontAwesomeIcons.shirt;
      case 'ENTERTAINMENT':
        return FontAwesomeIcons.gamepad;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  double _calculateMaxY(AdminProvider adminProvider, int tabIndex) {
    final data =
        tabIndex == 0 ? adminProvider.userStats : adminProvider.adStats;
    double maxY = 0;
    for (var item in data) {
      maxY = [maxY, (item['count'] as num).toDouble()]
          .reduce((a, b) => a > b ? a : b);
    }
    return maxY + 1;
  }

  List<LineChartBarData> _buildLineData(
      AdminProvider adminProvider, int tabIndex) {
    final data =
        tabIndex == 0 ? adminProvider.userStats : adminProvider.adStats;

    List<FlSpot> spots = [];
    if (_selectedTimePeriod == 'day') {
      for (int i = 0; i <= 23; i++) {
        final hourData = data.firstWhere(
          (item) => item['hour'] == i,
          orElse: () => {'hour': i, 'count': 0},
        );
        spots.add(FlSpot(i.toDouble(), (hourData['count'] as num).toDouble()));
      }
    } else if (_selectedTimePeriod == 'week') {
      // محاسبه روزهای هفته از شنبه تا امروز
      final tehranTime = tz.TZDateTime.now(tz.getLocation('Asia/Tehran'));
      final startOfWeek = tehranTime
          .subtract(Duration(days: tehranTime.weekday % 7)); // شروع هفته (شنبه)
      for (int i = 0; i <= (tehranTime.weekday % 7); i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final dayData = data.firstWhere(
          (item) => item['date'] == dateStr,
          orElse: () => {'date': dateStr, 'count': 0},
        );
        spots.add(FlSpot(i.toDouble(), (dayData['count'] as num).toDouble()));
      }
    } else if (_selectedTimePeriod == 'month') {
      spots = data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return FlSpot(
          index.toDouble(),
          (item['count'] as num).toDouble(),
        );
      }).toList();
    } else {
      spots = data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return FlSpot(
          index.toDouble(),
          (item['count'] as num).toDouble(),
        );
      }).toList();
    }

    return [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: tabIndex == 0 ? Colors.blue[700] : Colors.red[700],
        barWidth: 4,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: (tabIndex == 0 ? Colors.blue[700] : Colors.red[700])!
              .withOpacity(0.2),
        ),
      ),
    ];
  }

  String _getDateLabel(
      int index, String timePeriod, AdminProvider adminProvider) {
    if (timePeriod == 'day') {
      return '${index.toString().padLeft(2, '0')}:00';
    } else if (timePeriod == 'week') {
      final tehranTime = tz.TZDateTime.now(tz.getLocation('Asia/Tehran'));
      final startOfWeek =
          tehranTime.subtract(Duration(days: tehranTime.weekday % 7)); // شنبه
      final date = startOfWeek.add(Duration(days: index));
      final jalali = Jalali.fromDateTime(date);
      return '${jalali.day} ${_getPersianMonthName(jalali.month)}';
    }

    final data = _selectedTabIndex == 0
        ? adminProvider.userStats
        : adminProvider.adStats;
    if (index >= data.length || index < 0) return '';

    final dateStr = data[index]['date'] as String;
    late DateTime date;
    try {
      if (timePeriod == 'year') {
        date = DateTime(int.parse(dateStr), 1, 1);
      } else if (timePeriod == 'month') {
        final parts = dateStr.split('-');
        date = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      } else {
        date = DateTime.parse(dateStr);
      }
    } catch (e) {
      print('Error parsing date: $dateStr, error: $e');
      return '';
    }

    final jalali = Jalali.fromDateTime(date);
    switch (timePeriod) {
      case 'month':
        return _getPersianMonthName(jalali.month);
      case 'year':
        return jalali.year.toString();
      default:
        return '';
    }
  }

  String _getPersianMonthName(int month) {
    const months = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند'
    ];
    return months[month - 1];
  }
}
