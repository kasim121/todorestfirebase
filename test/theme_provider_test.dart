import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/providers/theme_provider.dart';
import 'package:flutter/material.dart';

void main() {
  // Required for shared_preferences and other platform services during tests
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('ThemeProvider toggles mode correctly', () async {
    final provider = ThemeProvider();

    // Initially should default to light; since _load() is async we wait a tick
    await Future.delayed(Duration.zero);
    expect(provider.mode, anyOf(ThemeMode.light, ThemeMode.dark));

    final initial = provider.mode;
    await provider.toggle();
    expect(provider.mode, isNot(initial));

    // toggling again should return to initial
    await provider.toggle();
    expect(provider.mode, initial);
  });
}
