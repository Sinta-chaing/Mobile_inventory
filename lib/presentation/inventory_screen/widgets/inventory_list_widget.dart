import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/empty_state_widget.dart';
import '../inventory_screen.dart';
import './inventory_item_card_widget.dart';

class InventoryListWidget extends StatelessWidget {
  final List<StockItem> items;
  final void Function(StockItem) onEdit;
  final void Function(StockItem) onDelete;
  final bool isTablet;
  final Map<int, double>? productScores;

  const InventoryListWidget({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
    this.isTablet = false,
    this.productScores,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'No stock items found',
        subtitle:
            'Add your first inventory item or try adjusting your search and filter settings.',
        ctaLabel: 'Add Item',
        onCta: () {},
      );
    }

    if (isTablet) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final score = productScores?[int.tryParse(item.id) ?? -1];
          return _AnimatedItemCard(
            item: item,
            index: index,
            onEdit: onEdit,
            onDelete: onDelete,
            score: score,
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final score = productScores?[int.tryParse(item.id) ?? -1];
        return _AnimatedItemCard(
          item: item,
          index: index,
          onEdit: onEdit,
          onDelete: onDelete,
          score: score,
        );
      },
    );
  }
}

class _AnimatedItemCard extends StatefulWidget {
  final StockItem item;
  final int index;
  final void Function(StockItem) onEdit;
  final void Function(StockItem) onDelete;
  final double? score;

  const _AnimatedItemCard({
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    this.score,
  });

  @override
  State<_AnimatedItemCard> createState() => _AnimatedItemCardState();
}

class _AnimatedItemCardState extends State<_AnimatedItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    final delay = (widget.index * 50).clamp(0, 400);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dismissible(
          key: Key(widget.item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppTheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.error,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Item'),
                content: Text(
                  'Remove "${widget.item.name}" from inventory? This cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) => widget.onDelete(widget.item),
          child: InventoryItemCardWidget(
            item: widget.item,
            onTap: () => widget.onEdit(widget.item),
            score: widget.score,
          ),
        ),
      ),
    );
  }
}
