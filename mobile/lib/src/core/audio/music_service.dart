import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kMusicEnabledKey = 'music_enabled';
const _kMusicVolumeKey = 'music_volume';

const List<String> _tracks = [
  'sounds/track_1.wav',
  'sounds/track_2.wav',
  'sounds/track_3.wav',
  'sounds/track_4.wav',
  'sounds/track_5.wav',
];

final musicServiceProvider = Provider<MusicService>((ref) {
  final service = MusicService();
  ref.onDispose(() => service.dispose());
  return service;
});

final musicEnabledProvider =
    StateNotifierProvider<MusicEnabledNotifier, bool>((ref) {
  final notifier = MusicEnabledNotifier(ref.watch(musicServiceProvider));
  return notifier;
});

class MusicEnabledNotifier extends StateNotifier<bool> {
  MusicEnabledNotifier(this._service) : super(true) {
    _load();
  }

  final MusicService _service;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kMusicEnabledKey) ?? true;
    if (state) {
      _service.playRandom();
    }
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMusicEnabledKey, state);
    if (state) {
      _service.playRandom();
    } else {
      _service.stop();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMusicEnabledKey, enabled);
    if (enabled) {
      _service.playRandom();
    } else {
      _service.stop();
    }
  }
}

class MusicService {
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();
  final List<String> _shuffledTracks = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  double _volume = 0.3;

  MusicService() {
    _loadVolume();
    _player.onPlayerComplete.listen((_) {
      if (_isPlaying) {
        _playNext();
      }
    });
  }

  Future<void> _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    _volume = prefs.getDouble(_kMusicVolumeKey) ?? 0.3;
    await _player.setVolume(_volume);
  }

  void _shuffle() {
    _shuffledTracks.clear();
    _shuffledTracks.addAll(_tracks);
    _shuffledTracks.shuffle(_random);
    _currentIndex = 0;
  }

  Future<void> playRandom() async {
    if (_shuffledTracks.isEmpty || _currentIndex >= _shuffledTracks.length) {
      _shuffle();
    }
    _isPlaying = true;
    try {
      await _player.setVolume(_volume);
      await _player.play(AssetSource(_shuffledTracks[_currentIndex]));
    } catch (_) {
      // Track might not exist yet, skip to next
      _playNext();
    }
  }

  Future<void> _playNext() async {
    _currentIndex++;
    if (_currentIndex >= _shuffledTracks.length) {
      _shuffle();
    }
    if (_isPlaying) {
      try {
        await _player.play(AssetSource(_shuffledTracks[_currentIndex]));
      } catch (_) {
        // Skip unavailable tracks
      }
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    await _player.stop();
  }

  Future<void> pause() async {
    _isPlaying = false;
    await _player.pause();
  }

  Future<void> resume() async {
    _isPlaying = true;
    await _player.resume();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kMusicVolumeKey, _volume);
  }

  double get volume => _volume;
  bool get isPlaying => _isPlaying;

  void dispose() {
    _player.dispose();
  }
}
