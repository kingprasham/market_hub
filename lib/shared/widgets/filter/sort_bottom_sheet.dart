import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';

enum SortOption {
  priceLowToHigh,
  priceHighToLow,
  nameAZ,
  nameZA,
  latest,
  oldest,
}

extension SortOptionExtension on SortOption {
  String get label {
    switch (this) {
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.nameAZ:
        return 'Name: A-Z';
      case SortOption.nameZA:
        return 'Name: Z-A';
      case SortOption.latest:
        return 'Latest First';
      case SortOption.oldest:
        return 'Oldest First';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOption.priceLowToHigh:
        return Icons.arrow_upward;
      case SortOption.priceHighToLow:
        return Icons.arrow_downward;
      case SortOption.nameAZ:
        return Icons.sort_by_alpha;
      case SortOption.nameZA:
        return Icons.sort_by_alpha;
      case SortOption.latest:
        return Icons.access_time;
      case SortOption.oldest:
        return Icons.access_time;
    }
  }
}

class SortBottomSheet extends StatefulWidget {
  final SortOption initialSort;
  final void Function(SortOption) onApply;
  final List<SortOption> availableOptions;

  const SortBottomSheet({
    super.key,
    required this.initialSort,
    required this.onApply,
    this.availableOptions = const [
      SortOption.priceLowToHigh,
      SortOption.priceHighToLow,
      SortOption.nameAZ,
      SortOption.nameZA,
      SortOption.latest,
      SortOption.oldest,
    ],
  });

  @override
  State<SortBottomSheet> createState() => _SortBottomSheetState();

  static void show({
    required BuildContext context,
    required SortOption initialSort,
    required void Function(SortOption) onApply,
    List<SortOption> availableOptions = const [
      SortOption.priceLowToHigh,
      SortOption.priceHighToLow,
      SortOption.nameAZ,
      SortOption.nameZA,
      SortOption.latest,
      SortOption.oldest,
    ],
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SortBottomSheet(
        initialSort: initialSort,
        onApply: onApply,
        availableOptions: availableOptions,
      ),
    );
  }
}

class _SortBottomSheetState extends State<SortBottomSheet> {
  late SortOption _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.initialSort;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ColorConstants.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: widget.availableOptions.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              color: ColorConstants.dividerColor,
            ),
            itemBuilder: (context, index) {
              final option = widget.availableOptions[index];
              return _buildSortOption(option);
            },
          ),
          const SizedBox(height: 8),
          _buildApplyButton(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ColorConstants.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Sort By',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            color: ColorConstants.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(SortOption option) {
    final isSelected = _selectedSort == option;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedSort = option),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorConstants.primaryOrange.withOpacity(0.1)
                      : ColorConstants.inputBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  option.icon,
                  size: 20,
                  color: isSelected
                      ? ColorConstants.primaryOrange
                      : ColorConstants.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? ColorConstants.primaryOrange
                        : ColorConstants.textPrimary,
                  ),
                ),
              ),
              Radio<SortOption>(
                value: option,
                groupValue: _selectedSort,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSort = value);
                  }
                },
                activeColor: ColorConstants.primaryOrange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _applySort,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Apply',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _applySort() {
    widget.onApply(_selectedSort);
    Navigator.pop(context);
  }
}

// Helper widget to show sort button with current selection
class SortButton extends StatelessWidget {
  final SortOption currentSort;
  final void Function(SortOption) onSortChanged;
  final List<SortOption> availableOptions;

  const SortButton({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    this.availableOptions = const [
      SortOption.priceLowToHigh,
      SortOption.priceHighToLow,
      SortOption.nameAZ,
      SortOption.nameZA,
      SortOption.latest,
      SortOption.oldest,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        SortBottomSheet.show(
          context: context,
          initialSort: currentSort,
          onApply: onSortChanged,
          availableOptions: availableOptions,
        );
      },
      icon: const Icon(Icons.sort, size: 18),
      label: const Text('Sort'),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorConstants.textPrimary,
        side: const BorderSide(color: ColorConstants.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
