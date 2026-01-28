import 'package:flutter/material.dart';
import 'package:queless/models/product.dart';
import 'package:queless/services/product_service.dart';
import 'package:queless/screens/product/product_detail_screen.dart';
import 'package:queless/utils/formatters.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryScreen extends StatefulWidget {
  final ProductCategory category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products =
          await _productService.getProductsByCategory(widget.category);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.displayName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Text('No products in this category',
                      style: theme.textTheme.titleMedium))
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return _HoverProductCard(product: product);
                  },
                ),
    );
  }
}

class _HoverProductCard extends StatefulWidget {
  final Product product;

  const _HoverProductCard({required this.product});

  @override
  State<_HoverProductCard> createState() => _HoverProductCardState();
}

class _HoverProductCardState extends State<_HoverProductCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        _isHovering ? theme.colorScheme.secondary : theme.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: widget.product))),
        child: Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: widget.product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.product.imageUrl,
                        imageBuilder: (context, imageProvider) => Container(
                          padding: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: Image(
                            image: imageProvider,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: Center(
                            child: Icon(Icons.local_bar,
                                size: 56,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3)),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        child: Center(
                            child: Icon(Icons.local_bar,
                                size: 56,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3))),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product.isLocalBrand) ...[
                      Row(
                        children: [
                          Icon(Icons.flag,
                              size: 12,
                              color: _isHovering
                                  ? theme.colorScheme.secondary
                                  : Colors.green),
                          const SizedBox(width: 4),
                          Text('Local',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: _isHovering
                                      ? theme.colorScheme.secondary
                                      : Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(widget.product.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: textColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (widget.product.volume != null)
                      Text(widget.product.volume!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: _isHovering
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6))),
                    const SizedBox(height: 8),
                    Text(Formatters.formatCurrency(widget.product.price),
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: textColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
