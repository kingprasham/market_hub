import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';

class CompanyDetailsPage extends StatefulWidget {
  const CompanyDetailsPage({super.key});

  @override
  State<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController(text: 'ABC Trading Co.');
  final _gstController = TextEditingController(text: '27AADCB2230M1ZT');
  final _panController = TextEditingController(text: 'AADCB2230M');
  final _addressController = TextEditingController(text: '123 Business Park, Mumbai');
  final _cityController = TextEditingController(text: 'Mumbai');
  final _stateController = TextEditingController(text: 'Maharashtra');
  final _pincodeController = TextEditingController(text: '400001');

  @override
  void dispose() {
    _companyNameController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
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
          'Company Details',
          style: TextStyles.h5.copyWith(color: ColorConstants.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorConstants.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Info Section
              _buildSectionHeader('Company Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _companyNameController,
                label: 'Company Name',
                icon: Icons.business,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _gstController,
                      label: 'GST Number',
                      icon: Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _panController,
                      label: 'PAN Number',
                      icon: Icons.credit_card,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Address Section
              _buildSectionHeader('Address'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _addressController,
                label: 'Street Address',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      icon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State',
                      icon: Icons.map,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 150,
                child: _buildTextField(
                  controller: _pincodeController,
                  label: 'Pincode',
                  icon: Icons.pin_drop,
                  keyboardType: TextInputType.number,
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveCompanyDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Company Details',
                    style: TextStyles.buttonText.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyles.h6.copyWith(color: ColorConstants.textPrimary),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: ColorConstants.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  void _saveCompanyDetails() {
    if (_formKey.currentState!.validate()) {
      Get.snackbar(
        'Success',
        'Company details updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.positiveGreen,
        colorText: Colors.white,
      );
      Get.back();
    }
  }
}
