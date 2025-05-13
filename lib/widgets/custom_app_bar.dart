import 'package:flutter/material.dart';
import '../screens/location_screen.dart';
import '../providers/ad_provider.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final adProvider = Provider.of<AdProvider>(context, listen: false);

    return AppBar(
      title: const Text('دیوار'),
      actions: [
        IconButton(
          icon: const Icon(Icons.location_on, size: 24),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationScreen()),
            );
          },
        ),
      ],
      leadingWidth: 300, // افزایش عرض برای نوار جستجوی بزرگ‌تر
      leading: Padding(
        padding: const EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
        child: TextField(
          onChanged: (value) {
            // TODO: Implement real-time search filtering
            // برای جستجوی بلادرنگ، می‌توانید اینجا از adProvider استفاده کنید
          },
          decoration: InputDecoration(
            hintText: 'جستجوی آگهی...',
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.3),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12), // افزایش ارتفاع
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
