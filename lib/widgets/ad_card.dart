import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ad.dart';

class AdCard extends StatelessWidget {
  final Ad ad;

  const AdCard({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final numberFormatter = NumberFormat('#,###', 'fa_IR');

    // Use ad.price for all ad types
    final price = ad.price != null && ad.price! > 0
        ? '${numberFormatter.format(ad.price!)} تومان'
        : 'قیمت توافقی';

    // Determine subtitle for VEHICLE or REAL_ESTATE
    final subtitle = ad.adType == 'VEHICLE'
        ? '${ad.brand ?? 'نامشخص'} ${ad.model ?? 'نامشخص'} ${ad.mileage != null ? '، ${numberFormatter.format(ad.mileage!)} کیلومتر' : ''}'
        : ad.adType == 'REAL_ESTATE'
            ? '${ad.area != null ? '${ad.area} متر' : ''} ${ad.rooms != null ? '، ${ad.rooms} خواب' : ''}'
            : ad.description.length > 30
                ? '${ad.description.substring(0, 30)}...'
                : ad.description;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/ad_details',
            arguments: ad,
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: ad.imageUrls.isNotEmpty
                  ? Image.network(
                      ad.imageUrls[0],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 50,
                        ),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 50,
                      ),
                    ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ad.provinceName ?? 'نامشخص'}، ${ad.cityName ?? 'نامشخص'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
