import 'package:flutter/material.dart';

import 'api/api.dart';
import 'state.dart';
import 'theme.dart';

/// Optimistic update: change the screen now, tell the server in the
/// background, and quietly put things back if the server says no.
/// Never use this for payments, bookings or cancellations.
Future<void> optimistic(BuildContext context,
    {required VoidCallback apply, required VoidCallback revert, required Future<void> Function() call, String? failMessage}) async {
  apply();
  try {
    await call();
  } on ApiError catch (e) {
    revert();
    if (context.mounted) toast(context, failMessage ?? e.message);
  }
}

/// Heart on a hotel. Removing shows an Undo toast.
Future<void> toggleSaved(BuildContext context, Hotel h) async {
  final was = app.saved.contains(h.id);
  void set(bool on) => app.set(() => on ? app.saved.add(h.id) : app.saved.remove(h.id));
  await optimistic(
    context,
    apply: () => set(!was),
    revert: () => set(was),
    call: () => api.setSaved(h.id, !was),
    failMessage: was ? 'Couldn\'t remove ${h.name}. Try again.' : 'Couldn\'t save ${h.name}. Try again.',
  );
  if (was && !app.saved.contains(h.id) && context.mounted) {
    undoToast(context, 'Removed ${h.name} from Saved', () => toggleSaved(context, h));
  }
}
