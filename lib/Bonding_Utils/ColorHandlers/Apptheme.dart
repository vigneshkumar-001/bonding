import 'package:bonding_app/Bonding_Utils/ColorHandlers/AppColors.dart';
import 'package:flutter/material.dart';

class Apptheme {
  static const Color buttonGradientStart = Color(0xFFB86AF6);
  static const Color buttonGradientEnd = Color(0xFFFF6A6A);
  static const List<Color> buttonGradientColors = [
    buttonGradientStart,
    buttonGradientEnd,
  ];
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: buttonGradientColors,
  );

  // App dark palette (matches current UI direction)
  static const Color bg0 = Color(0xFF140810);
  static const Color bg1 = Color(0xFF3A152A);
  static const Color bg2 = Color(0xFF5A1F3F);
  static const Color surface = Color(0xFF1E1325);
  static const Color surface2 = Color(0xFF24162C);
  static const Color outline = Color(0x33FFFFFF);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xB3FFFFFF);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bg0, bg1, bg0, bg0],
  );

  /// light theme Color
  static final lightThemeData = ThemeData(
    useMaterial3: true,
    bottomAppBarTheme: const BottomAppBarTheme(
      color: Color(0xFFD4D4D4),
    ), // Set bottom app bar color to gray
    // Force the app to look consistent even if light theme is used somewhere.
    colorScheme: const ColorScheme.dark().copyWith(
      primary: buttonGradientStart,
      secondary: buttonGradientEnd,
      surface: surface,
      onSurface: text,
      outline: outline,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: text,
      elevation: 0,
      centerTitle: false,
    ),
    scaffoldBackgroundColor: Colors.transparent,

    fontFamily: "LexendDeca",
    primaryColor: bg0,
    primaryColorLight: bg1,
    primaryColorDark: bg2,
    iconTheme: const IconThemeData(color: text),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonGradientStart,
        foregroundColor: Colors.white,
        disabledBackgroundColor: buttonGradientStart.withOpacity(0.45),
        disabledForegroundColor: Colors.white.withOpacity(0.75),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: buttonGradientStart,
        foregroundColor: Colors.white,
        disabledBackgroundColor: buttonGradientStart.withOpacity(0.45),
        disabledForegroundColor: Colors.white.withOpacity(0.75),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: buttonGradientStart,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonGradientStart,
        side: BorderSide(color: buttonGradientStart.withOpacity(0.9)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF141018),
      selectedItemColor: buttonGradientEnd,
      unselectedItemColor: Color(0xFF8B8B8B),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF141018),
      indicatorColor: surface2,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: buttonGradientEnd);
        }
        return const IconThemeData(color: Color(0xFF8B8B8B));
      }),
    ),
    cardTheme: CardThemeData(
      color: surface2,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    dividerTheme: const DividerThemeData(color: outline),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF201424),
      contentTextStyle: TextStyle(color: text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: buttonGradientStart),
      ),
      hintStyle: const TextStyle(color: textMuted),
      labelStyle: const TextStyle(color: textMuted),
    ),

    primarySwatch: MaterialColor(
      appColors.lightPrimaryColor,
      appColors.lightSwatchColor,
    ),
    cardColor: appColors.cardBackgroundLight,
    // backgroundColor: appColors.bgTextLight,
    shadowColor: Colors.white,
    hintColor: appColors.hintTextLight,
    highlightColor: Colors.white,
    unselectedWidgetColor: appColors.roundedButtonColorLight1,
    focusColor: appColors.roundedButtonColorLight2,
    // errorColor: appColors.errorSanckBarColorLight,
    canvasColor: appColors.greyContainerLight,
    dividerColor: appColors.buttonLightDiableGrey2,
    chipTheme: ChipThemeData(backgroundColor: appColors.SwapArrowRoundLight),
    indicatorColor: appColors.greyTextLight,
    disabledColor: appColors.hintLight,
    hoverColor: appColors.userTextLight,
    textTheme: TextTheme(
      labelLarge: TextStyle(
        color: appColors.textLight,
        fontFamily: "LexendDeca",
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),
      labelMedium: TextStyle(
        color: appColors.textLight,
        fontFamily: "LexendDeca",
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      labelSmall: TextStyle(
        color: appColors.textLight,
        fontFamily: "LexendDeca",
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: TextStyle(
        color: appColors.textBlackColorLight,
        fontFamily: "LexendDeca",
        fontSize: 23,
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(
        color: appColors.textBlackColorLight,
        fontFamily: "LexendDeca",
        fontSize: 14,
        fontWeight: FontWeight.bold,
        overflow: TextOverflow.ellipsis,
      ),
      bodySmall: TextStyle(
        color: appColors.textBlackColorLight,
        fontFamily: "LexendDeca",
        fontSize: 14,
        fontWeight: FontWeight.normal,
        overflow: TextOverflow.ellipsis,
      ),
      displayLarge: TextStyle(
        color: appColors.textLight,
        fontFamily: "LexendDeca",
        fontSize: 23,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
      displayMedium: TextStyle(
        color: appColors.underlineTextLight,
        fontFamily: "LexendDeca",
        fontSize: 14,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
      displaySmall: TextStyle(
        color: appColors.underlineTextLight,
        fontFamily: "LexendDeca",
        fontSize: 14,
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.normal,
      ),
      titleLarge: TextStyle(
        color: appColors.cntTextLight,
        fontFamily: "LexendDeca",
        fontSize: 23,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: appColors.cntTextLight1,
        fontFamily: "LexendDeca",
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: TextStyle(
        color: appColors.cntTextLight1,
        fontFamily: "LexendDeca",
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: appColors.cntTextLight,
        fontFamily: "BricolageGrotesque",
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      headlineLarge: TextStyle(
        color: appColors.cntTextLight1,
        fontFamily: "BricolageGrotesque",
        fontSize: 30,
        fontWeight: FontWeight.w500,
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: appColors.textBlackColorLight,
      focusColor: appColors.roundedButtonColorLight1,
      hoverColor: appColors.roundedButtonColorLight2,
    ),
    //iconTheme: IconThemeData(color: appColors.textBlackColorLight)
  );

  /// Dark Theme Color
  static final darkThemeData = ThemeData(
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: text,
      elevation: 0,
      centerTitle: false,
    ),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: buttonGradientStart,
      secondary: buttonGradientEnd,
      surface: surface,
      onSurface: text,
      outline: outline,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: "LexendDeca",
    primaryColor: bg0,
    iconTheme: const IconThemeData(color: text),
    primaryColorLight: bg1,
    primaryColorDark: bg2,
    primarySwatch: MaterialColor(
      appColors.darkPrimaryColor,
      appColors.darkSwatchColor,
    ),
    cardColor: surface2,
    // backgroundColor: appColors.bgTextDark,
    hintColor: appColors.hintTextDark,
    shadowColor: Color(0xFF364153),
    canvasColor: appColors.greyContainerDark,
    unselectedWidgetColor: appColors.roundedButtonColorDark1,
    highlightColor: Color(0XFF515a6a),
    focusColor: appColors.roundedButtonColorDark2,
    // errorColor: appColors.errorSanckBarColorDark,
    dividerColor: appColors.buttonDiableGrey2,
    indicatorColor: appColors.greyTextDark,
    hoverColor: appColors.userTextDark,
    chipTheme: ChipThemeData(backgroundColor: appColors.SwapArrowRoundDark),
    disabledColor: appColors.hintdark,
    bottomAppBarTheme: const BottomAppBarTheme(
      color: Color(0xFF141018),
    ), // Set bottom app bar color to black
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF141018),
      selectedItemColor: buttonGradientEnd,
      unselectedItemColor: Color(0xFF8B8B8B),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF141018),
      indicatorColor: surface2,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: buttonGradientEnd);
        }
        return const IconThemeData(color: Color(0xFF8B8B8B));
      }),
    ),
    cardTheme: CardThemeData(
      color: surface2,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    dividerTheme: const DividerThemeData(color: outline),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF201424),
      contentTextStyle: TextStyle(color: text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: buttonGradientStart),
      ),
      hintStyle: const TextStyle(color: textMuted),
      labelStyle: const TextStyle(color: textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonGradientStart,
        foregroundColor: Colors.white,
        disabledBackgroundColor: buttonGradientStart.withOpacity(0.45),
        disabledForegroundColor: Colors.white.withOpacity(0.75),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: buttonGradientStart,
        foregroundColor: Colors.white,
        disabledBackgroundColor: buttonGradientStart.withOpacity(0.45),
        disabledForegroundColor: Colors.white.withOpacity(0.75),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: buttonGradientStart,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonGradientStart,
        side: BorderSide(color: buttonGradientStart.withOpacity(0.9)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textTheme: TextTheme(
      labelLarge: TextStyle(
        color: appColors.textDark,
        fontFamily: "LexendDeca",
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),
      labelMedium: TextStyle(
        color: appColors.textDark,
        fontFamily: "LexendDeca",
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      labelSmall: TextStyle(
        color: appColors.textDark,
        fontFamily: "LexendDeca",
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: TextStyle(
        color: appColors.textBlackColorDark,
        fontFamily: "LexendDeca",
        fontSize: 23,
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(
        color: appColors.textBlackColorDark,
        fontFamily: "LexendDeca",
        fontSize: 14,
        fontWeight: FontWeight.bold,
        overflow: TextOverflow.ellipsis,
      ),
      bodySmall: TextStyle(
        color: appColors.textBlackColorDark,
        fontFamily: "LexendDeca",
        fontSize: 14,
        fontWeight: FontWeight.normal,
        overflow: TextOverflow.ellipsis,
      ),
      displayLarge: TextStyle(
        color: appColors.textDark,
        fontFamily: "LexendDeca",
        fontSize: 23,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
      displayMedium: TextStyle(
        color: appColors.underlineTextDark,
        fontFamily: "LexendDeca",
        fontSize: 14,
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: appColors.underlineTextDark,
        fontFamily: "LexendDeca",
        fontSize: 14,
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.normal,
      ),
      titleLarge: TextStyle(
        color: appColors.textDark,
        fontFamily: "LexendDeca",
        fontSize: 23,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: appColors.cntTextDark1,
        fontFamily: "LexendDeca",
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: TextStyle(
        color: appColors.cntTextDark1,
        fontFamily: "LexendDeca",
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: appColors.cntTextDark,
        fontFamily: "BricolageGrotesque",
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      headlineLarge: TextStyle(
        color: appColors.cntTextDark1,
        fontFamily: "BricolageGrotesque",
        fontSize: 30,
        fontWeight: FontWeight.w500,
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: appColors.roundedButtonColorDark1,
      focusColor: appColors.roundedButtonColorDark2,
      hoverColor: appColors.roundedButtonColorDark2,
    ),
    // iconTheme: IconThemeData(color: appColors.textBlackColorDark)
  );
}
