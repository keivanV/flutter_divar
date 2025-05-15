import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../models/ad.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize search bar with initialQuery and trigger search
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      print('SearchScreen initialized with query: ${widget.initialQuery}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AdProvider>(context, listen: false)
            .searchAds(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جستجوی آگهی‌ها'),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'جستجو در آگهی‌ها...',
                hintStyle: const TextStyle(fontFamily: 'Vazir'),
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              textDirection: TextDirection.rtl,
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  print('Searching for: $query');
                  Provider.of<AdProvider>(context, listen: false)
                      .searchAds(query);
                }
              },
            ),
          ),
          Expanded(
            child: Consumer<AdProvider>(
              builder: (context, adProvider, child) {
                print(
                    'SearchScreen Consumer rebuilt: searchResults=${adProvider.searchResults.length}');
                if (adProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (adProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          adProvider.errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontFamily: 'Vazir'),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            adProvider.searchAds(_searchController.text);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('تلاش مجدد',
                              style: TextStyle(
                                  color: Colors.white, fontFamily: 'Vazir')),
                        ),
                      ],
                    ),
                  );
                }
                if (adProvider.searchResults.isEmpty) {
                  return const Center(
                    child: Text(
                      'نتیجه‌ای یافت نشد',
                      style: TextStyle(fontSize: 18, fontFamily: 'Vazir'),
                      textDirection: TextDirection.rtl,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: adProvider.searchResults.length,
                  itemBuilder: (context, index) {
                    final ad = adProvider.searchResults[index];
                    // Determine price to display
                    String priceText;
                    if (ad.adType == 'REAL_ESTATE' && ad.totalPrice != null) {
                      priceText = 'قیمت: ${ad.totalPrice} تومان';
                    } else if (ad.adType == 'VEHICLE' && ad.basePrice != null) {
                      priceText = 'قیمت: ${ad.basePrice} تومان';
                    } else if (ad.price != null) {
                      priceText = 'قیمت: ${ad.price} تومان';
                    } else {
                      priceText = 'قیمت: توافقی';
                    }
                    // Determine specific details
                    String detailsText = '';
                    if (ad.adType == 'REAL_ESTATE' && ad.area != null) {
                      detailsText = 'متراژ: ${ad.area} متر';
                      if (ad.realEstateType != null) {
                        detailsText +=
                            ' | نوع: ${ad.realEstateType == 'SALE' ? 'فروش' : 'اجاره'}';
                      }
                    } else if (ad.adType == 'VEHICLE' &&
                        ad.brand != null &&
                        ad.model != null) {
                      detailsText = 'خودرو: ${ad.brand} ${ad.model}';
                      if (ad.mileage != null) {
                        detailsText += ' | کارکرد: ${ad.mileage} کیلومتر';
                      }
                    }
                    // Location
                    final locationText =
                        (ad.provinceName != null && ad.cityName != null)
                            ? 'مکان: ${ad.provinceName}، ${ad.cityName}'
                            : 'مکان: نامشخص';
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          print('Tapped ad: ${ad.adId}');
                          Navigator.pushNamed(context, '/ad_details',
                              arguments: ad);
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image or Placeholder
                            Container(
                              width: 120,
                              height: 120,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[300],
                              ),
                              child: ad.imageUrls.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        ad.imageUrls.first,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ad.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Vazir',
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ad.description.length > 50
                                          ? '${ad.description.substring(0, 50)}...'
                                          : ad.description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Vazir',
                                        color: Colors.grey,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      priceText,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Vazir',
                                        color: Colors.red,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    if (detailsText.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        detailsText,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Vazir',
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      'نوع: ${ad.adType == 'REAL_ESTATE' ? 'املاک' : ad.adType == 'VEHICLE' ? 'خودرو' : 'سایر'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Vazir',
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      locationText,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Vazir',
                                      ),
                                      textDirection: RegExp(r'^[a-zA-Z\s]+$')
                                              .hasMatch(ad.provinceName ?? '')
                                          ? TextDirection.ltr
                                          : TextDirection.rtl,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
