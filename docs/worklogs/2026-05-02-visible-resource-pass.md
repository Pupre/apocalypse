# 2026-05-02 시각 리소스 및 체감 피드백 패스

## 작업 맥락

이번 패스는 작은 시스템 개선에서 멈추지 않고, 플레이어가 실행 화면에서 바로 알아볼 수 있는 변화에 우선순위를 두었다. 목표는 “재난 이후의 차가운 도시를 실제로 걷고 있다”는 감각과 “실내 탐색이 장소와 사건을 가진다”는 감각을 강화하는 것이다.

## 구현 내용

- 새 AI 생성 리소스 `resources/ui/master/feedback/frost_screen_overlay_phone_ice.png`를 추가했다.
  - 휴대폰 화면 가장자리가 얼어붙고 균열이 번지는 형태의 투명 오버레이다.
  - 기존 `feedback/frost_screen_overlay.png` 별칭은 새 리소스를 기본으로 가리키도록 변경했다.
- 야외 위험 구역의 시각 존재감을 키웠다.
  - 빙판/틈바람 위험에 반투명 경고 영역, 큰 데칼, 글로우 데칼을 함께 그린다.
  - 위험 접촉 시 새 결빙 오버레이가 즉시 강하게 번지고, 카메라가 짧게 흔들린다.
- 새 AI 생성 리소스 `resources/ui/master/indoor/indoor_event_convenience_frozen.png`를 추가했다.
  - 실내 읽기 카드 상단에 표시되는 재난 직후 편의점 내부 일러스트다.
  - 실내 탐색 화면이 단순 텍스트 카드가 아니라 장소 분위기를 가진 화면으로 보이게 한다.
- 실내 결과 메시지에 상황 태그와 색상 톤을 붙였다.
  - 발견/획득/위험/상황을 구분해 같은 텍스트라도 사건 피드백처럼 읽히게 했다.

## 생성 리소스 메모

- 결빙 오버레이는 `imagegen` 기본 도구로 생성한 뒤, 마젠타 크로마키 배경을 로컬에서 제거해 투명 PNG로 만들었다.
- 실내 편의점 일러스트는 `imagegen` 기본 도구로 생성하고, UI 패널에 맞게 `960x480`으로 축소했다.
- 두 리소스 모두 최종본은 프로젝트 `resources/ui/master/...` 아래에 저장했고, 생성 원본은 `.codex/generated_images`에 그대로 남겨 두었다.

## 검증

- `res://tests/unit/test_inventory_weight_model.gd`
- `res://tests/unit/test_heat_source_rules.gd`
- `res://tests/unit/test_supply_source_selection.gd`
- `res://tests/unit/test_indoor_mode.gd`
- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

## 남은 판단

- 실내 일러스트의 공통 사용 문제는 추가 패스에서 건물 분류별 선택 구조로 해소했다. 이후에는 이벤트 중요도나 스토리 컷신에 따라 더 특수한 장면을 보여주는 방향이 좋다.
- 야외 위험 피드백은 체감 우선으로 강하게 잡았다. 실제 플레이 확인 후 너무 과하면 알파와 흔들림 강도를 낮추면 된다.

## 추가 패스: 건물 분류별 실내 일러스트

편의점 패널의 방향성이 좋았기 때문에, 같은 톤의 AI 생성 일러스트를 건물 분류별로 확장했다. 목표는 실내 탐색 화면이 항상 같은 이미지로 보이지 않고, “지금 들어온 장소가 어디인지”를 읽기 카드 상단에서 즉시 느끼게 하는 것이다.

### 구현 내용

- 새 AI 생성 리소스 네 장을 추가했다.
  - `resources/ui/master/indoor/indoor_event_medical_clinic.png`: 의원/약국 계열의 얼어붙은 진료실과 약품 보관 공간.
  - `resources/ui/master/indoor/indoor_event_residential_stairwell.png`: 아파트/주거 계열의 재난 이후 공동 복도와 계단참.
  - `resources/ui/master/indoor/indoor_event_industrial_garage.png`: 차고/창고/철물점 계열의 차가운 작업장과 보관소.
  - `resources/ui/master/indoor/indoor_event_food_kitchen.png`: 식당/카페 계열의 얼어붙은 주방.
