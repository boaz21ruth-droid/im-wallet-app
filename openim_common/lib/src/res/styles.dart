import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Styles {
  Styles._();

  static Color c_0089FF = const Color(0xFF005BB3);
  static Color c_0C1C33 = const Color(0xFF1A1C1F);
  static Color c_8E9AB0 = const Color(0xFF717786);
  static Color c_E8EAEF = const Color(0xFFC0C6D6);
  static Color c_FF381F = const Color(0xFFFF381F);
  static Color c_FFFFFF = const Color(0xFFFFFFFF);
  static Color c_18E875 = const Color(0xFF4EDEA3);
  static Color c_F0F2F6 = const Color(0xFFEDEDF1);
  static Color c_000000 = const Color(0xFF000000);
  static Color c_92B3E0 = const Color(0xFF92B3E0);
  static Color c_F2F8FF = const Color(0xFFF2F8FF);
  static Color c_F8F9FA = const Color(0xFFF9F9FD);
  static Color c_6085B1 = const Color(0xFF6085B1);
  static Color c_FFB300 = const Color(0xFFFFB300);
  static Color c_FFE1DD = const Color(0xFFFFE1DD);
  static Color c_707070 = const Color(0xFF717786);

  static Color c_92B3E0_opacity50 = c_92B3E0.withOpacity(.5);
  static Color c_E8EAEF_opacity50 = c_E8EAEF.withOpacity(.5);
  static Color c_F4F5F7 = const Color(0xFFF3F3F7);
  static Color c_CCE7FE = const Color(0xFFD6E3FF);

  static Color c_FFFFFF_opacity0 = c_FFFFFF.withOpacity(.0);
  static Color c_FFFFFF_opacity70 = c_FFFFFF.withOpacity(.7);
  static Color c_FFFFFF_opacity50 = c_FFFFFF.withOpacity(.5);
  static Color c_0089FF_opacity10 = c_0089FF.withOpacity(.1);
  static Color c_0089FF_opacity20 = c_0089FF.withOpacity(.2);
  static Color c_0089FF_opacity50 = c_0089FF.withOpacity(.5);
  static Color c_FF381F_opacity10 = c_FF381F.withOpacity(.1);
  static Color c_8E9AB0_opacity13 = c_8E9AB0.withOpacity(.13);
  static Color c_8E9AB0_opacity15 = c_8E9AB0.withOpacity(.15);
  static Color c_8E9AB0_opacity16 = c_8E9AB0.withOpacity(.16);
  static Color c_8E9AB0_opacity30 = c_8E9AB0.withOpacity(.3);
  static Color c_8E9AB0_opacity50 = c_8E9AB0.withOpacity(.5);
  static Color c_0C1C33_opacity30 = c_0C1C33.withOpacity(.3);
  static Color c_0C1C33_opacity60 = c_0C1C33.withOpacity(.6);
  static Color c_0C1C33_opacity85 = c_0C1C33.withOpacity(.85);
  static Color c_0C1C33_opacity80 = c_0C1C33.withOpacity(.8);
  static Color c_FF381F_opacity70 = c_FF381F.withOpacity(.7);
  static Color c_000000_opacity70 = c_000000.withOpacity(.7);
  static Color c_000000_opacity15 = c_000000.withOpacity(.15);
  static Color c_000000_opacity12 = c_000000.withOpacity(.12);
  static Color c_000000_opacity4 = c_000000.withOpacity(.04);

  static void applyLightTheme() {
    c_0089FF = const Color(0xFF005BB3); // primary accent (deep blue)
    c_0C1C33 = const Color(0xFF1A1C1F); // on-surface (main text)
    c_8E9AB0 = const Color(0xFF717786); // on-surface-variant (secondary text)
    c_E8EAEF = const Color(0xFFC0C6D6); // outline-variant (dividers)
    c_FFFFFF = const Color(0xFFFFFFFF); // surface (cards)
    c_F0F2F6 = const Color(0xFFEDEDF1); // surface-container
    c_F8F9FA = const Color(0xFFF9F9FD); // background
    c_92B3E0 = const Color(0xFF92B3E0);
    c_F2F8FF = const Color(0xFFF2F8FF);
    c_CCE7FE = const Color(0xFFD6E3FF); // primary-fixed (send bubble)
    c_F4F5F7 = const Color(0xFFF3F3F7); // surface-container-low (receive bubble)
    c_6085B1 = const Color(0xFF6085B1);
    c_FFB300 = const Color(0xFFFFB300);
    c_FFE1DD = const Color(0xFFFFE1DD);
    c_707070 = const Color(0xFF717786);
    c_18E875 = const Color(0xFF4EDEA3); // secondary/online green
    _updateOpacityVariants();
  }

  static void applyDarkTheme() {
    c_0089FF = const Color(0xFFADC6FF); // primary accent (light blue-purple)
    c_0C1C33 = const Color(0xFFE0E3E5); // on-surface (main text)
    c_8E9AB0 = const Color(0xFF8C909F); // on-surface-variant (secondary text)
    c_E8EAEF = const Color(0xFF424754); // outline-variant (dividers)
    c_FFFFFF = const Color(0xFF1D2022); // surface-container (cards)
    c_F0F2F6 = const Color(0xFF272A2C); // surface-container-high
    c_F8F9FA = const Color(0xFF101415); // background
    c_92B3E0 = const Color(0xFF3D4F6E);
    c_F2F8FF = const Color(0xFF1D2022);
    c_CCE7FE = const Color(0xFF1D2022); // send bubble (matches card)
    c_F4F5F7 = const Color(0xFF191C1E); // surface-container-low (receive bubble)
    c_6085B1 = const Color(0xFF4A6090);
    c_FFB300 = const Color(0xFFFFB300);
    c_FFE1DD = const Color(0xFF3D1E1A);
    c_707070 = const Color(0xFF8C909F);
    c_18E875 = const Color(0xFF4EDEA3); // secondary/online green
    _updateOpacityVariants();
  }

  static void _updateOpacityVariants() {
    c_92B3E0_opacity50 = c_92B3E0.withOpacity(.5);
    c_E8EAEF_opacity50 = c_E8EAEF.withOpacity(.5);
    c_FFFFFF_opacity0 = c_FFFFFF.withOpacity(.0);
    c_FFFFFF_opacity70 = c_FFFFFF.withOpacity(.7);
    c_FFFFFF_opacity50 = c_FFFFFF.withOpacity(.5);
    c_0089FF_opacity10 = c_0089FF.withOpacity(.1);
    c_0089FF_opacity20 = c_0089FF.withOpacity(.2);
    c_0089FF_opacity50 = c_0089FF.withOpacity(.5);
    c_8E9AB0_opacity13 = c_8E9AB0.withOpacity(.13);
    c_8E9AB0_opacity15 = c_8E9AB0.withOpacity(.15);
    c_8E9AB0_opacity16 = c_8E9AB0.withOpacity(.16);
    c_8E9AB0_opacity30 = c_8E9AB0.withOpacity(.3);
    c_8E9AB0_opacity50 = c_8E9AB0.withOpacity(.5);
    c_0C1C33_opacity30 = c_0C1C33.withOpacity(.3);
    c_0C1C33_opacity60 = c_0C1C33.withOpacity(.6);
    c_0C1C33_opacity85 = c_0C1C33.withOpacity(.85);
    c_0C1C33_opacity80 = c_0C1C33.withOpacity(.8);
    c_000000_opacity70 = c_000000.withOpacity(.7);
    c_000000_opacity15 = c_000000.withOpacity(.15);
    c_000000_opacity12 = c_000000.withOpacity(.12);
    c_000000_opacity4 = c_000000.withOpacity(.04);
  }

  static TextStyle get ts_FFFFFF_21sp => TextStyle(
        color: c_FFFFFF,
        fontSize: 21.sp,
      );
  static TextStyle get ts_FFFFFF_20sp_medium => TextStyle(
        color: c_FFFFFF,
        fontSize: 20.sp,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get ts_FFFFFF_18sp_medium => TextStyle(
        color: c_FFFFFF,
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get ts_FFFFFF_17sp => TextStyle(
        color: c_FFFFFF,
        fontSize: 17.sp,
      );
  static TextStyle get ts_FFFFFF_opacity70_17sp => TextStyle(
        color: c_FFFFFF_opacity70,
        fontSize: 17.sp,
      );
  static TextStyle get ts_FFFFFF_17sp_semibold => TextStyle(
        color: c_FFFFFF,
        fontSize: 17.sp,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get ts_FFFFFF_17sp_medium => TextStyle(
        color: c_FFFFFF,
        fontSize: 17.sp,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get ts_FFFFFF_16sp => TextStyle(
        color: c_FFFFFF,
        fontSize: 16.sp,
      );
  static TextStyle get ts_FFFFFF_14sp => TextStyle(
        color: c_FFFFFF,
        fontSize: 14.sp,
      );
  static TextStyle get ts_FFFFFF_opacity70_14sp => TextStyle(
        color: c_FFFFFF_opacity70,
        fontSize: 14.sp,
      );
  static TextStyle get ts_FFFFFF_14sp_medium => TextStyle(
        color: c_FFFFFF,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get ts_FFFFFF_12sp => TextStyle(
        color: c_FFFFFF,
        fontSize: 12.sp,
      );
  static TextStyle get ts_FFFFFF_10sp => TextStyle(
        color: c_FFFFFF,
        fontSize: 10.sp,
      );

  static TextStyle get ts_8E9AB0_10sp_semibold => TextStyle(
        color: c_8E9AB0,
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get ts_8E9AB0_10sp => TextStyle(
        color: c_8E9AB0,
        fontSize: 10.sp,
      );
  static TextStyle get ts_8E9AB0_12sp => TextStyle(
        color: c_8E9AB0,
        fontSize: 12.sp,
      );
  static TextStyle get ts_8E9AB0_13sp => TextStyle(
        color: c_8E9AB0,
        fontSize: 13.sp,
      );
  static TextStyle get ts_8E9AB0_14sp => TextStyle(
        color: c_8E9AB0,
        fontSize: 14.sp,
      );
  static TextStyle get ts_8E9AB0_15sp => TextStyle(
        color: c_8E9AB0,
        fontSize: 15.sp,
      );
  static TextStyle get ts_8E9AB0_16sp => TextStyle(
        color: c_8E9AB0,
        fontSize: 16.sp,
      );
  static TextStyle get ts_8E9AB0_17sp => TextStyle(
        color: c_8E9AB0,
        fontSize: 17.sp,
      );
  static TextStyle get ts_8E9AB0_opacity50_17sp => TextStyle(
        color: c_8E9AB0_opacity50,
        fontSize: 17.sp,
      );

  static TextStyle get ts_0C1C33_10sp => TextStyle(
        color: c_0C1C33,
        fontSize: 10.sp,
      );
  static TextStyle get ts_0C1C33_12sp => TextStyle(
        color: c_0C1C33,
        fontSize: 12.sp,
      );
  static TextStyle get ts_0C1C33_12sp_medium => TextStyle(
        color: c_0C1C33,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get ts_0C1C33_14sp => TextStyle(
        color: c_0C1C33,
        fontSize: 14.sp,
      );
  static TextStyle get ts_0C1C33_14sp_medium => TextStyle(
        color: c_0C1C33,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get ts_0C1C33_17sp => TextStyle(
        color: c_0C1C33,
        fontSize: 17.sp,
      );
  static TextStyle get ts_0C1C33_17sp_medium => TextStyle(
        color: c_0C1C33,
        fontSize: 17.sp,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get ts_0C1C33_17sp_semibold => TextStyle(
        color: c_0C1C33,
        fontSize: 17.sp,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get ts_0C1C33_20sp => TextStyle(
        color: c_0C1C33,
        fontSize: 20.sp,
      );
  static TextStyle get ts_0C1C33_20sp_medium => TextStyle(
        color: c_0C1C33,
        fontSize: 20.sp,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get ts_0C1C33_20sp_semibold => TextStyle(
        color: c_0C1C33,
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get ts_0089FF_10sp_semibold => TextStyle(
        color: c_0089FF,
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get ts_0089FF_10sp => TextStyle(
        color: c_0089FF,
        fontSize: 10.sp,
      );
  static TextStyle get ts_0089FF_12sp => TextStyle(
        color: c_0089FF,
        fontSize: 12.sp,
      );
  static TextStyle get ts_0089FF_14sp => TextStyle(
        color: c_0089FF,
        fontSize: 14.sp,
      );
  static TextStyle get ts_0089FF_16sp => TextStyle(
        color: c_0089FF,
        fontSize: 16.sp,
      );
  static TextStyle get ts_0089FF_16sp_medium => TextStyle(
        color: c_0089FF,
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get ts_0089FF_17sp => TextStyle(
        color: c_0089FF,
        fontSize: 17.sp,
      );
  static TextStyle get ts_0089FF_17sp_semibold => TextStyle(
        color: c_0089FF,
        fontSize: 17.sp,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get ts_0089FF_17sp_medium => TextStyle(
        color: c_0089FF,
        fontSize: 17.sp,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get ts_0089FF_14sp_medium => TextStyle(
        color: c_0089FF,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get ts_0089FF_22sp_semibold => TextStyle(
        color: c_0089FF,
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get ts_FF381F_17sp => TextStyle(
        color: c_FF381F,
        fontSize: 17.sp,
      );
  static TextStyle get ts_FF381F_14sp => TextStyle(
        color: c_FF381F,
        fontSize: 14.sp,
      );
  static TextStyle get ts_FF381F_12sp => TextStyle(
        color: c_FF381F,
        fontSize: 12.sp,
      );
  static TextStyle get ts_FF381F_10sp => TextStyle(
        color: c_FF381F,
        fontSize: 10.sp,
      );

  static TextStyle get ts_6085B1_17sp_medium => TextStyle(
        color: c_6085B1,
        fontSize: 17.sp,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get ts_6085B1_17sp => TextStyle(
        color: c_6085B1,
        fontSize: 17.sp,
      );
  static TextStyle get ts_6085B1_12sp => TextStyle(
        color: c_6085B1,
        fontSize: 12.sp,
      );
  static TextStyle get ts_6085B1_14sp => TextStyle(
        color: c_6085B1,
        fontSize: 14.sp,
      );
}
