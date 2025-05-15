
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  int? _selectedProvinceId;
  int? _selectedCityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Fetching provinces in LocationScreen');
      Provider.of<AdProvider>(context, listen: false).fetchProvinces();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('انتخاب لوکیشن'),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: Consumer<AdProvider>(
        builder: (context, adProvider, child) {
          print('Consumer rebuilt: provinces=${adProvider.provinces.length}, cities=${adProvider.cities.length}');
          if (adProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    adProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      adProvider.fetchProvinces();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('تلاش مجدد', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'استان',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  hint: const Text('انتخاب استان', textDirection: TextDirection.rtl),
                  value: _selectedProvinceId,
                  items: adProvider.provinces.map((province) {
                    return DropdownMenuItem<int>(
                      value: province.provinceId,
                      child: Text(province.name, textDirection: TextDirection.rtl),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvinceId = value;
                      _selectedCityId = null;
                    });
                    if (value != null) {
                      print('Fetching cities for provinceId: $value');
                      adProvider.fetchCities(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'شهر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  hint: const Text('انتخاب شهر', textDirection: TextDirection.rtl),
                  value: _selectedCityId,
                  items: adProvider.cities.map((city) {
                    return DropdownMenuItem<int>(
                      value: city.cityId,
                      child: Text(city.name, textDirection: TextDirection.rtl),
                    );
                  }).toList(),
                  onChanged: (_selectedProvinceId != null && adProvider.cities.isNotEmpty)
                      ? (value) {
                          setState(() {
                            _selectedCityId = value;
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: _selectedProvinceId != null && _selectedCityId != null
                        ? () {
                            print('Applying location filter: provinceId=$_selectedProvinceId, cityId=$_selectedCityId');
                            adProvider.setLocation(_selectedProvinceId!, _selectedCityId!);
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text(
                      'اعمال فیلتر',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
