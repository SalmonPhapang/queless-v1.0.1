import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:queless/models/store.dart';
import 'package:queless/screens/food/store_detail_screen.dart';
import 'package:queless/screens/home/store_products_screen.dart';
import 'package:queless/services/promotion_service.dart';
import 'package:queless/widgets/promo_badge.dart';

class StoreCard extends StatelessWidget {
  final Store store;

  const StoreCard({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promoService = PromotionService();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (store.category == 'food') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoreDetailScreen(store: store),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoreProductsScreen(store: store),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: promoService,
              builder: (context, _) {
                final promo = promoService.promotionForStore(store.id);

                final image = store.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: store.imageUrl,
                        imageBuilder: (context, imageProvider) => Container(
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              store.category == 'food'
                                  ? Icons.restaurant_menu
                                  : Icons.store_rounded,
                              size: 48,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            store.category == 'food'
                                ? Icons.restaurant_menu
                                : Icons.store_rounded,
                            size: 48,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      );

                return Stack(
                  children: [
                    image,
                    if (promo != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: PromoBadge(text: promo.badgeText),
                      ),
                    if (!store.isOpen)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'CLOSED',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: store.isOpen
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (store.rating > 0)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              store.rating.toStringAsFixed(1),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (!store.isOpen) ...[
                    const SizedBox(height: 4),
                    Text(
                      store.nextOpeningTime ?? 'Will open soon',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else if (store.category == 'food' &&
                      store.cuisineTypes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      store.cuisineTypes.join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (store.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      store.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.delivery_dining,
                          size: 18,
                          color: store.isOpen
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text(
                        '${store.deliveryTimeMin}-${store.deliveryTimeMax} min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: store.isOpen
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                          fontWeight: store.isOpen
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.directions_walk,
                          size: 18,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text(
                        'Nearby',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
