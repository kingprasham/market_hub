import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/loaders/shimmer_loader.dart';
import '../../../data/models/market/spot_bulletin_model.dart';
import '../../../data/models/market/ferrous_price_model.dart';
import '../../../data/models/market/non_ferrous_sheet_data.dart';
import '../controller/spot_price_controller.dart';
import '../../home/ui/widgets/side_menu.dart';

import 'package:intl/intl.dart';
import '../../../shared/widgets/common/common_app_bar_title.dart';

class SpotPriceScreen extends GetView<SpotPriceController> {
  const SpotPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      drawer: const SideMenu(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Obx(() => CommonAppBarTitle(
          title: 'Spot Prices',
          subtitle: controller.lastUpdated.value != null
              ? 'Last Updated: ${DateFormat('hh:mm:ss a').format(controller.lastUpdated.value!)}'
              : 'Updating...',
        )),
        actions: [
          Obx(() => controller.isRefreshing.value
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: controller.refreshData,
                  icon: const Icon(
                    Icons.refresh,
                    color: ColorConstants.textPrimary,
                  ),
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter (Ferrous / Non-Ferrous / Minor and Ferro)
          Obx(() => Column(
            children: [
              _buildCategoryFilter(),
              if (controller.selectedCategory.value == 'Steel')
                _buildFerrousSubCategoryFilter(),
              if (controller.selectedCategory.value == 'Minor and Ferro')
                _buildMinorSubCategoryFilter(),
            ],
          )),

          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const ShimmerListLoader();
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildBaseMetalContent(),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.spotCategories.length,
          itemBuilder: (context, index) {
            final category = controller.spotCategories[index];
            return Obx(() {
              final isSelected = controller.selectedCategory.value == category;
              return GestureDetector(
                onTap: () => controller.selectedCategory.value = category,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? ColorConstants.primaryBlue : Colors.grey[100],
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? ColorConstants.primaryBlue : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : ColorConstants.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildFerrousSubCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: SizedBox(
        height: 32,
        child: Obx(() {
            if (controller.ferrousSubCategories.isEmpty) return const SizedBox.shrink();
            
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.ferrousSubCategories.length,
              itemBuilder: (context, index) {
                final subCat = controller.ferrousSubCategories[index];
                return Obx(() {
                  final isSelected = controller.selectedFerrousSubCategory.value == subCat;
                  return GestureDetector(
                    onTap: () => controller.selectedFerrousSubCategory.value = subCat,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? ColorConstants.primaryOrange.withAlpha(25) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? ColorConstants.primaryOrange : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        subCat,
                        style: TextStyles.caption.copyWith(
                          color: isSelected ? ColorConstants.primaryOrange : ColorConstants.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                });
              },
            );
        }),
      ),
    );
  }

  Widget _buildMinorSubCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: SizedBox(
        height: 32,
        child: Obx(() {
            if (controller.minorSubCategories.isEmpty) return const SizedBox.shrink();
            
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.minorSubCategories.length,
              itemBuilder: (context, index) {
                final subCat = controller.minorSubCategories[index];
                return Obx(() {
                  final isSelected = controller.selectedMinorSubCategory.value == subCat;
                  return GestureDetector(
                    onTap: () => controller.selectedMinorSubCategory.value = subCat,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? ColorConstants.primaryOrange.withAlpha(25) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? ColorConstants.primaryOrange : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        subCat,
                        style: TextStyles.caption.copyWith(
                          color: isSelected ? ColorConstants.primaryOrange : ColorConstants.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                });
              },
            );
        }),
      ),
    );
  }

  Widget _buildCityFilter() {
    // Only show for Non-Ferrous (Legacy) or BME if needed
    // For now, hiding city filter for Ferrous as it has its own table structure
    // And Non-Ferrous might still use it?
    
    // Logic: If Tab is BME, show cities. 
    // If Tab is Base Metal AND Category is Non-Ferrous, maybe show cities?
    // User requirement: "inside base metals remove the existing filters which says all, bhiwadi and delhi"
    // So for Base Metal tab, we DON'T show this City Filter anymore.
    
    if (controller.selectedTabIndex.value == 0) return const SizedBox.shrink();

    if (controller.availableCities.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.availableCities.length,
          itemBuilder: (context, index) {
            final city = controller.availableCities[index];

            return Obx(() {
              final isSelected = controller.selectedCity.value == city;

              return GestureDetector(
                onTap: () => controller.selectedCity.value = city,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? ColorConstants.primaryBlue : Colors.grey[100],
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? ColorConstants.primaryBlue : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    city,
                    style: TextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : ColorConstants.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final isSelected = controller.selectedTabIndex.value == index;

    return GestureDetector(
      onTap: () => controller.selectedTabIndex.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: index == 0 ? 8 : 0),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstants.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? ColorConstants.primaryBlue
                : ColorConstants.borderColor,
          ),
        ),
        child: Center(
          child: Text(
            controller.tabs[index],
            style: TextStyles.bodyMedium.copyWith(
              color: isSelected ? Colors.white : ColorConstants.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Tab content is now always base metal content (BME tab removed)

  Widget _buildBaseMetalContent() {
    return Obx(() {
        final category = controller.selectedCategory.value;
        
        if (category == 'Steel') {
            return _buildFerrousList();
        } else if (category == 'Non-Ferrous') {
             // Show existing logic for Non-Ferrous
             return _buildNonFerrousList();
        } else {
             // Minor and Ferro
             return _buildMinorList();
        }
    });
  }

  Widget _buildFerrousList() {
      // Return a table or list of cards for the selected sub-category
      // Data is in controller.ferrousPrices
      return Obx(() {
          if (controller.ferrousPrices.isEmpty) {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text('Loading Steel Prices...', style: TextStyles.caption),
                      ],
                  ),
              );
          }
          
          return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.ferrousPrices.length,
              itemBuilder: (context, index) {
                  final item = controller.ferrousPrices[index];
                  final key = 'Ferrous|${item.category}|${item.city}';
                  return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text(
                                    item.city,
                                    style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                    Formatters.formatCurrency(item.price),
                                    style: TextStyles.bodyLarge.copyWith(
                                        color: ColorConstants.primaryBlue,
                                        fontWeight: FontWeight.bold
                                    ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getUpdatedAgo(key),
                            style: TextStyles.caption.copyWith(color: ColorConstants.textHint, fontSize: 10),
                          ),
                        ],
                      ),
                  );
              },
          );
      });
  }

  Widget _buildNonFerrousList() {
    return Obx(() {
      final nfData = controller.nonFerrousData.value;
      if (nfData == null || nfData.cities.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading Non-Ferrous Prices...', style: TextStyles.caption),
            ],
          ),
        );
      }

      final selectedCity = controller.selectedNonFerrousCity.value;
      final cityData = nfData.getCityData(selectedCity);
      final sections = cityData?.sections ?? [];

      return Column(
        children: [
          // ── City filter pills ──
          _buildNonFerrousCityFilter(),
          // ── Sections list ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (sections.isNotEmpty)
                  ...sections.map((section) => _buildCitySection(section)),
                if (sections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No data available for $selectedCity',
                        style: TextStyles.bodyMedium.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                    ),
                  ),
                // Delhi-only expanded sections (Brass, Gun Metal, Lead, etc.)
                if (selectedCity.toUpperCase() == 'DELHI' &&
                    nfData.delhiSections.isNotEmpty)
                  ...nfData.delhiSections.map((section) => _buildDelhiSection(section)),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCitySection(CityMetalSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.sectionName.toUpperCase() != 'GENERAL') ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD740), // Vibrant Yellow/Amber
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              section.sectionName.toUpperCase(),
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: ColorConstants.textPrimary,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ..._buildItemRows(section.items, section.sectionName),
      ],
    );
  }


  Widget _buildNonFerrousCityFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 36,
        child: Obx(() {
          final cities = controller.nonFerrousCities;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
              return Obx(() {
                final isSelected =
                    controller.selectedNonFerrousCity.value.toUpperCase() ==
                        city.toUpperCase();
                return GestureDetector(
                  onTap: () => controller.selectedNonFerrousCity.value = city,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorConstants.primaryBlue
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? ColorConstants.primaryBlue
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      _formatCityName(city),
                      style: TextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : ColorConstants.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              });
            },
          );
        }),
      ),
    );
  }

  List<Widget> _buildItemRows(List<MetalItem> items, String sectionName) {
    return items.map((item) {
      // Sub-header row (e.g. "COPPER SCRAP (ARM)") — no prices, just a label
      if (item.isSubHeader) {
        return Container(
          margin: const EdgeInsets.only(bottom: 4, top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            item.name,
            style: TextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorConstants.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        );
      }

      final hasTwoPrices = item.price2 != null;
      final key = 'NonFerrous|$sectionName|${item.name}|${controller.selectedNonFerrousCity.value}';
      
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.name.replaceAll('*', '').replaceAll(':', '').trim(),
                    style: TextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (hasTwoPrices) ...[
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.displayPrice1,
                          style: TextStyles.bodyLarge.copyWith(
                            color: ColorConstants.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.displayPrice2,
                          style: TextStyles.bodyLarge.copyWith(
                            color: const Color(0xFF1E8449),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.displayPrice1,
                      textAlign: TextAlign.end,
                      style: TextStyles.bodyLarge.copyWith(
                        color: ColorConstants.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _getUpdatedAgo(key),
              style: TextStyles.caption.copyWith(color: ColorConstants.textHint, fontSize: 10),
            ),
          ],
        ),
      );
    }).toList();
  }


  Widget _buildDelhiSection(DelhiMetalSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD740),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            section.sectionName.toUpperCase(),
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: ColorConstants.textPrimary,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        ..._buildItemRows(section.items, section.sectionName),
      ],
    );
  }

  String _formatCityName(String city) {
    // Title case: DELHI -> Delhi
    if (city.isEmpty) return city;
    return city[0].toUpperCase() + city.substring(1).toLowerCase();
  }

  Widget _buildDynamicMetalList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.availableMetals.length + 1,
      itemBuilder: (context, index) {
        if (index == controller.availableMetals.length) {
          return const SizedBox(height: 80);
        }

        final metalName = controller.availableMetals[index];
        final metalInfo = SpotMetalConfig.getMetalInfo(metalName);

        return _buildMetalCard(metalName, metalInfo);
      },
    );
  }

  Widget _buildMetalCard(String metalName, MetalInfo? metalInfo) {
    final gradientColors = metalInfo != null
        ? metalInfo.gradientColors.map((c) => Color(c)).toList()
        : [Colors.blue, Colors.blueAccent];
    final symbol = metalInfo?.symbol ?? metalName.substring(0, 2).toUpperCase();

    return GestureDetector(
      onTap: () => _navigateToDetail(metalName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        symbol,
                        style: TextStyles.h6.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metalName,
                          style: TextStyles.h6.copyWith(color: Colors.white),
                        ),
                        Text(
                          '${controller.getSubtypesForMetal(metalName).length} variants available',
                          style: TextStyles.caption.copyWith(
                            color: Colors.white.withAlpha(204),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildMetalQuickInfo(metalName),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMinorList() {
      return Obx(() {
          if (controller.minorPrices.isEmpty) {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          if (controller.isLoading.value) ...[
                             const CircularProgressIndicator(),
                             const SizedBox(height: 16),
                             Text('Loading Minor Prices...', style: TextStyles.caption),
                          ] else 
                             Text('No data available', style: TextStyles.caption),
                      ],
                  ),
              );
          }
          
          return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.minorPrices.length,
              itemBuilder: (context, index) {
                  final item = controller.minorPrices[index];
                  final key = 'Minor|${item.category}|${item.item}|${item.quality}';
                  // Item, Quality, Price, Unit, Date
                  return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.item, // Item Name
                                  style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.formatCurrency(double.tryParse(item.price.replaceAll(',', '')) ?? 0),
                                    style: TextStyles.bodyLarge.copyWith(
                                        color: ColorConstants.primaryBlue,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Text(
                                    item.unit,
                                    style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Expanded(
                                 child: Text(
                                   item.quality, // Quality & Origin
                                   style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
                                   maxLines: 1,
                                   overflow: TextOverflow.ellipsis,
                                 ),
                               ),
                               Text(
                                 item.date,
                                 style: TextStyles.caption.copyWith(color: ColorConstants.textSecondary),
                               ),
                             ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getUpdatedAgo(key),
                            style: TextStyles.caption.copyWith(color: ColorConstants.textHint, fontSize: 10),
                          ),
                        ],
                      ),
                  );
              },
          );
      });
  }

  Widget _buildMetalQuickInfo(String metalName) {
    final entries = controller.getFilteredEntries(metalName);
    if (entries.isEmpty) {
      return Text(
        'Tap to view prices',
        style: TextStyles.bodySmall.copyWith(
          color: ColorConstants.textSecondary,
        ),
      );
    }

    // Show first entry as sample
    final sample = entries.first;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sample.subtype,
              style: TextStyles.bodySmall.copyWith(
                color: ColorConstants.textSecondary,
              ),
            ),
            Text(
              '₹${sample.cashPrice.toStringAsFixed(0)}',
              style: TextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(25),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${_getUniqueCities(entries).length} cities',
            style: TextStyles.caption.copyWith(
              color: ColorConstants.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Set<String> _getUniqueCities(List<dynamic> entries) {
    final cities = <String>{};
    for (final entry in entries) {
      cities.add(entry.city);
    }
    return cities;
  }

  Widget _buildBmeContent() {
    return Obx(() {
      // Filter by selected city
      final filteredPrices = controller.selectedCity.value == 'All'
          ? controller.bmePrices.toList()
          : controller.bmePrices
              .where((p) => p.location == controller.selectedCity.value)
              .toList();

      // Group by location
      final groupedByLocation = <String, List<dynamic>>{};
      for (final price in filteredPrices) {
        final location = price.location;
        if (!groupedByLocation.containsKey(location)) {
          groupedByLocation[location] = [];
        }
        groupedByLocation[location]!.add(price);
      }

      if (groupedByLocation.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.update,
                  size: 64,
                  color: ColorConstants.textSecondary.withAlpha(100),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading real-time BME prices...',
                  style: TextStyles.bodyLarge.copyWith(
                    color: ColorConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Data refreshes every 5 minutes',
                  style: TextStyles.bodySmall.copyWith(
                    color: ColorConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...groupedByLocation.entries.map((entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationHeader(entry.key),
              ...entry.value.map((item) => _buildBmeCard(item)),
              const SizedBox(height: 16),
            ],
          )),
          const SizedBox(height: 80),
        ],
      );
    });
  }

  Widget _buildLocationHeader(String location) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 18,
            color: ColorConstants.primaryOrange,
          ),
          const SizedBox(width: 6),
          Text(
            location,
            style: TextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotCard(dynamic item) {
    final isPositive = item.change >= 0;

    return Obx(() {
      controller.watchlistUpdateTrigger.value; // Trigger rebuild
      final isInWatchlist = controller.isInWatchlist(item.id);

      return GestureDetector(
        onTap: () => _navigateToDetail(item.symbol),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getMetalColor(item.symbol).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item.symbol.substring(0, item.symbol.length > 2 ? 2 : item.symbol.length),
                    style: TextStyles.h6.copyWith(
                      color: _getMetalColor(item.symbol),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                      item.unit,
                      style: TextStyles.caption.copyWith(
                        color: ColorConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatCurrency(item.price),
                    style: TextStyles.h5,
                  ),
                  const SizedBox(height: 4),
                  Row(
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
                        '${isPositive ? '+' : ''}${item.change.toStringAsFixed(2)}',
                        style: TextStyles.bodySmall.copyWith(
                          color: isPositive
                              ? ColorConstants.positiveGreen
                              : ColorConstants.negativeRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Add Star Icon
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => controller.toggleWatchlist(item),
                icon: Icon(
                  isInWatchlist ? Icons.star : Icons.star_border,
                  color: isInWatchlist ? Colors.amber : ColorConstants.textSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _navigateToDetail(String symbol) {
    final lowerSymbol = symbol.toLowerCase();

    if (lowerSymbol.contains('copper')) {
      Get.toNamed('/copper-detail');
    } else if (lowerSymbol.contains('brass')) {
      Get.toNamed('/brass-detail');
    } else if (lowerSymbol.contains('gun')) {
      Get.toNamed('/gun-metal-detail');
    } else if (lowerSymbol.contains('lead')) {
      Get.toNamed('/lead-detail');
    } else if (lowerSymbol.contains('nickel')) {
      Get.toNamed('/nickel-detail');
    } else if (lowerSymbol.contains('tin')) {
      Get.toNamed('/tin-detail');
    } else if (lowerSymbol.contains('zinc')) {
      Get.toNamed('/zinc-detail');
    } else if (lowerSymbol.contains('aluminium')) {
      Get.toNamed('/aluminium-detail');
    }
  }

  Widget _buildBmeCard(dynamic item) {
    final isPositive = item.change >= 0;
    final isGold = item.symbol.toLowerCase().contains('gold');

    return Obx(() {
      controller.watchlistUpdateTrigger.value; // Trigger rebuild
      final isInWatchlist = controller.isInWatchlist(item.id);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGold
                ? Colors.amber.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
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
                    gradient: isGold
                        ? const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFC0C0C0), Color(0xFFA8A8A8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isGold ? Icons.star : Icons.brightness_7,
                    color: isGold ? Colors.white : Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.name,
                            style: TextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.purity != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isGold
                                    ? Colors.amber.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.purity,
                                style: TextStyles.caption.copyWith(
                                  color: isGold ? Colors.amber[700] : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.unit,
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(item.price),
                      style: TextStyles.h5,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? ColorConstants.positiveGreen.withOpacity(0.1)
                            : ColorConstants.negativeRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.trending_up : Icons.trending_down,
                            size: 14,
                            color: isPositive
                                ? ColorConstants.positiveGreen
                                : ColorConstants.negativeRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isPositive ? '+' : ''}${item.changePercent.toStringAsFixed(2)}%',
                            style: TextStyles.caption.copyWith(
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
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  'Last Price: ${Formatters.formatCurrency(item.price)}',
                  style: TextStyles.caption.copyWith(
                    color: ColorConstants.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => controller.toggleWatchlist(item),
                  icon: Icon(
                    isInWatchlist ? Icons.star : Icons.star_border,
                    color: isInWatchlist ? Colors.amber : ColorConstants.textSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Color _getMetalColor(String symbol) {
    final lowerSymbol = symbol.toLowerCase();
    if (lowerSymbol.contains('copper')) return const Color(0xFFB87333);
    if (lowerSymbol.contains('aluminium')) return Colors.blueGrey;
    if (lowerSymbol.contains('zinc')) return Colors.teal;
    if (lowerSymbol.contains('lead')) return Colors.grey;
    if (lowerSymbol.contains('nickel')) return Colors.indigo;
    if (lowerSymbol.contains('tin')) return Colors.brown;
    return ColorConstants.primaryBlue;
  }

  void _showAddToWatchlistDialog(dynamic item) {
    Get.snackbar(
      'Added to Watchlist',
      '${item.name} has been added to your watchlist',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ColorConstants.positiveGreen,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }
  String _getUpdatedAgo(String key) {
    final updated = controller.itemLastUpdated[key];
    if (updated == null) return 'Updated: Just now';
    return 'Updated: ${Formatters.formatRelativeTime(updated)}';
  }
}
