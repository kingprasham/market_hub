import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../data/models/market/spot_price_model.dart';
import '../../../data/models/market/ferrous_price_model.dart';
import '../../../data/models/market/minor_price_model.dart';
import '../controller/watchlist_controller.dart';
import '../../future/controller/future_controller.dart';
import '../../future/pages/london_lme/controller/london_lme_controller.dart';
import '../../future/pages/china_shfe/controller/china_shfe_controller.dart';
import '../../future/pages/us_comex/controller/us_comex_controller.dart';
import '../../spot_price/controller/spot_price_controller.dart';
import '../../future/pages/fx/controller/fx_controller.dart';
import '../../../core/utils/helpers.dart';

/// Dialog for adding items to watchlist - Shows selectable list from data sources
class AddToWatchlistDialog extends StatefulWidget {
  const AddToWatchlistDialog({super.key});

  @override
  State<AddToWatchlistDialog> createState() => _AddToWatchlistDialogState();
}

class _AddToWatchlistDialogState extends State<AddToWatchlistDialog> {
  String _currentStep = 'category'; // category, subcategory, items
  String _selectedCategory = '';
  String _selectedSubCategory = '';
  
  final _categories = ['Spot', 'Future', 'FX'];
  
  // Future sub-categories - Removed FX as it has its own top-level category
  final _futureSubCategories = ['London', 'China', 'COMEX'];
  
