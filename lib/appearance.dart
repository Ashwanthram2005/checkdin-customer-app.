import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state.dart';
import 'theme.dart';

enum AppTheme { light, dark, system }

extension AppThemeLabel on AppTheme {
  String get label => switch (this) {
        AppTheme.light => 'Light',
        AppTheme.dark => 'Dark',
        AppTheme.system => 'System default',
      };
}

/// Holds the guest's theme choice and repaints the app when it changes.
class Appearance {
  static AppTheme mode = AppTheme.system;
  static SharedPreferences? _prefs;

  static Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final i = _prefs!.getInt('theme');
      if (i != null && i >= 0 && i < AppTheme.values.length) mode = AppTheme.values[i];
    } catch (_) {}
    _resolve();
  }

  static bool get systemIsDark => WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;

  static void _resolve() {
    C.dark = mode == AppTheme.dark || (mode == AppTheme.system && systemIsDark);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: C.dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: C.dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: C.bg,
      systemNavigationBarIconBrightness: C.dark ? Brightness.light : Brightness.dark,
    ));
  }

  static void set(AppTheme m) {
    mode = m;
    _prefs?.setInt('theme', m.index);
    refresh();
  }

  /// Re-resolve (e.g. the phone switched to dark) and rebuild every widget,
  /// including const ones, so all colours pick up the new palette.
  static void refresh() {
    final was = C.dark;
    _resolve();
    if (was == C.dark) {
      app.set(() {});
      return;
    }
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
    app.set(() {});
  }
}
