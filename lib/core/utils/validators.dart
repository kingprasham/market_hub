import 'package:get/get.dart';
import '../constants/app_constants.dart';

class Validators {
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < AppConstants.minNameLength) {
      return 'Name is too short';
    }
    if (value.trim().length > AppConstants.maxNameLength) {
      return 'Name is too long';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name should only contain letters';
    }
    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phone = value.replaceAll(RegExp(r'\D'), '');
    if (phone.length != AppConstants.phoneLength) {
      return 'Phone number must be ${AppConstants.phoneLength} digits';
    }
    return null;
  }

  // WhatsApp number validation
  static String? validateWhatsApp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'WhatsApp number is required';
    }
    final phone = value.replaceAll(RegExp(r'\D'), '');
    if (phone.length != AppConstants.phoneLength) {
      return 'WhatsApp number must be ${AppConstants.phoneLength} digits';
    }
    return null;
  }

  // Pincode validation
  static String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value.trim())) {
      return 'Pincode must be ${AppConstants.pincodeLength} digits';
    }
    return null;
  }

  // PIN validation (4-digit)
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }
    if (value.length != AppConstants.pinLength) {
      return 'PIN must be ${AppConstants.pinLength} digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }
    return null;
  }

  // Confirm PIN validation
  static String? validateConfirmPin(String? value, String originalPin) {
    final pinError = validatePin(value);
    if (pinError != null) return pinError;

    if (value != originalPin) {
      return 'PINs do not match';
    }
    return null;
  }

  // OTP validation
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != AppConstants.otpLength) {
      return 'OTP must be ${AppConstants.otpLength} digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Terms acceptance validation
  static String? validateTermsAccepted(bool? accepted) {
    if (accepted != true) {
      return 'Please accept terms and conditions';
    }
    return null;
  }

  // Image/File validation
  static String? validateVisitingCard(String? path) {
    if (path == null || path.isEmpty) {
      return 'Please upload your visiting card';
    }
    return null;
  }
}
