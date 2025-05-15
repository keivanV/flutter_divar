import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/location_screen.dart';
import '../providers/ad_provider.dart';
import '../screens/search_screen.dart';
import '../models/province.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(BuildContext context, String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      print('CustomAppBar search query: $query');
      if (query.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchScreen(initialQuery: query),
          ),
        );
        Provider.of<AdProvider>(context, listen: false).searchAds(query);
      } else {
        print('CustomAppBar clearing search results');
        Provider.of<AdProvider>(context, listen: false).clearSearchResults();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('CustomAppBar build called');
    return AppBar(
      title: const Text('دیوار'),
      backgroundColor: Colors.red,
      actions: [
        Consumer<AdProvider>(
          builder: (context, adProvider, child) {
            String provinceName = 'لوکیشن';
            if (adProvider.selectedProvinceId != null) {
              final selectedProvince = adProvider.provinces.firstWhere(
                (province) =>
                    province.provinceId == adProvider.selectedProvinceId,
                orElse: () => Province(provinceId: 0, name: 'لوکیشن'),
              );
              provinceName = selectedProvince.name;
            }
            return Row(
              children: [
                Text(
                  provinceName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Vazir',
                  ),
                  textDirection: RegExp(r'^[a-zA-Z\s]+$').hasMatch(provinceName)
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                ),
                const SizedBox(width: 4), // Space between text and icon
                IconButton(
                  icon: const Icon(Icons.location_on, size: 24),
                  onPressed: () {
                    print('Navigating to LocationScreen');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LocationScreen()),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
      leadingWidth: 300,
      leading: Padding(
        padding: const EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            print('CustomAppBar TextField onChanged: $value');
            _onSearchChanged(context, value.trim());
          },
          decoration: InputDecoration(
            hintText: 'جستجو در عنوان یا توضیحات...',
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textDirection: TextDirection.rtl,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            print('CustomAppBar TextField onSubmitted: $value');
            final query = value.trim();
            if (query.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchScreen(initialQuery: query),
                ),
              );
              Provider.of<AdProvider>(context, listen: false).searchAds(query);
            }
          },
        ),
      ),
    );
  }
}
