# Flutter GL Test

A small Flutter Linux desktop app for exercising the GTK embedder's frame
scheduling and graphics pipeline. It runs a continuous `Ticker`, animates a
rotating gradient square, and reports the display refresh rate, measured frame
interval, FPS, and engine build/raster times.

This project was used to validate the Linux display-refresh-rate vsync work:

- Engine PR branch: `fix/linux-full-refreshing-rate`
- Repository: <https://github.com/LFRon/flutter-enhanced>

## What it measures

- `displayHz`: the `FlutterView.display.refreshRate` reported by the embedder
- `fps`: ticker callbacks counted in the last one-second window
- `interval_ms p50/p99`: percentiles of ticker-to-ticker frame intervals
- `build_ms`: maximum UI build duration from `SchedulerBinding` frame timings
- `raster_ms`: maximum raster duration from `SchedulerBinding` frame timings

Once per second the app prints a line like:

```text
HIGH_REFRESH fps=166 displayHz=165.00 interval_ms p50=6.06 p99=6.26 build_ms=0.31 raster_ms=0.95
```

## Requirements

- Flutter 3.50 or newer
- Linux desktop support (`flutter config --enable-linux-desktop`)
- A GTK 3 development environment

## Build and run

```bash
flutter pub get
flutter build linux --profile
GDK_BACKEND=wayland build/linux/x64/profile/bundle/flutter_gltest
```

The default Flutter engine only schedules frames at 60 Hz. To test high refresh
rates, build the Linux embedder from the `fix/linux-full-refreshing-rate`
branch and replace the bundled engine library:

```bash
cp /path/to/flutter-engine/src/out/host_profile/libflutter_linux_gtk.so \
   build/linux/x64/profile/bundle/lib/libflutter_linux_gtk.so

GDK_BACKEND=wayland build/linux/x64/profile/bundle/flutter_gltest
```

X11 and XWayland work as well:

```bash
GDK_BACKEND=x11 build/linux/x64/profile/bundle/flutter_gltest
```

## Resize stress test

Set `FLUTTER_GLTEST_RESIZE=1` to resize the window once per second. This
exercises the Wayland subsurface resize path while the app keeps animating.

```bash
FLUTTER_GLTEST_RESIZE=1 GDK_BACKEND=wayland \
  build/linux/x64/profile/bundle/flutter_gltest
```

## Tests

```bash
flutter test
flutter analyze
```

## Results from the development machine

Panel: 1920x1080 @ 165.00 Hz (BOE eDP-2), Wayland session.

| Mode | p50 interval | Measured FPS |
|---|---:|---:|
| Stock engine | 16.78 ms | 60 |
| Patched engine, 165 Hz display | 6.06 ms | 166 |
| Patched engine, 120 Hz override | 8.33 ms | 121 |
| Patched engine, 144 Hz override | 6.94 ms | 145 |
| Patched engine, 60 Hz override | 16.66 ms | 60 |
| Patched engine, 240 Hz override | 4.17 ms | 240 |
| Patched engine, X11/XWayland | 6.07 ms | 165 |
| Patched engine + resize stress | 6.06 ms | 166 |

The 120/144/240 Hz overrides were measured with the full development fork,
which has a test-only refresh-rate override. The clean upstream engine follows
the monitor's current mode instead.

## License

This project is distributed under the terms of the GPL-2.0 license in
`LICENSE`.