- `IndoorDirector.get_event_illustration_asset()`을 추가해 이벤트 지정값, 건물 지정값, 건물 ID, 건물 분류 순서로 일러스트를 고르게 했다.
- `IndoorMode`가 고정 편의점 이미지를 쓰지 않고, 현재 건물에 맞는 일러스트를 읽기 카드에 갱신하도록 바꾸었다.
- `UiKitResolver`와 리소스 매니페스트에 새 실내 일러스트 별칭과 메타데이터를 등록했다.

### 검증

- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_indoor_mode.gd`

## 추가 패스: 얕은 실내 네 곳의 게임성 확장

플레이어가 같은 명령을 반복하지 않아도 큰 배치로 이어가기 위해, 아직 2구역/2행동 구조에 머물던 장소 중 체감이 큰 네 곳을 먼저 끌어올렸다. 이번 기준은 “그 장소라서 납득되는 물건이 나오고, 서두르면 손해가 생기며, 도구를 준비하면 다른 선택지가 열린다”이다.

### 구현 내용

- `bakery_01`을 계산대, 깨진 진열장, 준비실, 뒤쪽 냉동고 4구역으로 확장했다.
  - 깨진 진열장은 빠르게 뒤지면 유리 부상과 소란을 감수하고, 작업 장갑이 있으면 더 오래 걸리지만 안전하게 정리한다.
  - 준비실과 냉동고는 포장재, 종이컵, 코코아 믹스, 보관 용기처럼 빵집에서 현실적으로 남을 만한 물건 중심으로 조정했다.
- `bookstore_01`을 입구 계산대, 작은 읽기 자리, 무너진 안쪽 서가, 직원 책상 4구역으로 확장했다.
  - 무너진 서가는 빠른 수색과 작업 장갑 수색으로 갈라지고, 따뜻한 음료 조합을 암시하는 단서를 드러낸다.
- `butcher_01`을 포장대, 작업 통로, 냉장실, 뒤쪽 보관 선반 4구역으로 확장했다.
  - 정육점은 상한 식량보다 포장재, 보냉 장비, 작업 도구가 더 현실적인 보상으로 나오게 했다.
  - 작업 통로와 냉장실은 각각 미끄러짐, 한기 위험을 가진다.
- `school_gate_01`을 경비실, 분실물 상자, 행정 선반, 잠긴 보건함 4구역으로 확장했다.
  - 보건함은 억지로 뜯으면 큰 소란을 내고, 작은 드라이버가 있으면 조용히 열 수 있다.
  - 분실물 상자는 장갑, 우산, 양말처럼 폐교 정문에서 자연스럽게 찾을 수 있는 보온품을 제공한다.

### 아이템/조합 연결

- 새 아이템 `warm_cocoa`, `sealed_warm_cocoa`를 추가했다.
- `hot_water + instant_cocoa_mix -> warm_cocoa` 조합을 추가했다.
- `thermos + warm_cocoa -> sealed_warm_cocoa` 조합을 추가했다.
- 빵집에서 찾은 코코아 믹스가 단순 루팅 보상이 아니라, 실제 야외 이동 전 준비 루프로 이어지게 했다.

### 야외 연결

- `1_0` 블록 빵집 뒤편에 눈더미 위험을 추가했다.
- `1_2` 블록 폐교 정문 앞에 빙판, 정육점 처마 쪽에 틈바람 위험을 추가했다.
- `2_0` 블록 서점 차양 아래에 틈바람 위험을 추가했다.
- 새 실내가 좋아져도 건물까지 가는 길이 비어 보이지 않도록, 진입 전 야외 판단 압력을 함께 보강했다.

### 검증

- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_indoor_content_depth.gd`
- `res://tests/unit/test_indoor_actions.gd`
- `res://tests/unit/test_indoor_loot_tables.gd`
- `res://tests/unit/test_crafting_resolver.gd`
- `res://tests/unit/test_life_world_item_matrix.gd`
- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/unit/test_outdoor_world_runtime.gd`
- `res://tests/unit/test_outdoor_map_view.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

