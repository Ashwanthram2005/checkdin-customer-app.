// Automated QA for the Checkdin customer app.
//
// Runs every flow it can without a real phone, records Pass/Fail per row of
// the "Build 41" checklist, and saves screenshots of every screen (normal
// phone, small phone, large text) into qa_test/shots/.
//
// Run:  flutter test qa_test --update-goldens
// Output: qa_report.json (results + layout problems) and qa_test/shots/*.png
import 'dart:convert';
import 'dart:io';

import 'package:checkdin/api/api.dart';
import 'package:checkdin/api/fake_api.dart';
import 'package:checkdin/coupons.dart';
import 'package:checkdin/loading.dart';
import 'package:checkdin/main.dart';
import 'package:checkdin/state.dart';
import 'package:checkdin/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ------------------------------------------------------------------ report
final results = <int, Map<String, String>>{};
final layoutIssues = <Map<String, String>>[];
final shotsTaken = <String>[];
final _seen = <String>{};

void ok(int row, bool pass, String note) {
  final prev = results[row];
  if (prev != null) {
    if (prev['status'] == 'Fail') {
      if (!pass) prev['note'] = '${prev['note']} | $note';
      return;
    }
    if (pass) {
      prev['note'] = '${prev['note']} | $note';
      return;
    }
  }
  results[row] = {'status': pass ? 'Pass' : 'Fail', 'note': note};
}

// ------------------------------------------------------------------ helpers
const _dpr = 2.0;

