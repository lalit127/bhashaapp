# BhashaApp v2.0 — Duolingo-inspired English Learning

## Design System

### Theme: Light + Vibrant (like Duolingo)
- Background: White / #F7F7F7
- Primary: #4CAF50 (Duolingo green)
- Accent: #FF6B2B (Saffron)
- Font: Nunito (rounded, friendly — download from Google Fonts)
- Buttons: "Bottom shadow" press effect (signature Duolingo style)

### Key Design Patterns
- Pill-shaped option buttons with bottom shadow
- XP bar with shine stripe  
- Streak fire dots for weekly calendar
- Hearts in top bar (not sidebar)
- Progress bar in lesson header
- Green/red feedback banners at bottom (not overlays)
- Celebration sheet after lesson complete

## Setup

1. Install fonts (see assets/fonts/README.md)
2. `flutter pub get`
3. `flutter pub run build_runner build`
4. Add Firebase config files
5. Add RevenueCat API keys in revenuecat_service.dart

## New Screens (v2)
- Welcome: Mascot + animated language carousel + bouncing
- Language Select: Card grid with color-coded selection
- Home: Duolingo header (streak/hearts/gems) + mission card
- Lesson: Top bar hearts, progress bar, bottom feedback panel
- Paywall: Gold hero + plan cards with bottom shadow
