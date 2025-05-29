import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/ad.dart';
import '../models/comment.dart';
import '../providers/auth_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/comment_provider.dart';

class AdDetailsScreen extends StatefulWidget {
  const AdDetailsScreen({super.key});

  @override
  _AdDetailsScreenState createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  int _currentImageIndex = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isCommentsExpanded = false;
  bool _isBookmarked = false;
  bool _isBookmarkLoading = false;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentImageIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBookmarkStatus();
      _fetchComments();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    final ad = ModalRoute.of(context)!.settings.arguments as Ad?;
    if (ad != null && ad.adId != null) {
      final commentProvider =
          Provider.of<CommentProvider>(context, listen: false);
      await commentProvider.fetchComments(ad.adId!);
    }
  }

  Future<void> _checkBookmarkStatus() async {
    final ad = ModalRoute.of(context)!.settings.arguments as Ad?;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookmarkProvider =
        Provider.of<BookmarkProvider>(context, listen: false);

    if (ad != null && authProvider.phoneNumber != null && ad.adId != null) {
      setState(() {
        _isBookmarkLoading = true;
      });
      try {
        final isBookmarked = await bookmarkProvider.isBookmarked(
          authProvider.phoneNumber!,
          ad.adId!,
        );
        if (mounted) {
          setState(() {
            _isBookmarked = isBookmarked;
            _isBookmarkLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isBookmarkLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا در بررسی نشان: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleBookmark(Ad ad) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookmarkProvider =
        Provider.of<BookmarkProvider>(context, listen: false);

    if (authProvider.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا وارد شوید')),
      );
      Navigator.pushNamed(context, '/auth');
      return;
    }

    if (ad.adId == null) return;

    setState(() {
      _isBookmarkLoading = true;
    });

    try {
      await bookmarkProvider.toggleBookmark(
          authProvider.phoneNumber!, ad.adId!);
      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
          _isBookmarkLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBookmarked ? 'به نشان‌ها اضافه شد' : 'از نشان‌ها حذف شد',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBookmarkLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
  }

  Future<void> _postComment(Ad ad) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final commentProvider =
        Provider.of<CommentProvider>(context, listen: false);

    if (authProvider.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا وارد شوید')),
      );
      Navigator.pushNamed(context, '/auth');
      return;
    }

    if (_commentController.text.trim().isEmpty || ad.adId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('متن کامنت نمی‌تواند خالی باشد')),
      );
      return;
    }

    try {
      await commentProvider.postComment(
        adId: ad.adId!,
        userPhoneNumber: authProvider.phoneNumber!,
        content: _commentController.text.trim(),
      );
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کامنت با موفقیت ثبت شد'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ثبت کامنت: $e')),
      );
    }
  }

  void _nextImage(int imageCount) {
    if (_currentImageIndex < imageCount - 1) {
      setState(() {
        _currentImageIndex++;
      });
      _pageController?.animateToPage(
        _currentImageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
      });
      _pageController?.animateToPage(
        _currentImageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Moved _buildFeatureCard before build to avoid reference error
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isAvailable,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isAvailable ? Colors.green : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isAvailable ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Moved _buildDetailItem before build to avoid reference error
  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ad = ModalRoute.of(context)!.settings.arguments as Ad;
    final numberFormatter = NumberFormat('#,###', 'fa_IR');
    final authProvider = Provider.of<AuthProvider>(context);
    final commentProvider = Provider.of<CommentProvider>(context);
    final phoneNumber = authProvider.phoneNumber;

    if (phoneNumber == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً ابتدا وارد شوید')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final formattedPrice = ad.adType == 'VEHICLE'
        ? (ad.basePrice != null && ad.basePrice! > 0
            ? '${numberFormatter.format(ad.basePrice!)} تومان'
            : 'قیمت توافقی')
        : (ad.price != null && ad.price! > 0
            ? '${numberFormatter.format(ad.price!)} تومان'
            : 'قیمت توافقی');

    final formattedDeposit = ad.deposit != null && ad.deposit! > 0
        ? '${numberFormatter.format(ad.deposit!)} تومان'
        : null;
    final formattedMonthlyRent = ad.monthlyRent != null && ad.monthlyRent! > 0
        ? '${numberFormatter.format(ad.monthlyRent!)} تومان'
        : null;
    final formattedTotalPrice = ad.totalPrice != null && ad.totalPrice! > 0
        ? '${numberFormatter.format(ad.totalPrice!)} تومان'
        : null;

    // Map adType to Persian labels
    final adCategory = {
          'REAL_ESTATE': 'املاک',
          'VEHICLE': 'خودرو',
          'DIGITAL': 'لوازم الکترونیکی',
          'HOME': 'لوازم خانگی',
          'PERSONAL': 'وسایل شخصی',
          'ENTERTAINMENT': 'سرگرمی و فراغت',
          'SERVICES': 'خدمات',
        }[ad.adType] ??
        'سایر';

    return Scaffold(
      appBar: AppBar(
        title:
            Text(ad.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        elevation: 0,
        centerTitle: true,
        actions: [
          _isBookmarkLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? Colors.yellow : Colors.white,
                  ),
                  onPressed: () => _toggleBookmark(ad),
                ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ad.imageUrls.isNotEmpty
                        ? PageView.builder(
                            controller: _pageController,
                            itemCount: ad.imageUrls.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) => Image.network(
                              ad.imageUrls[index],
                              alignment: Alignment.center,
                              fit: BoxFit.fitWidth,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'بدون تصویر',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    if (ad.imageUrls.isNotEmpty)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${ad.imageUrls.length} عکس',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (ad.imageUrls.isNotEmpty)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            ad.imageUrls.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.red
                                    : Colors.grey.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (ad.imageUrls.length > 1) ...[
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 32,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          onPressed:
                              _currentImageIndex < ad.imageUrls.length - 1
                                  ? () => _nextImage(ad.imageUrls.length)
                                  : null,
                        ),
                      ),
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 32,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          onPressed: _currentImageIndex > 0
                              ? () => _previousImage()
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              adCategory,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              ad.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'تاریخ ثبت: ${DateFormat('yyyy-MM-dd').format(ad.createdAt)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'موقعیت: ${ad.provinceName ?? 'نامشخص'}، ${ad.cityName ?? 'نامشخص'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[300], thickness: 1),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'کامنت مفید به این آگهی اضافه کنید',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.red),
                  onPressed: () => _postComment(ad),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[300], thickness: 1),
            InkWell(
              onTap: () {
                setState(() {
                  _isCommentsExpanded = !_isCommentsExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'نمایش کامنت‌ها برای این آگهی',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                    Icon(
                      _isCommentsExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            if (_isCommentsExpanded) ...[
              const SizedBox(height: 8),
              Consumer<CommentProvider>(
                builder: (context, commentProvider, child) {
                  if (commentProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (commentProvider.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Text(
                            'خطا: ${commentProvider.errorMessage}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _fetchComments(),
                            child: const Text('تلاش مجدد'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (commentProvider.comments.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'هنوز کامنتی ثبت نشده است',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                      ),
                    );
                  }
                  return Column(
                    children: commentProvider.comments
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[200],
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.value.nickname ??
                                            'کاربر ${entry.key + 1}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.value.content,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('yyyy-MM-dd HH:mm')
                                            .format(entry.value.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: Colors.grey[300], thickness: 1),
            if (ad.adType == 'REAL_ESTATE') ...[
              Text(
                'جزئیات ملک',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.local_parking,
                      label: 'پارکینگ',
                      isAvailable: ad.hasParking == true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.store,
                      label: 'انباری',
                      isAvailable: ad.hasStorage == true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.balcony,
                      label: 'بالکن',
                      isAvailable: ad.hasBalcony == true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ad.area != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.square_foot,
                        label: 'مساحت',
                        value: '${ad.area} متر مربع',
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  if (ad.rooms != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.bed,
                        label: 'اتاق',
                        value: ad.rooms.toString(),
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  if (ad.floor != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.stairs,
                        label: 'طبقه',
                        value: ad.floor.toString(),
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  if (ad.constructionYear != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.calendar_today,
                        label: 'سال ساخت',
                        value: ad.constructionYear.toString(),
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  if (formattedTotalPrice != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.account_balance_wallet,
                        label: 'قیمت کل',
                        value: formattedTotalPrice,
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  if (ad.realEstateType == 'RENT') ...[
                    if (formattedDeposit != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDetailItem(
                          context,
                          icon: Icons.payment,
                          label: 'ودیعه',
                          value: formattedDeposit,
                        ),
                      ),
                      Divider(color: Colors.grey[300], thickness: 1),
                    ],
                    if (formattedMonthlyRent != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDetailItem(
                          context,
                          icon: Icons.calendar_month,
                          label: 'اجاره ماهانه',
                          value: formattedMonthlyRent,
                        ),
                      ),
                      Divider(color: Colors.grey[300], thickness: 1),
                    ],
                  ],
                ],
              ),
            ] else if (ad.adType == 'VEHICLE') ...[
              Text(
                'جزئیات خودرو',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ad.brand != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.directions_car,
                        label: 'برند',
                        value: ad.brand!,
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  if (ad.model != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.model_training,
                        label: 'مدل',
                        value: ad.model!,
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  if (ad.mileage != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.speed,
                        label: 'کارکرد',
                        value: '${numberFormatter.format(ad.mileage!)} کیلومتر',
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  if (ad.color != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.color_lens,
                        label: 'رنگ',
                        value: ad.color!,
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  if (ad.gearbox != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.settings,
                        label: 'نوع گیربکس',
                        value: ad.gearbox == 'MANUAL' ? 'دستی' : 'اتوماتیک',
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDetailItem(
                      context,
                      icon: Icons.attach_money,
                      label: 'قیمت',
                      value: formattedPrice,
                    ),
                  ),
                  Divider(color: Colors.grey[300], thickness: 1),
                  if (ad.engineStatus != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.engineering,
                        label: 'وضعیت موتور',
                        value: ad.engineStatus == 'HEALTHY'
                            ? 'سالم'
                            : 'نیاز به تعمیر',
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  if (ad.chassisStatus != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.car_repair,
                        label: 'وضعیت شاسی',
                        value:
                            ad.chassisStatus == 'HEALTHY' ? 'سالم' : 'تصادفی',
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  if (ad.bodyStatus != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.car_crash,
                        label: 'وضعیت بدنه',
                        value: ad.bodyStatus == 'HEALTHY'
                            ? 'سالم'
                            : ad.bodyStatus == 'MINOR_SCRATCH'
                                ? 'خط و خش جزیی'
                                : 'تصادفی',
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                ],
              ),
            ] else if (['DIGITAL', 'HOME', 'PERSONAL', 'ENTERTAINMENT']
                .contains(ad.adType)) ...[
              Text(
                'جزئیات محصول',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ad.brand != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.branding_watermark,
                        label: 'برند',
                        value: ad.brand!,
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  if (ad.model != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDetailItem(
                        context,
                        icon: Icons.model_training,
                        label: 'مدل',
                        value: ad.model!,
                      ),
                    ),
                    Divider(color: Colors.grey[300], thickness: 1),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDetailItem(
                      context,
                      icon: Icons.attach_money,
                      label: 'قیمت',
                      value: formattedPrice,
                    ),
                  ),
                  Divider(color: Colors.grey[300], thickness: 1),
                ],
              ),
            ] else if (ad.adType == 'SERVICES') ...[
              Text(
                'جزئیات خدمات',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDetailItem(
                      context,
                      icon: Icons.attach_money,
                      label: 'هزینه',
                      value: formattedPrice,
                    ),
                  ),
                  Divider(color: Colors.grey[300], thickness: 1),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: Colors.grey[300], thickness: 1),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'توضیحات',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ad.description ?? 'بدون توضیحات',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('قابلیت چت هنوز پیاده‌سازی نشده است'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text(
                    'چت',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('تماس با صاحب آگهی'),
                        content: Text(
                          'شماره تماس: ${ad.ownerPhoneNumber ?? 'نامشخص'}',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.black,
                                  ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('بستن'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone, color: Colors.white),
                  label: const Text(
                    'تماس',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
