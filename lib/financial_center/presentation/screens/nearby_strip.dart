import 'package:flutter/material.dart';

class NearbyStrip extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onTapItem;
  final VoidCallback onClose;

  const NearbyStrip({
    super.key,
    required this.items,
    required this.onTapItem,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.only(bottom: 10, top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Địa điểm gần bạn",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // LIST OF ITEMS
            SizedBox(
              height: 160, // CHIỀU CAO ĐỦ CHO 3 ITEM
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final h = items[index];

                  final title = h['title']?.toString() ?? "";
                  final isTour = h['type'] == 'tour';

                  final img = h['thumbnail'] ?? h['image_url'] ?? "";
                  final rating = double.tryParse(h['review_score']?.toString() ?? "");
                  final d = (h['_distance'] as double?) ?? 0;
                  final km = (d / 1000).toStringAsFixed(1);

                  return GestureDetector(
                    onTap: () => onTapItem(h),
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // IMAGE
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: SizedBox(
                              height: 90,
                              width: double.infinity,
                              child: img != ""
                                  ? Image.network(
                                img,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                              )
                                  : Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image),
                              ),
                            ),
                          ),

                          // TITLE
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // RATING + DISTANCE
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Row(
                              children: [
                                if (!isTour && rating != null) ...[
                                  const Icon(Icons.star, size: 14, color: Colors.amber),
                                  const SizedBox(width: 3),
                                  Text(rating.toStringAsFixed(1)),
                                  const SizedBox(width: 10),
                                ],

                                const Icon(Icons.location_on, size: 14, color: Colors.red),
                                Text("$km km"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}