  // Spot sub-categories pulled from SpotPriceController
  List<String> get _spotSubCategories {
    if (Get.isRegistered<SpotPriceController>()) {
      return Get.find<SpotPriceController>().spotCategories;
    }
    return ['Non-Ferrous', 'Minor and Ferro', 'Steel'];
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'FX') {
        _currentStep = 'items';
      } else {
        _currentStep = 'subcategory';
      }
    });
  }

  void _onSubCategorySelected(String subCategory) {
    setState(() {
      _selectedSubCategory = subCategory;
      _currentStep = 'items';
    });
  }

  void _goBack() {
    setState(() {
      if (_currentStep == 'items') {
        if (_selectedCategory == 'FX') {
          _currentStep = 'category';
        } else {
          _currentStep = 'subcategory';
        }
      } else if (_currentStep == 'subcategory') {
        _currentStep = 'category';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildStepContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = 'Add to Watchlist';
    if (_currentStep == 'subcategory') title = 'Select $_selectedCategory';
    if (_currentStep == 'items') title = _selectedSubCategory.isEmpty ? _selectedCategory : _selectedSubCategory;

    return Row(
      children: [
        if (_currentStep != 'category')
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: _goBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyles.h5.copyWith(fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Get.back(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 'category':
        return _buildCategoryList();
      case 'subcategory':
        return _buildSubCategoryList();
      case 'items':
        return _buildItemList();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        return _buildSelectionCard(
          title: cat,
          icon: _getCategoryIcon(cat),
          color: _getCategoryColor(cat),
          onTap: () => _onCategorySelected(cat),
        );
      },
    );
  }

  Widget _buildSubCategoryList() {
    final subs = _selectedCategory == 'Future' ? _futureSubCategories : _spotSubCategories;
    return ListView.builder(
      itemCount: subs.length,
      itemBuilder: (context, index) {
        final sub = subs[index];
        return _buildSelectionCard(
          title: sub,
          icon: Icons.chevron_right_rounded,
          color: ColorConstants.primaryBlue,
          onTap: () => _onSubCategorySelected(sub),
        );
      },
    );
  }

  Widget _buildItemList() {
    if (_selectedCategory == 'Future') {
      return _buildFutureItems();
    } else if (_selectedCategory == 'Spot') {
      return _buildSpotItems();
    } else {
      return _buildFxItems();
    }
  }

  Widget _buildFutureItems() {
    return Obx(() {
      final controller = Get.find<FutureController>();
      List<dynamic> items = [];
      String type = '';
      bool loading = false;

      switch (_selectedSubCategory) {
        case 'London':
          final lme = Get.isRegistered<LondonLMEController>() 
              ? Get.find<LondonLMEController>() 
              : Get.put(LondonLMEController());
          items = lme.metals;
          loading = lme.isLoading.value;
          type = 'LME';
          break;
        case 'China':
          final shfe = Get.isRegistered<ChinaSHFEController>() 
              ? Get.find<ChinaSHFEController>() 
              : Get.put(ChinaSHFEController());
          items = shfe.metals;
          loading = shfe.isLoading.value;
          type = 'SHFE';
          break;
        case 'COMEX':
          final comex = Get.isRegistered<USComexController>() 
              ? Get.find<USComexController>() 
              : Get.put(USComexController());
          items = comex.metals;
          loading = comex.isLoading.value;
          type = 'COMEX';
          break;
      }

      if (loading && items.isEmpty) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ));
      }

      if (items.isEmpty) return _buildEmptyState();

      return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          
          // Handle specialized models from sub-controllers if needed
          String name = '';
          String symbol = '';
          double? price;
          double? change;
          double? changePercent;

          if (item is LMEMetal) {
            name = item.name;
            symbol = item.symbol;
            price = item.lastPrice;
            change = item.change;
            changePercent = item.changePercent;
          } else if (item is SHFEMetal) {
            name = item.name;
            symbol = item.symbol;
            price = item.lastPrice;
            change = item.change;
            changePercent = item.changePercent;
          } else if (item is ComexMetal) {
            name = item.name;
            symbol = item.symbol;
            price = item.lastPrice;
            change = item.change;
            changePercent = item.changePercent;
          } else {
            // Fallback for FutureDataModel
            name = '${type == 'LME' ? 'London' : type} ${item.symbol}';
            symbol = item.symbol;
            price = item.price;
            change = item.change;
            changePercent = item.changePercent;
          }

          return _buildItemTile(
            name: name,
            symbol: symbol,
            price: price,
            change: change,
            changePercent: changePercent,
            type: type,
            currency: type == 'LME' || type == 'COMEX' ? 'USD' : 'CNY',
          );
        },
      );
    });
  }

  Widget _buildSpotItems() {
    final controller = Get.find<SpotPriceController>();
    return Obx(() {
      List<dynamic> items = [];
      
      if (_selectedSubCategory == 'Non-Ferrous') {
        items = controller.baseMetalPrices;
      } else if (_selectedSubCategory == 'Minor and Ferro') {
        items = controller.minorPrices;
      } else if (_selectedSubCategory == 'Steel') {
        items = controller.ferrousPrices;
      }

      if (items.isEmpty) return _buildEmptyState();

      return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          String name = '';
          String symbol = '';
          String location = '';
          double? price;
          double? change;
          double? changePercent;

          if (item is Map) {
            name = item['name'] ?? '';
            symbol = item['symbol'] ?? name;
            price = (item['price'] as num?)?.toDouble();
            change = (item['change'] as num?)?.toDouble();
            changePercent = (item['changePercent'] as num?)?.toDouble();
          } else if (item is SpotPriceModel) {
            name = item.metalName;
            symbol = item.id;
            location = item.location;
            price = item.price;
            change = item.change;
            changePercent = item.changePercent;
          } else if (item is FerrousPriceModel) {
            name = item.category;
            symbol = '${item.category}_${item.city}';
            location = item.city;
            price = item.price;
          } else if (item is MinorPriceModel) {
            name = item.item;
            symbol = '${item.category}_${item.item}';
            location = item.category;
            // Parse price string like "123.45 Rs/Kg" or "100-110"
            final priceStr = item.price.split(' ').first;
            price = double.tryParse(priceStr.split('-').first);
          }

          return _buildItemTile(
            name: name,
            symbol: symbol,
            price: price,
            change: change,
            changePercent: changePercent,
            type: 'SPOT',
            currency: 'INR',
            location: location,
          );
        },
      );
    });
  }

  Widget _buildFxItems() {
    return Obx(() {
      final controller = Get.isRegistered<FxController>() 
          ? Get.find<FxController>() 
          : Get.put(FxController());
      final items = controller.currencyPairs;
      final loading = controller.isLoading.value;
      
      if (loading && items.isEmpty) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ));
      }

      if (items.isEmpty) return _buildEmptyState();

      return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildItemTile(
            name: item.pair,
            symbol: item.id,
            price: item.rate,
            change: item.change,
            changePercent: item.changePercent,
            type: 'FX',
            currency: 'INR',
          );
        },
      );
    });
  }

  Widget _buildItemTile({
    required String name,
    required String symbol,
    required double? price,
    double? change,
    double? changePercent,
    required String type,
    required String currency,
    String? location,
  }) {
    final watchlistController = Get.find<WatchlistController>();
    final isAdded = watchlistController.isStarred(symbol);
    final isPositive = (change ?? 0) >= 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      title: Text(name, style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Text(
        '$type${location != null && location.isNotEmpty ? ' • $location' : ''}',
        style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price != null ? '${currency == 'INR' ? '₹' : '\$'}${price.toStringAsFixed(2)}' : '--',
                style: TextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800, color: ColorConstants.textPrimary),
              ),
              if (changePercent != null)
                Text(
                  '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                  style: TextStyles.labelSmall.copyWith(
                    color: isPositive ? ColorConstants.positiveGreen : ColorConstants.negativeRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              isAdded ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
              color: isAdded ? ColorConstants.positiveGreen : ColorConstants.primaryBlue,
            ),
            onPressed: isAdded ? null : () {
              final itemType = type == 'London' ? 'LME' : (type == 'China' ? 'SHFE' : type);
              watchlistController.addToWatchlist(WatchlistItemModel(
                id: '${itemType}_$symbol',
                symbol: symbol,
                name: name,
                itemType: itemType,
                currency: currency,
                price: price,
                change: change,
                changePercent: changePercent,
                location: location,
                lastUpdated: DateTime.now(),
              ));
              setState(() {}); // Rebuild to show checkmark
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorConstants.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: ColorConstants.textHint),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Spot': return Icons.location_on_rounded;
      case 'Future': return Icons.trending_up_rounded;
      case 'FX': return Icons.currency_exchange_rounded;
      default: return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Spot': return ColorConstants.primaryOrange;
      case 'Future': return ColorConstants.primaryBlue;
      case 'FX': return Colors.teal;
      default: return ColorConstants.textSecondary;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: ColorConstants.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'No items available in this category',
            style: TextStyles.bodySmall.copyWith(color: ColorConstants.textHint),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Spot':
        return ColorConstants.primaryOrange;
      case 'London':
        return ColorConstants.primaryBlue;
      case 'China':
        return const Color(0xFFE53935);
      case 'COMEX':
        return const Color(0xFF7B1FA2);
      case 'FX':
        return const Color(0xFF00897B);
      default:
        return ColorConstants.textSecondary;
    }
  }
}

