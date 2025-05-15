
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                hint: const Text('مرتب‌سازی'),
                value: adProvider.sortBy,
                items: const [
                  DropdownMenuItem(
                    value: 'newest',
                    child: Text('جدیدترین'),
                  ),
                  DropdownMenuItem(
                    value: 'oldest',
                    child: Text('قدیمی‌ترین'),
                  ),
                  DropdownMenuItem(
                    value: 'price_asc',
                    child: Text('ارزان‌ترین'),
                  ),
                  DropdownMenuItem(
                    value: 'price_desc',
                    child: Text('گران‌ترین'),
                  ),
                ],
                onChanged: (value) {
                  print('Selected sortBy: $value');
                  adProvider.setFilters(sortBy: value);
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  adProvider.clearFilters();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
