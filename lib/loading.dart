import 'dart:async';

import 'package:flutter/material.dart';

import 'api/api.dart';
import 'screens/states.dart';
import 'theme.dart';

// =================================================================== skeletons

/// Gently pulses everything inside it. Put plain [Bone]s inside.
class Skeleton extends StatefulWidget {
  final Widget child;
  const Skeleton({super.key, required this.child});
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Loading',
        child: FadeTransition(
          opacity: Tween(begin: 0.45, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
          child: widget.child,
        ),
      );
}

/// One grey placeholder block.
class Bone extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const Bone({super.key, this.width, this.height = 12, this.radius = 8});
  @override
  Widget build(BuildContext context) =>
      Container(width: width, height: height, decoration: BoxDecoration(color: C.track, borderRadius: BorderRadius.circular(radius)));
}

Widget _gap([double h = 8]) => SizedBox(height: h);

/// Hotel card in results / saved lists.
class SkHotelCard extends StatelessWidget {
  const SkHotelCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: Sp.lg),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.xl)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Bone(height: 170, radius: R.xl),
          Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Bone(width: 190, height: 16),
              _gap(),
              const Bone(width: 140),
              _gap(14),
              const Row(children: [Bone(width: 70, height: 22, radius: R.pill), SizedBox(width: Sp.sm), Bone(width: 90, height: 22, radius: R.pill), Spacer(), Bone(width: 64, height: 20)]),
            ]),
          ),
        ]),
      );
}

/// A list of rows (bookings, refunds, notifications, credits...).
class SkRows extends StatelessWidget {
  final int count;
  final bool icon;
  final double height;
  const SkRows({super.key, this.count = 5, this.icon = true, this.height = 74});
  @override
  Widget build(BuildContext context) => Skeleton(
        child: Column(
          children: List.generate(
            count,
            (i) => Container(
              height: height,
              margin: const EdgeInsets.only(bottom: Sp.md),
              padding: const EdgeInsets.all(Sp.lg),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.xl)),
              child: Row(children: [
                if (icon) ...[const Bone(width: 42, height: 42, radius: R.lg), const SizedBox(width: Sp.md)],
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Bone(width: i.isEven ? 170 : 130, height: 14),
                    _gap(),
                    Bone(width: i.isEven ? 110 : 150, height: 10),
                  ]),
                ),
                const Bone(width: 52, height: 16),
              ]),
            ),
          ),
        ),
      );
}

/// Results / saved: a column of hotel cards.
class SkHotelList extends StatelessWidget {
  final int count;
  const SkHotelList({super.key, this.count = 3});
  @override
  Widget build(BuildContext context) => Skeleton(child: Column(children: List.generate(count, (_) => const SkHotelCard())));
}

/// Booking / coupon / refund style card.
class SkCards extends StatelessWidget {
  final int count;
  final double height;
  const SkCards({super.key, this.count = 3, this.height = 150});
  @override
  Widget build(BuildContext context) => Skeleton(
        child: Column(
          children: List.generate(
            count,
            (i) => Container(
              constraints: BoxConstraints(minHeight: height),
              margin: const EdgeInsets.only(bottom: Sp.md),
              padding: const EdgeInsets.all(Sp.lg),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.xl)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Expanded(child: Bone(height: 16)), SizedBox(width: Sp.x4), Bone(width: 80, height: 22, radius: R.pill)]),
                _gap(14),
                const Bone(width: 180),
                _gap(),
                const Bone(width: 130),
                _gap(16),
                const Bone(height: 36, radius: R.pill),
              ]),
            ),
          ),
        ),
      );
}

/// Home feed below the search bar.
class SkHome extends StatelessWidget {
  const SkHome({super.key});
  @override
  Widget build(BuildContext context) => Skeleton(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _gap(22),
            const Bone(width: 120, height: 12),
            _gap(12),
            const SizedBox(
              height: 150,
              child: Row(children: [Expanded(child: Bone(height: 150, radius: R.xl)), SizedBox(width: Sp.md), Expanded(child: Bone(height: 150, radius: R.xl))]),
            ),
            _gap(24),
            const Bone(width: 140, height: 12),
            _gap(12),
            for (var i = 0; i < 3; i++) ...[const Bone(height: 64, radius: R.lg), _gap(10)],
          ]),
        ),
      );
}

