# ParkTag architecture convention

MVC + GetX, feature-based modules. This doc exists because the project is
still small — it records the convention so future features land in the
right place without re-deriving it each time.

## Layout

```
lib/
  main.dart              entry point only: init Firebase, runApp(MyApp)
  firebase_options.dart  generated, do not edit by hand

  app/
    app.dart              MyApp: GetMaterialApp + theme + routes
    routes/
      app_routes.dart     route name constants
      app_pages.dart      GetPage list (view + binding per route)
    theme/
      app_colors.dart     shared brand tokens (used across modules)
      app_theme.dart      ThemeData

  modules/
    <feature>/
      controllers/
      views/
      bindings/
      models/             only if the model is truly feature-private
      widgets/            only if the widget is truly feature-private

  models/                 cross-feature models only (e.g. shared User)
  core/                   cross-feature services/utils, created when a
                           second feature needs the same logic — not before
  widgets/                globally reusable widgets, created when a widget
                           is actually reused by 2+ modules — not before
```

## Rules

- A feature's controller, view, and binding live together under
  `modules/<feature>/`. A trivial feature can be flat
  (`modules/<feature>/<feature>_view.dart`); once it grows, split into
  `controllers/`, `views/`, `bindings/` subfolders.
- **Every screen gets a `Binding`.** Views are `GetView<Controller>`, never
  `Get.put`/`Get.find` inline in a widget constructor or build method.
  If a controller must run logic (timers, listeners) regardless of whether
  the view reads its state, `Get.put` it eagerly in the binding — a lazy
  controller that's never read via `controller.x` in `build()` is never
  instantiated, so timers/onReady logic silently never run. (This bit us
  once already — see `SplashBinding`.)
- Navigate by route name (`Get.toNamed`, `Get.offAllNamed`) against
  `AppRoutes`, not by constructing the destination widget directly.
- `core/` and top-level `widgets/` and `models/` are for things used by
  **two or more** features. Don't pre-create them empty — add a file there
  the moment a second module needs what a first module already built.
- Don't introduce UseCases/Entities/DTOs/Repository interfaces unless an
  existing implementation genuinely needs the seam (e.g. swapping a real
  backend for a fake in tests). Firebase calls belong in a feature service
  or directly in the controller for something this size — promote to
  `core/services/` only once 2+ features need the same Firebase logic.
