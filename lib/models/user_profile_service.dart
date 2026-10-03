import 'dart:io';
import 'package:flutter/material.dart';

/// Singleton Service to manage shared user profile state across the app
class UserProfileService extends ChangeNotifier {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  String _name = 'Nguyễn Văn Minh';
  String _phone = '090 123 4567';
  String _email = 'minh.nguyen@gmail.com';
  String _address = 'P.1204 - Tòa S2.05, Vinhomes Grand Park';
  File? _avatarFile;

  String get name => _name;
  String get phone => _phone;
  String get email => _email;
  String get address => _address;
  File? get avatarFile => _avatarFile;

  /// Returns the short display name for greetings (e.g., "Minh" from "Nguyễn Văn Minh")
  String get shortName {
    final parts = _name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.last : _name;
  }

  /// Returns uppercase initials for the avatar placeholder (e.g., "NM")
  String get initials {
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return 'U';
  }

  void updateName(String newName) {
    final trimmed = newName.trim();
    if (trimmed.isNotEmpty && trimmed != _name) {
      _name = trimmed;
      notifyListeners();
    }
  }

  void updatePhone(String newPhone) {
    final trimmed = newPhone.trim();
    if (trimmed.isNotEmpty && trimmed != _phone) {
      _phone = trimmed;
      notifyListeners();
    }
  }

  void updateEmail(String newEmail) {
    final trimmed = newEmail.trim();
    if (trimmed.isNotEmpty && trimmed != _email) {
      _email = trimmed;
      notifyListeners();
    }
  }

  void updateAddress(String newAddress) {
    final trimmed = newAddress.trim();
    if (trimmed.isNotEmpty && trimmed != _address) {
      _address = trimmed;
      notifyListeners();
    }
  }

  void updateAvatar(File? file) {
    _avatarFile = file;
    notifyListeners();
  }
}
