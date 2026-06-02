class Localization {
  static const Map<String, Map<String, String>> _strings = {
    'ko-KR': {
      // Sidebar
      'tab_explore': '모드 탐색',
      'tab_installed': '설치 관리',
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
      'installed_btn_copy_native_launch': '네이티브 시작 옵션 복사',
      'installed_btn_copy_proton_launch': 'Proton 시작 옵션 복사',
      'settings_btn_check_updates': '업데이트 확인',
      'installed_steamlaunchoptionsguide_adofai_linux':
        '1) 리눅스 네이티브 실행 시 스팀 실행 옵션에 아래 스크립트를 입력하세요:\n'
        'eval "\$(./setup_helper.sh)" %command%\n\n'
        '2) Steam Proton(윈도우 버전) 실행 시 아래 스크립트를 입력하세요:\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_adofai_macos':
        'macOS 네이티브 실행 시 스팀 시작 옵션에 아래 스크립트를 입력하세요:\n'
        'eval "\$(./setup_helper.sh)" %command%\n\n'
        '* 게이트키퍼(보안) 경고 발생 시 터미널을 열고 게임 폴더로 이동하여 아래 명령어를 입력해 주세요:\n'
        'xattr -d com.apple.quarantine winhttp.dll MelonLoader/',
      'installed_steamlaunchoptionsguide_rd_linux':
        '1) 리눅스 네이티브 실행 시 스팀 실행 옵션에 아래 스크립트를 입력하세요:\n'
        'eval "\$(./setup_helper.sh)" %command%\n\n'
        '2) Steam Proton(윈도우 버전) 실행 시 아래 스크립트를 입력하세요:\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_rd_macos':
        'macOS 네이티브 실행 시 스팀 시작 옵션에 아래 스크립트를 입력하세요:\n'
        'eval "\$(./setup_helper.sh)" %command%\n\n'
        '* 게이트키퍼(보안) 경고 발생 시 터미널을 열고 게임 폴더로 이동하여 아래 명령어를 입력해 주세요:\n'
        'xattr -d com.apple.quarantine winhttp.dll MelonLoader/',
      'installed_steamlaunchoptionsguide_dl_linux':
        'Steam Proton(윈도우 버전) 실행 시 시작 옵션에 아래 스크립트를 입력하세요:\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_dl_macos':
        'macOS는 향후 지원 예정입니다.',

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
      'explore_err_load_failed': '모드 데이터를 불러오는 데 실패했습니다: {error}',

      // Status messages
      'status_loader_downloading': 'MelonLoader 다운로드 중...',
      'status_loader_migrating_umm': '기존 UMM 모드를 UMMMods 폴더로 이동 중...',
      'status_loader_installing': 'MelonLoader 다운로드 및 설치 중: {progress}%',
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
    },
    'en-US': {
      // Sidebar
      'tab_explore': 'Explore',
      'tab_installed': 'Installed',
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
      'explore_err_load_failed': 'Failed to load mod data: {error}',
      'installed_steamlaunchoptionsguide_adofai_linux':
        '1) For native Linux, enter the following launch option in Steam:\n'
        'eval "\$(./setup_helper.sh)" %command%\n\n'
        '2) For Steam Proton (Windows version), enter the following launch option:\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_adofai_macos':
        'For native macOS, enter the following launch option in Steam:\n'
        'eval "\$(./setup_helper.sh)" %command%\n\n'
        '* If a Gatekeeper security warning appears, open Terminal, navigate to the game folder, and run:\n'
        'xattr -d com.apple.quarantine winhttp.dll MelonLoader/',
      'installed_steamlaunchoptionsguide_rd_linux':
        '1) For native Linux, enter the following launch option in Steam:\n'
        'eval "\$(./setup_helper.sh)" %command%\n\n'
        '2) For Steam Proton (Windows version), enter the following launch option:\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_rd_macos':
        'For native macOS, enter the following launch option in Steam:\n'
        'eval "\$(./setup_helper.sh)" %command%\n\n'
        '* If a Gatekeeper security warning appears, open Terminal, navigate to the game folder, and run:\n'
        'xattr -d com.apple.quarantine winhttp.dll MelonLoader/',
      'installed_steamlaunchoptionsguide_dl_linux':
        'For Steam Proton (Windows version), enter the following launch option:\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_dl_macos':
        'macOS support is planned for a future release.',

      // Status messages
      'status_loader_downloading': 'Downloading MelonLoader...',
      'status_loader_migrating_umm': 'Migrating existing UMM mods to UMMMods folder...',
      'status_loader_installing': 'Downloading and installing MelonLoader: {progress}%',
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
    },
    'zh-CN': {
      // Sidebar
      'tab_explore': '模组探索',
      'tab_installed': '安装管理',
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
      'explore_err_load_failed': '加载模组数据失败: {error}',
      'installed_steamlaunchoptionsguide_adofai_linux':
        '1）使用 Linux 原生版本时，请在 Steam 启动选项中输入以下脚本：\n'
        'eval "\$(./setup_helper.sh)" %command%\n\n'
        '2）使用 Steam Proton（Windows 版本）时，请输入以下脚本：\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_adofai_macos':
        '使用 macOS 原生版本时，请在 Steam 启动选项中输入以下脚本：\n'
        'eval "\$(./setup_helper.sh)" %command%\n\n'
        '* 如果出现 Gatekeeper（安全）警告，请打开终端，进入游戏目录后执行以下命令：\n'
        'xattr -d com.apple.quarantine winhttp.dll MelonLoader/',
      'installed_steamlaunchoptionsguide_rd_linux':
        '1）使用 Linux 原生版本时，请在 Steam 启动选项中输入以下脚本：\n'
        'eval "\$(./setup_helper.sh)" %command%\n\n'
        '2）使用 Steam Proton（Windows 版本）时，请输入以下脚本：\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_rd_macos':
        '使用 macOS 原生版本时，请在 Steam 启动选项中输入以下脚本：\n'
        'eval "\$(./setup_helper.sh)" %command%\n\n'
        '* 如果出现 Gatekeeper（安全）警告，请打开终端，进入游戏目录后执行以下命令：\n'
        'xattr -d com.apple.quarantine winhttp.dll MelonLoader/',
      'installed_steamlaunchoptionsguide_dl_linux':
        '使用 Steam Proton（Windows 版本）时，请在启动选项中输入以下脚本：\n'
        'WINEDLLOVERRIDES="winhttp=n,b" %command%',
      'installed_steamlaunchoptionsguide_dl_macos':
        'macOS 支持将在未来版本中提供。',

      // Status messages
      'status_loader_downloading': '正在下载 MelonLoader...',
      'status_loader_migrating_umm': '正在将现有的 UMM 模组迁移到 UMMMods 文件夹...',
      'status_loader_installing': '正在下载并安装 MelonLoader：{progress}%',
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
