import 'package:flutter/material.dart';

/// Checkdin design tokens. Use these instead of raw numbers and colour codes.

/// Text sizes: 9 steps.
abstract final class Fs {
  static const xs = 11.0; // captions, badges, overlines
  static const sm = 12.0; // secondary text
  static const base = 13.0; // small body
  static const md = 14.0; // body, list titles
  static const lg = 16.0; // emphasised body, buttons
  static const xl = 18.0; // card titles
  static const h2 = 22.0; // section titles
  static const h1 = 28.0; // page titles
  static const display = 40.0; // big numbers
}

/// Spacing: 4-point grid.
abstract final class Sp {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const x3 = 32.0;
  static const x4 = 40.0;
  static const x5 = 48.0;
}

/// Corner radius.
abstract final class R {
  static const xs = 2.0; // handles and thin bars
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

/// Icon sizes.
abstract final class Ic {
  static const sm = 16.0;
  static const md = 20.0;
  static const lg = 24.0;
  static const xl = 32.0; // illustration
  static const xxl = 40.0; // illustration
  static const hero = 48.0; // illustration
  static const giant = 64.0; // illustration
}

/// Fixed colours that are not theme roles. Theme roles live in `C`.
abstract final class P {
  static const amber21 = Color(0xFF6B5200);
  static const amber27 = Color(0xFF8A6A00);
  static const amber48 = Color(0xFFF2B705);
  static const amber66 = Color(0xFFD9C27A);
  static const amber85 = Color(0xFFE8E2C8);
  static const amber92 = Color(0xFFFFF4D6);
  static const amber93 = Color(0xFFFFF6DA);
  static const amberSoft = Color(0xFFFFF1C7);
  static const blue40 = Color(0xFF1F5FAF);
  static const blue87 = Color(0xFFD6E0E6);
  static const blue94 = Color(0xFFE3EEFC);
  static const border = Color(0xFFDADAD2);
  static const disabled = Color(0xFFC9C9C1);
  static const dotIdle = Color(0xFFCFCFC7);
  static const googleBlue = Color(0xFF4285F4);
  static const googleGreen = Color(0xFF34A853);
  static const googleRed = Color(0xFFEA4335);
  static const googleYellow = Color(0xFFFBBC05);
  static const green86 = Color(0xFFD0E6DD);
  static const grey13 = Color(0xFF222222);
  static const grey16 = Color(0xFF2A2A2A);
  static const grey17 = Color(0xFF2B2B2B);
  static const grey20 = Color(0xFF333333);
  static const grey23 = Color(0xFF3A3A3A);
  static const grey38 = Color(0xFF6A645A);
  static const grey51 = Color(0xFF8A8478);
  static const grey87 = Color(0xFFE2E2DA);
  static const grey89 = Color(0xFFE8E8E0);
  static const grey90 = Color(0xFFE6EBE0);
  static const grey92 = Color(0xFFEDEDE6);
  static const grey93 = Color(0xFFF0F0EA);
  static const grey94 = Color(0xFFF1F2EC);
  static const grey95 = Color(0xFFF5F5F0);
  static const hint = Color(0xFF6F6F68);
  static const iconMuted = Color(0xFF8A8A82);
  static const ink = Color(0xFF111111);
  static const ink2 = Color(0xFF3F3F38);
  static const inkA10 = Color(0x1A111111);
  static const inkA14 = Color(0x24111111);
  static const inkA20 = Color(0x33111111);
  static const inkA25 = Color(0x40111111);
  static const inkA28 = Color(0x47111111);
  static const inkA55 = Color(0x8C111111);
  static const inkA6 = Color(0x0F111111);
  static const inkA60 = Color(0x99111111);
  static const inkA7 = Color(0x12111111);
  static const inkA70 = Color(0xB3111111);
  static const inkA8 = Color(0x14111111);
  static const inkA80 = Color(0xCC111111);
  static const inkCard = Color(0xFF1B1E19);
  static const lime = Color(0xFFD1F148);
  static const lime16 = Color(0xFF3D5200);
  static const lime85 = Color(0xFFDDE8C8);
  static const lime88 = Color(0xFFEEF8C8);
  static const lime94 = Color(0xFFF6FBE6);
  static const limeA18 = Color(0x2ED1F148);
  static const line = Color(0xFFEFEFEA);
  static const muted = Color(0xFF5C5C55);
  static const orange24 = Color(0xFF4A4030);
  static const orange27 = Color(0xFF8A5A00);
  static const orange35 = Color(0xFFB26A00);
  static const orange86 = Color(0xFFE6DDD0);
  static const orange91 = Color(0xFFFDE3D2);
  static const purple48 = Color(0xFF6A3FB5);
  static const purple87 = Color(0xFFE0D6E6);
  static const purple94 = Color(0xFFEEE6FB);
  static const red85 = Color(0xFFF2C4BF);
  static const red87 = Color(0xFFE6D6D6);
  static const redBright = Color(0xFFE5484D);
  static const redDark = Color(0xFFA3241A);
  static const whiteA20 = Color(0x33FFFFFF);
  static const whiteA40 = Color(0x66FFFFFF);
  static const whiteA60 = Color(0x99FFFFFF);
  static const whiteA65 = Color(0xA6FFFFFF);
  static const whiteA80 = Color(0xCCFFFFFF);
}
