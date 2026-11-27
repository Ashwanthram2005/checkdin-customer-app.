import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// Wrap a field (or a group of fields) and call `key.currentState?.shake()` when
/// the input is wrong: a short, damped side-to-side shake plus one haptic buzz.
/// Phones set to "reduce motion" get only the buzz.
class Shake extends StatefulWidget {
  final Widget child;
  const Shake({super.key, required this.child});
  @override
  State<Shake> createState() => ShakeState();
}

class ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  void shake() {
    HapticFeedback.mediumImpact();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final t = _c.value;
          final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      );
}

/// Shake every key given (null keys are skipped).
void shakeAll(Iterable<GlobalKey<ShakeState>?> keys) {
  var buzzed = false;
  for (final k in keys) {
    final s = k?.currentState;
    if (s == null) continue;
    if (!buzzed) {
      s.shake();
      buzzed = true;
    } else {
      s._c.forward(from: 0);
    }
  }
}

/// Red message under a field that fades and slides in.
class FieldError extends StatelessWidget {
  final String? message;
  final EdgeInsets padding;
  const FieldError(this.message, {super.key, this.padding = const EdgeInsets.fromLTRB(4, 8, 4, 0)});
  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topLeft,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(position: Tween(begin: const Offset(0, -0.3), end: Offset.zero).animate(a), child: c),
          ),
          child: message == null
              ? const SizedBox(width: double.infinity, key: ValueKey('none'))
              : Padding(
                  key: ValueKey(message),
                  padding: padding,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.error_outline_rounded, size: 15, color: C.red),
                    const SizedBox(width: 6),
                    Expanded(child: Text(message!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.red, height: 1.35))),
                  ]),
                ),
        ),
      );
}
