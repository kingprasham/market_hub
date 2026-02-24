import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/loaders/shimmer_loader.dart';
import '../../../shared/widgets/common/empty_state.dart';
import '../../../data/models/watchlist/watchlist_item_model.dart';
import '../controller/watchlist_controller.dart';
import '../widgets/watchlist_dialogs.dart';

import '../../../shared/widgets/common/common_app_bar_title.dart';

class WatchlistScreen extends GetView<WatchlistController> {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => WatchlistDialogs.showAddDialog(),
        backgroundColor: ColorConstants.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Obx(() => CommonAppBarTitle(
        title: 'Watchlist',
        subtitle: '${controller.filteredItems.length} items',
      )),
      actions: [
        Obx(() => IconButton(
          onPressed: controller.toggleEditMode,
          icon: Icon(
            controller.isEditing.value ? Icons.check : Icons.edit_outlined,
            color: controller.isEditing.value
                ? ColorConstants.primaryBlue
                : ColorConstants.textPrimary,
          ),
          tooltip: controller.isEditing.value ? 'Done' : 'Edit',
        )),
        IconButton(
          onPressed: () => WatchlistDialogs.showAddDialog(),
          icon: const Icon(
            Icons.add,
            color: ColorConstants.textPrimary,
          ),
          tooltip: 'Add item',
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Search field
          TextField(
            onChanged: controller.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search watchlist...',
              prefixIcon: const Icon(Icons.search, color: ColorConstants.textSecondary),
              filled: true,
              fillColor: ColorConstants.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SizedBox(
            height: 36,
            child: Obx(() {
              // Access the observable first to register the dependency
              final currentFilter = controller.selectedFilter.value;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.filters.length,
                itemBuilder: (context, index) {
                  final filter = controller.filters[index];
                  final isSelected = currentFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) => controller.setFilter(filter),
                      selectedColor: ColorConstants.primaryBlue.withOpacity(0.2),
                      checkmarkColor: ColorConstants.primaryBlue,
                      labelStyle: TextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? ColorConstants.primaryBlue
                            : ColorConstants.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const ShimmerListLoader();
      }

      final items = controller.filteredItems;

      if (items.isEmpty) {
        return EmptyState(
          icon: controller.searchQuery.value.isNotEmpty
              ? Icons.search_off
              : Icons.star_border,
          title: controller.searchQuery.value.isNotEmpty
              ? 'No results found'
              : 'No items in watchlist',
          description: controller.searchQuery.value.isNotEmpty
              ? 'Try a different search term'
              : 'Add metals, currencies, or commodities to track them here',
          actionText: controller.searchQuery.value.isEmpty ? 'Add Items' : null,
          onAction: controller.searchQuery.value.isEmpty
              ? () => WatchlistDialogs.showAddDialog()
              : null,
        );
      }

      return controller.isEditing.value
          ? _buildReorderableList(items)
          : _buildWatchlist(items);
    });
  }

  Widget _buildWatchlist(List<WatchlistItemModel> items) {
    return RefreshIndicator(
      onRefresh: controller.refreshWatchlist,
      color: ColorConstants.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildWatchlistCard(item);
        },
      ),
    );
  }

