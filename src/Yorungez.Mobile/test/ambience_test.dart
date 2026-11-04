import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/sky/data/mobile_services.dart';

final class DelayedPlayer implements AmbiencePlayer {
  final ready = Completer<void>();
  int plays = 0, pauses = 0, disposals = 0;
  @override
  Future<void> initialise() => ready.future;
  @override
  Future<void> play() async {
    plays++;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

void main() {
  test(
    'mute during delayed asset loading prevents a late audio restart',
    () async {
      final player = DelayedPlayer();
      final sound = SkyAmbience(player: player);
      final loading = sound.play();
      await sound.pause();
      player.ready.complete();
      await loading;
      expect(player.plays, 0);
      expect(player.pauses, 1);
      await sound.play();
      expect(player.plays, 1);
      await sound.close();
    },
  );
  test(
    'disposing during audio setup prevents playback and is idempotent',
    () async {
      final player = DelayedPlayer();
      final ambience = SkyAmbience(player: player);
      final loading = ambience.play();
      await ambience.close();
      await ambience.close();
      player.ready.complete();
      await loading;
      expect(player.plays, 0);
      expect(player.disposals, 1);
    },
  );
}
