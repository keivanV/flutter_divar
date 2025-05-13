import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;

  const CategoryCard({super.key, required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to category-specific ads
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 24,
                color: Theme.of(context).primaryColor), // کاهش اندازه آیکون
            const SizedBox(height: 4),
            Text(
              name,
              style: Theme.of(context).textTheme.labelMedium, // فونت کوچک‌تر
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
