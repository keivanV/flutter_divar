import 'dart:async';
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
  Timer? _debounce;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      print('SearchScreen initialized with query: ${widget.initialQuery}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AdProvider>(context, listen: false)
            .searchAds(widget.initialQuery!, isSuggestion: false);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        print('Searching for: $query');
        Provider.of<AdProvider>(context, listen: false)
            .searchAds(query, isSuggestion: true);
        setState(() {
          _showSuggestions = true;
        });
      } else {
        setState(() {
          _showSuggestions = false;
        });
        Provider.of<AdProvider>(context, listen: false).clearSearchResults();
      }
    });
  }

  void _selectSuggestion(Ad ad) {
    setState(() {
      _searchController.text = ad.title;
      _showSuggestions = false;
    });
    Provider.of<AdProvider>(context, listen: false)
        .searchAds(ad.title, isSuggestion: false);
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
            child: Stack(
              children: [
                TextField(
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
                  onChanged: _onSearchChanged,
                  onSubmitted: (query) {
                    if (query.isNotEmpty) {
                      print('Submitted search: $query');
                      Provider.of<AdProvider>(context, listen: false)
                          .searchAds(query, isSuggestion: false);
                      setState(() {
                        _showSuggestions = false;
                      });
                    }
                  },
                ),
                if (_showSuggestions)
                  Positioned(
                    top: 60,
                    right: 0,
                    left: 0,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Consumer<AdProvider>(
                          builder: (context, adProvider, child) {
                            if (adProvider.isLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (adProvider.searchResults.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Directionality(
                                  textDirection: TextDirection
                                      .rtl, // Set RTL for Persian/Arabic
                                  child: Text(
                                    'نتیجه‌ای یافت نشد',
                                    style: TextStyle(fontFamily: 'Vazir'),
                                  ),
                                ),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount:
                                  adProvider.searchResults.length.clamp(0, 5),
                              itemBuilder: (context, index) {
                                final ad = adProvider.searchResults[index];
                                return Directionality(
                                  textDirection: TextDirection
                                      .rtl, // Sets RTL for all child Text widgets
                                  child: ListTile(
                                    title: Text(
                                      ad.title,
                                      style:
                                          const TextStyle(fontFamily: 'Vazir'),
                                    ),
                                    subtitle: Text(
                                      ad.adType == 'REAL_ESTATE'
                                          ? 'املاک'
                                          : ad.adType == 'VEHICLE'
                                              ? 'خودرو'
                                              : 'سایر',
                                      style:
                                          const TextStyle(fontFamily: 'Vazir'),
                                    ),
                                    onTap: () => _selectSuggestion(ad),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<AdProvider>(
              builder: (context, adProvider, child) {
                print(
                    'SearchScreen Consumer rebuilt: searchResults=${adProvider.searchResults.length}');
                if (adProvider.isLoading && !_showSuggestions) {
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
                            adProvider.searchAds(_searchController.text,
                                isSuggestion: false);
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
                if (adProvider.searchResults.isEmpty && !_showSuggestions) {
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
