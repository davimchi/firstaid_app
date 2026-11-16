# First Aid App (Offline-First)

A Flutter-based, offline-first emergency response application designed for low-connectivity environments.

## Features
- **100% Offline Capable:** All first-aid protocols and emergency contacts are stored locally using SQLite.
- **Bilingual:** Full support for English and Kiswahili.
- **Hands-Free Audio:** Text-to-Speech reads instructions aloud for users with occupied hands.
- **GPS Hospital Locator:** Calculates distance to nearby hospitals offline using the Haversine formula.
- **Sync Engine:** Background version checks to download new protocols when internet is available.

## Tech Stack
- Flutter & Dart
- SQLite (sqflite)
- Geolocator
- Flutter TTS

## Backend
This app connects to a Laravel 13 API. [Link to backend repo](https://github.com/YOUR_USERNAME/firstaid-api)
