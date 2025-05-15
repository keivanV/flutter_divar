import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/ad_provider.dart';
import '../widgets/ad_card.dart';
import '../widgets/category_card.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/filter_bar.dart';
import 'bookmarks_screen.dart';
import 'post_ad_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adProvider = Provider.of<AdProvider>(context,
        listen: false); // Use listen: false for manual calls

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          // دسته‌بندی‌ها
          Container(
            padding: const EdgeInsets.all(4),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: categories
                  .asMap()
                  .entries
                  .map((entry) => SizedBox(
                        width: (MediaQuery.of(context).size.width - 24) / 4,
                        height: 60,
                        child: CategoryCard(
                          name: entry.value['name'],
                          icon: entry.value['icon'],
                        ),
                      ))
                  .toList(),
            ),
          ),
          // فیلتر
          const FilterBar(),
          // لیست آگهی‌ها
          Expanded(
            child: Consumer<AdProvider>(
              builder: (context, adProvider, child) {
                return adProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : adProvider.errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  adProvider.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                ElevatedButton(
                                  onPressed: () => adProvider.fetchAds(),
                                  child: const Text('تلاش مجدد'),
                                ),
                              ],
                            ),
                          )
                        : adProvider.ads.isEmpty
                            ? const Center(child: Text('هیچ آگهی یافت نشد'))
                            : RefreshIndicator(
                                onRefresh: () => adProvider.fetchAds(),
                                child: ListView.builder(
                                  itemCount: adProvider.ads.length,
                                  itemBuilder: (context, index) {
                                    final ad = adProvider.ads[index];
                                    print(
                                        'Rendering ad: ${ad.title} (ID: ${ad.adId})');
                                    return AdCard(ad: ad);
                                  },
                                ),
                              );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: navItems
            .asMap()
            .entries
            .map((entry) => BottomNavigationBarItem(
                  icon: Icon(entry.value['icon']),
                  label: entry.value['name'].toString(),
                ))
            .toList(),
        onTap: (index) {
          if (index == 0) {
            adProvider.fetchAds(); // Re-fetch ads when "آگهی‌ها" is pressed
          } else if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BookmarksScreen()));
          } else if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PostAdScreen()));
          } else if (index == 3) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
      ),
    );
  }
}
