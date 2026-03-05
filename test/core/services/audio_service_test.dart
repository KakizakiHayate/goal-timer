import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/services/audio_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class FakeSource extends Fake implements Source {}

void main() {
  late MockAudioPlayer mockAudioPlayer;
  late AudioService audioService;

  setUpAll(() {
    registerFallbackValue(FakeSource());
  });

  setUp(() {
    mockAudioPlayer = MockAudioPlayer();
    audioService = AudioService(audioPlayer: mockAudioPlayer);
  });

  group('AudioService Tests', () {
    test('T-1.1: playTimerCompletionSound()でAudioPlayer.play()が呼ばれること', () async {
      // Arrange
      when(
        () => mockAudioPlayer.play(any()),
      ).thenAnswer((_) async {});

      // Act
      await audioService.playTimerCompletionSound();

      // Assert
      verify(() => mockAudioPlayer.play(any())).called(1);
    });

    test('T-1.2: 複数回連続呼び出しでエラーなく完了すること', () async {
      // Arrange
      when(
        () => mockAudioPlayer.play(any()),
      ).thenAnswer((_) async {});

      // Act & Assert
      await audioService.playTimerCompletionSound();
      await audioService.playTimerCompletionSound();
      await audioService.playTimerCompletionSound();

      verify(() => mockAudioPlayer.play(any())).called(3);
    });

    test('T-5.2: AudioPlayerがエラーを投げてもクラッシュしないこと', () async {
      // Arrange
      when(
        () => mockAudioPlayer.play(any()),
      ).thenThrow(Exception('Audio playback failed'));

      // Act & Assert - エラーが伝播しないことを確認
      await expectLater(
        audioService.playTimerCompletionSound(),
        completes,
      );
    });
  });
}