/// Helper class to represent a watchlist option
class _WatchlistOption {
  final String symbol;
  final String name;
  final String type;
  final double? price;
  final String currency;
  final String? city;

  _WatchlistOption({
    required this.symbol,
    required this.name,
    required this.type,
    this.price,
    required this.currency,
    this.city,
  });
}

/// Dialog for editing watchlist items
class EditWatchlistItemDialog extends StatefulWidget {
  final WatchlistItemModel item;

  const EditWatchlistItemDialog({super.key, required this.item});

  @override
  State<EditWatchlistItemDialog> createState() => _EditWatchlistItemDialogState();
}

class _EditWatchlistItemDialogState extends State<EditWatchlistItemDialog> {
  late TextEditingController _nameController;
  late String _selectedType;
  late String _selectedCurrency;

  final _types = ['Spot', 'London', 'China', 'COMEX', 'FX'];
  final _currencies = ['INR', 'USD'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    // Map old types to new names
    String itemType = widget.item.itemType.isNotEmpty
        ? widget.item.itemType
        : (widget.item.type ?? 'Spot');
    if (itemType == 'LME') itemType = 'London';
    if (itemType == 'SHFE') itemType = 'China';
    _selectedType = _types.contains(itemType) ? itemType : 'Spot';
    _selectedCurrency = widget.item.currency ?? 'INR';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_outlined, color: ColorConstants.primaryBlue),
                const SizedBox(width: 12),
                Text('Edit ${widget.item.symbol}', style: TextStyles.h5),
              ],
            ),
            const SizedBox(height: 24),

            // Symbol (read-only)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorConstants.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    'Symbol: ',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ColorConstants.textSecondary,
                    ),
                  ),
                  Text(
                    widget.item.symbol,
                    style: TextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Type and Currency row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _types.contains(_selectedType) ? _selectedType : _types.first,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _types.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(value: currency, child: Text(currency));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    final updatedItem = widget.item.copyWith(
      name: _nameController.text.trim(),
      itemType: _selectedType,
      currency: _selectedCurrency,
    );

    // Update through service
    Get.find<WatchlistController>().addToWatchlist(updatedItem);
    Get.back();
  }
}

