class Localization {
  static const Map<String, Map<String, String>> _strings = {
    'ko-KR': {
      // Sidebar
      'tab_explore': '모드 탐색',
      'tab_installed': '설치 관리',
      'tab_cloud_save': '클라우드 백업',
      'tab_settings': '환경 설정',
      'sidebar_games_title': '대상 게임 (GAMES)',
      'sidebar_adofai_active': '얼불춤 (Active)',
      'sidebar_adofai_inactive': '얼불춤',
      'sidebar_adofai_tooltip': 'A Dance of Fire and Ice 모드 매니저가 활성화 상태입니다.',
      'sidebar_dancing-line_active': '댄싱 라인 (Active)',
      'sidebar_dancing-line_inactive': '댄싱 라인',
      'sidebar_dancing-line_tooltip': '댄싱 라인 (Dancing Line) 모드 매니저가 활성화 상태입니다.',
      'sidebar_rhythm-doctor_active': '리듬닥터 (Active)',
      'sidebar_rhythm-doctor_inactive': '리듬닥터',
      'sidebar_rhythm-doctor_tooltip': '리듬닥터 (Rhythm Doctor) 모드 매니저가 활성화 상태입니다.',

      // Settings Tab
      'settings_title': '설정 (SETTINGS)',
      'settings_game_path_title_adofai': '얼불춤 게임 설치 경로 설정',
      'settings_game_path_title_dancing-line': '댄싱 라인 게임 설치 경로 설정',
      'settings_path_empty': '게임 경로가 지정되지 않았습니다. 폴더를 선택해 주세요.',
      'settings_path_invalid_adofai':
          '⚠️ 해당 경로에 게임 실행 파일(A Dance of Fire and Ice)이 존재하지 않습니다.',
      'settings_path_invalid_dancing-line':
          '⚠️ 해당 경로에 게임 실행 파일(Dancing Line)이 존재하지 않습니다.',
      'settings_btn_select_manually': '폴더 수동 선택',
      'settings_btn_auto_detect': '스팀 경로 자동 감지',
      'settings_api_title': 'modlist.org API 서버 연동',
      'settings_btn_save': '저장',
      'settings_api_guide':
          '기본값은 https://modlist.org 이며 로컬 테스트 시 http://localhost:3000 으로 변경 가능합니다.',
      'settings_sys_title': '시스템 정보',
      'settings_sys_os': '운영체제(OS)',
      'settings_sys_ver': '프로그램 버전',
      'settings_sys_loader': '로더 타입',
      'settings_lang_title': '언어 설정 (Language)',
      'settings_api_saved': 'API URL 설정이 저장되었습니다.',
      'settings_path_detected_adofai': '얼불춤 스팀 기본 경로를 자동으로 설정했습니다.',
      'settings_path_detected_dancing-line': '댄싱 라인 스팀 기본 경로를 자동으로 설정했습니다.',
      'settings_path_detected_rhythm-doctor': '리듬닥터 스팀 기본 경로를 자동으로 설정했습니다.',
      'settings_path_not_found_adofai':
          '스팀 기본 경로에서 얼불춤 설치 폴더를 찾을 수 없습니다. 수동으로 선택해 주세요.',
      'settings_path_not_found_dancing-line':
          '스팀 기본 경로에서 댄싱 라인 설치 폴더를 찾을 수 없습니다. 수동으로 선택해 주세요.',
      'settings_path_not_found_rhythm-doctor':
          '스팀 기본 경로에서 리듬닥터 설치 폴더를 찾을 수 없습니다. 수동으로 선택해 주세요.',
      'settings_game_path_title_rhythm-doctor': '리듬닥터 게임 설치 경로 설정',
      'settings_path_invalid_rhythm-doctor':
          '⚠️ 해당 경로에 게임 실행 파일(Rhythm Doctor)이 존재하지 않습니다.',

      // Installed Tab
      'installed_title': '설치 관리 (INSTALLED)',
      'installed_loader_title': 'MelonLoader 관리',
      'installed_loader_active': 'MelonLoader가 활성화되어 있습니다. (v{version})',
      'installed_loader_inactive': 'MelonLoader가 설치되어 있지 않습니다.',
      'installed_loader_outdated_title': '구버전 MelonLoader가 감지되었습니다.',
      'installed_loader_umm_title': 'Unity Mod Manager(UMM)가 감지되었습니다.',
      'installed_btn_update_loader': 'v{version}로 업데이트',
      'installed_btn_uninstall': '제거 (Uninstall)',
      'installed_btn_replace_loader': 'MelonLoader로 교체 설치',
      'installed_btn_install': '설치 (Install)',
      'installed_loader_outdated_banner':
          '현재 감지된 MelonLoader 버전은 {version} 입니다.\n구버전 또는 외부에서 설치된 모드로더는 오류를 유발할 수 있으므로 최신 v{targetVersion}로 업데이트해 주세요.',
      'installed_umm_banner':
          '현재 게임 폴더 내에 Unity Mod Manager(UMM)가 설치되어 있는 것이 확인되었습니다.\nmodlist.org 앱의 모드들을 완벽히 연동(설치/삭제/업데이트)하려면 MelonLoader가 필수적입니다.\n위의 [MelonLoader로 교체 설치] 버튼을 누르면 기존 UMM을 지우고 MelonLoader 설치를 자동으로 진행합니다.',
      'replace_umm_dialog_title': 'Unity Mod Manager 교체 및 모드 이관',
      'replace_umm_dialog_body':
          '기존 Mods 폴더에 있는 UMM 모드들을 UMMMods 폴더로 안전하게 이관합니다.\n\n또한, 이관된 UMM 모드들이 MelonLoader에서 정상적으로 작동하도록 UMM 호환 모드(ummcompat)를 추가로 설치하시겠습니까?',
      'replace_umm_dialog_btn_yes': '예 (호환 모드 설치)',
      'replace_umm_dialog_btn_no': '아니오 (호환 모드 미설치)',
      'replace_umm_dialog_btn_cancel': '취소',
      'install_ummcompat_dialog_title': 'UMM 호환 모드 설치 권장',
      'install_ummcompat_dialog_body':
          '방금 설치한 UMM 모드가 MelonLoader에서 정상적으로 작동하려면 UMM 호환 모드(ummcompat)가 필요합니다.\n\n지금 UMM 호환 모드(ummcompat)를 추가로 설치하시겠습니까?',
      'delete_confirm_dialog_title': '모드 삭제',
      'delete_confirm_dialog_body': '{name} 모드를 정말로 삭제하시겠습니까?',
      'delete_confirm_dialog_btn_yes': '삭제',
      'delete_confirm_dialog_btn_no': '취소',
      'loader_uninstall_confirm_title': 'MelonLoader 제거',
      'loader_uninstall_confirm_body': 'MelonLoader를 정말로 제거하시겠습니까?\n제거 시 모드로더와 관련된 시스템 파일만 삭제되며, 설치한 모드 파일들은 Mods 폴더 내에 그대로 유지됩니다.',
      'installed_list_title': '설치된 모드 목록',
      'installed_btn_add_mod_manually': '파일에서 모드 설치',
      'installed_no_mods': '설치된 모드가 없습니다.',
      'installed_ver_prefix': '설치 버전: v{version}',
      'installed_latest_ver_prefix': '최신 버전: v{version}',
      'installed_game_ver_prefix': '지원 게임: {version}',
      'installed_btn_update_mod': '업데이트',
      'installed_btn_delete_mod': '삭제',
      'installed_copied_clipboard': '클립보드에 복사되었습니다.',
      'installed_err_file_picker': '파일 선택 중 오류가 발생했습니다: {error}',
      'installed_launch_guide_title': '💡 비윈도우 OS 추가 안내 사항',
      'installed_launch_auto_set': '✓ 스팀 실행 옵션이 자동으로 설정되었습니다.',
      'installed_launch_auto_set_restart':
          '변경 사항을 적용하려면 스팀을 완전히 종료한 후 다시 실행하세요.',
      'installed_btn_copy_native_launch': '네이티브 시작 옵션 복사',
      'installed_btn_copy_proton_launch': 'Proton 시작 옵션 복사',
      'settings_btn_check_updates': '업데이트 확인',
      'installed_steamlaunchoptionsguide_adofai_linux':
        '1) 리눅스 네이티브 실행 시 스팀 실행 옵션에 아래 스크립트를 입력하세요:\n'
        './setup_helper.sh %command%\n\n'
        '2) Steam Proton(윈도우 버전) 실행 시 아래 스크립트를 입력하세요:\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_adofai_macos':
        'macOS 네이티브 실행 시 아래 스팀 시작 옵션을 입력하세요 — 복사 버튼을 사용하세요'
        '(Steam은 macOS에서 상대 경로를 인식하지 못하므로 반드시 절대 경로여야 합니다):\n'
        '"<게임 폴더>/setup_helper.sh" %command%\n\n'
        'Modlist는 현재 Mac에 맞는 MelonLoader macOS 배포본을 설치합니다. Apple Silicon에서 x64 배포본을 설치한 경우 이 스크립트가 Rosetta로 게임을 실행합니다.\n\n'
        '* 게이트키퍼(보안) 경고 발생 시 터미널을 열고 게임 폴더로 이동하여 아래 명령어를 입력해 주세요:\n'
        'xattr -dr com.apple.quarantine setup_helper.sh MelonLoader.Bootstrap.dylib MelonLoader/',
      'installed_steamlaunchoptionsguide_rd_linux':
        '1) 리눅스 네이티브 실행 시 스팀 실행 옵션에 아래 스크립트를 입력하세요:\n'
        './setup_helper.sh %command%\n\n'
        '2) Steam Proton(윈도우 버전) 실행 시 아래 스크립트를 입력하세요:\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_rd_macos':
        'macOS 네이티브 실행 시 아래 스팀 시작 옵션을 입력하세요 — 복사 버튼을 사용하세요'
        '(Steam은 macOS에서 상대 경로를 인식하지 못하므로 반드시 절대 경로여야 합니다):\n'
        '"<게임 폴더>/setup_helper.sh" %command%\n\n'
        'Modlist는 현재 Mac에 맞는 MelonLoader macOS 배포본을 설치합니다. Apple Silicon에서 x64 배포본을 설치한 경우 이 스크립트가 Rosetta로 게임을 실행합니다.\n\n'
        '* 게이트키퍼(보안) 경고 발생 시 터미널을 열고 게임 폴더로 이동하여 아래 명령어를 입력해 주세요:\n'
        'xattr -dr com.apple.quarantine setup_helper.sh MelonLoader.Bootstrap.dylib MelonLoader/',
      'installed_steamlaunchoptionsguide_dl_linux':
        'Steam Proton(윈도우 버전) 실행 시 시작 옵션에 아래 스크립트를 입력하세요:\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_dl_macos':
        'macOS 네이티브 실행 시 아래 스팀 시작 옵션을 입력하세요 — 복사 버튼을 사용하세요'
        '(Steam은 macOS에서 상대 경로를 인식하지 못하므로 반드시 절대 경로여야 합니다):\n'
        '"<게임 폴더>/setup_helper.sh" %command%\n\n'
        'Modlist는 현재 Mac에 맞는 MelonLoader macOS 배포본을 설치합니다. Apple Silicon에서 x64 배포본을 설치한 경우 이 스크립트가 Rosetta로 게임을 실행합니다.\n\n'
        '* 게이트키퍼(보안) 경고 발생 시 터미널을 열고 게임 폴더로 이동하여 아래 명령어를 입력해 주세요:\n'
        'xattr -dr com.apple.quarantine setup_helper.sh MelonLoader.Bootstrap.dylib MelonLoader/',

      // Explore Tab
      'explore_filter_category': '카테고리',
      'explore_filter_category_all': '전체 카테고리',
      'category_ui': 'UI',
      'category_gameplay': '게임플레이',
      'category_utility': '유틸리티',
      'category_visuals': '비주얼',
      'category_library': '라이브러리',
      'explore_filter_sort': '정렬 기준',
      'explore_filter_sort_downloads': '다운로드 많은 순',
      'explore_filter_sort_downloads_asc': '다운로드 적은 순',
      'explore_filter_sort_updated': '최근 업데이트 순',
      'explore_filter_sort_created': '최근 등록 순',
      'explore_filter_sort_name': '이름순 (A-Z)',
      'explore_filter_sort_name_desc': '이름순 (Z-A)',
      'explore_search_placeholder': '모드 이름 또는 설명 검색...',
      'explore_no_mods_found': '조건에 맞는 모드를 찾을 수 없습니다.',
      'explore_badge_update_req': '업데이트 필요',
      'explore_badge_installed': '설치 완료',
      'explore_card_featured': '추천',
      'explore_modal_categories': '카테고리',
      'explore_modal_downloads': '다운로드 수',
      'explore_modal_author': '제작자',
      'explore_modal_collaborators': '협업자',
      'explore_modal_latest_ver': '최신 버전',
      'explore_modal_game_ver': '권장 게임 버전',
      'explore_modal_downloads_unit': '{count}회',
      'explore_modal_err_title': '오류',
      'explore_modal_err_body': '모드 상세 정보를 불러올 수 없습니다.',
      'explore_modal_btn_close': '닫기',
      'explore_modal_btn_delete': '모드 삭제',
      'explore_modal_btn_install': '모드 설치 (Install)',
      'explore_modal_warn_path': '⚠️ 설정 탭에서 올바른 게임 설치 경로를 먼저 지정해 주세요.',
      'explore_modal_warn_loader': '모드를 설치하려면 먼저 MelonLoader 설치가 필요합니다.',
      'explore_modal_btn_auto_loader': 'MelonLoader 자동 설치',
      'explore_modal_loading': '처리 중...',
      "explore_modal_expand": "펼치기",
      'explore_card_author_more': ' 외',
      'game_adofai': '얼불춤 (ADOFAI)',
      'game_dancing_line': '댄싱 라인 (Dancing Line)',
      'game_rhythm_doctor': '리듬닥터 (Rhythm Doctor)',
      'explore_modal_beta': '베타',
      'update_dialog_title': '새로운 버전 업데이트 안내',
      'update_dialog_body':
          '새로운 버전 {version}이 출시되었습니다!\n\n현재 버전: v{currentVersion}\n\n최신 버전을 다운로드하고 설치하시겠습니까?',
      'update_dialog_btn_yes': '업데이트 받기',
      'update_dialog_btn_no': '나중에 하기',
      'update_status_latest': '최신 버전을 사용 중입니다.',
      'update_status_error': '업데이트 정보를 가져오는 동안 오류가 발생했습니다.',
      'mod_update_toast_title': '{count}개의 모드에 새로운 업데이트가 있습니다.',
      'mod_update_toast_action': '이동',
      'explore_err_load_failed': '모드 데이터를 불러오는 데 실패했습니다: {error}',

      // Status messages
      'status_loader_downloading': 'MelonLoader 다운로드 중...',
      'status_loader_migrating_umm': '기존 UMM 모드를 UMMMods 폴더로 이동 중...',
      'status_loader_installing': 'MelonLoader 다운로드 중: {progress}%',
      'status_loader_extracting': 'MelonLoader 압축 해제 중...',
      'status_loader_configuring': 'MelonLoader 실행 파일 구성 중...',
      'status_loader_finalizing': 'MelonLoader 설치 마무리 중...',
      'status_loader_checking_ummcompat': 'UMM 호환 모드(ummcompat) 정보 확인 중...',
      'status_loader_install_success_with_ummcompat': 'MelonLoader 및 UMM 호환 모드 설치 성공!',
      'status_loader_install_success_fail_ummcompat': 'MelonLoader 설치 성공 (호환 모드 설치 실패: {error})',
      'status_loader_install_success': 'MelonLoader 설치 성공!',
      'status_loader_install_failed': 'MelonLoader 설치 실패: {error}',
      'status_loader_uninstalling': 'MelonLoader 제거 중...',
      'status_loader_uninstall_success': 'MelonLoader가 성공적으로 제거되었습니다.',
      'status_loader_uninstall_failed': 'MelonLoader 제거 실패: {error}',
      'status_mod_downloading': '{name} 다운로드 중...',
      'status_mod_downloading_progress': '{name} 다운로드 중: {progress}%',
      'status_mod_preparing': '{name} 다운로드 준비 중...',
      'status_mod_resolving_dependency': '의존성 모드 {dependency} 해결 중...',
      'status_mod_install_success': '{name} 설치 성공!',
      'status_mod_install_failed': '{name} 설치 실패: {error}',
      'status_mod_local_installing': '로컬 모드 설치 중...',
      'status_mod_local_install_success': '모드가 성공적으로 수동 설치되었습니다!',
      'status_mod_local_install_failed': '모드 수동 설치 실패: {error}',
      'status_mod_deleting': '{name} 삭제 중...',
      'status_mod_delete_success': '{name} 삭제 성공!',
      'status_mod_delete_failed': '{name} 삭제 실패: {error}',
      'status_ummcompat_checking': 'UMM 호환 모드(ummcompat) 정보 확인 중...',
      'status_ummcompat_success': 'UMM 호환 모드 설치 성공!',
      'status_ummcompat_failed': 'UMM 호환 모드 설치 실패: {error}',
      'status_mod_enabling': '{name} 활성화 중...',
      'status_mod_disabling': '{name} 비활성화 중...',
      'status_mod_enable_success': '{name} 활성화 성공!',
      'status_mod_disable_success': '{name} 비활성화 성공!',
      'status_mod_toggle_failed': '{name} 상태 변경 실패: {error}',
      'settings_token_title': '앱 연동 토큰 (Premium)',
      'settings_token_hint': '프로필 페이지에서 복사한 토큰을 입력하세요.',
      'settings_token_saved': '앱 연동 토큰이 저장되었습니다.',
      'settings_token_guide': '토큰은 modlist.org 웹사이트 프로필 탭에서 생성 및 복사할 수 있습니다.',
      'settings_cloud_title': '클라우드 백업 (Premium)',
      'settings_cloud_desc': 'UserData 폴더 및 UMM 모드 설정을 클라우드에 백업합니다. (실행파일/에셋/100MB 이상 제외)',
      'settings_cloud_btn_backup': '지금 백업',
      'settings_cloud_btn_restore': '복원',
      'settings_cloud_btn_delete': '삭제',
      'settings_cloud_used': '사용 용량: {used} / {max}',
      'settings_cloud_no_backup': '클라우드에 백업된 세이브 파일이 없습니다.',
      'cloud_link_title': '계정 연동 필요',
      'cloud_btn_link': 'Modlist 계정 연동하기',
      'cloud_link_guide': '버튼을 클릭하면 웹 브라우저가 열립니다.\n로그인한 후, 웹사이트에서 "Link Desktop App"을 클릭해 즉시 연결해 주세요.',
      'cloud_connected_account': '연동된 계정',
      'cloud_btn_disconnect': '연동 해제',
      'cloud_premium_desc': '모드리스트 프리미엄 멤버십',
      'cloud_premium_sub': '프리미엄 멤버십을 활성화하여 다양한 고급 기능을 만나보세요.',
      'cloud_benefit_1_title': '클라우드 세이브 동기화 (10 GB)',
      'cloud_benefit_1_desc': '게임 설정 및 세이브 파일을 클라우드에 백업하고 복원할 수 있습니다. 개별 파일 최대 100MB까지 대용량 파일 지원.',
      'cloud_benefit_2_title': '모드 프리셋 공유',
      'cloud_benefit_2_desc': '현재 사용 중인 모드와 버전 정보를 프리셋 링크로 저장해 친구들과 공유하고 즉시 동기화하세요.',
      'cloud_patreon_cta_text': '아직 프리미엄 멤버가 아니신가요?',
      'cloud_patreon_btn': 'Patreon에서 후원 및 멤버십 가입하기 (월 \$1)',
      'settings_preset_title': '모드 프리셋 공유 (Premium)',
      'settings_preset_btn_share': '현재 모드 프리셋 공유 링크 생성',
      'settings_preset_created_title': '프리셋 링크 생성 완료',
      'settings_preset_created_body': '모드 목록 프리셋 링크가 클립보드에 복사되었습니다. 다른 유저에게 공유하세요!',
      'settings_preset_sync_title': '공유 프리셋 동기화',
      'settings_preset_sync_body': '공유된 프리셋 모드 목록을 확인하고 동기화하시겠습니까? 누락된 모드는 자동으로 다운로드 및 설치를 진행하며, 활성화 여부도 프리셋에 맞춰 동기화됩니다.',
      'status_cloud_backup_start': '클라우드 백업 파일 압축 및 생성 중...',
      'status_cloud_backup_progress': '클라우드 백업 진행 중: {progress}%',
      'status_cloud_backup_success': '클라우드 백업 성공!',
      'status_cloud_backup_failed': '클라우드 백업 실패: {error}',
      'status_cloud_restore_start': '클라우드 복원 다운로드 중...',
      'status_cloud_restore_progress': '클라우드 복원 진행 중: {progress}%',
      'status_cloud_restore_success': '클라우드 세이브 복원 완료!',
      'status_cloud_restore_failed': '클라우드 복원 실패: {error}',
      'status_cloud_delete_start': '클라우드 백업 삭제 중...',
      'status_cloud_delete_success': '클라우드 백업이 삭제되었습니다.',
      'status_cloud_delete_failed': '클라우드 백업 삭제 실패: {error}',
      'cloud_backups_title': '클라우드 백업',
      'preset_attach_saves_title': '백업 파일(UserData) 첨부 선택',
      'preset_attach_saves_body': '이 프리셋에 최근 클라우드 백업 세이브/설정 파일도 함께 첨부하여 공유하시겠습니까? 다른 사용자가 모드와 함께 이 설정도 다운로드하여 동기화할 수 있게 됩니다.',
      'preset_attach_saves_yes': '예, 백업 첨부하여 공유',
      'preset_attach_saves_no': '아니오, 모드만 공유',
      'preset_sync_saves_title': '세이브/설정 파일 복원 선택',
      'preset_sync_saves_body': '이 프리셋에 세이브 및 설정 파일(UserData)이 포함되어 있습니다. 로컬 게임 폴더에 다운로드하여 적용하시겠습니까?\n\n경고: 적용 시 기존 로컬 세이브 및 설정이 덮어쓰여 교체됩니다.',
      'preset_sync_saves_yes': '예, 적용하기 (덮어쓰기)',
      'preset_sync_saves_no': '아니오, 모드만 설치',
      'cloud_presets_title': '내가 공유한 프리셋',
      'cloud_presets_empty': '공유한 프리셋이 없습니다.',
      'cloud_presets_copy_link': '링크 복사',
      'cloud_presets_delete_confirm': '정말 이 프리셋을 삭제하시겠습니까?',
      'btn_cancel': '취소',
      'backup_badge_sharing': '프리셋 공유 중',
      'backup_delete_warning_normal': '정말 이 클라우드 백업을 삭제하시겠습니까?',
      'backup_delete_warning_attached': '이 백업은 현재 공유 중인 프리셋에 복사되어 사용 중입니다. 백업을 삭제하더라도 공유된 프리셋의 세이브 파일은 안전하게 유지됩니다.\n\n정말 이 클라우드 백업을 삭제하시겠습니까?',
      'btn_delete_confirm': '삭제하기',
    },
    'en-US': {
      // Sidebar
      'tab_explore': 'Explore',
      'tab_installed': 'Installed',
      'tab_cloud_save': 'Cloud Backup',
      'tab_settings': 'Settings',
      'sidebar_games_title': 'TARGET GAMES',
      'sidebar_adofai_active': 'ADOFAI (Active)',
      'sidebar_adofai_inactive': 'ADOFAI',
      'sidebar_adofai_tooltip':
          'A Dance of Fire and Ice mod manager is active.',
      'sidebar_dancing-line_active': 'Dancing Line (Active)',
      'sidebar_dancing-line_inactive': 'Dancing Line',
      'sidebar_dancing-line_tooltip': 'Dancing Line mod manager is active.',
      'sidebar_rhythm-doctor_active': 'Rhythm Doctor (Active)',
      'sidebar_rhythm-doctor_inactive': 'Rhythm Doctor',
      'sidebar_rhythm-doctor_tooltip': 'Rhythm Doctor mod manager is active.',

      // Settings Tab
      'settings_title': 'Settings',
      'settings_game_path_title_adofai': 'ADOFAI Game Directory Settings',
      'settings_game_path_title_dancing-line': 'Dancing Line Game Directory Settings',
      'settings_path_empty':
          'Game directory is not specified. Please select a folder.',
      'settings_path_invalid_adofai':
          '⚠️ Game executable (A Dance of Fire and Ice) does not exist in this directory.',
      'settings_path_invalid_dancing-line':
          '⚠️ Game executable (Dancing Line) does not exist in this directory.',
      'settings_btn_select_manually': 'Select Folder Manually',
      'settings_btn_auto_detect': 'Auto-Detect Steam Path',
      'settings_api_title': 'modlist.org API Connection',
      'settings_btn_save': 'Save',
      'settings_api_guide':
          'Default is https://modlist.org. Can be changed to http://localhost:3000 for local testing.',
      'settings_sys_title': 'System Info',
      'settings_sys_os': 'Operating System (OS)',
      'settings_sys_ver': 'Program Version',
      'settings_sys_loader': 'Loader Type',
      'settings_lang_title': 'Language Setting',
      'settings_api_saved': 'API URL setting saved successfully.',
      'settings_path_detected_adofai':
          'ADOFAI default Steam directory set automatically.',
      'settings_path_detected_dancing-line':
          'Dancing Line default Steam directory set automatically.',
      'settings_path_detected_rhythm-doctor':
          'Rhythm Doctor default Steam directory set automatically.',
      'settings_path_not_found_adofai':
          'Cannot find ADOFAI installation directory in default Steam path. Please select manually.',
      'settings_path_not_found_dancing-line':
          'Cannot find Dancing Line installation directory in default Steam path. Please select manually.',
      'settings_path_not_found_rhythm-doctor':
          'Cannot find Rhythm Doctor installation directory in default Steam path. Please select manually.',
      'settings_game_path_title_rhythm-doctor': 'Rhythm Doctor Game Directory Settings',
      'settings_path_invalid_rhythm-doctor':
          '⚠️ Game executable (Rhythm Doctor) does not exist in this directory.',

      // Installed Tab
      'installed_title': 'Installed Mods',
      'installed_loader_title': 'MelonLoader Management',
      'installed_loader_active': 'MelonLoader is active. (v{version})',
      'installed_loader_inactive': 'MelonLoader is not installed.',
      'installed_loader_outdated_title': 'Outdated MelonLoader detected.',
      'installed_loader_umm_title': 'Unity Mod Manager (UMM) detected.',
      'installed_btn_update_loader': 'Update to v{version}',
      'installed_btn_uninstall': 'Uninstall',
      'installed_btn_replace_loader': 'Replace with MelonLoader',
      'installed_btn_install': 'Install',
      'installed_loader_outdated_banner':
          'Currently detected MelonLoader version is {version}.\nUsing outdated or external mod loaders may cause errors. Please update to the latest v{targetVersion}.',
      'installed_umm_banner':
          'Unity Mod Manager (UMM) has been detected in the game folder.\nMelonLoader is required to seamlessly manage (install/delete/update) mods via modlist.org.\nClicking [Replace with MelonLoader] will wipe UMM and automatically set up MelonLoader.',
      'replace_umm_dialog_title': 'Replace Unity Mod Manager & Migrate Mods',
      'replace_umm_dialog_body':
          'We will safely migrate the UMM mods in the existing Mods folder to the UMMMods folder.\n\nIn addition, would you like to install the UMM compatibility mod (ummcompat) so that the migrated UMM mods work properly under MelonLoader?',
      'replace_umm_dialog_btn_yes': 'Yes (Install Compatibility Mod)',
      'replace_umm_dialog_btn_no': 'No (Do Not Install)',
      'replace_umm_dialog_btn_cancel': 'Cancel',
      'install_ummcompat_dialog_title': 'Recommend UMM Compatibility Mod',
      'install_ummcompat_dialog_body':
          'The UMM mod you just installed requires the UMM compatibility mod (ummcompat) to work properly under MelonLoader.\n\nWould you like to install the UMM compatibility mod (ummcompat) now?',
      'delete_confirm_dialog_title': 'Delete Mod',
      'delete_confirm_dialog_body': 'Are you sure you want to delete the mod {name}?',
      'delete_confirm_dialog_btn_yes': 'Delete',
      'delete_confirm_dialog_btn_no': 'Cancel',
      'loader_uninstall_confirm_title': 'Uninstall MelonLoader',
      'loader_uninstall_confirm_body': 'Are you sure you want to uninstall MelonLoader?\nThis will only remove the mod loader files. Your installed mod files inside the Mods folder will remain intact.',
      'installed_list_title': 'Installed Mods List',
      'installed_btn_add_mod_manually': 'Install Mod from File',
      'installed_no_mods': 'No installed mods.',
      'installed_ver_prefix': 'Installed: v{version}',
      'installed_latest_ver_prefix': 'Latest: v{version}',
      'installed_game_ver_prefix': 'Req. Game: {version}',
      'installed_btn_update_mod': 'Update',
      'installed_btn_delete_mod': 'Delete',
      'installed_copied_clipboard': 'Copied to clipboard.',
      'installed_err_file_picker': 'An error occurred while picking file: {error}',
      'installed_launch_guide_title': '💡 Additional Guide for Non-Windows OS',
      'installed_launch_auto_set':
          '✓ Steam launch options were configured automatically.',
      'installed_launch_auto_set_restart':
          'Fully quit and reopen Steam for the change to take effect.',
      'installed_btn_copy_native_launch': 'Copy Native Launch Options',
      'installed_btn_copy_proton_launch': 'Copy Proton Launch Options',
      'settings_btn_check_updates': 'Check for Updates',

      // Explore Tab
      'explore_filter_category': 'Category',
      'explore_filter_category_all': 'All Categories',
      'category_ui': 'UI',
      'category_gameplay': 'Gameplay',
      'category_utility': 'Utility',
      'category_visuals': 'Visuals',
      'category_library': 'Library',
      'explore_filter_sort': 'Sort By',
      'explore_filter_sort_downloads': 'Most Downloaded',
      'explore_filter_sort_downloads_asc': 'Least Downloaded',
      'explore_filter_sort_updated': 'Recently Updated',
      'explore_filter_sort_created': 'Recently Added',
      'explore_filter_sort_name': 'Name (A-Z)',
      'explore_filter_sort_name_desc': 'Name (Z-A)',
      'explore_search_placeholder': 'Search mod name or description...',
      'explore_no_mods_found': 'No matching mods found.',
      'explore_badge_update_req': 'Update Req.',
      'explore_badge_installed': 'Installed',
      'explore_card_featured': 'Featured',
      'explore_modal_categories': 'Category',
      'explore_modal_downloads': 'Downloads',
      'explore_modal_author': 'Author',
      'explore_modal_collaborators': 'Collaborators',
      'explore_modal_latest_ver': 'Latest Version',
      'explore_modal_game_ver': 'Req. Game Ver.',
      'explore_modal_downloads_unit': '{count} times',
      'explore_modal_err_title': 'Error',
      'explore_modal_err_body': 'Could not load mod details.',
      'explore_modal_btn_close': 'Close',
      'explore_modal_btn_delete': 'Delete Mod',
      'explore_modal_btn_install': 'Install Mod',
      'explore_modal_warn_path':
          '⚠️ Please set a valid game path in the settings tab first.',
      'explore_modal_warn_loader':
          'MelonLoader installation is required first to install mods.',
      'explore_modal_btn_auto_loader': 'Auto-Install MelonLoader',
      'explore_modal_loading': 'Processing...',
      "explore_modal_expand": "Expend",
      'explore_card_author_more': ' and more',
      'game_adofai': 'ADOFAI',
      'game_dancing_line': 'Dancing Line',
      'game_rhythm_doctor': 'Rhythm Doctor',
      'explore_modal_beta': 'Beta',
      'update_dialog_title': 'New Update Available',
      'update_dialog_body':
          'A new version v{version} is available!\n\nCurrent version: v{currentVersion}\n\nWould you like to download and install the update now?',
      'update_dialog_btn_yes': 'Update Now',
      'update_dialog_btn_no': 'Later',
      'update_status_latest': 'You are already running the latest version.',
      'update_status_error':
          'An error occurred while fetching update information.',
      'mod_update_toast_title': 'New updates are available for {count} mods.',
      'mod_update_toast_action': 'View',
      'explore_err_load_failed': 'Failed to load mod data: {error}',
      'installed_steamlaunchoptionsguide_adofai_linux':
        '1) For native Linux, enter the following launch option in Steam:\n'
        './setup_helper.sh %command%\n\n'
        '2) For Steam Proton (Windows version), enter the following launch option:\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_adofai_macos':
        'For native macOS, set the Steam launch option below — use the Copy button '
        '(the path must be absolute; Steam on macOS ignores relative paths):\n'
        '"<game folder>/setup_helper.sh" %command%\n\n'
        'Modlist installs the MelonLoader macOS archive that matches this Mac. If an x64 archive is installed on Apple Silicon, this script launches the game through Rosetta.\n\n'
        '* If a Gatekeeper security warning appears, open Terminal, navigate to the game folder, and run:\n'
        'xattr -dr com.apple.quarantine setup_helper.sh MelonLoader.Bootstrap.dylib MelonLoader/',
      'installed_steamlaunchoptionsguide_rd_linux':
        '1) For native Linux, enter the following launch option in Steam:\n'
        './setup_helper.sh %command%\n\n'
        '2) For Steam Proton (Windows version), enter the following launch option:\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_rd_macos':
        'For native macOS, set the Steam launch option below — use the Copy button '
        '(the path must be absolute; Steam on macOS ignores relative paths):\n'
        '"<game folder>/setup_helper.sh" %command%\n\n'
        'Modlist installs the MelonLoader macOS archive that matches this Mac. If an x64 archive is installed on Apple Silicon, this script launches the game through Rosetta.\n\n'
        '* If a Gatekeeper security warning appears, open Terminal, navigate to the game folder, and run:\n'
        'xattr -dr com.apple.quarantine setup_helper.sh MelonLoader.Bootstrap.dylib MelonLoader/',
      'installed_steamlaunchoptionsguide_dl_linux':
        'For Steam Proton (Windows version), enter the following launch option:\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_dl_macos':
        'For native macOS, set the Steam launch option below — use the Copy button '
        '(the path must be absolute; Steam on macOS ignores relative paths):\n'
        '"<game folder>/setup_helper.sh" %command%\n\n'
        'Modlist installs the MelonLoader macOS archive that matches this Mac. If an x64 archive is installed on Apple Silicon, this script launches the game through Rosetta.\n\n'
        '* If a Gatekeeper security warning appears, open Terminal, navigate to the game folder, and run:\n'
        'xattr -dr com.apple.quarantine setup_helper.sh MelonLoader.Bootstrap.dylib MelonLoader/',

      // Status messages
      'status_loader_downloading': 'Downloading MelonLoader...',
      'status_loader_migrating_umm': 'Migrating existing UMM mods to UMMMods folder...',
      'status_loader_installing': 'Downloading MelonLoader: {progress}%',
      'status_loader_extracting': 'Extracting MelonLoader...',
      'status_loader_configuring': 'Configuring MelonLoader files...',
      'status_loader_finalizing': 'Finishing MelonLoader installation...',
      'status_loader_checking_ummcompat': 'Checking UMM compatibility mod (ummcompat) info...',
      'status_loader_install_success_with_ummcompat': 'MelonLoader and UMM compatibility mod installed successfully!',
      'status_loader_install_success_fail_ummcompat': 'MelonLoader installed successfully (Compatibility mod installation failed: {error})',
      'status_loader_install_success': 'MelonLoader installed successfully!',
      'status_loader_install_failed': 'MelonLoader installation failed: {error}',
      'status_loader_uninstalling': 'Uninstalling MelonLoader...',
      'status_loader_uninstall_success': 'MelonLoader has been uninstalled successfully.',
      'status_loader_uninstall_failed': 'MelonLoader uninstallation failed: {error}',
      'status_mod_downloading': 'Downloading {name}...',
      'status_mod_downloading_progress': 'Downloading {name}: {progress}%',
      'status_mod_preparing': 'Preparing to download {name}...',
      'status_mod_resolving_dependency': 'Resolving dependency: {dependency}...',
      'status_mod_install_success': 'Installed {name} successfully!',
      'status_mod_install_failed': 'Failed to install {name}: {error}',
      'status_mod_local_installing': 'Installing local mod...',
      'status_mod_local_install_success': 'Mod has been manually installed successfully!',
      'status_mod_local_install_failed': 'Failed to manually install mod: {error}',
      'status_mod_deleting': 'Deleting {name}...',
      'status_mod_delete_success': 'Deleted {name} successfully!',
      'status_mod_delete_failed': 'Failed to delete {name}: {error}',
      'status_ummcompat_checking': 'Checking UMM compatibility mod (ummcompat) info...',
      'status_ummcompat_success': 'UMM compatibility mod installed successfully!',
      'status_ummcompat_failed': 'Failed to install UMM compatibility mod: {error}',
      'status_mod_enabling': 'Enabling {name}...',
      'status_mod_disabling': 'Disabling {name}...',
      'status_mod_enable_success': 'Enabled {name} successfully!',
      'status_mod_disable_success': 'Disabled {name} successfully!',
      'status_mod_toggle_failed': 'Failed to toggle status of {name}: {error}',
      'settings_token_title': 'App Integration Token (Premium)',
      'settings_token_hint': 'Enter the token copied from your profile page.',
      'settings_token_saved': 'App Integration Token saved successfully.',
      'settings_token_guide': 'You can generate and copy this token from the profile tab on modlist.org.',
      'settings_cloud_title': 'Cloud Saving (Premium)',
      'settings_cloud_desc': 'Backup your UserData and UMM configurations to the cloud. (Excludes binaries, assets, and files > 100MB)',
      'settings_cloud_btn_backup': 'Backup Now',
      'settings_cloud_btn_restore': 'Restore',
      'settings_cloud_btn_delete': 'Delete',
      'settings_cloud_used': 'Used Storage: {used} / {max}',
      'settings_cloud_no_backup': 'No backup files found in the cloud.',
      'cloud_link_title': 'Account Linking Required',
      'cloud_btn_link': 'Link Modlist Account',
      'cloud_link_guide': 'Clicking the button will open your web browser.\nOnce logged in, click "Link Desktop App" on the website to connect instantly.',
      'cloud_connected_account': 'Connected Account',
      'cloud_btn_disconnect': 'Disconnect',
      'cloud_premium_desc': 'Modlist Premium Membership',
      'cloud_premium_sub': 'Unlock advanced features by activating your premium membership.',
      'cloud_benefit_1_title': 'Cloud Save Sync (10 GB)',
      'cloud_benefit_1_desc': 'Backup and restore game settings and configuration files to the cloud. Supports large files up to 100MB.',
      'cloud_benefit_2_title': 'Mod Preset Sharing',
      'cloud_benefit_2_desc': 'Generate shareable preset links to let friends synchronize their mod setup to match yours instantly.',
      'cloud_patreon_cta_text': 'Not a Premium Member yet?',
      'cloud_patreon_btn': 'Become a Patron / Join Membership (Only \$1/month)',
      'settings_preset_title': 'Mod Preset Sharing (Premium)',
      'settings_preset_btn_share': 'Share Active Mod Preset',
      'settings_preset_created_title': 'Preset Shared',
      'settings_preset_created_body': 'Preset link copied to clipboard. Share it with other players!',
      'settings_preset_sync_title': 'Sync Mod Preset',
      'settings_preset_sync_body': 'Do you want to sync your mod list with this preset? Missing mods will be downloaded/installed, and activation states will be set to match the preset.',
      'status_cloud_backup_start': 'Compressing and preparing cloud backup...',
      'status_cloud_backup_progress': 'Uploading backup: {progress}%',
      'status_cloud_backup_success': 'Cloud backup uploaded successfully!',
      'status_cloud_backup_failed': 'Cloud backup failed: {error}',
      'status_cloud_restore_start': 'Downloading cloud backup...',
      'status_cloud_restore_progress': 'Restoring backup: {progress}%',
      'status_cloud_restore_success': 'Cloud saves restored successfully!',
      'status_cloud_restore_failed': 'Cloud restore failed: {error}',
      'status_cloud_delete_start': 'Deleting cloud backup...',
      'status_cloud_delete_success': 'Cloud backup deleted successfully.',
      'status_cloud_delete_failed': 'Failed to delete cloud backup: {error}',
      'cloud_backups_title': 'Cloud Backups',
      'preset_attach_saves_title': 'Attach Backup Files (UserData)',
      'preset_attach_saves_body': 'Would you like to attach your latest cloud backup save/config files to this preset? Other users will be able to download and sync these settings along with the mods.',
      'preset_attach_saves_yes': 'Yes, Attach & Share',
      'preset_attach_saves_no': 'No, Share Mods Only',
      'preset_sync_saves_title': 'Restore Attached Saves/Configs',
      'preset_sync_saves_body': 'This preset contains configuration/save files (UserData). Do you want to download and apply them?\n\nWarning: Applying this will overwrite and replace your existing local saves and settings.',
      'preset_sync_saves_yes': 'Yes, Apply (Overwrite)',
      'preset_sync_saves_no': 'No, Install Mods Only',
      'cloud_presets_title': 'My Shared Presets',
      'cloud_presets_empty': 'No shared presets found.',
      'cloud_presets_copy_link': 'Copy Link',
      'cloud_presets_delete_confirm': 'Are you sure you want to delete this preset?',
      'btn_cancel': 'Cancel',
      'backup_badge_sharing': 'Sharing in Preset',
      'backup_delete_warning_normal': 'Are you sure you want to delete this cloud backup?',
      'backup_delete_warning_attached': 'This backup is copied and used in a shared preset. Deleting it will not affect the shared preset\'s copy of the saves.\n\nAre you sure you want to delete this cloud backup?',
      'btn_delete_confirm': 'Delete',
    },
    'zh-CN': {
      // Sidebar
      'tab_explore': '模组探索',
      'tab_installed': '安装管理',
      'tab_cloud_save': '云端备份',
      'tab_settings': '设置',
      'sidebar_games_title': '目标游戏 (GAMES)',
      'sidebar_adofai_active': '冰与火之舞 (Active)',
      'sidebar_adofai_inactive': '冰与火之舞',
      'sidebar_adofai_tooltip': '冰与火之舞模组管理器已激活。',
      'sidebar_dancing-line_active': '跳舞的线 (Active)',
      'sidebar_dancing-line_inactive': '跳舞的线',
      'sidebar_dancing-line_tooltip': '跳舞的线模组管理器已激活。',
      'sidebar_rhythm-doctor_active': '节奏医生 (Active)',
      'sidebar_rhythm-doctor_inactive': '节奏医生',
      'sidebar_rhythm-doctor_tooltip': '节奏医生模组管理器已激活。',

      // Settings Tab
      'settings_title': '设置 (SETTINGS)',
      'settings_game_path_title_adofai': '冰与火之舞安装路径设置',
      'settings_game_path_title_dancing-line': '跳舞的线安装路径设置',
      'settings_path_empty': '未指定游戏路径。请选择文件夹。',
      'settings_path_invalid_adofai':
          '⚠️ 该路径下不存在游戏运行文件 (A Dance of Fire and Ice)。',
      'settings_path_invalid_dancing-line':
          '⚠️ 该路径下不存在游戏运行文件 (Dancing Line)。',
      'settings_btn_select_manually': '手动选择文件夹',
      'settings_btn_auto_detect': '自动检测 Steam 路径',
      'settings_api_title': '连接 modlist.org API 服务器',
      'settings_btn_save': '保存',
      'settings_api_guide':
          '默认值为 https://modlist.org ，本地测试时可以更改为 http://localhost:3000 。',
      'settings_sys_title': '系统信息',
      'settings_sys_os': '操作系统 (OS)',
      'settings_sys_ver': '程序版本',
      'settings_sys_loader': '加载器类型',
      'settings_lang_title': '语言设置 (Language)',
      'settings_api_saved': 'API URL 设置已保存。',
      'settings_path_detected_adofai': '已自动设置冰与火之舞的默认 Steam 路径。',
      'settings_path_detected_dancing-line': '已自动设置跳舞的线的默认 Steam 路径。',
      'settings_path_detected_rhythm-doctor': '已自动设置节奏医生的默认 Steam 路径。',
      'settings_path_not_found_adofai':
          '在默认 Steam 路径下找不到冰与火之舞安装文件夹。请手动选择。',
      'settings_path_not_found_dancing-line':
          '在默认 Steam 路径下找不到跳舞的线安装文件夹。请手动选择。',
      'settings_path_not_found_rhythm-doctor':
          '在默认 Steam 路径下找不到节奏医生安装文件夹。请手动选择。',
      'settings_game_path_title_rhythm-doctor': '节奏医生安装路径设置',
      'settings_path_invalid_rhythm-doctor':
          '⚠️ 该路径下不存在游戏运行文件 (Rhythm Doctor)。',

      // Installed Tab
      'installed_title': '安装管理 (INSTALLED)',
      'installed_loader_title': 'MelonLoader 管理',
      'installed_loader_active': 'MelonLoader 已激活。(v{version})',
      'installed_loader_inactive': '未安装 MelonLoader。',
      'installed_loader_outdated_title': '检测到旧版本的 MelonLoader。',
      'installed_loader_umm_title': '检测到 Unity Mod Manager (UMM)。',
      'installed_btn_update_loader': '更新到 v{version}',
      'installed_btn_uninstall': '卸载 (Uninstall)',
      'installed_btn_replace_loader': '替换为 MelonLoader',
      'installed_btn_install': '安装 (Install)',
      'installed_loader_outdated_banner':
          '当前检测到的 MelonLoader 版本为 {version}。\n使用旧版本或外部安装的加载器可能会导致错误，请更新到最新的 v{targetVersion}。',
      'installed_umm_banner':
          '检测到当前游戏文件夹中安装了 Unity Mod Manager (UMM)。\n若要通过 modlist.org 完美连结 (安装/删除/更新) 模组，必须使用 MelonLoader。\n点击上方的 [替换为 MelonLoader] 按钮将自动清除现有的 UMM 并开始安装 MelonLoader。',
      'replace_umm_dialog_title': '替换 Unity Mod Manager 并迁移模组',
      'replace_umm_dialog_body':
          '我们将把现有 Mods 文件夹中的 UMM 模组安全地迁移到 UMMMods 文件夹。\n\n此外，您是否要加装 UMM 兼容模组 (ummcompat) 以便迁移后的 UMM 模组在 MelonLoader 下正常工作？',
      'replace_umm_dialog_btn_yes': '是 (安装兼容模组)',
      'replace_umm_dialog_btn_no': '否 (不安装)',
      'replace_umm_dialog_btn_cancel': '取消',
      'install_ummcompat_dialog_title': '建议安装 UMM 兼容模组',
      'install_ummcompat_dialog_body':
          '您刚刚安装的 UMM 模组需要 UMM 兼容模组 (ummcompat) 才能在 MelonLoader 下正常工作。\n\n您要现在加装 UMM 兼容模组 (ummcompat) 吗？',
      'delete_confirm_dialog_title': '删除模组',
      'delete_confirm_dialog_body': '您确定要删除模组 {name} 吗？',
      'delete_confirm_dialog_btn_yes': '删除',
      'delete_confirm_dialog_btn_no': '取消',
      'loader_uninstall_confirm_title': '卸载 MelonLoader',
      'loader_uninstall_confirm_body': '您确定要卸载 MelonLoader 吗？\n卸载只会清除模组加载器文件，您安装在 Mods 文件夹中的模组仍会被保留。',
      'installed_list_title': '已安装模组列表',
      'installed_btn_add_mod_manually': '从文件安装模组',
      'installed_no_mods': '没有已安装的模组。',
      'installed_ver_prefix': '安装版本: v{version}',
      'installed_latest_ver_prefix': '最新版本: v{version}',
      'installed_game_ver_prefix': '支持游戏: {version}',
      'installed_btn_update_mod': '更新',
      'installed_btn_delete_mod': '删除',
      'installed_copied_clipboard': '已复制到剪贴板。',
      'installed_err_file_picker': '选择文件时出错: {error}',
      'installed_launch_guide_title': '💡 非 Windows 系统额外说明',
      'installed_launch_auto_set': '✓ 已自动配置 Steam 启动选项。',
      'installed_launch_auto_set_restart': '请完全退出并重新打开 Steam 以使更改生效。',
      'installed_btn_copy_native_launch': '复制原生启动选项',
      'installed_btn_copy_proton_launch': '复制 Proton 启动选项',
      'settings_btn_check_updates': '检查更新',

      // Explore Tab
      'explore_filter_category': '类别',
      'explore_filter_category_all': '所有类别',
      'category_ui': 'UI',
      'category_gameplay': '游戏玩法',
      'category_utility': '实用工具',
      'category_visuals': '视觉效果',
      'category_library': '库 (Library)',
      'explore_filter_sort': '排序方式',
      'explore_filter_sort_downloads': '按下载量多到少',
      'explore_filter_sort_downloads_asc': '按下载量少到多',
      'explore_filter_sort_updated': '最近更新',
      'explore_filter_sort_created': '最近添加',
      'explore_filter_sort_name': '按名称 (A-Z)',
      'explore_filter_sort_name_desc': '按名称 (Z-A)',
      'explore_search_placeholder': '搜索模组名称或说明...',
      'explore_no_mods_found': '找不到匹配条件的模组。',
      'explore_badge_update_req': '需要更新',
      'explore_badge_installed': '已安装',
      'explore_card_featured': '推荐',
      'explore_modal_categories': '类别',
      'explore_modal_downloads': '下载次数',
      'explore_modal_author': '制作者',
      'explore_modal_collaborators': '协作者',
      'explore_modal_latest_ver': '最新版本',
      'explore_modal_game_ver': '推荐游戏版本',
      'explore_modal_downloads_unit': '{count} 次',
      'explore_modal_err_title': '错误',
      'explore_modal_err_body': '无法加载模组详细信息。',
      'explore_modal_btn_close': '关闭',
      'explore_modal_btn_delete': '删除模组',
      'explore_modal_btn_install': '安装模组 (Install)',
      'explore_modal_warn_path':
          '⚠️ 请先在设置标签页中指定正确的游戏安装路径。',
      'explore_modal_warn_loader': '安装模组前需要先安装 MelonLoader。',
      'explore_modal_btn_auto_loader': '自动安装 MelonLoader',
      'explore_modal_loading': '处理中...',
      'explore_modal_expand': '展开',
      'explore_card_author_more': ' 等人',
      'game_adofai': '冰与火之舞 (ADOFAI)',
      'game_dancing_line': '跳舞的线 (Dancing Line)',
      'game_rhythm_doctor': '节奏医生 (Rhythm Doctor)',
      'explore_modal_beta': '测试版 (Beta)',
      'update_dialog_title': '新版本更新通知',
      'update_dialog_body':
          '新版本 {version} 已发布！\n\n当前版本: v{currentVersion}\n\n您要下载并安装最新版本吗？',
      'update_dialog_btn_yes': '立即更新',
      'update_dialog_btn_no': '以后再说',
      'update_status_latest': '已是最新版本。',
      'update_status_error': '获取更新信息时出错。',
      'mod_update_toast_title': '有 {count} 个模组有新更新。',
      'mod_update_toast_action': '查看',
      'explore_err_load_failed': '加载模组数据失败: {error}',
      'installed_steamlaunchoptionsguide_adofai_linux':
        '1）使用 Linux 原生版本时，请在 Steam 启动选项中输入以下脚本：\n'
        './setup_helper.sh %command%\n\n'
        '2）使用 Steam Proton（Windows 版本）时，请输入以下脚本：\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_adofai_macos':
        '使用 macOS 原生版本时，请设置以下 Steam 启动选项 —— 请使用复制按钮'
        '（必须为绝对路径，Steam 在 macOS 上不解析相对路径）：\n'
        '"<游戏目录>/setup_helper.sh" %command%\n\n'
        'Modlist 会安装与当前 Mac 匹配的 MelonLoader macOS 包。如果在 Apple Silicon 上安装的是 x64 包，此脚本会通过 Rosetta 启动游戏。\n\n'
        '* 如果出现 Gatekeeper（安全）警告，请打开终端，进入游戏目录后执行以下命令：\n'
        'xattr -dr com.apple.quarantine setup_helper.sh MelonLoader.Bootstrap.dylib MelonLoader/',
      'installed_steamlaunchoptionsguide_rd_linux':
        '1）使用 Linux 原生版本时，请在 Steam 启动选项中输入以下脚本：\n'
        './setup_helper.sh %command%\n\n'
        '2）使用 Steam Proton（Windows 版本）时，请输入以下脚本：\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_rd_macos':
        '使用 macOS 原生版本时，请设置以下 Steam 启动选项 —— 请使用复制按钮'
        '（必须为绝对路径，Steam 在 macOS 上不解析相对路径）：\n'
        '"<游戏目录>/setup_helper.sh" %command%\n\n'
        'Modlist 会安装与当前 Mac 匹配的 MelonLoader macOS 包。如果在 Apple Silicon 上安装的是 x64 包，此脚本会通过 Rosetta 启动游戏。\n\n'
        '* 如果出现 Gatekeeper（安全）警告，请打开终端，进入游戏目录后执行以下命令：\n'
        'xattr -dr com.apple.quarantine setup_helper.sh MelonLoader.Bootstrap.dylib MelonLoader/',
      'installed_steamlaunchoptionsguide_dl_linux':
        '使用 Steam Proton（Windows 版本）时，请在启动选项中输入以下脚本：\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_dl_macos':
        '使用 macOS 原生版本时，请设置以下 Steam 启动选项 —— 请使用复制按钮'
        '（必须为绝对路径，Steam 在 macOS 上不解析相对路径）：\n'
        '"<游戏目录>/setup_helper.sh" %command%\n\n'
        'Modlist 会安装与当前 Mac 匹配的 MelonLoader macOS 包。如果在 Apple Silicon 上安装的是 x64 包，此脚本会通过 Rosetta 启动游戏。\n\n'
        '* 如果出现 Gatekeeper（安全）警告，请打开终端，进入游戏目录后执行以下命令：\n'
        'xattr -dr com.apple.quarantine setup_helper.sh MelonLoader.Bootstrap.dylib MelonLoader/',

      // Status messages
      'status_loader_downloading': '正在下载 MelonLoader...',
      'status_loader_migrating_umm': '正在将现有的 UMM 模组迁移到 UMMMods 文件夹...',
      'status_loader_installing': '正在下载 MelonLoader：{progress}%',
      'status_loader_extracting': '正在解压 MelonLoader...',
      'status_loader_configuring': '正在配置 MelonLoader 文件...',
      'status_loader_finalizing': '正在完成 MelonLoader 安装...',
      'status_loader_checking_ummcompat': '正在检查 UMM 兼容模组 (ummcompat) 信息...',
      'status_loader_install_success_with_ummcompat': 'MelonLoader 及 UMM 兼容模组安装成功！',
      'status_loader_install_success_fail_ummcompat': 'MelonLoader 安装成功 (兼容模组安装失败: {error})',
      'status_loader_install_success': 'MelonLoader 安装成功！',
      'status_loader_install_failed': 'MelonLoader 安装失败: {error}',
      'status_loader_uninstalling': '正在卸载 MelonLoader...',
      'status_loader_uninstall_success': 'MelonLoader 已成功卸载。',
      'status_loader_uninstall_failed': 'MelonLoader 卸载失败: {error}',
      'status_mod_downloading': '正在下载 {name}...',
      'status_mod_downloading_progress': '正在下载 {name}：{progress}%',
      'status_mod_preparing': '正在准备下载 {name}...',
      'status_mod_resolving_dependency': '正在解析依赖模组 {dependency}...',
      'status_mod_install_success': '安装 {name} 成功！',
      'status_mod_install_failed': '安装 {name} 失败: {error}',
      'status_mod_local_installing': '正在安装本地模组...',
      'status_mod_local_install_success': '模组已成功手动安装！',
      'status_mod_local_install_failed': '手动安装模组失败: {error}',
      'status_mod_deleting': '正在删除 {name}...',
      'status_mod_delete_success': '删除 {name} 成功！',
      'status_mod_delete_failed': '删除 {name} 失败: {error}',
      'status_ummcompat_checking': '正在检查 UMM 兼容模组 (ummcompat) 信息...',
      'status_ummcompat_success': 'UMM 兼容模组安装成功！',
      'status_ummcompat_failed': '安装 UMM 兼容模组失败: {error}',
      'status_mod_enabling': '正在启用 {name}...',
      'status_mod_disabling': '正在禁用 {name}...',
      'status_mod_enable_success': '启用 {name} 成功！',
      'status_mod_disable_success': '禁用 {name} 成功！',
      'status_mod_toggle_failed': '更改 {name} 状态失败: {error}',
      'settings_token_title': '应用连结令牌 (Premium)',
      'settings_token_hint': '输入从您的个人资料页面复制的令牌。',
      'settings_token_saved': '应用连结令牌已成功保存。',
      'settings_token_guide': '您可以在 modlist.org 的个人资料标签页中生成并复制此令牌。',
      'settings_cloud_title': '云端存档 (Premium)',
      'settings_cloud_desc': '将 UserData 和 UMM 配置备份到云端。(不包括二进制文件、资源以及大于 100MB 的文件)',
      'settings_cloud_btn_backup': '立即备份',
      'settings_cloud_btn_restore': '恢复',
      'settings_cloud_btn_delete': '删除',
      'settings_cloud_used': '已用空间: {used} / {max}',
      'settings_cloud_no_backup': '云端未找到备份文件。',
      'cloud_link_title': '需要关联账号',
      'cloud_btn_link': '关联 Modlist 账号',
      'cloud_link_guide': '点击该按钮将打开您的网页浏览器。\n登录后，在网站上点击“Link Desktop App”即可瞬间连接。',
      'cloud_connected_account': '已关联账号',
      'cloud_btn_disconnect': '解除关联',
      'cloud_premium_desc': 'Modlist Premium 会员权益',
      'cloud_premium_sub': '激活 Premium 会员身份以解锁各种高级功能。',
      'cloud_benefit_1_title': '云端存档同步 (10 GB)',
      'cloud_benefit_1_desc': '安全地备份和恢复游戏设置与存档文件。支持单个最大 100MB 的文件备份。',
      'cloud_benefit_2_title': '模组预设分享',
      'cloud_benefit_2_desc': '生成可分享的预设链接，让好友一键将模组配置同步至与您完全一致的状态。',
      'cloud_patreon_cta_text': '还不是 Premium 会员？',
      'cloud_patreon_btn': '在 Patreon 上赞助并加入会员 (仅需 \$1/月)',
      'settings_preset_title': '模组预设分享 (Premium)',
      'settings_preset_btn_share': '分享当前模组预设',
      'settings_preset_created_title': '预设已分享',
      'settings_preset_created_body': '预设连结已复制到剪贴板。分享给其他玩家！',
      'settings_preset_sync_title': '同步模组预设',
      'settings_preset_sync_body': '您想将模组列表与此预设同步吗？缺少的模组将被下载和安装，激活状态也将根据预设进行设置。',
      'status_cloud_backup_start': '正在压缩和准备云端备份...',
      'status_cloud_backup_progress': '正在上传备份: {progress}%',
      'status_cloud_backup_success': '云端备份上传成功！',
      'status_cloud_backup_failed': '云端备份失败: {error}',
      'status_cloud_restore_start': '正在下载云端备份...',
      'status_cloud_restore_progress': '正在恢复备份: {progress}%',
      'status_cloud_restore_success': '云端备份恢复成功！',
      'status_cloud_restore_failed': '云端恢复失败: {error}',
      'status_cloud_delete_start': '正在删除云端备份...',
      'status_cloud_delete_success': '云端备份已成功删除。',
      'status_cloud_delete_failed': '删除云端备份失败: {error}',
      'cloud_backups_title': '云端备份',
      'preset_attach_saves_title': '附加备份文件 (UserData)',
      'preset_attach_saves_body': '您要在此预设中附加最近的云端备份存档/配置文件吗？其他用户可以在同步模组的同时下载并同步这些设置。',
      'preset_attach_saves_yes': '是的，附加并分享',
      'preset_attach_saves_no': '不，仅分享模组',
      'preset_sync_saves_title': '恢复附加的存档/配置',
      'preset_sync_saves_body': '此预设包含存档/配置文件 (UserData)。您想要下载并应用它们吗？\n\n警告：应用此操作将覆盖并替换您现有的本地存档和设置。',
      'preset_sync_saves_yes': '是的，应用（覆盖）',
      'preset_sync_saves_no': '不，仅安装模组',
      'cloud_presets_title': '我分享的模组预设',
      'cloud_presets_empty': '未找到分享的预设。',
      'cloud_presets_copy_link': '复制链接',
      'cloud_presets_delete_confirm': '您确定要删除此预设吗？',
      'btn_cancel': '取消',
      'backup_badge_sharing': '预设分享中',
      'backup_delete_warning_normal': '您确定要删除此云端备份吗？',
      'backup_delete_warning_attached': '此备份已复制并在共享预设中使用。删除它不会影响共享预设中的存档副本。\n\n您确定要删除此云端备份吗？',
      'btn_delete_confirm': '删除',
    },
  };

  static String get(String locale, String key, {Map<String, String>? args}) {
    final language = _strings[locale] ?? _strings['en-US']!;
    var text = language[key] ?? _strings['en-US']![key] ?? key;

    if (args != null) {
      args.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }

    return text;
  }
}
