# Checkdin – customer app (Flutter)

Hourly hotel stays in Chennai. This is the first version of the customer app, built from the Checkdin design canvas.

## Screens

| Flow | Screens |
|---|---|
| Onboarding | Login · OTP (WhatsApp) · Your details |
| Search & booking | Search · Pick location · Check-in date · Check-in time · Results · Hotel listing · Reserve · Payment · Booking confirmed |
| Account | Account · Edit profile · My bookings · Booking details · Payment methods · Help |

## Get the APK

Every push to `main` runs **Actions → Build Android APK**. When it finishes (about 6–8 minutes):

1. Open the repo's **Releases** page.
2. Download `checkdin.apk` from the newest "Checkdin build".
3. On your Android phone, open the file and allow "Install unknown apps" when asked.

You can also start a build by hand: **Actions → Build Android APK → Run workflow**.

## Run on your laptop

```bash
flutter create --platforms=android --project-name checkdin .   # first time only
flutter pub get
flutter run
```

## What is still sample data

Everything in `lib/state.dart` is placeholder data: hotels, prices, ratings, booking ID, coupon `FIRST40`, cancellation rules. Real data, WhatsApp OTP (e.g. Gupshup / MSG91) and payments (e.g. Razorpay) still need a backend.

## Project layout

```
lib/
  main.dart          routes
  theme.dart         colours, buttons, cards, shared widgets
  state.dart         app state + sample data
  screens/           one file per screen
assets/logo.png      Checkdin logo
```