## 추가 패스: 식당 주방 분기와 행동 위험 미리보기

건물별 일러스트가 붙은 뒤에는, 그 이미지가 단순 장식으로 끝나지 않도록 식당 내부의 선택 구조를 먼저 깊게 만들었다. 작은 식당은 이제 홀과 보관실 사이에 주방이 있고, 주방 수색은 “빨리 뒤져서 다칠 위험을 감수한다”와 “작업 장갑으로 시간을 더 쓰고 조용히 연다” 사이의 선택으로 바뀌었다.

### 구현 내용

- `restaurant_01` 실내 이벤트를 홀, 주방, 안쪽 보관실 3구역 구조로 확장했다.
- 주방 수색에 두 가지 분기를 추가했다.
  - 빠른 수색: 25분, 소란, 손등 부상, 피로 증가를 감수하고 조리 도구와 온식 재료를 찾는다.
  - 작업 장갑 수색: 작업 장갑이 필요하고 35분이 걸리지만 소란과 부상 없이 같은 핵심 재료를 찾는다.
- 행동 버튼에 보조 라벨을 붙여 `필요: 작업 장갑`, `소란 +2`, `체력 -1`, `피로 +1` 같은 위험 정보를 행동 전에 볼 수 있게 했다.
- 이 보조 라벨은 기존 행동명 텍스트를 바꾸지 않아서 기존 UI 테스트와 버튼 탐색 흐름을 유지한다.

### 검증

- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_indoor_mode.gd`
- `res://tests/unit/test_indoor_content_depth.gd`
- `res://tests/unit/test_indoor_actions.gd`
- `res://tests/unit/test_indoor_loot_tables.gd`
- `res://tests/smoke/test_first_playable_loop.gd`

## 추가 패스: 야외 위험 예고와 외곽 위험 밀도

야외 위험은 접촉 후 피드백만 강한 상태였기 때문에, 플레이어가 위험을 밟기 전에 판단할 수 있는 예고를 HUD에 추가했다. 이제 건물 진입 힌트가 없는 상황에서 위험 구역 근처에 접근하면 `위험: 검은 빙판 · 체온 -1.5 · 피로 +1.5 · 부상 -0.5`처럼 예상 압력이 먼저 표시된다.

### 구현 내용

- 야외 HUD가 근처 위험 구역을 감지해 체온 손실, 피로 증가, 부상, 지연 시간을 미리 요약한다.
- 기존 빙판/틈바람 외에 `snow_drift`, `whiteout` 위험 타입을 시각 색상과 데칼 선택에 연결했다.
- `0_2`, `1_2`, `2_0`, `2_2` 외곽 블록에 눈더미와 시야 불량 위험을 추가했다.
- 위험 접촉 카메라 흔들림도 위험 종류에 따라 강도를 다르게 잡았다.

### 검증

- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/unit/test_outdoor_world_runtime.gd`
- `res://tests/unit/test_outdoor_map_view.gd`

## 추가 패스: 사무실/보안/서점/대피 공간 실내 일러스트

편의점 공통 이미지로 떨어지던 건물군을 줄이기 위해 AI 생성 실내 배너 네 장을 추가했다. 이번 리소스는 단순히 예쁜 배경을 늘리는 목적보다, “내가 들어온 장소가 어떤 종류의 판단을 요구하는지”를 카드 상단에서 바로 읽히게 하는 목적이다.

### 구현 내용

- 새 AI 생성 리소스 네 장을 추가했다.
  - `resources/ui/master/indoor/indoor_event_office_records.png`: 사무실과 기록보관 공간.
  - `resources/ui/master/indoor/indoor_event_security_station.png`: 파출소, 경비실, 장비 캐비닛 공간.
  - `resources/ui/master/indoor/indoor_event_bookstore_frozen.png`: 얼어붙은 서점과 종이 더미.
  - `resources/ui/master/indoor/indoor_event_civic_shelter.png`: 예배당과 임시 대피 공간.
