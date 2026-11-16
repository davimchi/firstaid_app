// Default implementation — used on Android, iOS, desktop.
// sqflite picks its factory automatically on these platforms.

Future<void> setupDatabase() async {
  // Nothing to do — sqflite handles native initialization.
}
