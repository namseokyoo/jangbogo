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

      print('음성 인식 초기화 시작...');

      // 웹에서는 사용자 제스처가 필요할 수 있으므로 더 구체적인 초기화
      final available = await _speechToText.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: kDebugMode,
      );

      if (available) {
        _isInitialized = true;
        print('음성 인식 초기화 성공');

        // 웹에서 권한을 미리 요청
        if (kIsWeb) {
          await _requestWebPermission();
        }
      } else {
        print('음성 인식을 사용할 수 없습니다');
      }

      return available;
    } catch (e) {
      print('음성 인식 초기화 실패: $e');
      return false;
    }
  }

  // 웹에서 마이크 권한 명시적 요청
  Future<void> _requestWebPermission() async {
    try {
      if (kIsWeb) {
        // 짧은 테스트 음성 인식을 실행하여 권한을 확실히 요청
        await _speechToText.listen(
          onResult: (result) {
            // 테스트이므로 결과는 무시
          },
          listenFor: const Duration(milliseconds: 100),
          pauseFor: const Duration(milliseconds: 100),
          partialResults: false,
          localeId: 'ko_KR',
        );

        // 즉시 중지
        await Future.delayed(const Duration(milliseconds: 200));
        await _speechToText.stop();

        print('웹 마이크 권한 요청 완료');
      }
    } catch (e) {
      print('웹 권한 요청 중 오류: $e');
    }
  }

  // 음성 인식 시작 (개선된 버전)
  Future<void> startListening({
    required Function(String) onResult,
    Function(double)? onSoundLevel,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('음성 인식을 초기화할 수 없습니다.');
      }
    }

    if (_isListening) {
      await stopListening();
      // 약간의 지연을 둬서 이전 세션이 완전히 종료되도록 함
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // 음성 레벨 콜백 설정
    _soundLevelCallback = onSoundLevel;

    try {
      print('음성 인식 시작...');

      final success = await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _confidenceLevel = result.confidence;

          print(
              '음성 인식 결과: ${result.recognizedWords} (신뢰도: ${result.confidence})');

          if (result.finalResult) {
            onResult(_lastWords);
          } else {
            // 부분 결과도 전달 (실시간 텍스트 표시용)
            onResult(_lastWords);
          }
        },
        listenFor: const Duration(minutes: 5), // 5분으로 조정 (너무 길면 웹에서 문제 발생 가능)
        pauseFor: const Duration(seconds: 3), // 3초로 조정
        partialResults: true,
        localeId: localeId ?? 'ko_KR',
        onSoundLevelChange: _handleSoundLevelChange,
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );

      if (success) {
        _isListening = true;
        print('음성 인식 시작 성공');
      } else {
        print('음성 인식 시작 실패');
        throw Exception('음성 인식을 시작할 수 없습니다.');
      }
    } catch (e) {
      print('음성 인식 시작 실패: $e');
      _isListening = false;
      throw Exception('음성 인식을 시작할 수 없습니다: $e');
    }
  }

  // 음성 인식 중지
  Future<void> stopListening() async {
    if (_isListening) {
      print('음성 인식 중지...');
      await _speechToText.stop();
      _isListening = false;
    }
  }

  // 음성 인식 취소
  Future<void> cancelListening() async {
    if (_isListening) {
      print('음성 인식 취소...');
      await _speechToText.cancel();
      _isListening = false;
      _lastWords = '';
      _confidenceLevel = 0.0;
    }
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
      // 이미 초기화되어 있으면 바로 확인
      if (_isInitialized) {
        return _speechToText.isAvailable;
      }

      // 초기화되지 않았으면 초기화 시도
      final available = await initialize();
      return available && _speechToText.isAvailable;
    } catch (e) {
      print('음성 인식 사용 가능 여부 확인 실패: $e');
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
    print('음성 인식 에러: ${error.errorMsg} (${error.permanent})');
    _isListening = false;
  }

  // 상태 변경 핸들링
  void _onStatus(String status) {
    print('음성 인식 상태: $status');

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
    print('음성 레벨: $level');

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
