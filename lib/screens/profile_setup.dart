import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _wa = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = _name.text.trim().length > 1;
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Spacer(),
              Image.asset('assets/logo.png', height: 32),
            ]),
            const SizedBox(height: 18),
            const Text('Last thing, promise.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.muted)),
            const SizedBox(height: 8),
            const Highlight(before: 'Nice to\nmeet ', marked: 'you.', size: 50, spacing: -2, height: 1.05),
          ]),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: C.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(children: [
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(24, 26, 24, 12), children: [
                  BrandField(label: 'Your name *', hint: 'What should we call you?', controller: _name, onChanged: (_) => setState(() {})),
                  const SizedBox(height: 18),
                  BrandField(label: 'Email (optional)', hint: 'For booking receipts', controller: _email, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => setState(() => _wa = !_wa),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _wa ? C.bg : C.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _wa ? C.ink : const Color(0xFFDADAD2), width: 1.5),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _wa ? C.ink : C.white,
                            borderRadius: BorderRadius.circular(6),
                            border: _wa ? null : Border.all(color: const Color(0xFF8A8A82), width: 2),
                          ),
                          child: _wa ? const Icon(Icons.check_rounded, size: 16, color: C.lime) : null,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Booking updates & deals on WhatsApp', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            SizedBox(height: 3),
                            Text('OTPs, confirmations, check-in details & offers.', style: TextStyle(fontSize: 13, color: C.muted)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 18 + MediaQuery.of(context).padding.bottom),
                child: Column(children: [
                  const LegalLine(lead: 'By continuing, I agree to the ', terms: 'T&Cs', underline: true),
                  const SizedBox(height: 12),
                  PillBtn('Start exploring stays',
                      kind: BtnKind.dark,
                      height: 56,
                      expand: true,
                      icon: Icons.arrow_forward_rounded,
                      onTap: ok
                          ? () {
                              app.set(() {
                                app.name = _name.text.trim();
                                app.email = _email.text.trim();
                                app.whatsappUpdates = _wa;
                              });
                              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
                            }
                          : null),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
