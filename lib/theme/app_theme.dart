// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Teal-based Audio Spectrum Color Palette
  static const Color primaryLight = Color(0xFF00695C); // Teal 800
  static const Color primaryVariantLight = Color(0xFF004D40); // Teal 900
  static const Color secondaryLight = Color(0xFF00897B); // Teal 600
  static const Color secondaryVariantLight = Color(0xFF4DB6AC); // Teal 300
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color errorLight = Color(0xFFFF6B6B);
  static const Color warningLight = Color(0xFFFFB800);
  static const Color successLight = Color(0xFF4DB6AC); // Teal 300
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onBackgroundLight = Color(0xFF2D3436);
  static const Color onSurfaceLight = Color(0xFF2D3436);
  static const Color onErrorLight = Color(0xFFFFFFFF);

  static const Color primaryDark = Color(0xFF4DB6AC); // Teal 300
  static const Color primaryVariantDark = Color(0xFF00695C); // Teal 800
  static const Color secondaryDark = Color(0xFF80CBC4); // Teal 200
  static const Color secondaryVariantDark = Color(0xFF004D40); // Teal 900
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color errorDark = Color(0xFFFF6B6B);
  static const Color warningDark = Color(0xFFFFB800);
  static const Color successDark = Color(0xFF80CBC4); // Teal 200
  static const Color onPrimaryDark = Color(0xFF000000);
  static const Color onSecondaryDark = Color(0xFF000000);
  static const Color onBackgroundDark = Color(0xFFFFFFFF);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFFFFFFFF);

  // Card and dialog colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2C2C2C);
  static const Color dialogLight = Color(0xFFFFFFFF);
  static const Color dialogDark = Color(0xFF2C2C2C);

  // Shadow colors
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowDark = Color(0x1A000000);

  // Divider colors
  static const Color dividerLight = Color(0xFFE8E9EA);
  static const Color dividerDark = Color(0xFF404040);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF2D3436);
  static const Color textSecondaryLight = Color(0xFF636E72);
  static const Color textDisabledLight = Color(0xFFB2BEC3);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB2BEC3);
  static const Color textDisabledDark = Color(0xFF636E72);

  // Earning and financial colors
  static const Color earningActiveLight = Color(0xFF4DB6AC); // Teal 300
  static const Color earningInactiveLight = Color(0xFFB2DFDB); // Teal 100
  static const Color earningActiveDark = Color(0xFF80CBC4); // Teal 200
  static const Color earningInactiveDark = Color(0xFF374151);

  static ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: primaryLight,
          onPrimary: onPrimaryLight,
          primaryContainer: primaryVariantLight,
          onPrimaryContainer: onPrimaryLight,
          secondary: secondaryLight,
          onSecondary: onSecondaryLight,
          secondaryContainer: secondaryVariantLight,
          onSecondaryContainer: onSecondaryLight,
          tertiary: successLight,
          onTertiary: onPrimaryLight,
          tertiaryContainer: successLight,
          onTertiaryContainer: onPrimaryLight,
          error: errorLight,
          onError: onErrorLight,
          errorContainer: errorLight.withAlpha(26),
          onErrorContainer: errorLight,
          surface: surfaceLight,
          onSurface: onSurfaceLight,
          onSurfaceVariant: textSecondaryLight,
          outline: dividerLight,
          outlineVariant: dividerLight.withAlpha(128),
          shadow: shadowLight,
          scrim: shadowLight,
          inverseSurface: surfaceDark,
          onInverseSurface: onSurfaceDark,
          inversePrimary: primaryDark,
          surfaceTint: primaryLight),
      scaffoldBackgroundColor: backgroundLight,
      cardColor: cardLight,
      dividerColor: dividerLight,

      // AppBar Theme
      appBarTheme: AppBarTheme(
          backgroundColor: surfaceLight,
          foregroundColor: onSurfaceLight,
          elevation: 0,
          shadowColor: shadowLight,
          surfaceTintColor: surfaceLight,
          centerTitle: false,
          titleTextStyle: _buildTextTheme(isLight: true).titleLarge?.copyWith(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: textPrimaryLight),
          iconTheme: IconThemeData(color: textPrimaryLight, size: 24),
          actionsIconTheme: IconThemeData(color: textPrimaryLight, size: 24)),

      // Card Theme
      cardTheme: CardThemeData(
          color: cardLight,
          elevation: 2,
          shadowColor: shadowLight,
          surfaceTintColor: surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surfaceLight,
          selectedItemColor: primaryLight,
          unselectedItemColor: textSecondaryLight,
          selectedLabelStyle: _buildTextTheme(isLight: true)
              .labelSmall
              ?.copyWith(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  fontSize: 12),
          unselectedLabelStyle: _buildTextTheme(isLight: true)
              .labelSmall
              ?.copyWith(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          enableFeedback: true),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surfaceLight,
          indicatorColor: primaryLight.withAlpha(26),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _buildTextTheme(isLight: true).labelSmall?.copyWith(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  color: primaryLight);
            }
            return _buildTextTheme(isLight: true).labelSmall?.copyWith(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                color: textSecondaryLight);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: primaryLight, size: 24);
            }
            return IconThemeData(color: textSecondaryLight, size: 24);
          }),
          height: 80,
          elevation: 8),

      // Drawer Theme
      drawerTheme: DrawerThemeData(
          backgroundColor: surfaceLight,
          surfaceTintColor: surfaceLight,
          elevation: 16,
          shadowColor: shadowLight,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16)))),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
          tileColor: surfaceLight,
          selectedTileColor: primaryLight.withAlpha(26),
          selectedColor: primaryLight,
          iconColor: textSecondaryLight,
          textColor: textPrimaryLight,
          titleTextStyle: _buildTextTheme(isLight: true).bodyLarge?.copyWith(
              fontFamily: 'Source Sans Pro', fontWeight: FontWeight.w400),
          subtitleTextStyle: _buildTextTheme(isLight: true).bodyMedium?.copyWith(
              fontFamily: 'Source Sans Pro',
              fontWeight: FontWeight.w400,
              color: textSecondaryLight),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: secondaryVariantLight, foregroundColor: onPrimaryLight, elevation: 4, focusElevation: 6, hoverElevation: 6, highlightElevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(foregroundColor: onPrimaryLight, backgroundColor: primaryLight, disabledForegroundColor: textDisabledLight, disabledBackgroundColor: dividerLight, elevation: 2, shadowColor: shadowLight, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: _buildTextTheme(isLight: true).labelLarge?.copyWith(fontFamily: 'Source Sans Pro', fontWeight: FontWeight.w600))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: primaryLight, disabledForegroundColor: textDisabledLight, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), side: BorderSide(color: primaryLight, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: _buildTextTheme(isLight: true).labelLarge?.copyWith(fontFamily: 'Source Sans Pro', fontWeight: FontWeight.w600))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primaryLight, disabledForegroundColor: textDisabledLight, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: _buildTextTheme(isLight: true).labelLarge?.copyWith(fontFamily: 'Source Sans Pro', fontWeight: FontWeight.w600))),

      // Text Theme
      textTheme: _buildTextTheme(isLight: true),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(fillColor: surfaceLight, filled: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dividerLight, width: 1)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dividerLight, width: 1)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryLight, width: 2)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorLight, width: 1)), focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorLight, width: 2)), disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: textDisabledLight, width: 1)), labelStyle: _buildTextTheme(isLight: true).bodyMedium?.copyWith(fontFamily: 'Source Sans Pro', color: textSecondaryLight), hintStyle: _buildTextTheme(isLight: true).bodyMedium?.copyWith(fontFamily: 'Source Sans Pro', color: textDisabledLight), errorStyle: _buildTextTheme(isLight: true).bodySmall?.copyWith(fontFamily: 'Source Sans Pro', color: errorLight)),

      // Switch Theme
      switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        if (states.contains(WidgetState.disabled)) {
          return textDisabledLight;
        }
        return surfaceLight;
      }), trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight.withAlpha(128);
        }
        if (states.contains(WidgetState.disabled)) {
          return textDisabledLight.withAlpha(77);
        }
        return dividerLight;
      })),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryLight;
            }
            if (states.contains(WidgetState.disabled)) {
              return textDisabledLight;
            }
            return surfaceLight;
          }),
          checkColor: WidgetStateProperty.all(onPrimaryLight),
          side: BorderSide(color: dividerLight, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),

      // Radio Theme
      radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        if (states.contains(WidgetState.disabled)) {
          return textDisabledLight;
        }
        return dividerLight;
      })),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryLight, linearTrackColor: dividerLight, circularTrackColor: dividerLight),

      // Slider Theme
      sliderTheme: SliderThemeData(activeTrackColor: primaryLight, inactiveTrackColor: dividerLight, thumbColor: primaryLight, overlayColor: primaryLight.withAlpha(51), valueIndicatorColor: primaryLight, valueIndicatorTextStyle: _buildTextTheme(isLight: true).bodySmall?.copyWith(color: onPrimaryLight, fontFamily: 'JetBrains Mono')),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(labelColor: primaryLight, unselectedLabelColor: textSecondaryLight, indicatorColor: primaryLight, indicatorSize: TabBarIndicatorSize.label, labelStyle: _buildTextTheme(isLight: true).titleSmall?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.w600), unselectedLabelStyle: _buildTextTheme(isLight: true).titleSmall?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.w400)),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(decoration: BoxDecoration(color: textPrimaryLight.withAlpha(230), borderRadius: BorderRadius.circular(8)), textStyle: _buildTextTheme(isLight: true).bodySmall?.copyWith(color: surfaceLight, fontFamily: 'Source Sans Pro'), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(backgroundColor: textPrimaryLight, contentTextStyle: _buildTextTheme(isLight: true).bodyMedium?.copyWith(color: surfaceLight, fontFamily: 'Source Sans Pro'), actionTextColor: secondaryVariantLight, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),

      // Chip Theme
      chipTheme: ChipThemeData(backgroundColor: dividerLight, selectedColor: primaryLight.withAlpha(26), disabledColor: textDisabledLight.withAlpha(77), labelStyle: _buildTextTheme(isLight: true).bodySmall?.copyWith(fontFamily: 'Source Sans Pro'), secondaryLabelStyle: _buildTextTheme(isLight: true).bodySmall?.copyWith(fontFamily: 'Source Sans Pro', color: primaryLight), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      dialogTheme: DialogThemeData(backgroundColor: dialogLight));

  static ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: primaryDark,
          onPrimary: onPrimaryDark,
          primaryContainer: primaryVariantDark,
          onPrimaryContainer: onPrimaryDark,
          secondary: secondaryDark,
          onSecondary: onSecondaryDark,
          secondaryContainer: secondaryVariantDark,
          onSecondaryContainer: onSecondaryDark,
          tertiary: successDark,
          onTertiary: onPrimaryDark,
          tertiaryContainer: successDark,
          onTertiaryContainer: onPrimaryDark,
          error: errorDark,
          onError: onErrorDark,
          errorContainer: errorDark.withAlpha(26),
          onErrorContainer: errorDark,
          surface: surfaceDark,
          onSurface: onSurfaceDark,
          onSurfaceVariant: textSecondaryDark,
          outline: dividerDark,
          outlineVariant: dividerDark.withAlpha(128),
          shadow: shadowDark,
          scrim: shadowDark,
          inverseSurface: surfaceLight,
          onInverseSurface: onSurfaceLight,
          inversePrimary: primaryLight,
          surfaceTint: primaryDark),
      scaffoldBackgroundColor: backgroundDark,
      cardColor: cardDark,
      dividerColor: dividerDark,

      // AppBar Theme
      appBarTheme: AppBarTheme(
          backgroundColor: surfaceDark,
          foregroundColor: onSurfaceDark,
          elevation: 0,
          shadowColor: shadowDark,
          surfaceTintColor: surfaceDark,
          centerTitle: false,
          titleTextStyle: _buildTextTheme(isLight: false).titleLarge?.copyWith(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: textPrimaryDark),
          iconTheme: IconThemeData(color: textPrimaryDark, size: 24),
          actionsIconTheme: IconThemeData(color: textPrimaryDark, size: 24)),

      // Card Theme
      cardTheme: CardThemeData(
          color: cardDark,
          elevation: 2,
          shadowColor: shadowDark,
          surfaceTintColor: surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surfaceDark,
          selectedItemColor: primaryDark,
          unselectedItemColor: textSecondaryDark,
          selectedLabelStyle: _buildTextTheme(isLight: false).labelSmall?.copyWith(
              fontFamily: 'Roboto', fontWeight: FontWeight.w500, fontSize: 12),
          unselectedLabelStyle: _buildTextTheme(isLight: false)
              .labelSmall
              ?.copyWith(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          enableFeedback: true),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surfaceDark,
          indicatorColor: primaryDark.withAlpha(51),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _buildTextTheme(isLight: false).labelSmall?.copyWith(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  color: primaryDark);
            }
            return _buildTextTheme(isLight: false).labelSmall?.copyWith(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                color: textSecondaryDark);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: primaryDark, size: 24);
            }
            return IconThemeData(color: textSecondaryDark, size: 24);
          }),
          height: 80,
          elevation: 8),

      // Drawer Theme
      drawerTheme: DrawerThemeData(
          backgroundColor: surfaceDark,
          surfaceTintColor: surfaceDark,
          elevation: 16,
          shadowColor: shadowDark,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16)))),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
          tileColor: surfaceDark,
          selectedTileColor: primaryDark.withAlpha(51),
          selectedColor: primaryDark,
          iconColor: textSecondaryDark,
          textColor: textPrimaryDark,
          titleTextStyle: _buildTextTheme(isLight: false).bodyLarge?.copyWith(
              fontFamily: 'Source Sans Pro', fontWeight: FontWeight.w400),
          subtitleTextStyle: _buildTextTheme(isLight: false).bodyMedium?.copyWith(
              fontFamily: 'Source Sans Pro',
              fontWeight: FontWeight.w400,
              color: textSecondaryDark),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: secondaryDark, foregroundColor: onSecondaryDark, elevation: 4, focusElevation: 6, hoverElevation: 6, highlightElevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(foregroundColor: onPrimaryDark, backgroundColor: primaryDark, disabledForegroundColor: textDisabledDark, disabledBackgroundColor: dividerDark, elevation: 2, shadowColor: shadowDark, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: _buildTextTheme(isLight: false).labelLarge?.copyWith(fontFamily: 'Source Sans Pro', fontWeight: FontWeight.w600))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: primaryDark, disabledForegroundColor: textDisabledDark, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), side: BorderSide(color: primaryDark, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: _buildTextTheme(isLight: false).labelLarge?.copyWith(fontFamily: 'Source Sans Pro', fontWeight: FontWeight.w600))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primaryDark, disabledForegroundColor: textDisabledDark, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: _buildTextTheme(isLight: false).labelLarge?.copyWith(fontFamily: 'Source Sans Pro', fontWeight: FontWeight.w600))),

      // Text Theme
      textTheme: _buildTextTheme(isLight: false),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(fillColor: surfaceDark, filled: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dividerDark, width: 1)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dividerDark, width: 1)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryDark, width: 2)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorDark, width: 1)), focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorDark, width: 2)), disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: textDisabledDark, width: 1)), labelStyle: _buildTextTheme(isLight: false).bodyMedium?.copyWith(fontFamily: 'Source Sans Pro', color: textSecondaryDark), hintStyle: _buildTextTheme(isLight: false).bodyMedium?.copyWith(fontFamily: 'Source Sans Pro', color: textDisabledDark), errorStyle: _buildTextTheme(isLight: false).bodySmall?.copyWith(fontFamily: 'Source Sans Pro', color: errorDark)),

      // Switch Theme
      switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        if (states.contains(WidgetState.disabled)) {
          return textDisabledDark;
        }
        return surfaceDark;
      }), trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark.withAlpha(128);
        }
        if (states.contains(WidgetState.disabled)) {
          return textDisabledDark.withAlpha(77);
        }
        return dividerDark;
      })),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryDark;
            }
            if (states.contains(WidgetState.disabled)) {
              return textDisabledDark;
            }
            return surfaceDark;
          }),
          checkColor: WidgetStateProperty.all(onPrimaryDark),
          side: BorderSide(color: dividerDark, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),

      // Radio Theme
      radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        if (states.contains(WidgetState.disabled)) {
          return textDisabledDark;
        }
        return dividerDark;
      })),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryDark, linearTrackColor: dividerDark, circularTrackColor: dividerDark),

      // Slider Theme
      sliderTheme: SliderThemeData(activeTrackColor: primaryDark, inactiveTrackColor: dividerDark, thumbColor: primaryDark, overlayColor: primaryDark.withAlpha(51), valueIndicatorColor: primaryDark, valueIndicatorTextStyle: _buildTextTheme(isLight: false).bodySmall?.copyWith(color: onPrimaryDark, fontFamily: 'JetBrains Mono')),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(labelColor: primaryDark, unselectedLabelColor: textSecondaryDark, indicatorColor: primaryDark, indicatorSize: TabBarIndicatorSize.label, labelStyle: _buildTextTheme(isLight: false).titleSmall?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.w600), unselectedLabelStyle: _buildTextTheme(isLight: false).titleSmall?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.w400)),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(decoration: BoxDecoration(color: textPrimaryDark.withAlpha(230), borderRadius: BorderRadius.circular(8)), textStyle: _buildTextTheme(isLight: false).bodySmall?.copyWith(color: backgroundDark, fontFamily: 'Source Sans Pro'), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(backgroundColor: textPrimaryDark, contentTextStyle: _buildTextTheme(isLight: false).bodyMedium?.copyWith(color: backgroundDark, fontFamily: 'Source Sans Pro'), actionTextColor: secondaryDark, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),

      // Chip Theme
      chipTheme: ChipThemeData(backgroundColor: dividerDark, selectedColor: primaryDark.withAlpha(51), disabledColor: textDisabledDark.withAlpha(77), labelStyle: _buildTextTheme(isLight: false).bodySmall?.copyWith(fontFamily: 'Source Sans Pro'), secondaryLabelStyle: _buildTextTheme(isLight: false).bodySmall?.copyWith(fontFamily: 'Source Sans Pro', color: primaryDark), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      dialogTheme: DialogThemeData(backgroundColor: dialogDark));

  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color textPrimary = isLight ? textPrimaryLight : textPrimaryDark;
    final Color textSecondary =
        isLight ? textSecondaryLight : textSecondaryDark;
    final Color textDisabled = isLight ? textDisabledLight : textDisabledDark;

    return TextTheme(
        // Display styles - Inter for headings
        displayLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 57,
            fontWeight: FontWeight.w400,
            color: textPrimary,
            letterSpacing: -0.25,
            height: 1.12),
        displayMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 45,
            fontWeight: FontWeight.w400,
            color: textPrimary,
            letterSpacing: 0,
            height: 1.16),
        displaySmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 36,
            fontWeight: FontWeight.w400,
            color: textPrimary,
            letterSpacing: 0,
            height: 1.22),

        // Headline styles - Inter for headings
        headlineLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 0,
            height: 1.25),
        headlineMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 0,
            height: 1.29),
        headlineSmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 0,
            height: 1.33),

        // Title styles - Inter for headings
        titleLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: 0,
            height: 1.27),
        titleMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 0.15,
            height: 1.50),
        titleSmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 0.1,
            height: 1.43),

        // Body styles - Source Sans Pro for body text
        bodyLarge: TextStyle(
            fontFamily: 'Source Sans Pro',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textPrimary,
            letterSpacing: 0.5,
            height: 1.50),
        bodyMedium: TextStyle(
            fontFamily: 'Source Sans Pro',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textPrimary,
            letterSpacing: 0.25,
            height: 1.43),
        bodySmall: TextStyle(
            fontFamily: 'Source Sans Pro',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textSecondary,
            letterSpacing: 0.4,
            height: 1.33),

        // Label styles - Roboto for captions and small text
        labelLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
            letterSpacing: 0.1,
            height: 1.43),
        labelMedium: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
            letterSpacing: 0.5,
            height: 1.33),
        labelSmall: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: textDisabled,
            letterSpacing: 0.5,
            height: 1.45));
  }

  // Helper methods for getting theme-aware colors
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? primaryLight
        : primaryDark;
  }

  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? secondaryLight
        : secondaryDark;
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? backgroundLight
        : backgroundDark;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? surfaceLight
        : surfaceDark;
  }

  static Color getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textPrimaryLight
        : textPrimaryDark;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textSecondaryLight
        : textSecondaryDark;
  }
}
