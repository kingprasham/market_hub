import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/color_constants.dart';
import '../../core/constants/text_styles.dart';

class SavedItemsPage extends StatefulWidget {
  const SavedItemsPage({super.key});

  @override
  State<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends State<SavedItemsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<SavedItem> _savedNews = [
    SavedItem(id: '1', title: 'Copper prices surge amid supply concerns', subtitle: '2 hours ago', type: 'News'),
    SavedItem(id: '2', title: 'Gold steady as investors await Fed minutes', subtitle: '5 hours ago', type: 'News'),
    SavedItem(id: '3', title: 'LME Aluminium inventories decline', subtitle: '1 day ago', type: 'News'),
  ];
  
  final List<SavedItem> _savedMetals = [
    SavedItem(id: '4', title: 'Copper - LME', subtitle: '\$9,245.50', type: 'Metal'),
    SavedItem(id: '5', title: 'Gold - COMEX', subtitle: '\$2,658.40', type: 'Metal'),
    SavedItem(id: '6', title: 'USD/INR', subtitle: '83.12', type: 'FX'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Saved Items',
          style: TextStyles.h5.copyWith(color: ColorConstants.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorConstants.textPrimary),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorConstants.primaryBlue,
          unselectedLabelColor: ColorConstants.textSecondary,
          indicatorColor: ColorConstants.primaryBlue,
          tabs: const [
            Tab(text: 'News'),
            Tab(text: 'Metals & FX'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedList(_savedNews),
          _buildSavedList(_savedMetals),
        ],
      ),
    );
  }

  Widget _buildSavedList(List<SavedItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: ColorConstants.textHint.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No Saved Items', style: TextStyles.h6.copyWith(color: ColorConstants.textSecondary)),
            const SizedBox(height: 8),
            Text('Items you save will appear here', style: TextStyles.bodySmall.copyWith(color: ColorConstants.textHint)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildSavedItemCard(items[index]),
    );
  }

  Widget _buildSavedItemCard(SavedItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: ColorConstants.negativeRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _savedNews.remove(item);
          _savedMetals.remove(item);
        });
        Get.snackbar('Removed', 'Item removed from saved',
            snackPosition: SnackPosition.BOTTOM);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getTypeColor(item.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getTypeIcon(item.type),
              color: _getTypeColor(item.type),
            ),
          ),
          title: Text(
            item.title,
            style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item.subtitle,
              style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.bookmark, color: ColorConstants.primaryOrange),
            onPressed: () {
              setState(() {
                _savedNews.remove(item);
                _savedMetals.remove(item);
              });
              Get.snackbar('Removed', 'Item removed from saved',
                  snackPosition: SnackPosition.BOTTOM);
            },
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'News':
        return Icons.article;
      case 'Metal':
        return Icons.trending_up;
      case 'FX':
        return Icons.currency_exchange;
      default:
        return Icons.bookmark;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'News':
        return ColorConstants.primaryBlue;
      case 'Metal':
        return ColorConstants.primaryOrange;
      case 'FX':
        return Colors.purple;
      default:
        return ColorConstants.textSecondary;
    }
  }
}

class SavedItem {
  final String id;
  final String title;
  final String subtitle;
  final String type;

  SavedItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
  });
}