- `IndoorDirector.get_event_illustration_asset()`에 사무실, 보안, 서점, 예배당 계열 매핑을 추가했다.
- `UiKitResolver`와 실내 리소스 매니페스트에 새 배너들을 등록했다.

### 검증

- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_indoor_mode.gd`

## 추가 패스: 겨울 생존자 주인공 스프라이트

야외 배경과 위험 피드백의 톤이 차갑고 무거워진 만큼, 기존 주인공 스프라이트도 같은 세계에 서 있는 사람처럼 보이도록 조정했다. 처음에는 기존 저해상도 프레임을 유지하면서 실루엣과 색감을 바꿨지만, 화면 확인 결과 큰 픽셀 덩어리감이 너무 강해 64px 기반의 부드러운 래스터 스프라이트로 다시 교체했다.

### 구현 내용

- AI 생성 레퍼런스 `resources/world/city/player/winter_survivor_reference.png`를 추가했다.
  - 검은 방한 파카, 후드, 올리브색 목도리/마스크, 장갑, 작은 갈색 배낭을 가진 겨울 생존자 방향 레퍼런스다.
  - 실제 게임 프레임은 이 레퍼런스를 그대로 축소한 것이 아니라, 레퍼런스의 복장 요소를 64px 래스터 스프라이트로 다시 그린 것이다.
- `resources/world/city/player` 아래 주인공 4방향 idle과 8프레임 walk를 갱신했다.
  - 정면/측면/후면 모두 후드와 차가운 하이라이트가 읽히도록 했다.
  - 목도리 또는 마스크, 올리브 장갑, 소형 배낭/스트랩을 방향별로 구분했다.
  - 32px 프레임을 크게 확대한 느낌을 줄이기 위해 더 높은 해상도에서 둥근 후드, 팔, 다리, 가방을 그린 뒤 게임 안에서는 축소해 사용한다.
- 야외 컨트롤러의 주인공 표시 크기, 걷기 프레임 수, 프레임 속도, bob을 상수화했다.
  - 새 스프라이트는 `TEXTURE_FILTER_LINEAR`로 표시해 큰 네모 픽셀처럼 보이는 문제를 줄였다.
  - 걷기 프레임은 4프레임에서 8프레임으로 늘려 좌우 팔/다리 흔들림이 더 부드럽게 이어진다.
- 사용자 확인 결과, 첫 패스는 캐릭터 톤 변화는 보였지만 걷기 애니메이션 체감이 약했다.
  - 4방향 walk 프레임의 팔, 다리, 장갑, 배낭 위치를 더 크게 흔들리도록 다시 그렸다.
  - 야외 런타임에서 걷는 동안 스프라이트가 1.6px 위로 살짝 튀는 bob을 추가해 실제 이동 중 프레임 전환이 더 잘 보이게 했다.
  - `test_outdoor_controller.gd`는 이동 중 idle 텍스처에서 walk 텍스처로 바뀌고 bob offset이 적용되는지 직접 검증한다.

### 검증

- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/unit/test_run_controller_live_transition.gd`
- `res://tests/unit/test_survivor_creator.gd`
- `res://tests/smoke/test_first_playable_loop.gd`
- 주인공 런타임 텍스처 64px 이상, 선형 필터링, 이동 중 walk 텍스처 전환과 bob 적용 확인

## 추가 패스: 네 개 소형 탐색지의 깊이 확장

구멍가게, 반찬 가게, 수리점, 물류 보관소는 아직 2구역 구조라 “이동 후 탐색”만 반복되는 느낌이 강했다. 이번 패스에서는 네 장소를 모두 4구역 구조로 확장하고, 서두르면 다치거나 소란이 생기지만 도구를 갖추면 더 안전하게 처리할 수 있는 분기를 붙였다.

### 구현 내용

