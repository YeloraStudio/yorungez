import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/sky_geometry.dart';

// Only non-personal UI choices. Never put coordinates, pose, tokens or notes here.
final class MobilePreferences {
  Future<bool> onboardingComplete() async =>
      (await SharedPreferences.getInstance()).getInt(
        'sky.privacyNoticeVersion',
      ) ==
      1;
  Future<void> completeOnboarding() async {
    await (await SharedPreferences.getInstance()).setInt(
      'sky.privacyNoticeVersion',
      1,
    );
  }

  Future<bool> musicEnabled() async =>
      (await SharedPreferences.getInstance()).getBool('sky.musicEnabled') ??
      true;
  Future<void> setMusic(bool enabled) async {
    await (await SharedPreferences.getInstance()).setBool(
      'sky.musicEnabled',
      enabled,
    );
  }
}

abstract interface class AmbiencePlayer {
  Future<void> initialise();
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

final class _AssetAmbiencePlayer implements AmbiencePlayer {
  final AudioPlayer _player = AudioPlayer();
  @override
  Future<void> initialise() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );
    await _player.setAsset('assets/generated/cylinder-four.m4a');
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(.18);
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> dispose() => _player.dispose();
}

final class SkyAmbience {
  SkyAmbience({AmbiencePlayer? player})
    : _player = player ?? _AssetAmbiencePlayer();
  final AmbiencePlayer _player;
  Future<void>? _initialising;
  bool _disposed = false;
  int _generation = 0;
  Future<void> play() async {
    if (_disposed) return;
    final generation = ++_generation;
    try {
      _initialising ??= _player.initialise();
      await _initialising;
      if (!_disposed && generation == _generation) {
        unawaited(_player.play().catchError((Object _) {}));
      }
    } catch (_) {
      _initialising = null;
      rethrow;
    }
  }

  Future<void> pause() async {
    _generation++;
    if (!_disposed) await _player.pause();
  }

  Future<void> close() async {
    if (_disposed) return;
    _generation++;
    _disposed = true;
    await _player.dispose();
  }
}

final class PoseSample {
  PoseSample(
    this.matrix,
    this.rotation,
    this.reference,
    this.quality,
    this.timestampMs,
    this.accuracy,
  );
  final List<double> matrix;
  final int rotation, quality;
  final String reference;
  final double timestampMs;
  final double? accuracy;
  ViewPose get pose => ViewPose.device(matrix, rotation);
  static PoseSample decode(dynamic value) {
    final m = Map<String, dynamic>.from(value as Map);
    final sample = PoseSample(
      (m['matrix'] as List).map((v) => (v as num).toDouble()).toList(),
      (m['rotation'] as num).toInt(),
      m['reference'] as String,
      (m['quality'] as num).toInt(),
      (m['timestampMs'] as num).toDouble(),
      (m['headingAccuracyDegrees'] as num?)?.toDouble(),
    );
    if (!['true', 'magnetic'].contains(sample.reference) ||
        !sample.timestampMs.isFinite ||
        sample.quality < 0 ||
        sample.quality > 3 ||
        (sample.accuracy != null &&
            (!sample.accuracy!.isFinite || sample.accuracy! < 0))) {
      throw const FormatException('Invalid pose metadata');
    }
    sample.pose;
    return sample;
  }

  bool fresh(DateTime now) =>
      now.millisecondsSinceEpoch - timestampMs >= -100 &&
      now.millisecondsSinceEpoch - timestampMs < 2000;
}

const nativePoseChannel = EventChannel('yorungez/pose');
