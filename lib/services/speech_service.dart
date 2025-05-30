import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidenceLevel = 0.0;
  double _soundLevel = 0.0;

  // 음성 레벨 콜백 함수
  Function(double)? _soundLevelCallback;

  // Getter들
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidenceLevel => _confidenceLevel;
  double get soundLevel => _soundLevel;

  // 음성 인식 초기화 (웹 최적화)
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        return true;
      }

      print('🎤 음성 인식 초기화 시작...');

      // 웹에서는 더 간단한 초기화
      final available = await _speechToText.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: kDebugMode,
      );

      if (available) {
        _isInitialized = true;
        print('✅ 음성 인식 초기화 성공');

        // 웹에서 사용 가능한 로케일 확인
        if (kIsWeb) {
          try {
            final locales = await _speechToText.locales();
            print('📍 사용 가능한 로케일: ${locales.length}개');
            for (var locale in locales.take(3)) {
              print('  - ${locale.localeId}: ${locale.name}');
            }
          } catch (e) {
            print('⚠️ 로케일 확인 실패: $e');
          }
        }
      } else {
        print('❌ 음성 인식을 사용할 수 없습니다');
      }

      return available;
    } catch (e) {
      print('🚨 음성 인식 초기화 실패: $e');
      return false;
    }
  }

  // 음성 인식 시작 (웹 안정성 최우선)
  Future<void> startListening({
    required Function(String) onResult,
    Function(double)? onSoundLevel,
    String? localeId,
  }) async {
    print('🎯 음성 인식 시작 요청...');

    if (!_isInitialized) {
      print('🔄 초기화되지 않음 - 재초기화 시도');
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('음성 인식을 초기화할 수 없습니다.');
      }
    }

    // 이미 실행 중이면 완전히 정리
    if (_isListening) {
      print('⚠️ 이미 음성인식 실행 중 - 강제 정리');
      await _completeReset();
    }

    // 음성 레벨 콜백 설정
    _soundLevelCallback = onSoundLevel;

    try {
      print('🚀 음성 인식 시작 중...');

      // 웹에서 더 안전한 설정
      final success = await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _confidenceLevel = result.confidence;

          print(
              '💬 인식 결과: "${result.recognizedWords}" (신뢰도: ${(result.confidence * 100).toStringAsFixed(1)}%)');

          // 실시간 결과 전달
          onResult(_lastWords);
        },
        listenFor: const Duration(minutes: 2), // 웹에서는 짧게
        pauseFor: const Duration(seconds: 2), // 웹에서는 짧게
        partialResults: true,
        localeId: localeId ?? 'ko_KR',
        onSoundLevelChange: _handleSoundLevelChange,
        cancelOnError: true, // 웹에서는 에러 시 자동 취소
        listenMode: ListenMode.confirmation,
      );

      if (success) {
        _isListening = true;
        print('✅ 음성 인식 시작 성공');
      } else {
        print('❌ 음성 인식 시작 실패 - listen() 반환값 false');
        throw Exception('음성 인식 세션을 시작할 수 없습니다.');
      }
    } catch (e) {
      print('🚨 음성 인식 시작 실패: $e');
      _isListening = false;
      await _completeReset();

      // 사용자가 이해하기 쉬운 에러 메시지
      String userMessage = '음성 인식을 시작할 수 없습니다';
      if (e.toString().contains('permission')) {
        userMessage = '마이크 권한이 필요합니다. 브라우저에서 마이크 사용을 허용해주세요';
      } else if (e.toString().contains('network')) {
        userMessage = '네트워크 연결을 확인해주세요';
      } else if (e.toString().contains('already started')) {
        userMessage = '잠시 후 다시 시도해주세요';
      }

      throw Exception(userMessage);
    }
  }

  // 음성 인식 중지
  Future<void> stopListening() async {
    if (_isListening) {
      print('🛑 음성 인식 중지...');
      try {
        await _speechToText.stop();
        print('✅ 음성 인식 중지 완료');
      } catch (e) {
        print('⚠️ 음성 인식 중지 중 오류: $e');
      }
      _isListening = false;
    }
  }

  // 음성 인식 취소
  Future<void> cancelListening() async {
    if (_isListening) {
      print('❌ 음성 인식 취소...');
      try {
        await _speechToText.cancel();
        print('✅ 음성 인식 취소 완료');
      } catch (e) {
        print('⚠️ 음성 인식 취소 중 오류: $e');
      }
      _isListening = false;
      _lastWords = '';
      _confidenceLevel = 0.0;
    }
  }

  // 완전한 리셋 (웹 안정성용)
  Future<void> _completeReset() async {
    print('🔄 음성 인식 완전 리셋...');
    try {
      // 모든 종료 방법 시도
      if (_speechToText.isListening) {
        await _speechToText.cancel();
        await Future.delayed(const Duration(milliseconds: 100));
        await _speechToText.stop();
      }

      // 충분한 대기 시간
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      print('⚠️ 리셋 중 오류 (무시됨): $e');
    } finally {
      _isListening = false;
      _lastWords = '';
      _confidenceLevel = 0.0;
      _soundLevel = 0.0;
      print('✅ 리셋 완료');
    }
  }

  // 강제 정리 (웹에서 상태 불일치 해결용)
  Future<void> forceStop() async {
    await _completeReset();
  }

  // 사용 가능한 로케일 목록 조회
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _speechToText.locales();
  }

  // 음성 인식 사용 가능 여부 확인 (개선된 버전)
  Future<bool> isAvailable() async {
    try {
      // 초기화되지 않았으면 초기화 시도
      if (!_isInitialized) {
        final available = await initialize();
        return available && _speechToText.isAvailable;
      }

      // 이미 초기화되어 있으면 바로 확인
      return _speechToText.isAvailable;
    } catch (e) {
      print('🚨 음성 인식 사용 가능 여부 확인 실패: $e');
      return false;
    }
  }

  // 텍스트를 구매 목록으로 파싱 (띄어쓰기 기준으로 분리)
  List<String> parseShoppingItems(String text) {
    if (text.isEmpty) return [];

    // 텍스트 정제
    String cleanedText = text.trim();

    // 특수 문자 제거 및 정제
    cleanedText = cleanedText
        .replaceAll(RegExp(r'[.,!?;:]'), ' ') // 특수 문자를 공백으로 대체
        .replaceAll(RegExp(r'\s+'), ' ') // 연속된 공백을 하나로 합치기
        .trim();

    // 띄어쓰기로 분리
    List<String> items = cleanedText
        .split(' ')
        .where((item) => item.isNotEmpty)
        .map((item) => item.trim())
        .where((item) => item.length > 0)
        .toList();

    // 중복 제거
    return items.toSet().toList();
  }

  // 일반적인 구매 목록 키워드 감지 및 정제
  List<String> enhanceShoppingItems(List<String> items) {
    const Map<String, String> synonyms = {
      // 식품류
      '쌀': '쌀',
      '밥': '쌀',
      '라면': '라면',
      '면': '라면',
      '우유': '우유',
      '물': '물',
      '음료': '음료수',

      // 채소류
      '양파': '양파',
      '당근': '당근',
      '감자': '감자',
      '배추': '배추',
      '상추': '상추',

      // 과일류
      '사과': '사과',
      '바나나': '바나나',
      '오렌지': '오렌지',
      '포도': '포도',

      // 생활용품
      '휴지': '휴지',
      '세제': '세제',
      '샴푸': '샴푸',
      '비누': '비누',
      '치약': '치약',
      '칫솔': '칫솔',
    };

    return items.map((item) {
      String lowerItem = item.toLowerCase();

      // 동의어 변환
      for (String key in synonyms.keys) {
        if (lowerItem.contains(key)) {
          return synonyms[key]!;
        }
      }

      return item;
    }).toList();
  }

  // 에러 핸들링
  void _onError(SpeechRecognitionError error) {
    print('🚨 음성 인식 에러: ${error.errorMsg} (영구: ${error.permanent})');
    _isListening = false;

    // 영구적인 에러면 초기화 상태 리셋
    if (error.permanent) {
      _isInitialized = false;
    }
  }

  // 상태 변경 핸들링
  void _onStatus(String status) {
    print('📊 음성 인식 상태: $status');

    switch (status) {
      case 'listening':
        _isListening = true;
        break;
      case 'notListening':
      case 'done':
        _isListening = false;
        break;
    }
  }

  // 음성 레벨 변경 핸들링
  void _handleSoundLevelChange(double level) {
    _soundLevel = level;

    // 등록된 콜백이 있으면 호출
    if (_soundLevelCallback != null) {
      _soundLevelCallback!(level);
    }
  }

  // 리소스 정리
  void dispose() {
    if (_isListening) {
      stopListening();
    }
  }
}
