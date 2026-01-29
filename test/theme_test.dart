import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:main10app/theme.dart';

void main() {
  test('Topic: Theme Verification - Premium Indigo Theme', () {
    // 1. Verify ColorScheme
    expect(appTheme.colorScheme.primary, const Color(0xFF3F51B5));
    expect(appTheme.colorScheme.secondary, const Color(0xFFE91E63));
    
    // 2. Verify CardTheme
    expect(appTheme.cardTheme.color, Colors.white);
    expect(appTheme.cardTheme.elevation, 2.0);
    expect(appTheme.cardTheme.shape, isA<RoundedRectangleBorder>());
    final shape = appTheme.cardTheme.shape as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(16));

    // 3. Verify InputTheme
    expect(appTheme.inputDecorationTheme.filled, true);
    expect(appTheme.inputDecorationTheme.fillColor, Colors.white);
    expect(appTheme.inputDecorationTheme.focusedBorder, isA<OutlineInputBorder>());
    
    // 4. Verify useMaterial3
    expect(appTheme.useMaterial3, true);
  });
}
