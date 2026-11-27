import 'package:flutter/material.dart';

/// True only inside automated QA tests: skips network map tiles and the
/// connectivity check so screens can be captured offline.
bool kQaMode = false;

/// Apple-style continuous ("squircle") corners. [r] is the radius you'd
/// give a normal rounded rectangle; the curve starts earlier and eases in.
ShapeBorder smooth(double r, {BorderSide side = BorderSide.none}) =>
    r <= 0 ? RoundedRectangleBorder(side: side) : ContinuousRectangleBorder(borderRadius: BorderRadius.circular(r * 2.25), side: side);

/// Checkdin brand colours. Every colour is a getter so the whole app can
/// switch between light and dark at runtime (see [ThemeModeX]).
class C {
  static bool dark = false;
  static Color _p(int light, int night) => Color(dark ? night : light);

  static Color get bg => _p(0xFFF5F6F0, 0xFF10120F);
  // Content colours: text, icons, borders.
  static Color get ink => _p(0xFF111111, 0xFFF1F2EC);
  static Color get white => _p(0xFFFFFFFF, 0xFFFFFFFF);
  static Color get lime => _p(0xFFD1F148, 0xFFD1F148);
  // Surface colours: card / button / tile fills.
  static Color get card => _p(0xFFFFFFFF, 0xFF1B1E19);
  static Color get inkBg => _p(0xFF111111, 0xFF30352B);
  static Color get limeBg => _p(0xFFD1F148, 0xFF56661A);
  static Color get limeSoft => _p(0xFFEEF8C8, 0xFF262D12);
  static Color get limeInk => _p(0xFF3F4A1A, 0xFFD1F148);
  static Color get green => _p(0xFF3D6B00, 0xFF9BD14A);
  static Color get muted => _p(0xFF5C5C55, 0xFFA6A79E);
  static Color get muted2 => _p(0xFF6A6A63, 0xFF9A9B92);
  static Color get faint => _p(0xFFB9B9B0, 0xFF6B6D64);
  static Color get line => _p(0xFFEFEFEA, 0xFF262922);
  static Color get border => _p(0xFFE2E2DA, 0xFF363A31);
  static Color get track => _p(0xFFE9E9E2, 0xFF2A2E26);
  static Color get red => _p(0xFFC8281C, 0xFFFF7A6E);
  static Color get redSoft => _p(0xFFFDE8E6, 0xFF3A1D1A);
  static Color get gold => const Color(0xFFF2B705);

  /// A hard-coded light fill (pastel tile, placeholder) toned down in dark mode.
  static Color tint(Color c) => dark ? Color.lerp(c, const Color(0xFF1B1E19), 0.82)! : c;

  /// A hard-coded dark text colour lifted so it stays readable in dark mode.
  static Color tx(Color c) => dark ? Color.lerp(c, const Color(0xFFF1F2EC), 0.7)! : c;
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
  final Color? _bg;
  Color get bg => _bg ?? C.card;
  final bool shadow;
  final String tooltip;
  final double size;
  final Color? _iconColor;
  Color get iconColor => _iconColor ?? C.ink;
  const CircleBtn(
      {super.key,
      required this.icon,
      this.onTap,
      Color? bg,
      this.shadow = true,
      this.tooltip = '',
      this.size = 44,
      Color? iconColor})
      : _bg = bg,
        _iconColor = iconColor;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
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
    );
    // Small buttons still get a 48 x 48 touch area.
    return Semantics(
      button: true,
      label: tooltip,
      child: size >= 48
          ? btn
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: SizedBox(width: 48, height: 48, child: Center(child: btn)),
            ),
    );
  }
}

class BackBtn extends StatelessWidget {
  final Color? _bg;
  Color get bg => _bg ?? C.card;
  final bool shadow;
  final VoidCallback? onTap;
  const BackBtn({super.key, Color? bg, this.shadow = true, this.onTap}) : _bg = bg;
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
      decoration: BoxDecoration(
        color: C.card,
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
        Container(width: 4, height: 14, decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text.toUpperCase(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: C.muted)),
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
  final Color? _color;
  Color get color => _color ?? C.card;
  final VoidCallback? onTap;
  final Border? border;
  const WhiteCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 22, Color? color, this.onTap, this.border})
      : _color = color;
  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: ShapeDecoration(color: color, shape: smooth(radius, side: border?.top ?? BorderSide.none)),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(customBorder: smooth(radius), onTap: onTap, child: box),
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
  /// Shows a spinner in place of the label and ignores taps.
  final bool loading;
  const PillBtn(this.label,
      {super.key,
      this.onTap,
      this.kind = BtnKind.lime,
      this.height = 52,
      this.icon,
      this.trailingIcon = true,
      this.fontSize = 15.5,
      this.expand = false,
      this.loading = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null || loading;
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
        onTap: loading ? null : onTap,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: border),
          child: Stack(alignment: Alignment.center, children: [
            Opacity(
              opacity: loading ? 0 : 1,
              child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: children),
            ),
            if (loading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(fg)),
              ),
          ]),
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
      decoration: BoxDecoration(
        color: C.card,
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
            decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(size * 0.3)),
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
  final Color? _bg;
  Color get bg => _bg ?? C.bg;
  final Color? _fg;
  Color get fg => _fg ?? C.ink;
  final double size;
  final double radius;
  const IconTile(this.icon, {super.key, Color? bg, Color? fg, this.size = 40, this.radius = 12})
      : _bg = bg,
        _fg = fg;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: ShapeDecoration(color: bg, shape: smooth(radius)),
        child: Icon(icon, size: size * 0.48, color: fg),
      );
}