  Widget _buildReorderableList(List<WatchlistItemModel> items) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      onReorder: controller.reorderWatchlist,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildEditableCard(item, index);
      },
    );
  }

  Widget _buildWatchlistCard(WatchlistItemModel item) {
    final isPositive = item.isPositive;

    return Obx(() {
      // Observe watchlistUpdateTrigger to rebuild when starred status changes
      controller.watchlistUpdateTrigger.value;
      final isStarred = controller.isStarred(item.id) || controller.isStarred(item.symbol);

      return GestureDetector(
      onTap: () => _showItemDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isStarred
              ? Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTypeColor(item.type ?? item.itemType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      item.symbol.substring(0, item.symbol.length > 2 ? 2 : item.symbol.length),
                      style: TextStyles.h6.copyWith(
                        color: _getTypeColor(item.type ?? item.itemType),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.alertEnabled == true) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.notifications_active,
                              size: 16,
                              color: ColorConstants.primaryOrange,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(item.type ?? item.itemType).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.type ?? item.itemType,
                              style: TextStyles.caption.copyWith(
                                color: _getTypeColor(item.type ?? item.itemType),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (item.location != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              item.location!,
                              style: TextStyles.caption.copyWith(
                                color: ColorConstants.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Star button
                IconButton(
                  onPressed: () => controller.toggleStar(item.id),
                  icon: Icon(
                    isStarred ? Icons.star : Icons.star_border,
                    color: isStarred ? Colors.amber : ColorConstants.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayPrice,
                      style: TextStyles.h5,
                    ),
                    if (item.lastUpdated != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        Formatters.timeAgo(item.lastUpdated!),
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? ColorConstants.positiveGreen.withOpacity(0.1)
                        : ColorConstants.negativeRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: isPositive
                            ? ColorConstants.positiveGreen
                            : ColorConstants.negativeRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.displayChangePercent,
                        style: TextStyles.bodySmall.copyWith(
                          color: isPositive
                              ? ColorConstants.positiveGreen
                              : ColorConstants.negativeRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.alertEnabled == true && item.alertPrice != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryOrange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ColorConstants.primaryOrange.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 18,
                      color: ColorConstants.primaryOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alert when price goes ${item.alertType} ',
                      style: TextStyles.bodySmall.copyWith(
                        color: ColorConstants.textSecondary,
                      ),
                    ),
                    Text(
                      '${item.currency == 'INR' ? '\u20B9' : '\$'}${Formatters.formatNumber(item.alertPrice!)}',
                      style: TextStyles.bodySmall.copyWith(
                        color: ColorConstants.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      );
    });
  }

  Widget _buildEditableCard(WatchlistItemModel item, int index) {
    return KeyedSubtree(
      key: ValueKey(item.id),
      child: Obx(() {
        // Observe watchlistUpdateTrigger to rebuild when starred status changes
        controller.watchlistUpdateTrigger.value;
        final isStarred = controller.isStarred(item.id) || controller.isStarred(item.symbol);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConstants.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.drag_handle,
                color: ColorConstants.textSecondary,
              ),
              const SizedBox(width: 12),
              if (isStarred)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.star, color: Colors.amber, size: 18),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.type ?? item.itemType} | ${item.displayPrice}',
                      style: TextStyles.caption.copyWith(
                        color: ColorConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => WatchlistDialogs.showEditDialog(item),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: ColorConstants.primaryBlue,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: () => WatchlistDialogs.showDeleteConfirmation(item),
                icon: const Icon(
                  Icons.delete_outline,
                  color: ColorConstants.negativeRed,
                  size: 20,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showItemDetails(WatchlistItemModel item) {
    final isStarred = controller.isStarred(item.id) || controller.isStarred(item.symbol);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorConstants.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getTypeColor(item.type ?? item.itemType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      item.symbol.substring(0, item.symbol.length > 2 ? 2 : item.symbol.length),
                      style: TextStyles.h5.copyWith(
                        color: _getTypeColor(item.type ?? item.itemType),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: TextStyles.h5),
                      Text(
                        '${item.type ?? item.itemType} | ${item.symbol}',
                        style: TextStyles.bodySmall.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => controller.toggleStar(item.id),
                  icon: Icon(
                    isStarred ? Icons.star : Icons.star_border,
                    color: isStarred ? Colors.amber : ColorConstants.textSecondary,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Current Price', item.displayPrice),
            _buildDetailRow('Change', '${item.displayChange} (${item.displayChangePercent})'),
            if (item.lastUpdated != null)
              _buildDetailRow('Last Updated', Formatters.formatTime(item.lastUpdated!)),
            if (item.location != null)
              _buildDetailRow('Location', item.location!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      WatchlistDialogs.showSetAlertDialog(item);
                    },
                    icon: Icon(
                      item.alertEnabled == true
                          ? Icons.notifications_active
                          : Icons.notifications_outlined,
                    ),
                    label: Text(item.alertEnabled == true ? 'Edit Alert' : 'Set Alert'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: item.alertEnabled == true
                            ? ColorConstants.primaryOrange
                            : ColorConstants.primaryBlue,
                      ),
                      foregroundColor: item.alertEnabled == true
                          ? ColorConstants.primaryOrange
                          : ColorConstants.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      WatchlistDialogs.showDeleteConfirmation(item);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.negativeRed,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.bodyMedium.copyWith(
              color: ColorConstants.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'LME':
      case 'LONDON':
        return ColorConstants.primaryBlue;
      case 'SHFE':
      case 'CHINA':
        return Colors.red;
      case 'COMEX':
        return Colors.purple;
      case 'SPOT':
        return ColorConstants.primaryOrange;
      case 'FX':
        return Colors.teal;
      default:
        return ColorConstants.textSecondary;
    }
  }
}
