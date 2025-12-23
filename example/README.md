# flutter_markdown_example

Demonstrates how to use the flutter_markdown_plus package.

## Running the Example

```bash
cd example
flutter run
```

## Optional Demos

Some demos depend on optional packages (like `flutter_markdown_plus_latex`) that are not included by default. These are managed through a configuration system to allow validation and publishing without requiring these dependencies.

### Configuration

Optional demos are configured in `optional_demos.yaml`:

```yaml
demos:
  latex:
    enabled: false  # Set to true to enable
    package: flutter_markdown_plus_latex
    version: ^1.0.4
    # path: ../../flutter_markdown_plus_latex  # Uncomment for local development
    import: "package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart"
    demo_file: lib/demos/markdown_latex_plugin_demo.dart
    demo_class: MarkdownLatexPluginDemo
```

### Enabling Optional Demos

1. Edit `optional_demos.yaml` and set `enabled: true` for the demos you want
2. Run the configure script:
   ```bash
   cd example
   dart run tool/configure_demos.dart
   ```
3. Get dependencies:
   ```bash
   flutter pub get
   ```
4. Run the example app:
   ```bash
   flutter run
   ```

### Disabling for Validation/Publishing

Before running `./validate.sh` or publishing the package:

1. Set `enabled: false` for all optional demos in `optional_demos.yaml`
2. Run the configure script:
   ```bash
   cd example
   dart run tool/configure_demos.dart
   ```
3. Run validation:
   ```bash
   cd ..
   ./validate.sh
   ```

### Adding a New Optional Demo

To add a new optional demo:

1. Create the demo file in `lib/demos/` (e.g., `my_plugin_demo.dart`)
2. Add an entry to `optional_demos.yaml`:
   ```yaml
   demos:
     my_plugin:
       enabled: false
       package: flutter_markdown_plus_my_plugin
       version: ^1.0.0
       import: "package:flutter_markdown_plus_my_plugin/flutter_markdown_plus_my_plugin.dart"
       demo_file: lib/demos/my_plugin_demo.dart
       demo_class: MyPluginDemo
   ```
3. Run the configure script to update the generated files

### How It Works

The configure script (`tool/configure_demos.dart`) automatically:

- Updates `pubspec.yaml` with enabled/disabled dependencies (between marker comments)
- Generates `lib/demos/optional_demos.g.dart` with imports and the demo list
- Updates `analysis_options.yaml` to exclude disabled demo files from analysis

The generated `optional_demos.g.dart` file exports a list called `optionalDemos` which is spread into the demo list in `home_screen.dart`.
