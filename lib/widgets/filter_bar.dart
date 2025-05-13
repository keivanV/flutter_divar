import 'package:flutter/material.dart';
import '../providers/ad_provider.dart';
import 'package:provider/provider.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final adProvider = Provider.of<AdProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: adProvider.sortBy,
        hint: const Text('مرتب‌سازی'),
        isExpanded: true,
        items: const [
          DropdownMenuItem(value: 'newest', child: Text('جدیدترین')),
          DropdownMenuItem(value: 'oldest', child: Text('قدیمی‌ترین')),
          DropdownMenuItem(value: 'cheapest', child: Text('ارزان‌ترین')),
          DropdownMenuItem(value: 'most_expensive', child: Text('گران‌ترین')),
        ],
        onChanged: (value) {
          adProvider.fetchAds(sortBy: value);
        },
      ),
    );
  }
}