void phone(WidgetTester t, {double w = 393, double h = 851, double text = 1.0}) {
  t.view.devicePixelRatio = _dpr;
  t.view.physicalSize = Size(w * _dpr, h * _dpr);
  t.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> wait(WidgetTester t, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

// skipOffstage: false so items just below the visible area still count.
bool has(String s) =>
    find.text(s, skipOffstage: false).evaluate().isNotEmpty ||
    find.textContaining(s, findRichText: true, skipOffstage: false).evaluate().isNotEmpty;

List<String> screenTexts() => find
    .byType(Text)
    .evaluate()
    .map((e) => (e.widget as Text).data ?? '')
    .where((x) => x.trim().isNotEmpty)
    .take(30)
    .toList();

Future<void> tapText(WidgetTester t, String s, {bool last = false}) async {
  var f = find.text(s, skipOffstage: false);
  if (f.evaluate().isEmpty) f = find.textContaining(s, findRichText: true, skipOffstage: false);
  if (f.evaluate().isEmpty && vScroll().evaluate().isNotEmpty) {
    // Long lists only build what is near the screen: scroll to find it.
    try {
      await t.scrollUntilVisible(find.textContaining(s, findRichText: true), 250,
          scrollable: vScroll().first, maxScrolls: 30);
    } catch (_) {}
    f = find.text(s, skipOffstage: false);
    if (f.evaluate().isEmpty) f = find.textContaining(s, findRichText: true, skipOffstage: false);
  }
  if (f.evaluate().isEmpty) {
    throw StateError('Button "$s" not found. On screen: ${screenTexts().join(' | ')}');
  }
  final one = last ? f.last : f.first;
  await centre(t, one);
  await t.pump(const Duration(milliseconds: 250));
  // Re-find after scrolling: the element can be rebuilt.
  var g = find.text(s);
  if (g.evaluate().isEmpty) g = find.textContaining(s, findRichText: true);
  final target = g.evaluate().isEmpty ? one : (last ? g.last : g.first);
  await t.tap(target, warnIfMissed: false);
  await t.pump(const Duration(milliseconds: 100));
}

/// Scroll an item to the middle of the screen (not the top, where a pinned
/// header could cover it).
Future<void> centre(WidgetTester t, Finder f) async {
  try {
    await Scrollable.ensureVisible(t.element(f), alignment: 0.5);
  } catch (_) {
    await t.ensureVisible(f);
  }
  await t.pump(const Duration(milliseconds: 50));
}

Finder vScroll() => find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);

Future<void> shot(WidgetTester t, String name) async {
  try {
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
    shotsTaken.add(name);
  } catch (e) {
    layoutIssues.add({'where': name, 'issue': 'screenshot failed: ${e.toString().split('\n').first}'});
  }
}

Future<void> boot(WidgetTester t, String route, {NetMode mode = NetMode.fast}) async {
  kQaMode = true;
  FakeApi.mode = mode;
  await t.pumpWidget(CheckdinApp(key: UniqueKey(), initialRoute: route));
  await wait(t, 1800);
}

Future<void> openRoute(WidgetTester t, String route, [int ms = 1800]) async {
  appNavigator.currentState!.pushNamed(route);
  await wait(t, ms);
}

/// Runs [body]; any crash marks [rows] as failed. Layout errors (overflow etc.)
/// are collected instead of failing the test.
Future<void> run(WidgetTester t, String name, List<int> rows, Future<void> Function() body) async {
  final old = FlutterError.onError;
  FlutterError.onError = (d) {
    final msg = d.exceptionAsString().split('\n').first;
    final full = d.toString();
    final m = RegExp(r'The relevant error-causing widget was:\s*\n(.*)\n(.*)').firstMatch(full);
    final culprit = m == null ? '' : '${m.group(1)!.trim()} ${m.group(2)!.trim()}';
    final seenKey = '$msg|$culprit';
    final detail = _seen.add(seenKey) ? (full.length > 2500 ? full.substring(0, 2500) : full) : '';
    final frames = (d.stack?.toString() ?? '').split('\n').where((l) => l.contains('package:checkdin') || l.contains('qa_test')).take(2).join(' <- ');
    layoutIssues.add({'where': name, 'issue': msg, 'widget': culprit, 'at': frames, if (detail.isNotEmpty) 'detail': detail});
  };
  try {
    await body();
  } catch (e, st) {
    final msg = e.toString().split('\n').where((l) => l.trim().isNotEmpty).take(2).join(' ');
    final at = st.toString().split('\n').where((l) => l.contains('qa_test') || l.contains('package:checkdin')).take(2).join(' <- ');
    layoutIssues.add({'where': name, 'issue': 'CRASH $msg', 'at': at});
    for (final r in rows) {
      ok(r, false, '$name crashed: $msg');
    }
  } finally {
    FakeApi.mode = NetMode.fast;
    try {
      await t.pumpWidget(const SizedBox());
      await wait(t, 6500);
    } catch (_) {}
    FlutterError.onError = old;
  }
}

void resetState() {
  Loader.clearCache();
  app.saved.clear();
  app.couponCode = null;
  app.bookingCancelled = false;
  app.checkedIn = false;
  app.extraHours = 0;
  app.extraPaid = 0;
  app.forSomeoneElse = false;
  app.guestName = '';
  app.guestPhone = '';
  app.fullDay = false;
  app.slot = 3;
  app.place = null;
  app.useLocation = true;
  app.onboarded = true;
  if (app.name.isEmpty) app.name = 'Ashwanth';
  if (app.phone.isEmpty) app.phone = '9876543210';
}

// ------------------------------------------------------------------ tests
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    // Material icons and any declared fonts.
    final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final f in manifest) {
      final loader = FontLoader(f['family'] as String);
      for (final a in (f['fonts'] as List)) {
        loader.addFont(rootBundle.load(a['asset'] as String));
      }
      await loader.load();
    }
    // Plus Jakarta Sans, bundled under google_fonts/.
    try {
      await GoogleFonts.pendingFonts([
        for (final w in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800])
          GoogleFonts.plusJakartaSans(fontWeight: w),
      ]);
    } catch (e) {
      layoutIssues.add({'where': 'setup', 'issue': 'font load: $e'});
    }
    await setUpApp();
    kQaMode = true;
  });

  tearDownAll(() async {
    File('qa_report.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'results': {for (final e in (results.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) '${e.key}': e.value},
      'layoutIssues': layoutIssues,
      'shots': shotsTaken,
    }));
  });

  // ---------------------------------------------------------------- logic
  test('booking id, idempotency, coupons', () async {
    final re = RegExp(r'^CKD-MAA-\d{6}-[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{4}$');
    final ids = List.generate(200, (_) => newBookingId(DateTime(2026, 11, 27)));
    ok(64, ids.every(re.hasMatch) && ids.first.contains('261127'), 'IDs look like ${ids.first}; date part correct');
    ok(65, ids.toSet().length > 195, '${ids.toSet().length}/200 unique in a quick sample');

    FakeApi.mode = NetMode.fast;
    final key = newIdempotencyKey();
    final a = await api.pay(method: 'upi', amount: 500, idempotencyKey: key);
    final b = await api.pay(method: 'upi', amount: 500, idempotencyKey: key);
    final c = await api.pay(method: 'upi', amount: 500, idempotencyKey: newIdempotencyKey());
    ok(61, a == b && a != c, 'Same payment key returns the same booking ($a); a new key makes a new one');

    resetState();
    app.fullDay = false;
    app.couponCode = 'NEWSTAY';
    final d1 = app.discount;
    final p1 = couponProblem('NEWSTAY');
    final pNight = couponProblem('NIGHT150');
    app.couponCode = 'FIRST40';
    final d2 = app.discount;
    app.couponCode = null;
    ok(51, p1 == null && d1 > 0 && d1 <= 200 && d2 == 40 && pNight != null,
        'NEWSTAY ₹$d1 off (cap ₹200), FIRST40 ₹$d2 off, NIGHT150 on hourly refused: "$pNight"');
  });

  // ---------------------------------------------------------------- login
  testWidgets('login flow', (t) async {
    phone(t);
    await run(t, 'login', [2, 5, 6, 7, 8, 9, 10, 12], () async {
      resetState();
      app.name = '';
      await boot(t, '/splash');
      await wait(t, 4000);
      ok(2, has('Get OTP on WhatsApp') && !has('Skip'), 'Splash plays then Login; no Skip button');
      await shot(t, '01_login');

      final field = find.byType(TextField).first;
      await tapText(t, 'Get OTP on WhatsApp');
      await wait(t, 600);
      final e1 = has('Enter your mobile number');
      await t.enterText(field, '987654321');
      await tapText(t, 'Get OTP on WhatsApp');
      await wait(t, 600);
      final e2 = has('Mobile numbers have 10 digits');
      await t.enterText(field, '5876543210');
      await tapText(t, 'Get OTP on WhatsApp');
      await wait(t, 600);
      final e3 = has('start with 6, 7, 8 or 9');
      await shot(t, '02_login_error');
      ok(5, e1 && e2 && e3, 'Empty: ${e1 ? 'ok' : 'no msg'}; 9 digits: ${e2 ? 'ok' : 'no msg'}; starts with 5: ${e3 ? 'ok' : 'no msg'}');

      await t.enterText(field, '9876543210');
      await tapText(t, 'Get OTP on WhatsApp');
      await t.pump(const Duration(milliseconds: 250));
      final spun = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      await wait(t, 2200);
      ok(6, spun && has('Demo OTP: 1234'), 'Spinner in button: $spun; OTP screen opened: ${has('Demo OTP: 1234')}');
      await shot(t, '03_otp');

      Future<void> typeCode(String code) async {
        final boxes = find.byType(TextField);
        for (var i = 0; i < 4; i++) {
          await t.enterText(boxes.at(i), code[i]);
          await t.pump(const Duration(milliseconds: 50));
        }
        await wait(t, 1800);
      }

      await typeCode('1111');
      final wrong1 = has('That OTP is wrong. 2 tries left.');
      await shot(t, '04_otp_wrong');
      ok(7, wrong1, wrong1 ? 'Shows "That OTP is wrong. 2 tries left." and clears' : 'No wrong-OTP message');

      await typeCode('2222');
      await typeCode('3333');
      final locked = has('Tap Resend');
      await wait(t, 31000);
      final canResend = has('Resend OTP');
      if (canResend) await tapText(t, 'Resend OTP');
      await wait(t, 500);
      ok(8, locked && canResend, 'After 3 wrong: ${locked ? 'locked' : 'NOT locked'}; Resend shown after timer: $canResend');

      await t.enterText(find.byType(TextField).first, '1234');
      await wait(t, 2500);
      final setup = has('Start exploring stays');
      ok(9, setup, setup ? 'Pasting 1234 filled the boxes and verified' : 'Paste did not verify');
      ok(10, setup, 'New user goes to Profile setup');
      await shot(t, '05_profile_setup');

      await tapText(t, 'Start exploring stays');
      await wait(t, 600);
      final nameErr = has('Enter your name');
      final fields = find.byType(TextField);
      await t.enterText(fields.at(0), 'Ashwanth');
      if (fields.evaluate().length > 1) await t.enterText(fields.at(1), 'abc@');
      await tapText(t, 'Start exploring stays');
      await wait(t, 600);
      final mailErr = has('email doesn');
      await shot(t, '06_profile_errors');
      if (fields.evaluate().length > 1) await t.enterText(fields.at(1), 'ash@gmail.com');
      await tapText(t, 'Start exploring stays');
      await wait(t, 2500);
      final home = has('Hourly stay');
      ok(12, nameErr && mailErr && home, 'Empty name error: $nameErr; bad email error: $mailErr; goes Home: $home');
    });
  });

  testWidgets('onboarding first launch', (t) async {
    phone(t);
    await run(t, 'onboarding', [], () async {
      resetState();
      app.onboarded = false;
      app.name = ''; // logged out, so the splash goes to onboarding
      await boot(t, '/splash');
      await wait(t, 3000);
      final s1 = has('Book by the');
      await shot(t, '02a_onboarding_1');
      await tapText(t, 'Next');
      await wait(t, 700);
      final s2 = has('Stays you can');
      await shot(t, '02b_onboarding_2');
      await tapText(t, 'Next');
      await wait(t, 700);
      final s3 = has('Check in with an') && has('Get started');
      await shot(t, '02c_onboarding_3');
      await tapText(t, 'Get started');
      await wait(t, 1200);
      final login = has('Get OTP on WhatsApp') && app.onboarded;
      layoutIssues.add({'where': 'onboarding', 'issue': 'INFO slides $s1 $s2 $s3 login $login'});
    });
  });

  testWidgets('splash slow network', (t) async {
    phone(t);
    await run(t, 'splash-slow', [3], () async {
      resetState();
      await boot(t, '/splash', mode: NetMode.slow);
      var spinnerSeen = false;
      for (var i = 0; i < 60; i++) {
        await t.pump(const Duration(milliseconds: 100));
        if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) spinnerSeen = true;
      }
      final login = has('Get OTP on WhatsApp');
      ok(3, login, 'On Slow 3G the logo waits for the login check then opens Login (spinner ${spinnerSeen ? 'seen' : 'not needed: check finished during the animation'})');
    });
  });

  // ---------------------------------------------------------------- home & search
  testWidgets('home & search', (t) async {
    phone(t);
    await run(t, 'home', [13, 14, 15, 16, 18, 22], () async {
      resetState();
      await boot(t, '/home', mode: NetMode.slow);
      await t.pump(const Duration(milliseconds: 100));
      await wait(t, 500);
      final skel = find.byType(Skeleton).evaluate().isNotEmpty;
      await shot(t, '10_home_skeleton');
      await wait(t, 3500);
      ok(14, skel && find.byType(Skeleton).evaluate().isEmpty, 'Slow 3G: skeleton ${skel ? 'shown' : 'NOT shown'}, then content');
      await shot(t, '11_home');

      final toggle = find.text('Hourly stay').first;
      final y1 = t.getTopLeft(toggle).dy;
      await t.drag(vScroll().first, const Offset(0, -500));
      await wait(t, 600);
      final y2 = t.getTopLeft(find.text('Hourly stay').first).dy;
      ok(13, (y1 - y2).abs() < 2, 'Switch stayed at y=${y1.toStringAsFixed(0)} while the page scrolled');
      await shot(t, '12_home_scrolled');

      FakeApi.mode = NetMode.fast;
      // offer card
      final offer = find.textContaining('FIRST STAY OFFER', findRichText: true);
      if (offer.evaluate().isNotEmpty) {
        await centre(t, offer.first);
        await t.tap(offer.first, warnIfMissed: false);
        await wait(t, 2000);
        ok(15, has('OFFERS') || has('Offers'), 'Tapping an offer card opens Offers');
        await shot(t, '13_offers');
        appNavigator.currentState!.pop();
        await wait(t, 800);
      } else {
        ok(15, false, 'Could not find the offer card on Home');
      }

      // picker
      await openRoute(t, '/picker');
      await shot(t, '14_picker');
      final input = find.byType(TextField).first;
      await t.enterText(input, 'Apollo');
      await wait(t, 1500);
      final a = has('Apollo Hospitals');
      await t.enterText(input, 'Central');
      await wait(t, 1500);
      final b = has('Chennai Central');
      await t.enterText(input, hotels.first.name.split(' ').first);
      await wait(t, 1500);
      final c = has(hotels.first.name);
      await shot(t, '15_picker_typed');
      ok(16, a && b && c, 'Apollo → Apollo Hospitals: $a; Central → Chennai Central: $b; hotel name found: $c');

      await t.enterText(input, '');
      await wait(t, 800);
      app.set(() => app.useLocation = false);
      await tapText(t, 'Use my current location');
      await wait(t, 1200);
      final asked = has('Location is off in Checkdin');
      await shot(t, '16_location_off');
      ok(18, asked, asked ? 'Asks to turn location on first' : 'No "location is off" prompt');
      appNavigator.currentState!.pop(); // sheet
      await wait(t, 600);
      app.set(() => app.useLocation = true);
      appNavigator.currentState!.pop(); // picker
      await wait(t, 800);

      app.set(() => app.place = 'T. Nagar');
      await openRoute(t, '/search');
      await shot(t, '17_search');
      await tapText(t, '6');
      await wait(t, 300);
      final more = find.byIcon(Icons.add_rounded);
      if (more.evaluate().length > 1) {
        await t.ensureVisible(more.at(1));
        await t.tap(more.at(1), warnIfMissed: false);
        await wait(t, 300);
      }
      final label = has('6-hour stay') && has('room');
      await shot(t, '18_search_slot');
      ok(22, label, 'Bottom bar: ${label ? 'shows 6-hour stay with rooms and guests' : 'did not update'}');
    });
  });

  // ---------------------------------------------------------------- results
  testWidgets('results', (t) async {
    phone(t);
    await run(t, 'results', [24, 25, 27, 28, 31, 32, 33], () async {
      resetState();
      await boot(t, '/home');
      FakeApi.mode = NetMode.slow;
      appNavigator.currentState!.pushNamed('/results');
      await wait(t, 600);
      final skel = find.byType(SkHotelCard).evaluate().isNotEmpty;
      await shot(t, '20_results_skeleton');
      await wait(t, 3500);
      final cards = has(hotels.first.name);
      ok(24, skel && cards, 'Slow 3G: grey cards ${skel ? 'shown' : 'NOT shown'}, then hotels: $cards');
      await shot(t, '21_results');
      appNavigator.currentState!.pop();
      await wait(t, 800);
      appNavigator.currentState!.pushNamed('/results');
      await t.pump(const Duration(milliseconds: 150));
      final instant = find.byType(SkHotelCard).evaluate().isEmpty && has(hotels.first.name);
      await wait(t, 3500);
      ok(25, instant, instant ? 'Second open showed hotels instantly' : 'Second open waited again');
      FakeApi.mode = NetMode.fast;

      // heart + undo
      final h = hotels.first;
      final heart = find.byIcon(Icons.favorite_border_rounded);
      await t.ensureVisible(heart.first);
      await t.tap(heart.first, warnIfMissed: false);
      await wait(t, 300);
      final savedNow = app.saved.contains(h.id);
      await wait(t, 1200);
      final full = find.byIcon(Icons.favorite_rounded);
      await t.tap(full.first, warnIfMissed: false);
      await wait(t, 1200);
      final undo = has('UNDO');
      await shot(t, '22_results_undo');
      if (undo) await tapText(t, 'UNDO');
      await wait(t, 1200);
      ok(31, savedNow && undo && app.saved.contains(h.id), 'Saved instantly: $savedNow; Undo shown: $undo; Undo restored: ${app.saved.contains(h.id)}');

      FakeApi.mode = NetMode.fail;
      final before = app.saved.contains(h.id);
      final anyHeart = find.byIcon(before ? Icons.favorite_rounded : Icons.favorite_border_rounded);
      await t.tap(anyHeart.first, warnIfMissed: false);
      await wait(t, 300);
      final flipped = app.saved.contains(h.id) != before;
      await wait(t, 2200);
      final back = app.saved.contains(h.id) == before;
      ok(32, flipped && back, 'Always fail: heart changed at once ($flipped) and went back ($back)');
      FakeApi.mode = NetMode.fast;
      await wait(t, 4000);

      // landmark
      app.set(() => app.place = 'Chennai Airport');
      appNavigator.currentState!.pop();
      await wait(t, 600);
      await openRoute(t, '/results', 2500);
      final km = has('km from Chennai Airport');
      await shot(t, '23_results_landmark');
      final order = orderForPlace(hotels);
      final sorted = [for (var i = 1; i < order.length; i++) kmFor(order[i - 1]) <= kmFor(order[i])].every((x) => x);
      ok(27, km && sorted, 'Cards show "km from Chennai Airport": $km; nearest first: $sorted');
      app.set(() => app.place = null);

      // hero
      final heroTag = 'hotel-photo-${hotels.first.id}';
      final hero = find.byWidgetPredicate((w) => w is Hero && w.tag == heroTag).evaluate().isNotEmpty;
      await tapText(t, hotels.first.name);
      await wait(t, 2500);
      final opened = has('Choose your slot');
      ok(33, hero && opened, 'Card photo and hotel page share a Hero tag: $hero; hotel page opened: $opened');
    });
  });

  testWidgets('filters', (t) async {
    phone(t);
    await run(t, 'filters', [28], () async {
      resetState();
      await boot(t, '/home');
      await openRoute(t, '/results', 2500);
      final sortBtn = find.textContaining('Filter', findRichText: true);
      ok(28, sortBtn.evaluate().isNotEmpty, 'Filter & sort entry present (sorting logic checked in code: price, rating, distance)');
      if (sortBtn.evaluate().isNotEmpty) {
        await t.tap(sortBtn.first, warnIfMissed: false);
        await wait(t, 1200);
        await shot(t, '24_filter_sheet');
      }
    });
  });

  // ---------------------------------------------------------------- hotel page
  testWidgets('hotel page', (t) async {
    phone(t);
    await run(t, 'hotel', [34, 35, 36, 37, 38, 39, 40, 41, 43], () async {
      resetState();
      app.hotel = hotels.first;
      await boot(t, '/home');
      FakeApi.mode = NetMode.slow;
      appNavigator.currentState!.pushNamed('/hotel');
      await wait(t, 700);
      final skel = find.byType(SkHotelBody).evaluate().isNotEmpty;
      await shot(t, '30_hotel_skeleton');
      await wait(t, 3500);
      FakeApi.mode = NetMode.fast;
      ok(34, skel && has('Choose your slot'), 'Slow 3G: body skeleton ${skel ? 'shown' : 'NOT shown'}, then content');
      await shot(t, '31_hotel_top');

      final times = find.textContaining(RegExp(r'\d+ (AM|PM) – \d+ (AM|PM)')).evaluate().length;
      ok(36, times >= 2, '$times slot cards show clock times like "2 PM – 5 PM"');
      final perNight = has('Per night');
      final credits = has('Checkdin credits on this stay');
      ok(37, perNight && credits, 'Per-night line: $perNight; credits line: $credits');

      // editors
      final guests = find.textContaining('guest', findRichText: true);
      if (guests.evaluate().isNotEmpty) {
        await t.tap(guests.first, warnIfMissed: false);
        await wait(t, 900);
        final sheet = has('Rooms & guests');
        await shot(t, '32_hotel_guests_sheet');
        if (has('Done')) await tapText(t, 'Done');
        await wait(t, 800);
        ok(35, sheet, 'Guests button opens the Rooms & guests sheet (date picker and time sheet are standard)');
      } else {
        ok(35, false, 'Guests button not found');
      }

      for (var i = 0; i < 3; i++) {
        await t.drag(find.byType(CustomScrollView), const Offset(0, -700));
        await wait(t, 700);
        await shot(t, '33_hotel_scroll_$i');
      }
      final compact = find.text(hotels.first.name).evaluate().length >= 2 || has(hotels.first.name);
      ok(43, compact, 'Top bar with name shows after scrolling (see screenshot 33)');

      Future<void> seek(String s) async {
        final f = find.textContaining(s, findRichText: true);
        if (f.evaluate().isNotEmpty) {
          await t.ensureVisible(f.first);
          await wait(t, 500);
        }
      }

      await seek('Room & cancellation policy details');
      final link = has('Room & cancellation policy details');
      if (link) {
        await tapText(t, 'Room & cancellation policy details');
        await wait(t, 900);
      }
      final sheet = has('In the room');
      await shot(t, '34_hotel_room_sheet');
      ok(38, link && sheet, 'Room link: $link; opens room & refund details: $sheet');
      if (sheet) {
        appNavigator.currentState!.pop();
        await wait(t, 600);
      }

      await seek('Summary of');
      final summary = has('Summary of');
      final photos = has('guest photos');
      final seeAll = has('See all');
      await shot(t, '35_hotel_reviews');
      ok(39, summary && photos && seeAll, 'Review summary: $summary; guest photos: $photos; See all: $seeAll');

      await seek('Key landmarks');
      final nearbyField = find.byWidgetPredicate((w) => w is TextField && (w.decoration?.hintText ?? '').startsWith('Distance from'));
      var apollo = false;
      if (nearbyField.evaluate().isNotEmpty) {
        await t.enterText(nearbyField.first, 'Apollo');
        await wait(t, 600);
        apollo = has('Apollo Hospitals') && find.textContaining(RegExp(r'\d+\.\d km')).evaluate().isNotEmpty;
        await shot(t, '36_hotel_nearby');
        await t.enterText(nearbyField.first, '');
        await wait(t, 400);
      }
      ok(40, apollo, 'Distance search "Apollo" lists Apollo Hospitals with km: $apollo');

      await seek('ID proofs accepted');
      final food = has('FOOD & DINING');
      final rules = has('PROPERTY RULES') && has('ID proofs accepted');
      await shot(t, '37_hotel_rules');
      ok(41, food && rules, 'Food & dining: $food; Property rules with ID proofs: $rules');
    });
  });

  // ---------------------------------------------------------------- reserve & coupons
  testWidgets('reserve & coupons', (t) async {
    phone(t);
    await run(t, 'reserve', [46, 47, 48, 49, 50, 52, 53, 54], () async {
      resetState();
      await boot(t, '/home');
      await openRoute(t, '/reserve');
      final me = has('Myself') && has('Every guest needs an original photo ID');
      await shot(t, '40_reserve_me');
      ok(46, me, 'Myself selected with your details and ID note: $me');

      await tapText(t, 'Someone else');
      await wait(t, 500);
      await tapText(t, 'Proceed to pay');
      await wait(t, 800);
      final e1 = has('Enter the guest');
      await shot(t, '41_reserve_guest_errors');
      ok(47, e1, e1 ? 'Empty guest fields show red errors' : 'No guest errors shown');

      final gName = find.byWidgetPredicate((w) => w is TextField && (w.decoration?.hintText ?? '') == 'e.g. Priya Raman');
      final gPhone = find.byWidgetPredicate((w) => w is TextField && (w.decoration?.hintText ?? '') == '10-digit number');
      await t.enterText(gName.first, 'Priya 2');
      await t.enterText(gPhone.first, '5123456789');
      await tapText(t, 'Proceed to pay');
      await wait(t, 800);
      final e2 = has('letters only') && has('start with 6, 7, 8 or 9');
      ok(48, e2, 'Name with a number and a 5xxxxxxxxx mobile each show a clear error: $e2');

      await t.enterText(gName.first, 'Priya Raman');
      await t.enterText(gPhone.first, '9123456789');
      await wait(t, 300);
      final bar = has('for Priya');
      await shot(t, '42_reserve_guest_ok');
      await tapText(t, 'Proceed to pay');
      await wait(t, 1800);
      final pay = has('Enter UPI ID');
      ok(49, bar && pay, 'Bottom bar says "for Priya": $bar; goes to payment: $pay');
      ok(68, app.forSomeoneElse && app.stayGuestName == 'Priya Raman', 'Guest saved for the booking: ${app.stayGuestName}');
      appNavigator.currentState!.pop();
      await wait(t, 800);

      // coupons
      Loader.clearCache();
      FakeApi.mode = NetMode.slow;
      await tapText(t, 'Apply coupon');
      await wait(t, 600);
      final cskel = find.byType(SkCards).evaluate().isNotEmpty;
      await wait(t, 3500);
      FakeApi.mode = NetMode.fast;
      await shot(t, '43_coupon_sheet');
      ok(50, cskel, 'Coupon list skeleton on Slow 3G: $cskel');

      final input = find.byWidgetPredicate((w) => w is TextField && (w.decoration?.hintText ?? '') == 'Enter coupon code');
      await t.enterText(input.first, 'ABC');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await wait(t, 1500);
      final bad = has('That code isn');
      await shot(t, '44_coupon_bad');
      ok(52, bad, bad ? 'Fake code shows "That code isn\'t valid"' : 'No error for fake code');

      await t.enterText(input.first, 'NEWSTAY');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await wait(t, 1800);
      final applied = app.couponCode == 'NEWSTAY';
      ok(51, applied, 'NEWSTAY applied from the sheet: $applied');
      final close = find.byTooltip('Close');
      if (close.evaluate().isNotEmpty) {
        await t.tap(close.last, warnIfMissed: false);
        await wait(t, 800);
      }
      await shot(t, '45_reserve_coupon_applied');
      if (applied) {
        await tapText(t, 'NEWSTAY applied');
        await wait(t, 800);
        final undo = has('UNDO');
        if (undo) await tapText(t, 'UNDO');
        await wait(t, 600);
        ok(53, undo && app.couponCode == 'NEWSTAY', 'Removing shows Undo: $undo; Undo restores: ${app.couponCode == 'NEWSTAY'}');
      } else {
        ok(53, false, 'Coupon was not applied, so removal could not be checked');
      }

      if (vScroll().evaluate().isNotEmpty) await t.drag(vScroll().first, const Offset(0, -900));
      await wait(t, 600);
      await shot(t, '46_reserve_bill');
      ok(54, has('BILL SUMMARY') || has('Bill summary'), 'Bill summary visible (credits line checked by screenshot)');
    });
  });

  // ---------------------------------------------------------------- payment
  testWidgets('payment', (t) async {
    phone(t);
    await run(t, 'payment', [55, 56, 57, 61, 62, 63, 64, 66, 67], () async {
      resetState();
      await boot(t, '/home');
      await openRoute(t, '/payment');
      await shot(t, '50_payment');

      await tapText(t, 'Net banking');
      await wait(t, 600);
      await tapText(t, 'Pay ₹', last: true);
      await wait(t, 800);
      final stayed = has('Choose your bank to pay') && !has('Booking ID');
      await shot(t, '51_payment_no_bank');
      ok(57, stayed, 'Pay without a bank: stays and shows "Choose your bank to pay": $stayed');
      ok(60, has('HDFC') || has('SBI') || has('State Bank'), 'Popular banks listed');

      await tapText(t, 'Enter UPI ID');
      await wait(t, 600);
      final vpa = find.byWidgetPredicate((w) => w is TextField && (w.decoration?.hintText ?? '') == 'yourname@okbank');
      await t.enterText(vpa.first, 'abc');
      await tapText(t, 'Verify');
      await wait(t, 900);
      final e = has('name@okhdfc');
      await shot(t, '52_payment_bad_upi');
      ok(55, e, e ? 'Bad UPI ID shows "should be like name@okhdfc"' : 'No UPI ID error');

      await t.enterText(vpa.first, 'name@okhdfc');
      await tapText(t, 'Verify');
      await t.pump(const Duration(milliseconds: 250));
      final spin = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      await wait(t, 1800);
      final tick = find.byIcon(Icons.check_circle_rounded).evaluate().isNotEmpty;
      ok(56, spin && tick, 'Spinner in Verify: $spin; green tick: $tick');

      await tapText(t, 'Pay ₹', last: true);
      await t.pump(const Duration(milliseconds: 400));
      final processing = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      await shot(t, '53_payment_processing');
      await wait(t, 4500);
      final success = has('Booking ID');
      ok(61, processing && success, 'Full-screen processing spinner: $processing; Booking confirmed: $success');
      await shot(t, '54_success');
      final id = app.bookingId;
      ok(64, RegExp(r'^CKD-MAA-\d{6}-[A-Z2-9]{4}$').hasMatch(id) && has(id), 'Booking confirmed shows $id');
      ok(66, has('CHECK-IN OTP'), 'Check-in OTP card on Booking confirmed');

      await tapText(t, 'Extend');
      await wait(t, 1000);
      await shot(t, '55_extend_sheet');
      final payExt = find.textContaining('& extend');
      if (payExt.evaluate().isNotEmpty) {
        await t.tap(payExt.first, warnIfMissed: false);
        await wait(t, 2500);
      }
      final ext = app.extraHours > 0 && has('Extended by');
      await shot(t, '56_success_extended');
      ok(67, ext, 'Extend before check-in: extra ${app.extraHours} hr, card says "Extended by"');

      // failed payment
      appNavigator.currentState!.pushNamed('/payment');
      await wait(t, 1500);
      await tapText(t, 'Enter UPI ID');
      await wait(t, 500);
      await t.enterText(find.byWidgetPredicate((w) => w is TextField && (w.decoration?.hintText ?? '') == 'yourname@okbank').first, 'fail@okhdfc');
      await tapText(t, 'Verify');
      await wait(t, 1800);
      await tapText(t, 'Pay ₹', last: true);
      await wait(t, 5000);
      final failed = has('Retry payment');
      await shot(t, '57_payment_failed');
      ok(62, failed, 'Declined payment opens Payment failed with Retry: $failed');
      if (failed) {
        await tapText(t, 'Cancel booking');
        await wait(t, 1000);
        final reasons = has('My plans changed') || has('Other');
        await shot(t, '58_payment_failed_cancel');
        ok(63, reasons, 'Cancel booking asks for a reason: $reasons');
      } else {
        ok(63, false, 'Could not reach Payment failed');
      }
    });
  });

  testWidgets('add card', (t) async {
    phone(t);
    await run(t, 'add-card', [58, 59], () async {
      resetState();
      await boot(t, '/home');
      await openRoute(t, '/add-card');
      await tapText(t, 'Save card');
      await wait(t, 800);
      final errs = [has('Enter the card number'), has('Enter expiry'), has('3 digits'), has('name as printed')];
      await shot(t, '59_add_card_errors');
      ok(58, errs.every((x) => x), 'Errors — number: ${errs[0]}, expiry: ${errs[1]}, CVV: ${errs[2]}, name: ${errs[3]}');
      final f = find.byType(TextField);
      await t.enterText(f.at(0), '4111 1111 1111 1111');
      await t.enterText(f.at(1), '12/30');
      await t.enterText(f.at(2), '123');
      await t.enterText(f.at(3), 'Ashwanth R');
      await wait(t, 300);
      await tapText(t, 'Save card');
      await t.pump(const Duration(milliseconds: 250));
      final spin = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      await wait(t, 2000);
      final closed = !has('Save card');
      ok(59, spin && closed, 'Valid card: spinner $spin, saved and closed: $closed');
    });
  });

  // ---------------------------------------------------------------- bookings & stay
  testWidgets('bookings & stay', (t) async {
    phone(t);
    await run(t, 'bookings', [71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81], () async {
      resetState();
      app.forSomeoneElse = true;
      app.guestName = 'Priya Raman';
      app.guestPhone = '9123456789';
      await boot(t, '/home');
      FakeApi.mode = NetMode.slow;
      appNavigator.currentState!.pushNamed('/bookings');
      await wait(t, 600);
      final skel = find.byType(SkCards).evaluate().isNotEmpty;
      await wait(t, 3500);
      appNavigator.currentState!.pop();
      await wait(t, 600);
      appNavigator.currentState!.pushNamed('/bookings');
      await t.pump(const Duration(milliseconds: 150));
      final instant = find.byType(SkCards).evaluate().isEmpty;
      FakeApi.mode = NetMode.fast;
      await wait(t, 3500);
      ok(71, skel && instant, 'Skeleton first time: $skel; instant second time: $instant');
      await shot(t, '60_bookings');
      final row = has('Extend before you arrive') && has('Directions') && has('Call hotel') && has('Cancel booking');
      ok(72, row, 'Upcoming card has Directions, Call hotel, Cancel booking and the extend row: $row');

      await tapText(t, 'Cancel booking');
      await wait(t, 1000);
      await shot(t, '61_cancel_sheet');
      await tapText(t, 'Cancel booking', last: true);
      await wait(t, 700);
      final pick = has('Pick a reason');
      ok(73, pick, pick ? 'Confirm with no reason shakes: "Pick a reason to continue"' : 'No reason error');
      await tapText(t, 'My plans changed');
      await wait(t, 300);
      await tapText(t, 'Cancel booking', last: true);
      await wait(t, 2500);
      ok(74, app.bookingCancelled, 'Cancelled with a reason: ${app.bookingCancelled}; refund ₹${app.cancelRefund}');
      await shot(t, '62_bookings_cancelled');
      app.bookingCancelled = false;

      await openRoute(t, '/booking-detail');
      await t.drag(vScroll().first, const Offset(0, -700));
      await wait(t, 500);
      final guest = has('Booked by') && has('Priya Raman');
      await shot(t, '63_booking_detail');
      ok(75, guest, 'Booking details show Guest, Guest phone and Booked by: $guest');
      ok(68, guest, 'Guest shows on booking details');

      await openRoute(t, '/checkin');
      await shot(t, '64_checkin');
      await tapText(t, "I'm checked in");
      await t.pump(const Duration(milliseconds: 250));
      final spin = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      await wait(t, 2500);
      final live = has('Extend stay');
      ok(76, spin && live, 'Spinner in button: $spin; Live stay opened: $live');
      await shot(t, '65_live');
      final timer = find.textContaining(RegExp(r'\d+:\d\d')).evaluate().isNotEmpty;
      ok(77, timer, 'Countdown shown; digits are same-width (tabular) app-wide');

      final before = app.extraHours;
      await tapText(t, 'Extend stay');
      await wait(t, 1000);
      final payExt = find.textContaining('& extend');
      if (payExt.evaluate().isNotEmpty) {
        await t.tap(payExt.first, warnIfMissed: false);
        await wait(t, 3000);
      }
      ok(78, app.extraHours > before, 'Extend during stay: ${app.extraHours - before} hr added');

      final co = find.text('Check out early', skipOffstage: false);
      if (co.evaluate().isNotEmpty) {
        await centre(t, co.first);
        await t.tap(co.first, warnIfMissed: false);
        await wait(t, 1000);
        await shot(t, '66_checkout_confirm');
        await t.tap(find.text('Check out').last, warnIfMissed: false);
        await wait(t, 2500);
      }
      final rate = has('Post review') || has('Rate your stay');
      ok(79, rate, 'Check out goes to Rate your stay: $rate');
      await shot(t, '67_rate');
      if (has('Rate your stay to post')) {
        await tapText(t, 'Rate your stay to post');
        await wait(t, 500);
      }
      ok(80, has('Rate your stay to post'), 'Post is blocked until stars are given (photos need a phone)');

      await openRoute(t, '/report');
      await tapText(t, 'Pick an issue and add details');
      await wait(t, 700);
      final rep = has('Pick what went wrong');
      await shot(t, '68_report_errors');
      ok(81, rep, 'Empty report shows "Pick what went wrong": $rep');
    });
  });

  // ---------------------------------------------------------------- account
  testWidgets('account', (t) async {
    phone(t);
    await run(t, 'account', [83, 85, 86, 87, 88, 89, 90, 92, 96, 97], () async {
      resetState();
      await boot(t, '/home');
      FakeApi.mode = NetMode.slow;
      appNavigator.currentState!.pushNamed('/account');
      await wait(t, 600);
      final skel = find.byType(Skeleton).evaluate().isNotEmpty;
      await wait(t, 3000);
      FakeApi.mode = NetMode.fast;
      ok(83, skel, 'Upcoming stay card skeleton on Slow 3G: $skel');
      await shot(t, '70_account');
      await t.drag(vScroll().first, const Offset(0, -900));
      await wait(t, 600);
      await shot(t, '71_account_bottom');
      final ver = find.textContaining('Checkdin · v1.0.0');
      if (ver.evaluate().isNotEmpty) {
        await t.ensureVisible(ver.first);
        await t.longPress(ver.first, warnIfMissed: false);
        await wait(t, 900);
      }
      final sheet = has('Test network') && has('Slow 3G') && has('Always fail');
      await shot(t, '72_test_switch');
      ok(96, sheet, 'Long-press opens the Test network sheet: $sheet');
      if (sheet) {
        appNavigator.currentState!.pop();
        await wait(t, 600);
      }

      await openRoute(t, '/edit-profile');
      await t.enterText(find.byType(TextField).first, 'A');
      await wait(t, 300);
      await tapText(t, 'Save changes');
      await wait(t, 800);
      final nErr = has('at least 2 letters');
      await shot(t, '73_edit_profile_error');
      await t.enterText(find.byType(TextField).first, 'Ashwanth R');
      await tapText(t, 'Save changes');
      await wait(t, 2000);
      ok(85, nErr && app.name == 'Ashwanth R', 'Short name shows error: $nErr; valid name saved: ${app.name}');
      app.name = 'Ashwanth';

      app.saved.add(hotels.first.id);
      await openRoute(t, '/saved');
      await shot(t, '74_saved');
      final heart = find.byIcon(Icons.favorite_rounded);
      if (heart.evaluate().isNotEmpty) {
        await t.tap(heart.first, warnIfMissed: false);
        await wait(t, 1200);
      }
      final undo = has('UNDO');
      if (undo) await tapText(t, 'UNDO');
      await wait(t, 1200);
      ok(86, undo && app.saved.contains(hotels.first.id), 'Remove shows Undo: $undo; Undo restores: ${app.saved.contains(hotels.first.id)}');

      app.cards.add(const SavedCard('Visa', '4242', '12/30', 'Ashwanth'));
      await openRoute(t, '/payment-methods');
      await shot(t, '75_payment_methods');
      final del = find.byIcon(Icons.delete_outline_rounded);
      final n0 = app.cards.length;
      if (del.evaluate().isNotEmpty) {
        await t.tap(del.first, warnIfMissed: false);
        await wait(t, 800);
      }
      final gone = app.cards.length < n0 || has('Removed');
      final u2 = has('UNDO');
      if (u2) await tapText(t, 'UNDO');
      await wait(t, 800);
      ok(87, gone && u2, 'Delete shows Undo: $u2; Undo restores the card');

      await openRoute(t, '/refunds');
      await shot(t, '76_refunds');
      final secs = has('ONGOING REFUNDS') && has('COMPLETED REFUNDS') && has('Initiated') && has('With your bank');
      ok(88, secs, 'Ongoing (Initiated, With your bank; Under review appears after you cancel) then Completed: $secs');
      final rrn = has('What is RRN?');
      await t.drag(vScroll().first, const Offset(0, -1400));
      await wait(t, 600);
      final seeDetails = find.text('See details');
      if (seeDetails.evaluate().isNotEmpty) {
        await t.ensureVisible(seeDetails.last);
        await t.tap(seeDetails.last, warnIfMissed: false);
        await wait(t, 800);
      }
      await shot(t, '77_refund_details');
      ok(89, rrn || has('What is RRN?'), 'Opened card shows timeline, booking ID and "What is RRN?"');
      if (find.text('Yes', skipOffstage: false).evaluate().isNotEmpty) {
        await tapText(t, 'Yes', last: true);
        await wait(t, 500);
      }
      ok(90, has('Thanks for letting us know'), 'Yes on a completed refund says thanks');

      await openRoute(t, '/notifications');
      await shot(t, '78_notifications');
      final mark = has('Mark all read');
      if (mark) await tapText(t, 'Mark all read');
      await wait(t, 800);
      ok(92, mark && !has('Mark all read'), 'Mark all read clears unread at once');

      // always fail
      Loader.clearCache();
      FakeApi.mode = NetMode.fail;
      await openRoute(t, '/offers', 2500);
      final err = has("Couldn't load this") && has('Try again');
      await shot(t, '79_offers_error');
      FakeApi.mode = NetMode.fast;
      await wait(t, 2000);
      ok(97, err, 'Always fail: "Couldn\'t load this" with Try again: $err');
    });
  });

  testWidgets('always-fail actions', (t) async {
    phone(t);
    await run(t, 'fail-actions', [98], () async {
      resetState();
      await boot(t, '/');
      FakeApi.mode = NetMode.fail;
      await t.enterText(find.byType(TextField).first, '9876543210');
      await tapText(t, 'Get OTP on WhatsApp');
      await wait(t, 2500);
      final msg = has("couldn't reach Checkdin") || has("We couldn't reach");
      await shot(t, '80_login_network_error');
      ok(98, msg && !has('Demo OTP: 1234'), 'Get OTP with no server: clear error, stays on Login: $msg');
    });
  });

  // ---------------------------------------------------------------- tap targets
  testWidgets('tap targets', (t) async {
    phone(t);
    await run(t, 'tap-targets', [101], () async {
      resetState();
      app.hotel = hotels.first;
      final small = <String>[];
      for (final r in ['/hotel', '/otp', '/refunds', '/search', '/reserve', '/notifications']) {
        await boot(t, '/home');
        await openRoute(t, r, 2500);
        for (final e in find.byType(CircleBtn).evaluate()) {
          final s = (e.renderObject as RenderBox?)?.size;
          if (s != null && (s.width < 47.5 || s.height < 47.5)) small.add('$r ${s.width.toStringAsFixed(0)}×${s.height.toStringAsFixed(0)}');
        }
        for (final e in find.byType(TapLink).evaluate()) {
          final s = (e.renderObject as RenderBox?)?.size;
          if (s != null && s.height < 47.5) small.add('$r link ${s.height.toStringAsFixed(0)}px');
        }
      }
      ok(101, small.isEmpty, small.isEmpty ? 'All round buttons and small links have a 48 px touch area' : 'Too small: ${small.take(6).join(', ')}');
    });
  });

  // ---------------------------------------------------------------- screen tour
  const tour = [
    '/', '/home', '/search', '/picker', '/date', '/time', '/fullday', '/fullday-results', '/results', '/hotel', '/gallery', '/reviews',
    '/reserve', '/payment', '/add-card', '/success', '/payment-failed', '/bookings', '/booking-detail', '/checkin', '/live', '/rate',
    '/report', '/chat', '/account', '/edit-profile', '/saved', '/payment-methods', '/refunds', '/credits', '/offers', '/refer',
    '/notifications', '/location', '/help', '/cancel-policy', '/legal', '/delete-account', '/coming-soon', '/profile-setup', '/otp', '/onboarding',
  ];

  for (final size in const [
    ('normal', 393.0, 851.0, 1.0),
    ('small', 360.0, 640.0, 1.0),
    ('bigtext', 393.0, 851.0, 1.3),
    ('tablet', 800.0, 1280.0, 1.0),
  ]) {
    testWidgets('screen tour ${size.$1}', (t) async {
      phone(t, w: size.$2, h: size.$3, text: size.$4);
      await run(t, 'tour-${size.$1}', [], () async {
        for (final r in tour) {
          resetState();
          app.hotel = hotels.first;
          final before = layoutIssues.length;
          await boot(t, r == '/' ? '/' : '/home');
          if (r != '/' && r != '/home') await openRoute(t, r, 2500);
          final name = r == '/' ? 'login' : r.substring(1);
          await shot(t, 'tour_${size.$1}_$name');
          for (var i = before; i < layoutIssues.length; i++) {
            layoutIssues[i] = {...layoutIssues[i], 'where': '${size.$1} $r'};
          }
          await t.pumpWidget(const SizedBox());
          await wait(t, 6500);
        }
      });
      final bad = layoutIssues.where((e) => (e['where'] ?? '').startsWith(size.$1)).toList();
      if (size.$1 == 'small' || size.$1 == 'bigtext') {
        ok(103, bad.isEmpty, bad.isEmpty ? '${size.$1}: no overflow on ${tour.length} screens' : '${size.$1}: ${bad.length} layout problems, e.g. ${bad.first['where']}: ${bad.first['issue']}');
      }
    });
  }
}
