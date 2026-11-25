import 'package:flutter/material.dart';

/// Checkdin brand colours.
class C {
  static const bg = Color(0xFFF5F6F0);
  static const ink = Color(0xFF111111);
  static const lime = Color(0xFFD1F148);
  static const limeSoft = Color(0xFFEEF8C8);
  static const limeInk = Color(0xFF3F4A1A);
  static const green = Color(0xFF3D6B00);
  static const muted = Color(0xFF5C5C55);
  static const muted2 = Color(0xFF6A6A63);
  static const faint = Color(0xFFB9B9B0);
  static const line = Color(0xFFEFEFEA);
  static const border = Color(0xFFE2E2DA);
  static const track = Color(0xFFE9E9E2);
  static const red = Color(0xFFC8281C);
  static const redSoft = Color(0xFFFDE8E6);
  static const gold = Color(0xFFF2B705);
  static const white = Colors.white;
}

const kShadow = [BoxShadow(color: Color(0x14111111), blurRadius: 14, offset: Offset(0, 4))];
const kSheetShadow = [BoxShadow(color: Color(0x14111111), blurRadius: 30, offset: Offset(0, -8))];

String inr(num v) {
  final s = v.round().toString();
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${parts.join(',')},$last3';
}

String hourLabel(int h24, {bool short = false}) {
  final h = h24 % 24;
  final ap = h < 12 ? 'AM' : 'PM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return short ? '$h12 $ap' : '$h12:00 $ap';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const monthsLong = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
String dateLabel(DateTime d) => '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

/// Round white button with an icon (back, close, help...).
class CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color bg;
  final bool shadow;
  final String tooltip;
  final double size;
  final Color iconColor;
  const CircleBtn(
      {super.key,
      required this.icon,
      this.onTap,
      this.bg = C.white,
      this.shadow = true,
      this.tooltip = '',
      this.size = 44,
      this.iconColor = C.ink});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle, boxShadow: shadow ? kShadow : null),
            child: Icon(icon, size: size * 0.48, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class BackBtn extends StatelessWidget {
  final Color bg;
  final bool shadow;
  final VoidCallback? onTap;
  const BackBtn({super.key, this.bg = C.white, this.shadow = true, this.onTap});
  @override
  Widget build(BuildContext context) => CircleBtn(
        icon: Icons.arrow_back_rounded,
        bg: bg,
        shadow: shadow,
        tooltip: 'Back',
        onTap: onTap ?? () => Navigator.maybePop(context),
      );
}

/// Centered title bar: back · title · optional trailing.
class TitleBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  const TitleBar({super.key, required this.title, this.trailing, this.onBack});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      BackBtn(onTap: onBack),
      Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
      trailing ?? const SizedBox(width: 44),
    ]);
  }
}

/// White header with rounded bottom used on flow pages.
class SheetHeader extends StatelessWidget {
  final Widget child;
  const SheetHeader({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 16),
      decoration: const BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x0F111111), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(children: [
        Container(width: 4, height: 14, decoration: BoxDecoration(color: C.lime, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: C.muted)),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final VoidCallback? onTap;
  final Border? border;
  const WhiteCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 22, this.color = C.white, this.onTap, this.border});
  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius), border: border),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: box),
    );
  }
}

enum BtnKind { lime, dark, outline, soft }

class PillBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final BtnKind kind;
  final double height;
  final IconData? icon;
  final bool trailingIcon;
  final double fontSize;
  final bool expand;
  const PillBtn(this.label,
      {super.key,
      this.onTap,
      this.kind = BtnKind.lime,
      this.height = 52,
      this.icon,
      this.trailingIcon = true,
      this.fontSize = 15.5,
      this.expand = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    Color bg, fg;
    Border? border;
    switch (kind) {
      case BtnKind.lime:
        bg = C.lime;
        fg = C.ink;
        break;
      case BtnKind.dark:
        bg = C.ink;
        fg = C.lime;
        break;
      case BtnKind.outline:
        bg = C.white;
        fg = C.ink;
        border = Border.all(color: const Color(0xFFDADAD2), width: 1.5);
        break;
      case BtnKind.soft:
        bg = C.bg;
        fg = C.ink;
        break;
    }
    if (!enabled) {
      bg = const Color(0xFFEFEFEA);
      fg = C.muted2;
      border = null;
    }
    final children = <Widget>[];
    final ic = icon == null ? null : Icon(icon, size: 18, color: fg);
    if (ic != null && !trailingIcon) children.addAll([ic, const SizedBox(width: 8)]);
    children.add(Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: fg)));
    if (ic != null && trailingIcon) children.addAll([const SizedBox(width: 8), ic]);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: border),
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: children),
        ),
      ),
    );
  }
}

/// Sticky white bar at the bottom of a page.
class BottomBar extends StatelessWidget {
  final Widget child;
  const BottomBar({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: kSheetShadow,
      ),
      child: child,
    );
  }
}

/// Text with a lime highlight block on part of it.
class Highlight extends StatelessWidget {
  final String before;
  final String marked;
  final String after;
  final double size;
  final TextAlign align;
  final double spacing;
  final double height;
  const Highlight(
      {super.key, this.before = '', required this.marked, this.after = '', this.size = 30, this.align = TextAlign.start, this.spacing = -1, this.height = 1.12});
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: size, fontWeight: FontWeight.w800, letterSpacing: spacing, height: height, color: C.ink);
    return Text.rich(
      TextSpan(style: style, children: [
        TextSpan(text: before),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: size * 0.25),
            decoration: BoxDecoration(color: C.lime, borderRadius: BorderRadius.circular(size * 0.3)),
            child: Text(marked, style: style),
          ),
        ),
        TextSpan(text: after),
      ]),
      textAlign: align,
    );
  }
}

/// Small rounded tile holding an icon.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  final double radius;
  const IconTile(this.icon, {super.key, this.bg = C.bg, this.fg = C.ink, this.size = 40, this.radius = 12});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
        child: Icon(icon, size: size * 0.48, color: fg),
      );
}

/// iOS-like switch in brand colours.
class BrandSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color onColor;
  const BrandSwitch({super.key, required this.value, required this.onChanged, this.onColor = C.ink});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: value ? onColor : const Color(0xFFCFCFC7), borderRadius: BorderRadius.circular(999)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: value && onColor == C.ink ? C.lime : C.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

/// Two-option pill switch (white pill on grey track).
class SegmentPill extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  final Color track;
  final double height;
  const SegmentPill({super.key, required this.options, required this.selected, required this.onChanged, this.track = C.track, this.height = 42});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: List.generate(options.length, (i) {
          final on = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? C.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: on ? const [BoxShadow(color: Color(0x1A111111), blurRadius: 8, offset: Offset(0, 2))] : null,
                ),
                child: Text(options[i],
                    style: TextStyle(fontSize: 14, fontWeight: on ? FontWeight.w800 : FontWeight.w700, color: on ? C.ink : C.muted2)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Grey placeholder until real hotel photos exist.
class PhotoPlaceholder extends StatelessWidget {
  final double height;
  final double radius;
  final String label;
  const PhotoPlaceholder({super.key, this.height = 180, this.radius = 0, this.label = 'Hotel photo'});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFE2E3DA), borderRadius: BorderRadius.circular(radius)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.image_outlined, size: 32, color: Color(0xFF7C7C74)),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.muted2)),
        ],
      ]),
    );
  }
}

class RatingBadge extends StatelessWidget {
  final String rating;
  final int? reviews;
  final bool dark;
  const RatingBadge(this.rating, {super.key, this.reviews, this.dark = true});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: dark ? C.ink : C.white, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, size: 14, color: C.gold),
        const SizedBox(width: 3),
        Text(rating, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: dark ? C.white : C.ink)),
        if (reviews != null)
          Text(' ($reviews)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: dark ? C.faint : C.muted2)),
      ]),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const Tag(this.text, {super.key, this.bg = C.limeSoft, this.fg = const Color(0xFF3D5200)});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
      );
}

