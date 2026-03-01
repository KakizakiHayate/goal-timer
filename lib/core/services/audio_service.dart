import 'package:audioplayers/audioplayers.dart';

import '../utils/app_logger.dart';

/// 音声再生サービス
/// タイマー完了時のチャイム音などを再生する
class AudioService {
  static const String _timerCompletionSoundPath = 'sounds/school_chime.mp3';

  final AudioPlayer _audioPlayer;

  AudioService({AudioPlayer? audioPlayer})
      : _audioPlayer = audioPlayer ?? AudioPlayer();

  /// タイマー完了時のチャイム音を再生する
  /// カウントダウンタイマーが0になった際に呼び出される
  Future<void> playTimerCompletionSound() async {
    try {
      await _audioPlayer.play(AssetSource(_timerCompletionSoundPath));
    } catch (error, stackTrace) {
      AppLogger.instance.e('チャイム音の再生に失敗しました', error, stackTrace);
    }
  }
}
