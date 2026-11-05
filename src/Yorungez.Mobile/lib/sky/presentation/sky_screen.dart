import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../catalogue/data/catalogue_repository.dart';
import '../../catalogue/domain/sky_object.dart';
import '../../l10n/generated/app_localizations.dart';
import '../data/mobile_services.dart';
import '../data/screen_awake.dart';
import '../data/native_sky.dart';
import '../data/sky_visuals.dart';
import '../data/iss_elements.dart';
import '../domain/sky_frame.dart';
import '../domain/sky_track.dart';
import '../domain/sky_geometry.dart';
import 'sky_painter.dart';
import 'sky_sidebar.dart';
import '../domain/dwell_selection.dart';
import '../data/device_location.dart';
import '../../account/account_models.dart';
import '../../account/account_widgets.dart';
import '../../planning/planning_time.dart';

class SkyScreen extends ConsumerStatefulWidget {
  const SkyScreen({super.key, this.initialObserver});
  final SkyObserver? initialObserver;
  @override
  ConsumerState<SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends ConsumerState<SkyScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin, RouteAware {
  final _preferences = MobilePreferences();
  final _screenAwake = ScreenAwake();
  final _layers = <SkyLayer>{
    SkyLayer.stars,
    SkyLayer.solar,
    SkyLayer.deepSky,
    SkyLayer.horizon,
    SkyLayer.constellations,
    SkyLayer.figures,
    SkyLayer.cosmic,
  };
  final _visuals = SkyVisuals();
  SkyAmbience? _audio;
  SkyWorker? _worker;
  Catalogue? _catalogue;
  SkyFrame? _frame;
  SkyTrack? _track;
  IssElements? _iss;
  DateTime? _issAttempt;
  bool _issBusy = false;
  bool _followOnResume = false;
  bool _trackPending = false;
  SkyObserver? _observer;
  CameraController? _camera;
  StreamSubscription<dynamic>? _sensor;
  Timer? _timer, _dwellTimer;
  final _scaffold = GlobalKey<ScaffoldState>();
  final _dwell = DwellSelection();
  final _clock = Stopwatch()..start();
  late final AnimationController _selectionAnimation;
  bool _drawerOpen = false, _modalOpen = false;
  PoseSample? _sample;
  ViewPose _pose = ViewPose.horizon(180, 25);
  bool _loading = true,
      _active = true,
      _calculating = false,
      _locating = false,
      _cameraBusy = false;
  bool _muted = false, _following = false, _cameraPrepared = false;
  int? _onboarding = 0;
  int _generation = 0, _cameraGeneration = 0;
  double? _yawOffset;
  double _fov = 60;
  String? _selected, _issue;
  String? _pendingFocus, _focusedTarget;
  PageRoute<dynamic>? _route;
  bool _routeVisible = true, _preferencesBusy = false;
  DateTime? _deviceRetryAt;
  bool _manualViewRequested = false;

  @override
  void initState() {
    super.initState();
    _observer = widget.initialObserver;
    _pendingFocus = ref.read(skyFocusProvider);
    _selectionAnimation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _dwellTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateDwell(),
    );
    WidgetsBinding.instance.addObserver(this);
    unawaited(_screenAwake.setActive(_active));
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    unawaited(_initialise());
    unawaited(
      _visuals
          .initialise()
          .then((_) {
            if (mounted) setState(() {});
          })
          .catchError((Object _) {
            if (mounted) setState(() => _issue = 'visuals');
          }),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_active) return;
      if (_sample != null && !_sample!.fresh(DateTime.now())) {
        _sample = null;
        _yawOffset = null;
        if (mounted) setState(() => _issue = 'stale');
      }
      unawaited(_calculate());
      unawaited(_requestTrack());
      unawaited(_loadIss());
      if (_observer?.device == true &&
          _onboarding == null &&
          _observer?.measuredAt != null &&
          DateTime.now().difference(_observer!.measuredAt!) >
              const Duration(minutes: 1)) {
        unawaited(_locate(request: false));
      }
    });
  }

  Future<void> _initialise() async {
    var completed = false, music = true;
    try {
      completed = await _preferences.onboardingComplete();
      music = await _preferences.musicEnabled();
    } catch (_) {
      /* Optional UI storage. */
    }
    if (!mounted) return;
    final accountPreferences = ref.read(accountStateProvider).preferences;
    if (accountPreferences != null) music = accountPreferences.musicEnabled;
    setState(() {
      _loading = false;
      _onboarding = completed ? null : 0;
      _muted = !music;
      if (accountPreferences != null) {
        _layers
          ..clear()
          ..addAll(
            SkyLayer.values.where(
              (layer) => accountPreferences.layers.contains(layer.name),
            ),
          );
      }
    });
    if (completed) {
      if (_observer == null) {
        await _locate(request: false);
      } else {
        unawaited(_calculate());
      }
      if (mounted &&
          _observer != null &&
          _focusedTarget == null &&
          _pendingFocus == null &&
          _active) {
        _startTracking();
      }
      if (mounted && !_muted) unawaited(_playMusic());
    }
  }

  Future<void> _calculate() async {
    if (_calculating ||
        !_active ||
        _observer == null ||
        !mounted ||
        _issue == 'calculation') {
      return;
    }
    _calculating = true;
    final observer = _observer!,
        generation = _generation,
        instant = ref.read(skyInstantProvider) ?? DateTime.now().toUtc();
    try {
      final catalogue = await ref.read(catalogueProvider.future);
      _catalogue = catalogue;
      if (!mounted || !_active) return;
      if (_worker == null) {
        final worker = await ref.read(skyWorkerProvider.future);
        if (!mounted) {
          return;
        }
        _worker = worker;
      }
      final raw = await _worker!.calculate(
        observer,
        instant,
        iss: _iss?.usable(instant) == true ? _iss!.values : const [],
      );
      if (!mounted || !_active || generation != _generation) return;
      final frame = SkyFrame.decode(catalogue, observer, instant, raw);
      ref.read(skyFrameProvider.notifier).publish(frame);
      setState(() {
        _frame = frame;
        final focused = frame.points[_focusedTarget];
        if (!_following && focused != null) {
          _pose = ViewPose.horizon(focused.azimuth, focused.altitude);
        }
        if (_selected == issObject.id &&
            !frame.points.containsKey(issObject.id)) {
          _selected = null;
          _track = null;
        }
        if (_issue == 'calculation') _issue = null;
      });
      _consumeFocus();
    } catch (_) {
      if (mounted) ref.invalidate(skyWorkerProvider);
      _worker = null;
      if (mounted && _active) setState(() => _issue = 'calculation');
    } finally {
      _calculating = false;
    }
  }

  void _setObserver(SkyObserver observer) {
    final resumeTracking = _following;
    _stopTracking();
    _generation++;
    _dwell.reset();
    _pendingFocus ??= _focusedTarget;
    _selected = null;
    _track = null;
    ref.read(skyFrameProvider.notifier).publish(null);
    setState(() {
      _observer = observer;
      _frame = null;
      _issue = null;
    });
    unawaited(_calculate());
    if ((resumeTracking || (observer.device && !_manualViewRequested)) &&
        _onboarding == null &&
        _active) {
      _startTracking();
    }
  }

  Future<void> _locate({bool request = true}) async {
    if (_locating) return;
    if (!request &&
        _deviceRetryAt != null &&
        DateTime.now().isBefore(_deviceRetryAt!)) {
      return;
    }
    _deviceRetryAt = DateTime.now().add(const Duration(minutes: 1));
    if (mounted) setState(() => _locating = true);
    var generation = _generation;
    try {
      final source = ref.read(deviceLocationProvider);
      if (!await source.permitted(request: request)) {
        if (mounted && generation == _generation && _observer?.device == true) {
          _stopTracking();
          _generation++;
          ref.read(skyFrameProvider.notifier).publish(null);
          setState(() {
            _observer = null;
            _frame = null;
            _track = null;
            _selected = null;
          });
        }
        if (request && mounted) setState(() => _issue = 'denied');
        return;
      }
      try {
        final cached = await source.recent();
        if (!mounted || generation != _generation || !_active) return;
        final observer = cached == null
            ? null
            : deviceObserver(cached, DateTime.now(), provisional: true);
        if (_observer == null && observer != null) {
          _setObserver(observer);
          generation = _generation;
        }
      } catch (_) {
        /* A fresh fix is still attempted if the OS cache is absent. */
      }
      final fix = await source.current();
      if (!mounted || generation != _generation || !_active) return;
      final observer = deviceObserver(fix, DateTime.now());
      if (observer == null) throw StateError('Invalid device fix');
      _setObserver(observer);
    } catch (_) {
      if (mounted && (request || _observer?.device == true)) {
        setState(() => _issue = 'gps');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _manualLocation() async {
    final text = AppLocalizations.of(context);
    final lat = TextEditingController(
      text: _observer?.latitude.toString() ?? '',
    );
    final lon = TextEditingController(
      text: _observer?.longitude.toString() ?? '',
    );
    final height = TextEditingController();
    var invalid = false;
    final observer = await showModalBottomSheet<SkyObserver>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheet).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text.manualLocation,
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                for (final field in [
                  (lat, text.latitudeLabel),
                  (lon, text.longitudeLabel),
                  (height, text.elevationLabel),
                ]) ...[
                  TextField(
                    controller: field.$1,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(labelText: field.$2),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(text.elevationAssumption),
                if (invalid)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      text.invalidLocation,
                      style: TextStyle(
                        color: Theme.of(sheet).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    try {
                      final result = SkyObserver(
                        double.parse(lat.text.trim()),
                        double.parse(lon.text.trim()),
                        elevation: height.text.trim().isEmpty
                            ? 0
                            : double.parse(height.text.trim()),
                      );
                      Navigator.pop(sheet, result);
                    } catch (_) {
                      update(() => invalid = true);
                    }
                  },
                  child: Text(text.applyLocation),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(
                    sheet,
                    SkyObserver(41.0082, 28.9784, example: true),
                  ),
                  child: Text(text.exampleLocation),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Controllers remain alive through the modal's closing animation.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    lat.dispose();
    lon.dispose();
    height.dispose();
    if (mounted && observer != null) _setObserver(observer);
  }

  Future<void> _cameraToggle({bool permissionOnly = false}) async {
    if (_cameraBusy) return;
    if (_camera != null) {
      await _closeCamera();
      if (mounted) setState(() {});
      return;
    }
    final generation = ++_cameraGeneration;
    setState(() => _cameraBusy = true);
    CameraController? next;
    try {
      final cameras = await availableCameras();
      final rear = cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .first;
      next = CameraController(
        rear,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await next.initialize();
      if (!mounted || !_active || generation != _cameraGeneration) {
        await next.dispose();
        return;
      }
      _cameraPrepared = true;
      if (permissionOnly) {
        await next.dispose();
      } else {
        _fov = 60;
        _camera = next;
        if (!_following) _startTracking();
      }
      setState(() => _issue = null);
    } catch (_) {
      await next?.dispose();
      if (mounted) setState(() => _issue = 'camera');
    } finally {
      if (mounted) setState(() => _cameraBusy = false);
    }
  }

  Future<void> _closeCamera() async {
    _cameraGeneration++;
    final camera = _camera;
    _camera = null;
    _fov = 60;
    await camera?.dispose();
  }

  Future<void> _playMusic() async {
    if (_muted || !_active || !mounted) return;
    try {
      _audio ??= SkyAmbience();
      await _audio!.play();
      if (_muted || !_active) await _audio!.pause();
    } catch (_) {
      if (mounted) setState(() => _issue = 'audio');
    }
  }

  Future<void> _toggleMusic() async {
    if (_preferencesBusy) return;
    setState(() => _muted = !_muted);
    if (_muted) {
      await _audio?.pause();
    } else {
      await _playMusic();
    }
    try {
      if (ref.read(accountStateProvider).user == null) {
        await _preferences.setMusic(!_muted);
      } else {
        await _savePreferences();
      }
    } catch (_) {
      /* UI preference only. */
    }
  }

  Future<void> _savePreferences() async {
    if (_preferencesBusy) return;
    setState(() => _preferencesBusy = true);
    try {
      await ref
          .read(accountSessionProvider)
          .savePreferences(!_muted, _layers.map((l) => l.name).toSet());
    } on AccountFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accountError(AppLocalizations.of(context), error)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _preferencesBusy = false);
    }
  }

  Future<void> _applyPreferences(ExplorationPreferences preferences) async {
    if (!mounted) return;
    setState(() {
      _muted = !preferences.musicEnabled;
      _layers
        ..clear()
        ..addAll(
          SkyLayer.values.where(
            (layer) => preferences.layers.contains(layer.name),
          ),
        );
    });
    if (_muted) {
      await _audio?.pause();
    } else if (_active && _onboarding == null) {
      await _playMusic();
    }
  }

  Future<void> _anonymousPreferences() async {
    final epoch = ref.read(accountStateProvider).epoch;
    var music = true;
    try {
      music = await _preferences.musicEnabled();
    } catch (_) {
      /* Optional anonymous UI preference. */
    }
    if (!mounted ||
        ref.read(accountStateProvider).user != null ||
        ref.read(accountStateProvider).epoch != epoch) {
      return;
    }
    await _applyPreferences(
      ExplorationPreferences(music, {
        'stars',
        'solar',
        'deepSky',
        'horizon',
        'constellations',
        'figures',
        'cosmic',
      }, 0),
    );
  }

  Future<void> _startExploring() async {
    if (_observer == null) {
      setState(() => _issue = 'location');
      return;
    }
    try {
      await _preferences.completeOnboarding();
    } catch (_) {
      /* Retry notice on next launch. */
    }
    if (!mounted) return;
    setState(() => _onboarding = null);
    _startTracking();
    unawaited(_calculate());
    if (!_muted) unawaited(_playMusic());
  }

  void _stopTracking() {
    _dwell.reset();
    unawaited(_sensor?.cancel());
    _sensor = null;
    _sample = null;
    _following = false;
    _yawOffset = null;
  }

  void _startTracking() {
    ref.read(skyInstantProvider.notifier).select(null);
    _stopTracking();
    _manualViewRequested = false;
    _focusedTarget = null;
    setState(() {
      _following = true;
      _issue = null;
    });
    _sensor = nativePoseChannel.receiveBroadcastStream().listen(
      (event) {
        try {
          if (!mounted || !_following || !_active) return;
          final sample = PoseSample.decode(event);
          if (!sample.fresh(DateTime.now()) ||
              (_sample != null && sample.timestampMs <= _sample!.timestampMs)) {
            return;
          }
          if (_sample != null && sample.reference != _sample!.reference) {
            _yawOffset = null;
          }
          setState(() {
            _sample = sample;
            if (sample.quality == 0) {
              _yawOffset = null;
              _dwell.reset();
              _issue = 'stale';
              return;
            }
            if (sample.reference == 'true' || _poseCorrection != null) {
              _pose = ViewPose.device(
                sample.matrix,
                sample.rotation,
                _poseCorrection ?? 0,
              );
              if (_issue == 'stale') _issue = null;
            }
          });
        } catch (_) {
          if (mounted) setState(() => _issue = 'sensor');
        }
      },
      onError: (Object error) {
        _stopTracking();
        if (mounted) setState(() => _issue = 'sensor');
      },
    );
  }

  double? get _poseCorrection {
    if (_yawOffset != null) return _yawOffset;
    final model = _frame?.magneticCorrection;
    if (_sample?.reference != 'magnetic' ||
        (_sample?.quality ?? 0) < 2 ||
        _observer?.example == true ||
        model == null ||
        model.$3 < 6000 ||
        model.$2 > 2 ||
        _frame == null ||
        DateTime.now().toUtc().difference(_frame!.instant).abs() >
            const Duration(seconds: 30) ||
        DateTime.now().toUtc().year < 2025 ||
        DateTime.now().toUtc().year >= 2030) {
      return null;
    }
    return model.$1 * radians;
  }

  bool get _aligned =>
      _following &&
      _sample != null &&
      _sample!.quality > 0 &&
      _sample!.fresh(DateTime.now()) &&
      (_sample!.reference == 'true' || _poseCorrection != null);
  void _align({bool target = false}) {
    final sample = _sample;
    final point = _frame?.points[_selected];
    if (sample == null ||
        sample.quality == 0 ||
        !sample.fresh(DateTime.now()) ||
        sample.pose.forward.altitude.abs() > 85 ||
        (target &&
            (point == null ||
                point.altitude < 0 ||
                point.altitude.abs() > 85))) {
      setState(() => _issue = 'alignment');
      return;
    }
    setState(() {
      _yawOffset =
          ((target ? point!.azimuth : 0) - sample.pose.forward.azimuth) *
          radians;
      _pose = ViewPose.device(sample.matrix, sample.rotation, _yawOffset!);
      _issue = null;
    });
  }

  void _focus(String id) {
    if (!_active) {
      _pendingFocus = id;
      return;
    }
    final point = _frame?.points[id];
    if (point == null) {
      if (id == issObject.id) setState(() => _issue = "iss");
      return;
    }
    _stopTracking();
    _followOnResume = false;
    _focusedTarget = id;
    _manualViewRequested = true;
    unawaited(_closeCamera());
    setState(() {
      _selected = id;
      _dwell.reset();
      _selectionAnimation.forward(from: 0);
      _track = null;
      unawaited(_requestTrack());
      _pose = ViewPose.horizon(point.azimuth, point.altitude);
    });
  }

  Future<void> _search() async {
    final id = await context.push<String>('/catalogue?pick=true');
    if (mounted && id != null) _focus(id);
  }

  void _consumeFocus() {
    final id = _pendingFocus;
    if (id == null || !_active || _frame == null || _onboarding != null) return;
    _pendingFocus = null;
    _focus(id);
    ref.read(skyFocusProvider.notifier).consumed(id);
  }

  Future<void> _sheet(Widget child) async {
    _dwell.reset();
    _modalOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      );
    } finally {
      _modalOpen = false;
    }
  }

  String? _message(AppLocalizations t) => switch (_issue) {
    'denied' => t.gpsDenied,
    'gps' => t.gpsUnavailable,
    'camera' => t.cameraUnavailable,
    'audio' => t.musicUnavailable,
    'visuals' => t.visualsUnavailable,
    'iss' => t.issUnavailable,
    'sensor' => t.sensorUnavailable,
    'stale' => t.sensorStale,
    'alignment' => t.alignmentUnavailable,
    'calculation' => t.calculationError,
    'location' => t.chooseLocationFirst,
    _ => null,
  };
  Future<void> _calibration() {
    final t = AppLocalizations.of(context);
    return _sheet(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.calibrationTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Center(
            child: Icon(
              Icons.all_inclusive,
              size: 72,
              color: Color(0xFFC9B6A6),
            ),
          ),
          Text(t.calibrationBody),
          const SizedBox(height: 16),
          Text(t.calibrationAccuracy),
          const Divider(height: 32),
          Text(t.alignmentInstruction),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              _align();
              Navigator.pop(context);
            },
            child: Text(t.alignNorth),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _selected == null
                ? null
                : () {
                    _align(target: true);
                    Navigator.pop(context);
                  },
            child: Text(t.alignTarget),
          ),
        ],
      ),
    );
  }

  void _settings() => _scaffold.currentState?.openDrawer();

  void _select(String id) {
    if (_selected == id) return;
    setState(() {
      _selected = id;
      _track = null;
    });
    unawaited(_requestTrack());
    _selectionAnimation.forward(from: 0);
  }

  Future<void> _loadIss() async {
    final now = DateTime.now().toUtc();
    if (!_active ||
        _onboarding != null ||
        _issBusy ||
        (_issAttempt != null &&
            now.difference(_issAttempt!) < const Duration(hours: 2))) {
      return;
    }
    _issAttempt = now;
    _issBusy = true;
    try {
      final value = await IssRepository(ref.read(apiProvider)).load(now);
      if (mounted) setState(() => _iss = value);
    } finally {
      _issBusy = false;
    }
  }

  Future<void> _requestTrack() async {
    final frame = _frame, id = _selected, worker = _worker;
    if (!_active ||
        frame == null ||
        id == null ||
        worker == null ||
        _trackPending ||
        frame.points[id]?.object.kind == ObjectKind.constellation ||
        (_track?.id == id &&
            frame.instant.difference(_track!.centre).abs() <
                const Duration(minutes: 1))) {
      return;
    }
    final generation = _generation;
    _trackPending = true;
    try {
      final raw = await worker.trajectory(
        frame.observer,
        frame.instant,
        id,
        iss: id == issObject.id && _iss?.usable(frame.instant) == true
            ? _iss!.values
            : const [],
      );
      if (!mounted ||
          !_active ||
          generation != _generation ||
          id != _selected) {
        return;
      }
      setState(() => _track = SkyTrack(id, frame.instant, frame.observer, raw));
    } catch (_) {
      // No decorative fallback. A later selected-target tick retries calculation.
    } finally {
      _trackPending = false;
    }
  }

  void _updateDwell() {
    if (!mounted ||
        !_active ||
        _onboarding != null ||
        _modalOpen ||
        _drawerOpen ||
        ModalRoute.of(context)?.isCurrent != true ||
        (_following && !_aligned) ||
        _frame == null) {
      _dwell.reset();
      return;
    }
    final painter = _makePainter(ref.read(localeProvider).languageCode);
    SkyPoint? candidate;
    var best = 4 * radians;
    // Retain a candidate within 5 degrees to avoid resetting for hand tremor.
    final held = _frame!.points[_dwell.candidate];
    if (held != null &&
        painter!.visible(held) &&
        math.acos(held.vector.dot(_pose.forward).clamp(-1.0, 1.0)) <
            5 * radians) {
      candidate = held;
    } else {
      for (final point in _frame!.points.values) {
        if (!painter!.visible(point)) continue;
        final angle = math.acos(
          point.vector.dot(_pose.forward).clamp(-1.0, 1.0),
        );
        if (angle < best) {
          best = angle;
          candidate = point;
        }
      }
    }
    final id = _dwell.update(candidate?.object.id, _clock.elapsed);
    if (id != null) _select(id);
    if (_dwell.candidate != null) setState(() {});
  }

  String _brief(SkyPoint point, String language, AppLocalizations t) {
    final object = point.object;
    if (object.summaries[language] case final String summary) return summary;
    return switch (object.kind) {
      ObjectKind.solarSystem => t.solarSystemObject,
      ObjectKind.satellite => t.stationObject,
      ObjectKind.star => t.starInConstellation(
        _catalogue
                ?.find('con-${object.constellation.toLowerCase()}')
                ?.name(language) ??
            object.constellation,
      ),
      ObjectKind.constellation =>
        point.altitude >= 0 ? t.constellationAbove : t.constellationBelow,
      ObjectKind.deepSky =>
        object.subtype == 'G'
            ? t.galaxyObject
            : object.subtype.contains('Cl')
            ? t.clusterObject
            : t.nebulaObject,
    };
  }

  SkyPainter? _makePainter(String language) {
    if (_frame == null || _catalogue == null) return null;
    final t = AppLocalizations.of(context);
    return SkyPainter(
      frame: _frame!,
      catalogue: _catalogue!,
      pose: _pose,
      fov: _fov,
      layers: Set.unmodifiable(_layers),
      language: language,
      cardinals: [t.northLabel, t.eastLabel, t.southLabel, t.westLabel],
      selected: _selected,
      optical: true,
      camera: _camera != null,
      dwellProgress: _dwell.progress(_clock.elapsed),
      selectionProgress: _selectionAnimation.value,
      visuals: _visuals,
      track: _track?.id == _selected ? _track : null,
    );
  }

  Future<void> _sourceSheet() {
    final t = AppLocalizations.of(context), frame = _frame, iss = _iss;
    final magnetic = frame?.magneticCorrection;
    return _sheet(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.sources, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(t.illustrationPolicy),
          Text(t.cosmicCredit),
          Text(t.cosmicLimitations),
          const Divider(height: 28),
          Text(t.magneticModelInfo),
          if (magnetic != null)
            Text(
              'WMM2025 · D ${magnetic.$1.toStringAsFixed(2)}° · σ ${magnetic.$2.toStringAsFixed(2)}° · H ${magnetic.$3.round()} nT',
            ),
          const Divider(height: 28),
          Text(
            iss == null || !iss.usable(DateTime.now().toUtc())
                ? t.issUnavailable
                : t.issSourceInfo,
          ),
          if (iss != null) ...[
            Text('NORAD 25544 · CelesTrak · TEME / UTC / SGP4 / WGS72'),
            Text('EPOCH ${iss.epoch.toIso8601String()}'),
            Text('EXPIRES ${iss.expires.toIso8601String()}'),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/sources');
            },
            child: Text(t.sources),
          ),
        ],
      ),
    );
  }

  Future<void> _locationSheet() async {
    final t = AppLocalizations.of(context);
    await _sheet(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.locationUpdate,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(t.locationRationale),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              unawaited(_locate());
            },
            child: Text(t.enableLocation),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              unawaited(_manualLocation());
            },
            child: Text(t.manualLocation),
          ),
          const SizedBox(height: 12),
          if (_observer != null) ...[
            Text(
              '${_observer!.latitude.toStringAsFixed(5)}, ${_observer!.longitude.toStringAsFixed(5)}',
            ),
            if (_observer!.accuracy != null)
              Text('±${_observer!.accuracy!.round()} m'),
            Text(t.elevationAssumption),
          ],
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      skyRouteObserver.unsubscribe(this);
      _route = route;
      skyRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    didChangeAppLifecycleState(
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed,
    );
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    didChangeAppLifecycleState(
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed && _routeVisible;
    unawaited(_screenAwake.setActive(_active));
    if (!_active) {
      _followOnResume = _following || _followOnResume;
      _stopTracking();
      // An OS permission prompt can temporarily make the app inactive. Do not
      // invalidate its pending user request unless the app actually backgrounds.
      if (_camera != null || state != AppLifecycleState.inactive) {
        unawaited(_closeCamera());
      }
      unawaited(_audio?.pause());
    } else {
      if (_followOnResume && _onboarding == null && _observer != null) {
        _followOnResume = false;
        _startTracking();
      }
      if (mounted) setState(() {});
      unawaited(_calculate());
      _deviceRetryAt = null;
      if (_onboarding == null &&
          (_observer == null || _observer?.device == true)) {
        unawaited(_locate(request: false));
      }
      if (_onboarding == null && !_muted) unawaited(_playMusic());
    }
  }

  @override
  void dispose() {
    _active = false;
    unawaited(_screenAwake.close());
    _generation++;
    _cameraGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    skyRouteObserver.unsubscribe(this);
    _timer?.cancel();
    _dwellTimer?.cancel();
    _selectionAnimation.dispose();
    _visuals.close();
    _stopTracking();
    unawaited(_closeCamera());
    unawaited(_audio?.close());
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  Widget _button(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool active = false,
  }) => IconButton.filledTonal(
    style: IconButton.styleFrom(
      backgroundColor: active
          ? const Color(0xFF8B2333)
          : const Color(0xD93C3F43),
      foregroundColor: const Color(0xFFF7F1E6),
      minimumSize: const Size(48, 48),
    ),
    onPressed: onTap,
    icon: Icon(icon),
    tooltip: label,
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context),
        language = ref.watch(localeProvider).languageCode;
    ref.watch(catalogueProvider);
    final planningZone = ref.watch(planningZoneProvider);
    final simulation = ref.watch(skyInstantProvider);
    ref.listen(skyInstantProvider, (_, next) {
      _generation++;
      _frame = null;
      ref.read(skyFrameProvider.notifier).publish(null);
      _track = null;
      _dwell.reset();
      if (next != null) {
        _stopTracking();
        _followOnResume = false;
        unawaited(_closeCamera());
      }
      unawaited(_calculate());
    });
    ref.listen(skyFocusProvider, (_, next) {
      if (next != null) {
        _pendingFocus = next;
        unawaited(_calculate());
      }
    });
    ref.listen(accountStateProvider.select((s) => s.preferences), (_, next) {
      if (next != null) unawaited(_applyPreferences(next));
    });
    ref.listen(accountStateProvider.select((s) => s.user?.id), (
      previous,
      next,
    ) {
      if (previous != null && next == null) unawaited(_anonymousPreferences());
    });
    final frame = _frame, point = frame?.points[_selected];
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final status = simulation != null
        ? t.simulation
        : _following
        ? (_aligned
              ? (_yawOffset != null
                    ? t.alignedNorth
                    : _sample?.reference == 'true'
                    ? t.trueNorth
                    : t.modeledNorth)
              : (_sample?.reference == 'magnetic'
                    ? t.magneticNorth
                    : t.waitingAlignment))
        : t.manualView;
    final formatter = NumberFormat.decimalPatternDigits(
      locale: language,
      decimalDigits: 1,
    );
    final painter = _makePainter(language);
    if (painter != null) {
      unawaited(
        _visuals
            .updateArt(painter.wantedArt(), () {
              if (mounted) setState(() {});
            })
            .catchError((Object _) {}),
      );
    }
    final location = _observer == null
        ? t.locationNeeded
        : '${_observer!.example
                  ? t.exampleLocation
                  : _observer!.device
                  ? t.deviceLocationLabel
                  : t.manualLocationLabel}\n'
              '${_observer!.latitude.toStringAsFixed(4)}, ${_observer!.longitude.toStringAsFixed(4)}'
              '${_observer!.accuracy == null ? '' : ' · ±${_observer!.accuracy!.round()} m'}';
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
      floatingActionButton: simulation == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 64),
                child: FilledButton.icon(
                  onPressed: () =>
                      ref.read(skyInstantProvider.notifier).select(null),
                  icon: const Icon(Icons.history),
                  label: Text(t.backToLive),
                ),
              ),
            ),
      key: _scaffold,
      backgroundColor: Colors.black,
      onDrawerChanged: (open) {
        _dwell.reset();
        setState(() => _drawerOpen = open);
      },
      drawer: _onboarding != null
          ? null
          : SkySidebar(
              savingPreferences: _preferencesBusy,
              layers: _layers,
              muted: _muted,
              language: language,
              location: location,
              clock:
                  '${PlanningTime.label(frame?.instant ?? DateTime.now().toUtc(), planningZone, language)}\n$planningZone\n${PlanningTime.utc(frame?.instant ?? DateTime.now().toUtc(), language)}',
              simulated: simulation != null,
              showTonight: () => context.push('/tonight'),
              showCalendar: () => context.push('/calendar'),
              showReminders: () => context.push('/reminders'),
              showTimeZone: () => context.push('/time-zone'),
              returnToLive: () {
                ref.read(skyInstantProvider.notifier).select(null);
              },
              changeLocation: () => unawaited(_locationSheet()),
              calibrate: () => unawaited(_calibration()),
              showSources: () => unawaited(_sourceSheet()),
              showConnection: () => context.push('/connection'),
              toggleMusic: _toggleMusic,
              changeLayer: (layer, enabled) {
                if (_preferencesBusy) return;
                _dwell.reset();
                setState(() {
                  if (enabled) {
                    _layers.add(layer);
                  } else {
                    _layers.remove(layer);
                  }
                });
                if (ref.read(accountStateProvider).user != null) {
                  unawaited(_savePreferences());
                }
              },
              showPrivacy: () => unawaited(
                _sheet(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.privacyTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(t.privacyBody),
                      const SizedBox(height: 16),
                      Text(t.privacyVersion),
                    ],
                  ),
                ),
              ),
            ),
      body: LayoutBuilder(
        builder: (context, bounds) => Stack(
          children: [
            if (_camera != null && _camera!.value.isInitialized)
              Positioned.fill(child: _CameraBackground(controller: _camera!)),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Fixed FOV. A manual pan is an explicit fallback only; no pinch zoom.
                onPanUpdate: _following || _camera != null
                    ? null
                    : (details) {
                        _dwell.reset();
                        _focusedTarget = null;
                        _manualViewRequested = true;
                        setState(
                          () => _pose = ViewPose.horizon(
                            (_pose.forward.azimuth -
                                    details.delta.dx * _fov / bounds.maxWidth +
                                    360) %
                                360,
                            (_pose.forward.altitude +
                                    details.delta.dy * _fov / bounds.maxHeight)
                                .clamp(-90.0, 90.0),
                          ),
                        );
                      },
                onTapUp: (event) {
                  final id = painter
                      ?.pick(event.localPosition, bounds.biggest)
                      ?.object
                      .id;
                  if (id != null) _select(id);
                },
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _camera != null && !_aligned ? null : painter,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    left: 12,
                    top: 8,
                    child: _button(
                      Icons.menu_rounded,
                      t.skySettings,
                      _settings,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 8,
                    child: Column(
                      children: [
                        _button(
                          Icons.search_rounded,
                          t.searchSky,
                          frame == null ? null : () => unawaited(_search()),
                        ),
                        const SizedBox(height: 8),
                        _button(
                          _camera == null
                              ? Icons.camera_alt_outlined
                              : Icons.auto_awesome,
                          _camera == null ? t.cameraMode : t.virtualMode,
                          _cameraBusy
                              ? null
                              : () {
                                  _dwell.reset();
                                  unawaited(_cameraToggle());
                                },
                          active: _camera != null,
                        ),
                        const SizedBox(height: 8),
                        _button(
                          Icons.explore_outlined,
                          _following ? t.stopTracking : t.startTracking,
                          () {
                            if (_following) {
                              _manualViewRequested = true;
                              _followOnResume = false;
                              _stopTracking();
                              setState(() {});
                            } else {
                              _startTracking();
                            }
                          },
                          active: _following,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 76,
                    right: 76,
                    top: 14,
                    child: Column(
                      children: [
                        Text(
                          status,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFC9B6A6),
                          ),
                        ),
                        if (_camera != null)
                          Text(
                            t.cameraApproximate,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        if (_following && !_aligned && _sample != null)
                          TextButton(
                            onPressed: () => unawaited(_calibration()),
                            child: Text(t.showCalibration),
                          ),
                      ],
                    ),
                  ),
                  if (_message(t) != null)
                    Positioned(
                      left: 16,
                      right: 76,
                      top: landscape ? 70 : 100,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xDD3C3F43),
                        ),
                        onPressed: () {
                          setState(() => _issue = null);
                          if (_frame == null) unawaited(_calculate());
                        },
                        child: Text(_message(t)!),
                      ),
                    ),
                  if (point != null)
                    Align(
                      alignment: Alignment.center,
                      child: IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 96),
                          child: Text(
                            '${t.azimuthLabel} ${formatter.format(point.azimuth)}°    ${t.altitudeLabel} ${formatter.format(point.altitude)}°',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFC9B6A6),
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: landscape ? 8 : null,
                    right: landscape ? null : 12,
                    bottom: landscape ? 4 : 20,
                    child: CompassRose(
                      azimuth: _pose.forward.azimuth,
                      cardinals: [
                        t.northLabel,
                        t.eastLabel,
                        t.southLabel,
                        t.westLabel,
                      ],
                      label:
                          '${t.azimuthLabel} ${formatter.format(_pose.forward.azimuth)}° · $status',
                    ),
                  ),
                  if (_camera == null && _layers.contains(SkyLayer.cosmic))
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Text(
                          t.cosmicCredit,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF9EA1A6),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: landscape ? 112 : 20,
                    right: landscape ? 20 : 112,
                    bottom: 20,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: bounds.maxHeight * .32,
                      ),
                      child: SingleChildScrollView(
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0xBB000000)],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (point != null) ...[
                                  Text(
                                    point.object.name(language),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: const Color(0xFFF7F1E6),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_brief(point, language, t)),

                                  if (_track?.id == point.object.id)
                                    Text(
                                      t.apparentTrack(
                                        DateFormat(
                                          "MM-dd HH:mm 'UTC'",
                                        ).format(_track!.points.first.instant),
                                        DateFormat(
                                          "MM-dd HH:mm 'UTC'",
                                        ).format(_track!.points.last.instant),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFC9B6A6),
                                      ),
                                    ),
                                  Text(
                                    t.illustrationPolicy,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF9EA1A6),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.push(
                                      '/objects/${point.object.id}',
                                    ),
                                    child: Text(t.objectDetails),
                                  ),
                                ] else
                                  Text(
                                    t.dwellHelp,
                                    style: const TextStyle(
                                      color: Color(0xFFC9B6A6),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_onboarding == null && _observer == null && !_loading)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _Glass(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.locationNeeded,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(t.locationRationale),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _locating
                                    ? null
                                    : () => unawaited(_locate()),
                                child: Text(t.enableLocation),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => unawaited(_manualLocation()),
                                child: Text(t.manualLocation),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_observer != null &&
                          frame == null &&
                          _issue != 'calculation' ||
                      _loading)
                    const Center(child: CircularProgressIndicator()),
                  if (!_loading && _onboarding != null)
                    Positioned.fill(
                      child: BlockSemantics(
                        child: ColoredBox(
                          color: const Color(0xFF080B10),
                          child: _onboardingView(t),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _onboardingView(AppLocalizations t) {
    final step = _onboarding!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/generated/app-icon.png',
                    height: 76,
                    width: 76,
                    semanticLabel: 'Yorungez',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                step == 0
                    ? t.onboardingTitle
                    : step == 1
                    ? t.permissionsTitle
                    : t.calibrationTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (step == 0) ...[
                Text(
                  t.privacyTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(t.privacyBody),
                const SizedBox(height: 18),
                Text(
                  t.privacyVersion,
                  style: const TextStyle(color: Color(0xFFC9B6A6)),
                ),
                const SizedBox(height: 18),
                const LanguagePicker(),
              ],
              if (step == 1) ...[
                Text(t.locationRationale),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _locating ? null : () => unawaited(_locate()),
                  icon: const Icon(Icons.my_location),
                  label: Text(_locating ? t.loading : t.enableLocation),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => unawaited(_manualLocation()),
                  child: Text(t.manualLocation),
                ),
                const SizedBox(height: 12),
                if (_observer != null)
                  Text(
                    '${_observer!.example
                        ? t.exampleLocation
                        : _observer!.device
                        ? t.deviceLocationLabel
                        : t.manualLocationLabel} ✓',
                  ),
                const Divider(height: 30),
                Text(t.cameraRationale),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _cameraBusy
                      ? null
                      : () => unawaited(_cameraToggle(permissionOnly: true)),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(t.enableCamera),
                ),
                const SizedBox(height: 12),
                Text(
                  _cameraPrepared
                      ? t.cameraPermissionReady
                      : t.permissionOptional,
                  style: const TextStyle(color: Color(0xFFC9B6A6)),
                ),
              ],
              if (step == 2) ...[
                const Icon(
                  Icons.all_inclusive,
                  size: 76,
                  color: Color(0xFFC9B6A6),
                ),
                const SizedBox(height: 20),
                Text(t.calibrationBody),
                const SizedBox(height: 16),
                Text(t.calibrationAccuracy),
              ],
              if (_message(t) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    _message(t)!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (step == 1 && _observer == null) {
                    setState(() => _issue = 'location');
                    return;
                  }
                  if (step < 2) {
                    setState(() => _onboarding = step + 1);
                  } else {
                    unawaited(_startExploring());
                  }
                },
                child: Text(step == 2 ? t.startExploring : t.continueLabel),
              ),
              if (step > 0) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _onboarding = step - 1),
                  child: Text(t.previousStep),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xD92A2C30),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x339EA1A6)),
    ),
    child: child,
  );
}

class _CameraBackground extends StatelessWidget {
  const _CameraBackground({required this.controller});
  final CameraController controller;
  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final ratio = landscape
        ? controller.value.aspectRatio
        : 1 / controller.value.aspectRatio;
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ratio * 1000,
            height: 1000,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}
