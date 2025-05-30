# 장보고왔다 (Jangbogo) 🛒

> 똑똑한 구매 목록 관리 서비스

Flutter로 개발된 현대적이고 직관적인 구매 목록 관리 앱입니다. 음성 입력과 텍스트 입력을 모두 지원하며, 파스텔 컬러의 아름다운 UI로 쇼핑을 더 즐겁게 만들어드립니다.

## ✨ 주요 기능

### 🎤 음성 & 텍스트 입력
- **음성 인식**: 자연스럽게 말하면 자동으로 아이템이 추가됩니다
- **공백 구분**: "사과 바나나 우유"처럼 한 번에 여러 아이템 추가 가능
- **똑똑한 파싱**: 음성을 텍스트로 변환하고 아이템별로 자동 분리

### ✅ 스마트 체크리스트
- **원터치 완료**: 탭 한 번으로 구매 완료/미완료 전환
- **스와이프 삭제**: 좌측으로 밀어서 빠른 삭제
- **시각적 피드백**: 완료된 아이템은 취소선과 회색 처리

### 🔍 강력한 필터링 & 검색
- **상태별 필터**: 전체/구매예정/완료별로 보기
- **기간별 필터**: 오늘/이번주/이번달/올해/전체 기간
- **실시간 검색**: 아이템명, 카테고리, 메모에서 즉시 검색
- **카테고리별 분류**: 식료품, 생활용품 등으로 체계적 관리

### 📊 통계 대시보드
- **실시간 통계**: 할일/완료/전체 개수를 한눈에
- **진행률 확인**: 구매 진행 상황을 시각적으로 표시

### 🎨 아름다운 디자인
- **파스텔 테마**: 눈에 편안한 파스텔 컬러 팔레트
- **매끄러운 애니메이션**: 확장형 플로팅 버튼과 부드러운 전환
- **반응형 레이아웃**: 다양한 화면 크기에 최적화
- **직관적 UX**: 누구나 쉽게 사용할 수 있는 인터페이스

## 🚀 데모

### 라이브 데모
👉 **[https://namseokyoo.github.io/jangbogo](https://namseokyoo.github.io/jangbogo)** (곧 배포 예정)

### 스크린샷
*스크린샷 추가 예정*

## 🛠 기술 스택

- **Framework**: Flutter 3.7+
- **상태관리**: Provider
- **데이터베이스**: 
  - 모바일: SQLite
  - 웹: SharedPreferences + JSON
- **음성인식**: speech_to_text
- **폰트**: Google Fonts (Noto Sans)
- **애니메이션**: flutter_staggered_animations

## 🎯 사용법

### 기본 사용법
1. **아이템 추가**: 오른쪽 하단의 + 버튼 클릭
2. **음성 입력**: 마이크 버튼으로 음성 인식 모드
3. **텍스트 입력**: 키보드 버튼으로 직접 입력
4. **완료 처리**: 아이템 왼쪽 원을 탭하여 완료/미완료 전환
5. **삭제**: 아이템을 왼쪽으로 스와이프

### 고급 기능
- **다중 입력**: "사과 바나나 우유 빵"처럼 공백으로 구분하여 여러 아이템 한번에 추가
- **카테고리 설정**: 아이템별로 카테고리 지정 가능
- **메모 추가**: 각 아이템에 상세 메모 첨부
- **가격 & 수량**: 예산 관리를 위한 가격과 수량 정보

## 🔧 개발자 가이드

### 개발 환경 설정
```bash
# Flutter 설치 확인
flutter --version

# 프로젝트 클론
git clone https://github.com/namseokyoo/jangbogo.git
cd jangbogo

# 의존성 설치
flutter pub get

# 웹에서 실행
flutter run -d chrome

# 모바일에서 실행 (Android)
flutter run

# 웹 빌드
flutter build web
```

### 프로젝트 구조
```
lib/
├── models/           # 데이터 모델
├── services/         # 비즈니스 로직 (데이터베이스, 음성인식)
├── providers/        # 상태 관리
├── screens/          # 화면 위젯
├── widgets/          # 재사용 가능한 위젯
├── utils/           # 유틸리티 (테마, 상수)
└── main.dart        # 앱 진입점
```

## 🤝 기여하기

이 프로젝트에 기여하고 싶으시다면:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 연락처

**개발자**: namseokyoo  
**프로젝트 링크**: [https://github.com/namseokyoo/jangbogo](https://github.com/namseokyoo/jangbogo)

---

*쇼핑이 더 즐거워지는 그 순간, 장보고왔다와 함께하세요! 🛒✨*
