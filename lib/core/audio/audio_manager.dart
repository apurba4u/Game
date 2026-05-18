import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._internal();

  factory AudioManager() => instance;

  AudioManager._internal();

  bool _isMusicEnabled = true;
  bool _isSFXEnabled = true;

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSFXEnabled => _isSFXEnabled;

  void toggleMusic(bool enabled) {
    _isMusicEnabled = enabled;
    if (!enabled) {
      stopBGM();
    } else {
      // Loop main theme if desired
    }
  }

  void toggleSFX(bool enabled) {
    _isSFXEnabled = enabled;
  }

  Future<void> playBGM(String assetName) async {
    if (!_isMusicEnabled || kIsWeb) return;
    try {
      await FlameAudio.bgm.play(assetName, volume: 0.4);
    } catch (e) {
      debugPrint('BGM play error: $e');
    }
  }

  Future<void> stopBGM() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('BGM stop error: $e');
    }
  }

  Future<void> playSFX(String assetName) async {
    if (!_isSFXEnabled) return;
    try {
      await FlameAudio.play(assetName, volume: 0.8);
    } catch (e) {
      debugPrint('SFX play error: $e');
    }
  }
}
