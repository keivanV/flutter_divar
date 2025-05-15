
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ad.dart';
import '../providers/ad_provider.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    print('SearchScreen initState called');
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!;
      print('SearchScreen initial query: $_searchQuery');
      Provider.of<AdProvider>(context, listen: false).searchAds(_searchQuery);
    }
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      print('TextField listener triggered: $query');
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _searchQuery = query;
          print('Search query updated: $_searchQuery');
        });
        if (query.isNotEmpty) {
          print('Triggering search for query: $query');
          Provider.of<AdProvider>(context, listen: false).searchAds(query);
        } else {
          print('Clearing search results');
          Provider.of<AdProvider>(context, listen: false).clearSearchResults();
        }
      });
    });
  }

  @override
  void dispose() {
    print('SearchScreen dispose called');
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('SearchScreen build called');
    return Scaffold(
      appBar: AppBar(
        title: const Text('جستجوی آگهی'),
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
                hintText: 'جستجو در عنوان یا توضیحات...',
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.search,
              autofocus: true,
              onChanged: (value) {
                print('TextField onChanged: $value');
              },
              onSubmitted: (value) {
                final query = value.trim();
                print('TextField onSubmitted: $query');
                if (query.isNotEmpty) {
                  Provider.of<AdProvider>(context, listen: false).searchAds(query);
                }
              },
            ),
          ),
          Expanded(
            child: Consumer<AdProvider>(
              builder: (context, adProvider, child) {
                print('Consumer rebuilt with ${adProvider.searchResults.length} results');
                print('Current state: isLoading=${adProvider.isLoading}, error=${adProvider.errorMessage}');
                if (adProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (adProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          adProvider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (_searchQuery.isNotEmpty) {
                              adProvider.searchAds(_searchQuery);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('تلاش مجدد', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }
                if (adProvider.searchResults.isNotEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: adProvider.searchResults.length,
                    itemBuilder: (context, index) {
                      final ad = adProvider.searchResults[index];
                      print('Rendering ad: ${ad.adId}, title: ${ad.title}');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(
                            ad.title,
                            textDirection: TextDirection.rtl,
                          ),
                          subtitle: Text(
                            ad.description.length > 50
                                ? '${ad.description.substring(0, 50)}...'
                                : ad.description,
                            textDirection: TextDirection.rtl,
                          ),
                          onTap: () {
                            print('Tapped ad: ${ad.adId}');
                            Navigator.pushNamed(context, '/ad_details', arguments: ad);
                          },
                        ),
                      );
                    },
                  );
                }
                // Show nothing when no results or query is empty
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