- `corner_store_01`은 앞 선반, 재고 구석, 낡은 계산대, 뒤쪽 냉장고 구조가 되었다.
  - 계산대는 급히 젖히면 아크릴 조각에 다치고 소란이 생긴다.
  - 작업 장갑이 있으면 더 오래 걸리지만 안전하게 정리한다.
  - 재고 구석은 생수 수량 공급원으로 연결된다.
- `deli_01`은 포장대, 깨진 반찬 진열장, 안쪽 준비대, 작은 냉장 보관실 구조가 되었다.
  - 즉석밥, 조미김, 어묵 통조림, 양념류, 포일 트레이처럼 실제 반찬 가게에서 납득되는 보상을 중심으로 재구성했다.
  - 진열장은 빠른 위험 수색과 장갑 기반 안전 수색으로 갈라진다.
- `repair_shop_01`은 작업대, 부품 선반, 공구 캐비닛, 뒤쪽 정비 베이 구조가 되었다.
  - 공구 캐비닛은 억지로 뜯으면 큰 금속음과 손상 위험을 감수하고, 드라이버가 있으면 조용히 연다.
  - 정비 베이는 사이펀 호스, 작업용 수건, 실링제, 호스 밴드 같은 보수/이송 루프 아이템을 제공한다.
- `storage_depot_01`은 적재문 앞, 안쪽 보관 랙, 관리 케이지, 무너진 팔레트 더미 구조가 되었다.
  - 팔레트 더미는 빠르게 헤집으면 적재물이 무너지고, 작업 장갑을 쓰면 안전하게 정리한다.
  - 포장재, 방수포, 빈 제리캔, 로프, 플라스틱 상자처럼 무겁지만 의미 있는 물류 보상을 준다.
- 네 장소 앞 야외 블록에 건물 진입 전 판단 압력을 추가했다.
  - 수리점 앞 언 기름물, 반찬 가게 배송 골목 틈바람, 물류 보관소 적재문 앞 눈더미, 구멍가게 차양 밑 빙판을 추가했다.

### 검증

- `res://tests/unit/test_indoor_content_depth.gd`
- `res://tests/unit/test_indoor_loot_tables.gd`
- `res://tests/unit/test_indoor_actions.gd`
- `res://tests/unit/test_indoor_director.gd`
- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/unit/test_outdoor_world_runtime.gd`
- `res://tests/unit/test_outdoor_map_view.gd`
- `res://tests/unit/test_crafting_resolver.gd`
- `res://tests/unit/test_life_world_item_matrix.gd`
- `res://tests/smoke/test_first_playable_loop.gd`
- 전체 `game/tests/unit/*.gd` 및 `game/tests/smoke/*.gd` 통과
## 추가 패스: 야외 리소스 대격변 1차

플레이어가 처음 보는 야외 화면의 인상을 끌어올리기 위해, 이번 패스는 단순한 단일 PNG 교체가 아니라 AI 생성 원본 시트, 런타임 PNG 추출, 맵 데이터 연결을 한 덩어리로 묶어 진행했다.

### 구현 내용

- `resources/world/city/reference/`에 야외 스타일 보드와 AI 생성 원본 시트를 보관했다.
  - `world_visual_overhaul_direction.png`: 야외 전체 톤 기준 보드.
  - `outdoor_building_sheet_2026-05-02.png`: 4x4 건물 외형 시트.
  - `outdoor_prop_sheet_2026-05-02.png`: 4x4 소품 시트.
  - `outdoor_terrain_sheet_2026-05-02.png`: 4x4 도로/눈/보도 타일 시트.
- `scripts/generate_world_visual_overhaul_assets.ps1`을 추가해 야외 리소스를 재생성 가능하게 만들었다.
  - 기본 절차형 리소스를 먼저 만든 뒤, AI 원본 시트가 있으면 건물/소품/지형 타일을 잘라 런타임 PNG로 덮어쓴다.
  - 마젠타 크로마키 배경을 제거해 Godot에서 바로 쓸 수 있는 투명 컷아웃으로 변환한다.
