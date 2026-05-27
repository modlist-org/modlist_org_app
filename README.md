# modlist.org Mod Installer

[English](#english) | [한국어](#한국어)

---

## English

A premium, high-fidelity Flutter application designed to manage, browse, and install mods for **A Dance of Fire and Ice (ADOFAI)** and other supported games. It interfaces with the official **modlist.org** API to provide a seamless modding experience.

### Features

#### 1. Mod Loader Management (MelonLoader & UMM)
- **Automatic Loader Setup**: Detects, installs, and updates **MelonLoader** (v0.7.3) automatically.
- **Unity Mod Manager (UMM) Replacement**: Detects existing UMM installations (both Doorstop and Assembly injection modes) and replaces them cleanly with MelonLoader.
- **Automated UMM Mod Migration**: Automatically migrates your existing UMM mods from the `Mods/` directory to the `UMMMods/` directory so they are loaded correctly by the UMM compatibility layer.
- **UMM Compatibility Option**: Prompts users to install the UMM compatibility mod (`ummcompat`) when replacing UMM, ensuring maximum compatibility for older mods.
- **Assembly Patch Cleanup**: Automatically detects and restores original, pristine Unity engine DLLs (e.g., `UnityEngine.CoreModule.dll`, `UnityEngine.dll`) from backups if they were patched/altered by UMM.

#### 2. Mod Exploration & Installation
- **Browse & Search**: Dynamic mod browsing with categories, full-text search, and various sorting options (e.g., download count, updates).
- **One-Click Installation**: Download and extract mods directly into your game directory in one click.
- **Version Select & Beta Testing**: Choose between stable releases and beta versions of mods depending on your preference.

#### 3. Installed Mod Management
- **Status Toggle**: Easily enable or disable individual mods with toggles.
- **Update Checks**: Real-time comparisons between installed versions and the latest versions available on modlist.org.
- **Clean Uninstallation**: Safely delete mods and associated config files.

#### 4. Design & Aesthetics
- **Premium Pastel Dark Mode**: A custom-designed dark theme incorporating harmonious pastel colors, micro-animations, and glassmorphism-inspired elements.
- **Responsive Layout**: Adapts smoothly to various window dimensions on desktop and web builds.
- **Dynamic Fonts**: Dynamically downloads and applies the modern **SUIT** typeface at runtime for consistent, high-end typography on all platforms.

---

### Project Structure

```
lib/
├── main.dart                 # App initialization & dynamic font loading
└── src/
    ├── core/
    │   ├── adofai_game.dart  # ADOFAI platform-specific pathing, backups & DLL restore logic
    │   ├── game.dart         # Abstract game manager and loader detection
    │   ├── installer_state.dart # Core installer logic (MelonLoader installation, UMM migration)
    │   └── localization.dart # English/Korean localization strings
    ├── models/
    │   └── mod_model.dart    # Dart models for mods and version data
    ├── services/
    │   └── api_service.dart  # Integration with the modlist.org API
    └── ui/
        ├── main_layout.dart  # Primary navigation and tab controller
        ├── explore_tab.dart  # Remote mod browser & info cards
        ├── installed_tab.dart# Local loader/mod controls & migration dialogues
        └── settings_tab.dart # Configuration (paths, base URL, language, cache controls)
```

---

### Getting Started

#### Prerequisites
- Flutter SDK (v3.12.0 or higher)
- Dart SDK

#### Run Locally
1. Clone the repository.
2. Retrieve packages:
   ```bash
   flutter pub get
   ```
3. Run the development server or local app:
   ```bash
   flutter run
   ```

#### Build Production Bundle
To build for Windows Desktop:
```bash
flutter build windows
```

To build for Web:
```bash
flutter build web
```

---

### License
This project is licensed under the GNU General Public License v3 (GPL-3.0). See [LICENSE.md](./LICENSE.md) for the full license text.

---

## 한국어

**얼음과 불의 춤 (ADOFAI)** 및 기타 지원되는 게임을 위한 프리미엄 고성능 Flutter 모드 매니저/인스톨러 앱입니다. 공식 **modlist.org** API와 연동하여 편리하고 쾌적한 모딩 경험을 제공합니다.

### 주요 기능

#### 1. 모드 로더 관리 (MelonLoader 및 UMM)
- **로더 자동 설치**: **MelonLoader** (v0.7.3) 버전을 자동으로 감지, 설치 및 업데이트합니다.
- **Unity Mod Manager (UMM) 교체**: 기존 UMM 설치 상태(Doorstop 방식 및 Assembly 인젝션 방식 모두 지원)를 감지하고, MelonLoader로 깔끔하게 교체합니다.
- **자동 UMM 모드 마이그레이션**: MelonLoader 교체 시 기존 `Mods/` 폴더 내 UMM 모드들을 `UMMMods/` 폴더로 자동 마이그레이션하여 UMM 호환 레이어를 통해 정상 구동되도록 돕습니다.
- **UMM 호환성 모드 권장**: UMM 교체 시 UMM 호환성 모드(`ummcompat`)를 함께 설치할 것인지 사용자에게 팝업 다이얼로그를 통해 안내합니다.
- **어셈블리 패치 정리**: UMM에 의해 패치/변조된 오리지널 Unity 엔진 DLL 파일들(예: `UnityEngine.CoreModule.dll`, `UnityEngine.dll`)을 백업본에서 자동으로 찾아 복원합니다.

#### 2. 모드 탐색 및 설치
- **모드 검색 및 카테고리 필터링**: 실시간 검색, 카테고리 필터링, 정렬 기능(다운로드순, 최신순 등)을 지원합니다.
- **원클릭 설치**: API로부터 모드를 다운로드하여 게임 폴더에 즉시 자동 압축 해제 및 배치합니다.
- **버전 선택 및 베타 테스트**: 안정 버전을 설치하거나 필요에 따라 베타 버전을 선택해 테스트해 볼 수 있습니다.

#### 3. 설치된 모드 관리
- **활성화 상태 토글**: 개별 모드를 마우스 클릭 한 번으로 활성화/비활성화 상태로 토글할 수 있습니다.
- **업데이트 검사**: 로컬에 설치된 모드와 modlist.org에 배포된 최신 버전을 비교하여 업데이트 필요 여부를 실시간으로 시각화합니다.
- **안전한 삭제**: 모드 파일 및 개별 설정 정보를 게임 디렉토리에서 깔끔하게 제거합니다.

#### 4. 디자인 및 시각적 요소
- **프리미엄 파스텔 다크 모드**: 감각적인 다크 테마 배경에 세련된 파스텔 톤 포인트 컬러, 미세 애니메이션, 글래스모피즘 스타일 디자인을 적용하였습니다.
- **반응형 레이아웃**: 데스크톱 프로그램 창 크기 조정 및 웹 브라우저 환경에 유연하게 대응합니다.
- **동적 폰트 다운로드**: 앱 실행 시 CDN으로부터 현대적인 **SUIT** 서체를 자동으로 다운로드하여 적용해, 플랫폼을 막론하고 미려한 타이포그래피를 유지합니다.

---

### 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점 및 SUIT 폰트 런타임 다운로드 설정
└── src/
    ├── core/
    │   ├── adofai_game.dart  # 플랫폼별 경로 탐색, 백업 및 DLL 복구 로직
    │   ├── game.dart         # 게임 추상 클래스 및 로더 감지 도구
    │   ├── installer_state.dart # 핵심 설치 상태 관리 (MelonLoader 설치, 폴더 마이그레이션)
    │   └── localization.dart # 영어/한국어 로컬라이제이션 리소스
    ├── models/
    │   └── mod_model.dart    # 모드 및 버전 정보 구조 정의
    ├── services/
    │   └── api_service.dart  # modlist.org API 통신 클라이언트
    └── ui/
        ├── main_layout.dart  # 네비게이션 및 탭 스위처 레이아웃
        ├── explore_tab.dart  # 온라인 모드 브라우저 및 상세 정보 카드
        ├── installed_tab.dart# 로컬 로더/모드 제어 및 마이그레이션 다이얼로그
        └── settings_tab.dart # 경로 설정, API 주소 커스텀, 언어 및 캐시 설정
```

---

### 시작하기

#### 준비 사항
- Flutter SDK (v3.12.0 이상)
- Dart SDK

#### 로컬 실행 방법
1. 저장소를 클론합니다.
2. 종속성 패키지를 로드합니다:
   ```bash
   flutter pub get
   ```
3. 개발 모드로 실행합니다:
   ```bash
   flutter run
   ```

#### 배포용 빌드 방법
Windows 빌드:
```bash
flutter build windows
```

Web 빌드:
```bash
flutter build web
```

---

### 라이선스
본 프로젝트는 GNU General Public License v3 (GPL-3.0) 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE.md](./LICENSE.md) 파일을 참조하십시오.
