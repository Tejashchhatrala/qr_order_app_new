import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final bool enableNotifications;
  final bool enableSoundEffects;
  final String language;
  final String currency;

  AppSettings({
    this.themeMode = ThemeMode.system,
    this.enableNotifications = true,
    this.enableSoundEffects = true,
    this.language = 'en',
    this.currency = 'INR',
  });

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.index,
        'enableNotifications': enableNotifications,
        'enableSoundEffects': enableSoundEffects,
        'language': language,
        'currency': currency,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values[json['themeMode'] ?? 0],
      enableNotifications: json['enableNotifications'] ?? true,
      enableSoundEffects: json['enableSoundEffects'] ?? true,
      language: json['language'] ?? 'en',
      currency: json['currency'] ?? 'INR',
    );
  }
}
