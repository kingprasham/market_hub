import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';

class FilterOptions {
  final DateTimeRange? dateRange;
  final List<String> selectedLocations;
  final List<String> selectedExchanges;
  final List<String> selectedMetals;

  FilterOptions({
    this.dateRange,
    this.selectedLocations = const [],
    this.selectedExchanges = const [],
    this.selectedMetals = const [],
  });

  FilterOptions copyWith({
    DateTimeRange? dateRange,
    List<String>? selectedLocations,
    List<String>? selectedExchanges,
    List<String>? selectedMetals,
  }) {
    return FilterOptions(
      dateRange: dateRange ?? this.dateRange,
      selectedLocations: selectedLocations ?? this.selectedLocations,
      selectedExchanges: selectedExchanges ?? this.selectedExchanges,
      selectedMetals: selectedMetals ?? this.selectedMetals,
    );
  }

  int get activeFilterCount {
    int count = 0;
    if (dateRange != null) count++;
    if (selectedLocations.isNotEmpty) count++;
    if (selectedExchanges.isNotEmpty) count++;
    if (selectedMetals.isNotEmpty) count++;
    return count;
  }

  bool get hasFilters => activeFilterCount > 0;
}

class FilterBottomSheet extends StatefulWidget {
  final FilterOptions initialFilters;
  final void Function(FilterOptions) onApply;
  final bool showDateRange;
  final bool showLocations;
  final bool showExchanges;
  final bool showMetals;

  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
    this.showDateRange = true,
    this.showLocations = true,
    this.showExchanges = true,
    this.showMetals = true,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();

  static void show({
    required BuildContext context,
    required FilterOptions initialFilters,
    required void Function(FilterOptions) onApply,
    bool showDateRange = true,
    bool showLocations = true,
    bool showExchanges = true,
    bool showMetals = true,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialFilters: initialFilters,
        onApply: onApply,
        showDateRange: showDateRange,
        showLocations: showLocations,
        showExchanges: showExchanges,
        showMetals: showMetals,
      ),
    );
  }
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late DateTimeRange? _dateRange;
  late List<String> _selectedLocations;
  late List<String> _selectedExchanges;
  late List<String> _selectedMetals;

  final List<String> _availableLocations = [
    'India',
    'China',
    'United States',
    'United Kingdom',
    'Singapore',
    'Japan',
  ];

  final List<String> _availableExchanges = [
    'London',
    'China',
    'COMEX',
    'MCX',
    'NYMEX',
    'TOCOM',
  ];

  final List<String> _availableMetals = [
    'Copper',
    'Aluminium',
    'Zinc',
    'Nickel',
    'Lead',
    'Tin',
    'Brass',
    'Gun Metal',
  ];

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initialFilters.dateRange;
    _selectedLocations = List.from(widget.initialFilters.selectedLocations);
    _selectedExchanges = List.from(widget.initialFilters.selectedExchanges);
    _selectedMetals = List.from(widget.initialFilters.selectedMetals);
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
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showDateRange) ...[
                    _buildDateRangeSection(),
                    const SizedBox(height: 24),
                  ],
                  if (widget.showLocations) ...[
                    _buildLocationsSection(),
                    const SizedBox(height: 24),
                  ],
                  if (widget.showExchanges) ...[
                    _buildExchangesSection(),
                    const SizedBox(height: 24),
                  ],
                  if (widget.showMetals) ...[
                    _buildMetalsSection(),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomBar(),
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
            'Filters',
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

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: ColorConstants.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: ColorConstants.primaryOrange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dateRange != null
                        ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                        : 'Select date range',
                    style: TextStyle(
                      fontSize: 14,
                      color: _dateRange != null
                          ? ColorConstants.textPrimary
                          : ColorConstants.textHint,
                    ),
                  ),
                ),
                if (_dateRange != null)
                  IconButton(
                    onPressed: () => setState(() => _dateRange = null),
                    icon: const Icon(Icons.clear, size: 20),
                    color: ColorConstants.textHint,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Locations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableLocations.map((location) {
            final isSelected = _selectedLocations.contains(location);
            return FilterChip(
              label: Text(location),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLocations.add(location);
                  } else {
                    _selectedLocations.remove(location);
                  }
                });
              },
              selectedColor: ColorConstants.primaryOrange,
              checkmarkColor: Colors.white,
              backgroundColor: ColorConstants.inputBackground,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : ColorConstants.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExchangesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exchanges',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableExchanges.map((exchange) {
            final isSelected = _selectedExchanges.contains(exchange);
            return FilterChip(
              label: Text(exchange),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedExchanges.add(exchange);
                  } else {
                    _selectedExchanges.remove(exchange);
                  }
                });
              },
              selectedColor: ColorConstants.primaryBlue,
              checkmarkColor: Colors.white,
              backgroundColor: ColorConstants.inputBackground,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : ColorConstants.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metal Types',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._availableMetals.map((metal) {
          final isSelected = _selectedMetals.contains(metal);
          return CheckboxListTile(
            title: Text(
              metal,
              style: const TextStyle(
                fontSize: 14,
                color: ColorConstants.textPrimary,
              ),
            ),
            value: isSelected,
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedMetals.add(metal);
                } else {
                  _selectedMetals.remove(metal);
                }
              });
            },
            activeColor: ColorConstants.primaryOrange,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: ColorConstants.surfaceColor,
        border: Border(
          top: BorderSide(
            color: ColorConstants.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primaryOrange,
                side: const BorderSide(color: ColorConstants.primaryOrange),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Reset',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _applyFilters,
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
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ColorConstants.primaryOrange,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _resetFilters() {
    setState(() {
      _dateRange = null;
      _selectedLocations.clear();
      _selectedExchanges.clear();
      _selectedMetals.clear();
    });
  }

  void _applyFilters() {
    final filters = FilterOptions(
      dateRange: _dateRange,
      selectedLocations: _selectedLocations,
      selectedExchanges: _selectedExchanges,
      selectedMetals: _selectedMetals,
    );

    widget.onApply(filters);
    Navigator.pop(context);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
