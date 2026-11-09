import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';

class SoundService {
  FlutterSoundPlayer? _player;
  bool _isPlayerInitialized = false;
  bool _isDriverArrivedLooping = false;
  Timer? _loopTimer;
  final Map<String, Uint8List> _soundCache = <String, Uint8List>{};

  static const String rideSound = 'assets/sounds/ride_sound.mp3';
  static const String driverWaiting = 'assets/sounds/driver_waiting.mp3';

  Future<void> init() async {
    if (_isPlayerInitialized) return;
    try {
      _player = FlutterSoundPlayer(logLevel: Level.nothing);
      await _player!.openPlayer();
      _isPlayerInitialized = true;
      debugPrint('SoundService initialized successfully.');
    } catch (e) {
      debugPrint('SoundService initialization failed: $e');
      _isPlayerInitialized = false;
    }
  }

  Future<Uint8List?> _loadSoundBytes(String assetPath) async {
    if (_soundCache.containsKey(assetPath)) {
      return _soundCache[assetPath];
    }
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      _soundCache[assetPath] = bytes;
      return bytes;
    } catch (e) {
      debugPrint('Error loading sound asset $assetPath: $e');
      return null;
    }
  }

  Future<void> _playSound(
    String assetPath, {
    VoidCallback? whenFinished,
  }) async {
    try {
      if (!_isPlayerInitialized) {
        await init();
      }
      if (_player == null || !_isPlayerInitialized) return;

      final Uint8List? bytes = await _loadSoundBytes(assetPath);
      if (bytes == null || bytes.isEmpty) return;

      if (_player!.isPlaying) {
        await _player!.stopPlayer();
      }

      await _player!.startPlayer(
        fromDataBuffer: bytes,
        codec: Codec.mp3,
        whenFinished: whenFinished,
      );
    } catch (e) {
      debugPrint('Error playing sound ($assetPath): $e');
    }
  }

  /// Action 1: Sound effect when user receives a new offer from drivers.
  Future<void> playOfferReceivedSound() async {
    _stopDriverArrivedLoop();
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
    }
    await _playSound(rideSound);
  }

  /// Action 2: Sound effect when ride is accepted.
  Future<void> playRideAcceptedSound() async {
    _stopDriverArrivedLoop();
    await _playSound(rideSound);
  }

  /// Action 3: Sound effect when driver arrives at user location.
  /// Plays again and again until user clicks "I am coming" button or state changes.
  Future<void> playDriverArrivedSound() async {
    _stopDriverArrivedLoop();
    _isDriverArrivedLooping = true;
    await _playDriverArrivedIteration();
  }

  Future<void> _playDriverArrivedIteration() async {
    if (!_isDriverArrivedLooping) return;

    await _playSound(
      driverWaiting,
      whenFinished: () {
        if (!_isDriverArrivedLooping) return;
        _playDriverArrivedIteration();
      },
    );
  }

  /// Stops the repeating driver arrived sound.
  void stopRepeatingSound() {
    _stopDriverArrivedLoop();
  }

  void _stopDriverArrivedLoop() {
    _isDriverArrivedLooping = false;
    _loopTimer?.cancel();
    _loopTimer = null;
    try {
      if (_player != null && _player!.isPlaying) {
        _player!.stopPlayer();
      }
    } catch (e) {
      debugPrint('Error stopping player: $e');
    }
  }

  /// Action 4: Sound effect when ride starts after picking up the user.
  Future<void> playRideStartedSound() async {
    _stopDriverArrivedLoop();
    await _playSound(rideSound);
  }

  /// Action 5a: Sound effect when ride is completed.
  Future<void> playRideCompletedSound() async {
    _stopDriverArrivedLoop();
    await _playSound(rideSound);
  }

  /// Action 5b: Sound effect when ride is cancelled.
  Future<void> playRideCancelledSound() async {
    _stopDriverArrivedLoop();
    await _playSound(rideSound);
  }

  Future<void> dispose() async {
    _stopDriverArrivedLoop();
    _soundCache.clear();
    try {
      if (_player != null) {
        await _player!.closePlayer();
        _player = null;
      }
      _isPlayerInitialized = false;
    } catch (e) {
      debugPrint('Error disposing SoundService player: $e');
    }
  }
}
