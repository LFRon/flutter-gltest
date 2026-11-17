import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const GlTestApp());
}

class GlTestApp extends StatelessWidget {
  const GlTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter GL Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const GlTestPage(),
    );
  }
}

class GlTestPage extends StatefulWidget {
  const GlTestPage({super.key});

  @override
  State<GlTestPage> createState() => _GlTestPageState();
}

class _GlTestPageState extends State<GlTestPage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> _frames = ValueNotifier<int>(0);
  final List<double> _frameIntervalsMs = <double>[];
  final Stopwatch _reportWatch = Stopwatch()..start();

  Duration? _lastElapsed;
  int _framesThisSecond = 0;
  int _lastReportedFps = 0;
  double _lastBuildMs = 0;
  double _lastRasterMs = 0;
  double _lastP50Ms = 0;
  double _lastP99Ms = 0;
  double _displayRefreshRate = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final Duration? previous = _lastElapsed;
    _lastElapsed = elapsed;

    if (previous != null) {
      final double intervalMs =
          (elapsed - previous).inMicroseconds / 1000.0;
      if (intervalMs > 0 && intervalMs < 100) {
        _frameIntervalsMs.add(intervalMs);
        if (_frameIntervalsMs.length > 600) {
          _frameIntervalsMs.removeAt(0);
        }
      }
    }

    _framesThisSecond++;
    _frames.value++;

    if (_reportWatch.elapsedMilliseconds >= 1000 && mounted) {
      _lastReportedFps = _framesThisSecond;
      _framesThisSecond = 0;
      _reportWatch.reset();
      _report();
    }
  }

  void _onTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) {
      return;
    }
    double buildMs = 0;
    double rasterMs = 0;
    for (final FrameTiming timing in timings) {
      buildMs = math.max(
        buildMs,
        timing.buildDuration.inMicroseconds / 1000.0,
      );
      rasterMs = math.max(
        rasterMs,
        timing.rasterDuration.inMicroseconds / 1000.0,
      );
    }
    _lastBuildMs = buildMs;
    _lastRasterMs = rasterMs;
  }

  void _report() {
    final List<double> sorted = List<double>.of(_frameIntervalsMs)..sort();
    double percentile(double p) {
      if (sorted.isEmpty) {
        return 0;
      }
      final int index = ((sorted.length - 1) * p).round();
      return sorted[index];
    }

    final view = View.maybeOf(context);
    _displayRefreshRate = view?.display.refreshRate ?? 0;
    _lastP50Ms = percentile(0.50);
    _lastP99Ms = percentile(0.99);

    debugPrint(
      'HIGH_REFRESH fps=$_lastReportedFps '
      'displayHz=${_displayRefreshRate.toStringAsFixed(2)} '
      'interval_ms p50=${_lastP50Ms.toStringAsFixed(2)} '
      'p99=${_lastP99Ms.toStringAsFixed(2)} '
      'build_ms=${_lastBuildMs.toStringAsFixed(2)} '
      'raster_ms=${_lastRasterMs.toStringAsFixed(2)}',
    );
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ValueListenableBuilder<int>(
              valueListenable: _frames,
              builder: (BuildContext context, int frames, Widget? child) {
                return Transform.rotate(
                  angle: frames * 0.04,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[Colors.blue, Colors.pink],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<int>(
              valueListenable: _frames,
              builder: (BuildContext context, int frames, Widget? child) {
                final String displayHz = _displayRefreshRate > 0
                    ? _displayRefreshRate.toStringAsFixed(2)
                    : '--';
                return Text(
                  'frames: $frames\n'
                  'fps: $_lastReportedFps\n'
                  'display: $displayHz Hz\n'
                  'interval p50: ${_lastP50Ms.toStringAsFixed(2)} ms\n'
                  'interval p99: ${_lastP99Ms.toStringAsFixed(2)} ms\n'
                  'build: ${_lastBuildMs.toStringAsFixed(2)} ms\n'
                  'raster: ${_lastRasterMs.toStringAsFixed(2)} ms',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