/// iOS-like switch in brand colours.
class BrandSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? _onColor;
  Color get onColor => _onColor ?? C.inkBg;
  const BrandSwitch({super.key, required this.value, required this.onChanged, Color? onColor}) : _onColor = onColor;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: value ? onColor : C.tint(Color(0xFFCFCFC7)), borderRadius: BorderRadius.circular(999)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: value && onColor == C.inkBg ? C.lime : C.white, shape: BoxShape.circle),
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
  final Color? _track;
  Color get track => _track ?? C.track;
  final double height;
  const SegmentPill({super.key, required this.options, required this.selected, required this.onChanged, Color? track, this.height = 42}) : _track = track;
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
                  color: on ? C.card : Colors.transparent,
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
      decoration: ShapeDecoration(color: C.tint(const Color(0xFFE2E3DA)), shape: smooth(radius)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.image_outlined, size: 32, color: Color(0xFF7C7C74)),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.muted2)),
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
      decoration: BoxDecoration(color: dark ? C.inkBg : C.card, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.star_rounded, size: 14, color: C.gold),
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
  final Color? _bg;
  Color get bg => _bg ?? C.limeSoft;
  final Color? _fg;
  Color get fg => _fg ?? C.tx(const Color(0xFF3D5200));
  const Tag(this.text, {super.key, Color? bg, Color? fg})
      : _bg = bg,
        _fg = fg;
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
  final Color? _chip;
  Color get chip => _chip ?? C.limeBg;
  const StayTimeline(
      {super.key, required this.inTime, required this.outTime, required this.inDate, required this.outDate, required this.slot, Color? chip})
      : _chip = chip;
  @override
  Widget build(BuildContext context) {
    Widget col(String label, String time, String date, CrossAxisAlignment a) => Column(crossAxisAlignment: a, children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: C.muted)),
          const SizedBox(height: 3),
          Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(date, style: TextStyle(fontSize: 12, color: C.muted)),
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
    final b = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.border, width: 1.5));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.muted)),
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
          fillColor: C.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          border: b,
          enabledBorder: b,
          disabledBorder: b,
          focusedBorder: b.copyWith(borderSide: BorderSide(color: C.ink, width: 1.5)),
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
          decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, size: 15, color: C.ink),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: C.inkBg,
      behavior: SnackBarBehavior.floating,
      shape: smooth(16),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    ));
}

/// Toast with an Undo button, for quick reversible actions.
void undoToast(BuildContext context, String msg, VoidCallback onUndo) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: C.inkBg,
      behavior: SnackBarBehavior.floating,
      shape: smooth(16),
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      action: SnackBarAction(label: 'UNDO', textColor: C.lime, onPressed: onUndo),
    ));
}

/// Makes a small text link easy to hit (at least 48 px tall) without
/// changing how it looks.
class TapLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final TextStyle? style;
  const TapLink(this.text, {super.key, required this.onTap, this.style});
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Text(text,
                  style: style ?? const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
            ),
          ),
        ),
      );
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
          color: C.card,
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
                  decoration: BoxDecoration(color: on ? C.inkBg : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 22, color: on ? C.lime : C.ink),
                    if (on) ...[
                      const SizedBox(width: 8),
                      Text(t[0], style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: C.lime)),
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


/// "By continuing, I accept the Terms & Privacy Policy" with both links tappable.
class LegalLine extends StatelessWidget {
  final String lead;
  final String terms;
  final bool underline;
  const LegalLine({super.key, this.lead = 'By continuing, I accept the ', this.terms = 'Terms & Conditions', this.underline = false});
  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: 12.5, color: C.muted, height: 1.5);
    final link = TextStyle(
        fontSize: 12.5,
        height: 1.5,
        color: C.ink,
        fontWeight: FontWeight.w700,
        decoration: underline ? TextDecoration.underline : TextDecoration.none);
    Widget l(String t, String arg) => GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/legal', arguments: arg),
          child: Text(t, style: link),
        );
    return Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text(lead, style: base),
      l(terms, 'terms'),
      Text(' & ', style: base),
      l('Privacy Policy', 'privacy'),
    ]);
  }
}