- 야외 건물 외형 매핑을 확장했다.
  - 빵집, 중고 서점, 정육점, 교회, 학교 정문, 코너 가게, 연립 주택 등은 별도 건물 PNG로 보인다.
  - 수리점/차고, 물류 보관소, 구내 식당, 찻집 등도 최소한 구분 가능한 외형 파일을 갖는다.
- 야외 소품 배치가 `asset_id`를 직접 지정할 수 있게 했다.
  - 같은 `rubble`이라도 덤프스터, 바리케이드, 타이어 더미처럼 다른 그림을 놓을 수 있다.
  - 가로등, 버스 정류장 표지, 쇼핑카트, 눈더미, 불붙은 드럼통 같은 소품이 맵 데이터에서 직접 연결된다.
- 3x3 야외 블록의 도로 구조를 조금 더 비대칭적으로 바꿨다.
  - 각 블록에 전면 공간, 좁은 골목, 서비스 차선, 주차장 느낌의 포장을 추가했다.
  - 기존 직선 십자 도로는 유지하되, 주변 건물 앞에 목적지가 느껴지는 바닥 질감과 소품을 더했다.

### 검증

- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/unit/test_outdoor_map_view.gd`
- `res://tests/smoke/test_first_playable_loop.gd`
- `git diff --check`

### 남은 판단

- 이번 패스는 야외 첫인상을 크게 바꾸는 1차 작업이다. 다만 일부 보조 건물은 아직 절차형 컷아웃 기반이므로, 다음 리소스 패스에서는 보조 건물 전용 AI 시트를 한 번 더 뽑아 차고, 물류 보관소, 구내 식당, 찻집, 호스텔 계열까지 같은 밀도로 끌어올리는 것이 좋다.
- 지형 타일은 시각 밀도가 크게 올라갔지만 반복 타일로 쓰일 때 경계가 아주 완벽한 타일링은 아니다. 실제 플레이 화면에서 반복감이 거슬리면 가장 많이 보이는 `road_plain`, `slush_road`, `snow_ground`, `sidewalk_snow`부터 별도 무봉합 타일로 다시 생성한다.

## 추가 패스: 보조 건물 AI 컷아웃 2차

1차 야외 리소스 교체 뒤에도 일부 보조 건물이 절차형 컷아웃으로 남아 있어, 장거리 이동 시 외형 밀도가 떨어질 수 있다고 판단했다. 그래서 별도 AI 생성 시트를 하나 더 만들어 세탁소, 주택, 수리점, 차고, 물류 보관소, 구내 식당, 찻집, 호스텔, 식당 계열까지 같은 방향의 외형으로 맞췄다.

### 구현 내용

- `resources/world/city/reference/outdoor_secondary_building_sheet_2026-05-02.png`를 추가했다.
- 생성 스크립트가 보조 건물 시트를 잘라 다음 런타임 PNG를 만들도록 확장했다.
  - `building_hardware.png`
  - `building_laundry.png`
  - `building_residence.png`
  - `building_repair_shop.png`
  - `building_restaurant.png`
  - `building_chapel.png`
  - 기존 `building_storage_depot.png`, `building_garage.png`, `building_canteen.png`, `building_tea_shop.png`, `building_deli.png`, `building_hostel.png`도 AI 컷아웃으로 덮어썼다.
- `OutdoorArtResolver`의 건물 매핑을 더 세분화했다.
  - 철물점, 세탁소, 단독 주택, 수리점, 식당, 예배당이 더 이상 범용 창고/사무실/카페 외형을 공유하지 않는다.

### 검증

- `res://tests/unit/test_outdoor_controller.gd`
- `res://tests/smoke/test_first_playable_loop.gd`
- `git diff --check`

### 남은 판단

- AI 시트 기반 컷아웃은 실제 인게임 축소 상태에서 품질이 좋지만, 마젠타 크로마키 잔상이 일부 어두운 그림자 가장자리에 아주 조금 남을 수 있다. 현재 직접 확인한 세탁소와 물류 보관소는 플레이 화면에서 문제될 수준은 아니라고 판단했다.
