# App Icon & Splash Screen Assets

Place the following image files in this directory (`assets/images/`):

## Required Files

### `app_icon.png`
- **Size:** 1024x1024 pixels
- **Format:** PNG with transparency
- **Content:** F1 Tipp Mix logo on a dark background (`#0D0D0F`)
- **Used for:** Main app icon on Android

### `app_icon_foreground.png`
- **Size:** 1024x1024 pixels
- **Format:** PNG with transparency
- **Content:** F1 Tipp Mix logo only (no background) — the adaptive icon background color `#0D0D0F` is applied automatically
- **Used for:** Android adaptive icon foreground layer
- **Note:** Keep the logo within the inner 66% safe zone (centered in a ~672x672 area) to avoid clipping on different device shapes

### `splash_logo.png`
- **Size:** 512x512 pixels
- **Format:** PNG with transparency
- **Content:** F1 Tipp Mix logo for the splash/loading screen
- **Used for:** Native splash screen on Android (including Android 12+)

## Generating Icons & Splash

After placing the image files, run from the `mobile/` directory:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Or use the `build_apk.ps1` script from the project root which handles this automatically.