/// Dialog for setting price alerts
class SetAlertDialog extends StatefulWidget {
  final WatchlistItemModel item;

  const SetAlertDialog({super.key, required this.item});

  @override
  State<SetAlertDialog> createState() => _SetAlertDialogState();
}

class _SetAlertDialogState extends State<SetAlertDialog> {
  late TextEditingController _priceController;
  String _alertType = 'above';

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.item.alertPrice?.toStringAsFixed(2) ??
            widget.item.price?.toStringAsFixed(2) ?? '',
    );
    _alertType = widget.item.alertType ?? 'above';
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = widget.item.currency == 'INR' ? '\u20B9' : '\$';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_outlined, color: ColorConstants.primaryOrange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Set Alert for ${widget.item.name}', style: TextStyles.h5),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Current price info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Price:',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ColorConstants.textSecondary,
                    ),
                  ),
                  Text(
                    '$currencySymbol${widget.item.price?.toStringAsFixed(2) ?? '--'}',
                    style: TextStyles.h6,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Alert type selection
            Text(
              'Alert me when price goes:',
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAlertTypeButton(
                    'above',
                    'Above',
                    Icons.trending_up,
                    ColorConstants.positiveGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAlertTypeButton(
                    'below',
                    'Below',
                    Icons.trending_down,
                    ColorConstants.negativeRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Alert price field
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Alert Price',
                prefixText: '$currencySymbol ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                if (widget.item.alertEnabled == true)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _removeAlert,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorConstants.negativeRed,
                        side: const BorderSide(color: ColorConstants.negativeRed),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Remove Alert'),
                    ),
                  ),
                if (widget.item.alertEnabled == true)
                  const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _setAlert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(widget.item.alertEnabled == true ? 'Update Alert' : 'Set Alert'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTypeButton(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _alertType == value;
    return GestureDetector(
      onTap: () => setState(() => _alertType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : ColorConstants.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : ColorConstants.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyles.bodyMedium.copyWith(
                color: isSelected ? color : ColorConstants.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setAlert() {
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      Helpers.showError('Please enter a valid price');
      return;
    }

    Get.find<WatchlistController>().setAlert(
      id: widget.item.id,
      alertPrice: price,
      alertType: _alertType,
    );
    Get.back();
  }

  void _removeAlert() {
    Get.find<WatchlistController>().removeAlert(widget.item.id);
    Get.back();
  }
}

/// Helper to show dialogs
class WatchlistDialogs {
  static void showAddDialog() {
    Get.dialog(const AddToWatchlistDialog());
  }

  static void showEditDialog(WatchlistItemModel item) {
    Get.dialog(EditWatchlistItemDialog(item: item));
  }

  static void showSetAlertDialog(WatchlistItemModel item) {
    Get.dialog(SetAlertDialog(item: item));
  }

  static void showDeleteConfirmation(WatchlistItemModel item) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove from Watchlist'),
        content: Text('Are you sure you want to remove ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.find<WatchlistController>().removeFromWatchlist(item.id);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: ColorConstants.negativeRed),
            ),
          ),
        ],
      ),
    );
  }
}
