import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/google_sheets_service.dart';
import '../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../data/models/market/spot_bulletin_model.dart';
import '../controller/watchlist_controller.dart';
import '../../../core/utils/helpers.dart';

/// Dialog for adding items to watchlist - Shows selectable list from data sources
class AddToWatchlistDialog extends StatefulWidget {
  const AddToWatchlistDialog({super.key});

  @override
  State<AddToWatchlistDialog> createState() => _AddToWatchlistDialogState();
}

class _AddToWatchlistDialogState extends State<AddToWatchlistDialog> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<_WatchlistOption> _allOptions = [];
  List<_WatchlistOption> _filteredOptions = [];
  bool _isLoading = true;

  final _categories = ['All', 'Spot', 'London', 'China', 'COMEX', 'FX'];

  @override
  void initState() {
    super.initState();
    _loadAvailableItems();
    _searchController.addListener(_filterOptions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAvailableItems() {
    final options = <_WatchlistOption>[];
    
    // Get spot metals from Google Sheets
    try {
      final sheetsService = Get.find<GoogleSheetsService>();
      final bulletin = sheetsService.spotBulletin;
      
      if (bulletin != null && bulletin.metalSections.isNotEmpty) {
        for (final section in bulletin.metalSections) {
          for (final entry in section.entries) {
            options.add(_WatchlistOption(
              symbol: '${entry.metalName.toUpperCase()}-${entry.subtype.toUpperCase()}'.replaceAll(' ', '-'),
              name: '${entry.metalName} ${entry.subtype}',
              type: 'Spot',
              price: entry.cashPrice,
              currency: 'INR',
              city: entry.city,
            ));
          }
        }
      }
      
      // Add BME rates (Gold, Silver)
      for (final bme in sheetsService.bmeRates) {
        options.add(_WatchlistOption(
          symbol: '${bme.metalName.toUpperCase()}-${bme.purity}'.replaceAll(' ', '-'),
          name: '${bme.metalName} ${bme.purity}',
          type: 'Spot',
          price: bme.price,
          currency: 'INR',
          city: bme.city,
        ));
      }
    } catch (e) {
      debugPrint('Could not load Google Sheets data: $e');
    }
    
    // Add static configurable items if no data loaded
    if (options.isEmpty) {
      // Add from SpotMetalConfig
      for (final metal in SpotMetalConfig.metals) {
        for (final subtype in metal.subtypes) {
          options.add(_WatchlistOption(
            symbol: '${metal.name.toUpperCase()}-${subtype.toUpperCase()}'.replaceAll(' ', '-'),
            name: '${metal.name} $subtype',
            type: 'Spot',
            price: null,
            currency: 'INR',
          ));
        }
      }
    }
    
    // Add LME metals
    final lmeMetals = ['Copper', 'Aluminium', 'Zinc', 'Nickel', 'Lead', 'Tin'];
    for (final metal in lmeMetals) {
      options.add(_WatchlistOption(
        symbol: metal.toUpperCase(),
        name: 'LME $metal',
        type: 'London',
        price: null,
        currency: 'USD',
      ));
    }
    
    // Add SHFE metals
    for (final metal in lmeMetals.take(4)) {
      options.add(_WatchlistOption(
        symbol: '${metal.toUpperCase()}-SHFE',
        name: 'SHFE $metal',
        type: 'China',
        price: null,
        currency: 'CNY',
      ));
    }
    
    // Add COMEX metals
    options.add(_WatchlistOption(symbol: 'GOLD-COMEX', name: 'COMEX Gold', type: 'COMEX', price: null, currency: 'USD'));
    options.add(_WatchlistOption(symbol: 'SILVER-COMEX', name: 'COMEX Silver', type: 'COMEX', price: null, currency: 'USD'));
    options.add(_WatchlistOption(symbol: 'COPPER-COMEX', name: 'COMEX Copper', type: 'COMEX', price: null, currency: 'USD'));
    
    // Add FX pairs
    final fxPairs = ['USD/INR', 'EUR/INR', 'GBP/INR', 'JPY/INR', 'EUR/USD', 'GBP/USD'];
    for (final pair in fxPairs) {
      options.add(_WatchlistOption(
        symbol: pair,
        name: pair,
        type: 'FX',
        price: null,
        currency: pair.endsWith('INR') ? 'INR' : 'USD',
      ));
    }
    
    // Remove duplicates by symbol
    final seen = <String>{};
    final uniqueOptions = <_WatchlistOption>[];
    for (final option in options) {
      if (!seen.contains(option.symbol)) {
        seen.add(option.symbol);
        uniqueOptions.add(option);
      }
    }
    
    setState(() {
      _allOptions = uniqueOptions;
      _filteredOptions = uniqueOptions;
      _isLoading = false;
    });
  }

  void _filterOptions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOptions = _allOptions.where((option) {
        final matchesSearch = query.isEmpty ||
            option.name.toLowerCase().contains(query) ||
            option.symbol.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == 'All' ||
            option.type == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _addItem(_WatchlistOption option) {
    final controller = Get.find<WatchlistController>();
    
    // Check if already in watchlist
    if (controller.isInWatchlist(option.symbol)) {
      Helpers.showError('${option.name} is already in your watchlist');
      return;
    }
    
    final item = WatchlistItemModel(
      symbol: option.symbol,
      name: option.name,
      itemType: option.type,
      currency: option.currency,
      price: option.price,
    );
    
    controller.addToWatchlist(item);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.add_circle_outline, color: ColorConstants.primaryBlue),
                const SizedBox(width: 12),
                Text('Add to Watchlist', style: TextStyles.h5),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search metals, currencies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 12),
            
            // Category filter
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedCategory = cat);
                        _filterOptions();
                      },
                      selectedColor: ColorConstants.primaryBlue.withValues(alpha: 0.2),
                      checkmarkColor: ColorConstants.primaryBlue,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Items list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredOptions.isEmpty
                      ? Center(
                          child: Text(
                            'No items found',
                            style: TextStyles.bodyMedium.copyWith(
                              color: ColorConstants.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredOptions.length,
                          itemBuilder: (context, index) {
                            final option = _filteredOptions[index];
                            return _buildOptionTile(option);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(_WatchlistOption option) {
    final controller = Get.find<WatchlistController>();
    final isAdded = controller.isInWatchlist(option.symbol);
    final currencySymbol = option.currency == 'INR' ? '₹' : '\$';
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getTypeColor(option.type).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            option.type[0],
            style: TextStyles.bodyLarge.copyWith(
              color: _getTypeColor(option.type),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(option.name, style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${option.type}${option.city != null ? ' • ${option.city}' : ''}',
        style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
      ),
      trailing: isAdded
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColorConstants.positiveGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Added',
                style: TextStyles.caption.copyWith(color: ColorConstants.positiveGreen),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (option.price != null)
                  Text(
                    '$currencySymbol${option.price!.toStringAsFixed(0)}',
                    style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
      onTap: isAdded ? null : () => _addItem(option),
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
      idOrSymbol: widget.item.id,
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
              Get.find<WatchlistController>().removeFromWatchlist(item.symbol);
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
