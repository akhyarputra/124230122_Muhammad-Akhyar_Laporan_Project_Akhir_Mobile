MVC layout introduced (minimal change, non-destructive)

What I added

- `lib/controllers/auth_controller.dart` — a ChangeNotifier controller that wraps `AuthService`.
- `pubspec.yaml` — added `provider: ^6.0.5` dependency for simple DI/state provider.
- `lib/main.dart` — wired `AuthController` into the widget tree via `MultiProvider`.

Notes and how this maps to your current code

- Models: keep existing models (e.g. `lib/features/info/models/plant_model.dart`). You can move cross-feature models to `lib/models/` later if needed.
- Views: your existing `lib/features/**/screens/*.dart` files remain the View layer.
- Controllers: new folder `lib/controllers/` contains controllers that mediate between Views and Services. Start by creating controllers for features where you have business logic (auth, profile, cart, home, info).
- Services: keep existing `lib/service/` as the data/access layer (API calls, shared preferences, hive, etc.). Controllers should call Services; Views should read controller state and call controller methods.

How to use AuthController in a View

Example (inside a Widget):

```dart
final auth = context.watch<AuthController>();
if (auth.isLoggedIn) {
  // show user data
  final name = auth.username;
}

// to login:
await context.read<AuthController>().login(username: 'u', password: 'p');

// to logout:
await context.read<AuthController>().logout();
```

Next steps to convert more code

1. Create controllers per feature (e.g., `home_controller.dart`, `profile_controller.dart`, `cart_controller.dart`) that wrap existing services.
2. Move stateful logic out of Screens into Controllers (e.g., form submission, API calls).
3. Replace direct `SharedPreferences`/`Hive` usage in Views with Controller APIs.
4. (Optional) Move models into `lib/models/` and expose them from Controllers.

Testing & build

- Run `flutter pub get` to fetch the new `provider` package.
- Run `flutter clean` and then `flutter run` (or your usual build command).

If anything breaks, paste the first error output here and I will adapt the controller/view wiring further.
