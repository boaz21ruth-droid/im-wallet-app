import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'core/controller/im_controller.dart';
import 'core/controller/theme_controller.dart';
import 'routes/app_pages.dart';
import 'widgets/app_view.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (tc) => AppView(
        builder: (locale, builder) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          enableLog: true,
          builder: builder,
          translations: TranslationService(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          fallbackLocale: TranslationService.fallbackLocale,
          locale: locale,
          localeResolutionCallback: (locale, list) {
            Get.locale ??= locale;
            return locale;
          },
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          getPages: AppPages.routes,
          initialBinding: InitBinding(),
          initialRoute: AppRoutes.splash,
          theme: _buildTheme(isDark: false),
          darkTheme: _buildTheme(isDark: true),
          themeMode: tc.isDark.value ? ThemeMode.dark : ThemeMode.light,
        ),
      ),
    );
  }

  ThemeData _buildTheme({required bool isDark}) =>
      (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
        scaffoldBackgroundColor:
            isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F6FA),
        canvasColor: isDark ? const Color(0xFF161B27) : Colors.white,
        appBarTheme: AppBarTheme(
          color: isDark ? const Color(0xFF0D1117) : Colors.white,
          elevation: 0,
        ),
        textSelectionTheme: const TextSelectionThemeData()
            .copyWith(cursorColor: Colors.blue),
        checkboxTheme: const CheckboxThemeData().copyWith(
          checkColor: WidgetStateProperty.all(Colors.white),
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return Colors.grey;
            if (states.contains(WidgetState.selected)) return Colors.blue;
            return isDark ? const Color(0xFF1E2436) : Colors.white;
          }),
          side: BorderSide(color: Colors.grey.shade500, width: 1),
        ),
        dialogTheme: const DialogThemeData().copyWith(
          backgroundColor: isDark ? const Color(0xFF161B27) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            textStyle: WidgetStatePropertyAll(
              TextStyle(
                fontSize: 16.sp,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            foregroundColor: WidgetStatePropertyAll(
                isDark ? Colors.white : Colors.black),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData().copyWith(
          color: Colors.white,
          linearTrackColor: Colors.grey[300],
          circularTrackColor: Colors.grey[300],
        ),
        cupertinoOverrideTheme: CupertinoThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primaryColor: CupertinoColors.systemBlue,
          barBackgroundColor:
              isDark ? const Color(0xFF0D1117) : Colors.white,
          applyThemeToAll: true,
          textTheme: CupertinoTextThemeData(
            navActionTextStyle: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.label,
                fontSize: 17.sp),
            actionTextStyle: TextStyle(
                color: CupertinoColors.systemBlue, fontSize: 17.sp),
            textStyle: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.label,
                fontSize: 17.sp),
            navLargeTitleTextStyle: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.label,
                fontSize: 20.sp),
            navTitleTextStyle: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.label,
                fontSize: 17.sp),
            pickerTextStyle: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.label,
                fontSize: 17.sp),
            tabLabelTextStyle: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.label,
                fontSize: 17.sp),
            dateTimePickerTextStyle: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.label,
                fontSize: 17.sp),
          ),
        ),
      );
}

class InitBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<IMController>(IMController());
    Get.put<PushController>(PushController());
    Get.put<CacheController>(CacheController());
  }
}