/// Hotel page body below the photos.
class SkHotelBody extends StatelessWidget {
  const SkHotelBody({super.key});
  @override
  Widget build(BuildContext context) => Skeleton(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _gap(16),
          Container(
            padding: const EdgeInsets.all(Sp.lg),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.xl)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Expanded(child: Bone(height: 46, radius: R.lg)), SizedBox(width: Sp.sm), Expanded(child: Bone(height: 46, radius: R.lg))]),
              _gap(),
              const Bone(height: 46, radius: R.lg),
              _gap(18),
              const Bone(width: 150, height: 16),
              _gap(12),
              const Row(children: [Bone(width: 104, height: 92, radius: R.lg), SizedBox(width: Sp.sm), Bone(width: 104, height: 92, radius: R.lg), SizedBox(width: Sp.sm), Expanded(child: Bone(height: 92, radius: R.lg))]),
            ]),
          ),
          _gap(22),
          const Bone(width: 90, height: 12),
          _gap(10),
          Container(
            padding: const EdgeInsets.all(Sp.lg),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.xl)),
            child: const Row(children: [
              Bone(width: 128, height: 104, radius: R.lg),
              SizedBox(width: Sp.lg),
              Expanded(child: Column(children: [Bone(), SizedBox(height: Sp.md), Bone(), SizedBox(height: Sp.md), Bone(), SizedBox(height: Sp.md), Bone()])),
            ]),
          ),
        ]),
      );
}

/// Search picker suggestions.
class SkSuggestions extends StatelessWidget {
  const SkSuggestions({super.key});
  @override
  Widget build(BuildContext context) => Skeleton(
        child: Column(
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.md),
              child: Row(children: [
                const Bone(width: 36, height: 36, radius: R.md),
                const SizedBox(width: Sp.md),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Bone(width: 120.0 + i * 15, height: 13), _gap(6), const Bone(width: 90, height: 10)])),
              ]),
            ),
          ),
        ),
      );
}

// =================================================================== Loader

/// Loads data, showing [skeleton] only if it takes longer than 300 ms (and then
/// for at least 400 ms so it never flickers). On failure it shows a retry state.
class Loader<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget skeleton;
  final Widget Function(BuildContext context, T data) builder;
  /// Change this to load again (e.g. when the date or place changes).
  final Object? reloadKey;
  /// Stale-while-revalidate: if this screen was loaded before with the same
  /// key, show that copy instantly and refresh quietly in the background.
  /// Leave null for anything that must be fresh (prices, availability).
  final String? cacheKey;
  const Loader({super.key, required this.load, required this.skeleton, required this.builder, this.reloadKey, this.cacheKey});

  static final Map<String, Object?> _cache = {};

  /// Forget every cached screen (tests, or after logout).
  static void clearCache() => _cache.clear();
  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  T? _data;
  bool _has = false, _showSkel = false;
  Object? _err;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void didUpdateWidget(covariant Loader<T> old) {
    super.didUpdateWidget(old);
    if (old.reloadKey != widget.reloadKey) _run();
  }

  Future<void> _run() async {
    final gen = ++_gen;
    final key = widget.cacheKey;
    if (key != null && Loader._cache.containsKey(key)) {
      // Show the last copy now, refresh behind it. Errors keep the old copy.
      setState(() {
        _err = null;
        _data = Loader._cache[key] as T;
        _has = true;
      });
      try {
        final d = await widget.load();
        Loader._cache[key] = d;
        if (mounted && gen == _gen) setState(() => _data = d);
      } catch (_) {}
      return;
    }
    setState(() {
      _err = null;
      _showSkel = false;
      _has = false;
    });
    DateTime? shownAt;
    final t = Timer(const Duration(milliseconds: 300), () {
      if (mounted && gen == _gen && !_has) {
        shownAt = DateTime.now();
        setState(() => _showSkel = true);
      }
    });
    try {
      final d = await widget.load();
      if (key != null) Loader._cache[key] = d;
      t.cancel();
      if (shownAt != null) {
        final left = 400 - DateTime.now().difference(shownAt!).inMilliseconds;
        if (left > 0) await Future<void>.delayed(Duration(milliseconds: left));
      }
      if (!mounted || gen != _gen) return;
      setState(() {
        _data = d;
        _has = true;
        _showSkel = false;
      });
    } catch (e) {
      t.cancel();
      if (!mounted || gen != _gen) return;
      setState(() {
        _err = e;
        _showSkel = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_err != null) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Couldn\'t load this',
        body: _err is ApiError ? '$_err' : 'Something went wrong. Please try again.',
        primary: 'Try again',
        onPrimary: _run,
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _has
          ? KeyedSubtree(key: const ValueKey('data'), child: widget.builder(context, _data as T))
          : (_showSkel ? KeyedSubtree(key: const ValueKey('skel'), child: widget.skeleton) : const SizedBox(key: ValueKey('none'), height: 1)),
    );
  }
}

