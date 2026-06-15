import 'package:flutter/material.dart';
import 'package:hybrid_location/hybrid_location.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HybridLocation.configure(
    const LocationConfig(
      googleApiKey: 'YOUR_GOOGLE_API_KEY',
      providerOrder: [
        LocationSource.wifi,
        LocationSource.cellTower,
        LocationSource.ip,
      ],
      cacheExpiry: Duration(minutes: 3),
      enableBluetooth: false,
      httpTimeoutMs: 8000,
    ),
  );

  runApp(const HybridLocationApp());
}

/// Root application widget.
class HybridLocationApp extends StatelessWidget {
  /// Creates the [HybridLocationApp].
  const HybridLocationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Hybrid Location Demo',
      home: _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  bool _tracking = false;

  @override
  void initState() {
    super.initState();
    _demonstrateSingleFetch();
  }

  Future<void> _demonstrateSingleFetch() async {
    // One-shot location fetch
    try {
      final result = await HybridLocation.getLocation();
      debugPrint('Lat: ${result.latitude}, Lng: ${result.longitude}');
      debugPrint('Accuracy: ${result.accuracyMeters}m via ${result.source}');
      debugPrint('Cached: ${result.isCached}');
    } on HybridLocationException catch (e) {
      debugPrint('Failed: ${e.message}');
      debugPrint('Tried: ${e.failedSources}');
    }
  }

  Future<void> _startTracking() async {
    HybridLocation.locationStream.listen((loc) {
      debugPrint('Update: ${loc.latitude}, ${loc.longitude} [${loc.source}]');
    });
    await HybridLocation.startTracking(
      interval: const Duration(minutes: 5),
    );
    setState(() => _tracking = true);
  }

  Future<void> _stopTracking() async {
    await HybridLocation.stopTracking();
    setState(() => _tracking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hybrid Location Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const LocationDisplay(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _tracking ? _stopTracking : _startTracking,
              child: Text(_tracking ? 'Stop Tracking' : 'Start Tracking'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card widget that displays the current location obtained from
/// [HybridLocation.getLocation].
///
/// Shows:
/// - A source badge coloured by provider type.
/// - Latitude and longitude to 5 decimal places.
/// - Estimated accuracy in metres.
/// - A Refresh button that re-fetches and rebuilds.
/// - A loading indicator while fetching.
/// - An error message when [HybridLocationException] is thrown.
class LocationDisplay extends StatefulWidget {
  /// Creates a [LocationDisplay].
  const LocationDisplay({super.key});

  @override
  State<LocationDisplay> createState() => _LocationDisplayState();
}

class _LocationDisplayState extends State<LocationDisplay> {
  HybridLocationResult? _result;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await HybridLocation.getLocation();
      setState(() {
        _result = result;
        _loading = false;
      });
    } on HybridLocationException catch (e) {
      setState(() {
        _error = '${e.message}\nTried: ${e.failedSources.map((s) => s.name).join(', ')}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && _error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (!_loading && _result != null) ...[
              _SourceBadge(source: _result!.source),
              const SizedBox(height: 8),
              Text(
                'Lat: ${_result!.latitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                'Lng: ${_result!.longitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Accuracy: ${_result!.accuracyMeters.toStringAsFixed(0)} m',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_result!.isCached)
                const Text(
                  '(cached)',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _loading ? null : _fetch,
                child: const Text('Refresh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final LocationSource source;

  Color get _color {
    switch (source) {
      case LocationSource.wifi:
        return Colors.blue;
      case LocationSource.cellTower:
        return Colors.orange;
      case LocationSource.ip:
        return Colors.green;
      case LocationSource.bluetooth:
        return Colors.purple;
      case LocationSource.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        source.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