/// Check-in ── slot ── check-out row.
class StayTimeline extends StatelessWidget {
  final String inTime, outTime, inDate, outDate, slot;
  final Color chip;
  const StayTimeline(
      {super.key, required this.inTime, required this.outTime, required this.inDate, required this.outDate, required this.slot, this.chip = C.lime});
  @override
  Widget build(BuildContext context) {
    Widget col(String label, String time, String date, CrossAxisAlignment a) => Column(crossAxisAlignment: a, children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: C.muted)),
          const SizedBox(height: 3),
          Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(date, style: const TextStyle(fontSize: 12, color: C.muted)),
        ]);
    return Row(children: [
      Expanded(child: col('CHECK-IN', inTime, inDate, CrossAxisAlignment.start)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: chip, borderRadius: BorderRadius.circular(999)),
        child: Text(slot, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      ),
      Expanded(child: col('CHECK-OUT', outTime, outDate, CrossAxisAlignment.end)),
    ]);
  }
}

/// Bordered text field used across forms.
class BrandField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;
  const BrandField(
      {super.key, required this.label, this.hint, this.controller, this.keyboard, this.onChanged, this.errorText, this.enabled = true});
  @override
  Widget build(BuildContext context) {
    final b = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border, width: 1.5));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.muted)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboard,
        onChanged: onChanged,
        enabled: enabled,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF8A8A82), fontWeight: FontWeight.w400),
          errorText: errorText,
          isDense: true,
          filled: true,
          fillColor: C.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          border: b,
          enabledBorder: b,
          disabledBorder: b,
          focusedBorder: b.copyWith(borderSide: const BorderSide(color: C.ink, width: 1.5)),
        ),
      ),
    ]);
  }
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 15, color: C.ink),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: C.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    ));
}


/// Go back to [name] if it is in the stack, otherwise open it on top of Home.
void popTo(BuildContext context, String name) {
  var found = false;
  Navigator.popUntil(context, (r) {
    if (r.settings.name == name) found = true;
    return found || r.isFirst;
  });
  if (!found) Navigator.pushNamed(context, name);
}

void goHome(BuildContext context) => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);

/// Floating bottom navigation used on Home, Saved and Offers.
class BottomNav extends StatelessWidget {
  final String current;
  const BottomNav({super.key, required this.current});

  static const _tabs = [
    ['Home', '/home'],
    ['Saved', '/saved'],
    ['Bookings', '/bookings'],
    ['Offers', '/offers'],
    ['Account', '/account'],
  ];
  static const _icons = {
    'Home': Icons.home_rounded,
    'Saved': Icons.favorite_border_rounded,
    'Bookings': Icons.calendar_month_outlined,
    'Offers': Icons.confirmation_number_outlined,
    'Account': Icons.person_outline_rounded,
  };

  void _go(BuildContext context, String label, String route) {
    if (label == current) return;
    if (route == '/bookings' || route == '/account') {
      Navigator.pushNamed(context, route);
    } else if (route == '/home') {
      goHome(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, route, ModalRoute.withName('/home'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: C.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: Color(0x24111111), blurRadius: 34, offset: Offset(0, 12))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _tabs.map((t) {
            final on = t[0] == current;
            final icon = _icons[t[0]]!;
            return Semantics(
              button: true,
              selected: on,
              label: t[0],
              child: GestureDetector(
                onTap: () => _go(context, t[0], t[1]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: on ? 18 : 13),
                  decoration: BoxDecoration(color: on ? C.ink : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 22, color: on ? C.lime : C.ink),
                    if (on) ...[
                      const SizedBox(width: 8),
                      Text(t[0], style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: C.lime)),
                    ],
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