// =================================================================== spinners

/// Small spinner used inside buttons and for pull-to-refresh style waits.
class Spinner extends StatelessWidget {
  final double size;
  final Color? color;
  const Spinner({super.key, this.size = 20, this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(color ?? C.ink)),
      );
}

/// A [PillBtn] that runs an async action, showing a spinner inside itself and
/// ignoring extra taps until it finishes. Pass [validate] to shake/flag errors
/// without showing the spinner.
class AsyncBtn extends StatefulWidget {
  final String label;
  final Future<void> Function()? onTap;
  final BtnKind kind;
  final double height, fontSize;
  final IconData? icon;
  final bool trailingIcon, expand;
  const AsyncBtn(this.label,
      {super.key,
      this.onTap,
      this.kind = BtnKind.lime,
      this.height = 52,
      this.icon,
      this.trailingIcon = true,
      this.fontSize = Fs.lg,
      this.expand = false});
  @override
  State<AsyncBtn> createState() => _AsyncBtnState();
}

class _AsyncBtnState extends State<AsyncBtn> {
  bool _busy = false;
  Future<void> _go() async {
    if (_busy || widget.onTap == null) return;
    setState(() => _busy = true);
    final started = DateTime.now();
    try {
      await widget.onTap!();
    } finally {
      final left = 400 - DateTime.now().difference(started).inMilliseconds;
      if (left > 0 && mounted) await Future<void>.delayed(Duration(milliseconds: left));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PillBtn(widget.label,
      kind: widget.kind,
      height: widget.height,
      fontSize: widget.fontSize,
      icon: widget.icon,
      trailingIcon: widget.trailingIcon,
      expand: widget.expand,
      loading: _busy,
      onTap: widget.onTap == null ? null : _go);
}

/// Full-screen "Processing payment" spinner. Back is blocked until [work] ends.
Future<T> withPaymentSpinner<T>(BuildContext context, Future<T> work) async {
  final nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: P.inkA80,
    builder: (_) => PopScope(
      canPop: false,
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.fromLTRB(Sp.xxl, Sp.x3, Sp.xxl, Sp.xxl),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.xl)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Spinner(size: 40),
            const SizedBox(height: Sp.lg),
            const Text('Processing payment…', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800, decoration: TextDecoration.none)),
            const SizedBox(height: Sp.sm),
            Text('Please don\'t press back or close the app.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.base, color: C.muted, height: 1.4, decoration: TextDecoration.none)),
          ]),
        ),
      ),
    ),
  );
  try {
    return await work;
  } finally {
    if (nav.canPop()) nav.pop();
  }
}

/// Whole-page skeleton: real back button and title, grey content below.
class SkPage extends StatelessWidget {
  final String title;
  final Widget child;
  const SkPage({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 24),
        children: [TitleBar(title: title), const SizedBox(height: Sp.lg), child],
      );
}
