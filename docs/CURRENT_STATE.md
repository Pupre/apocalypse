# Current State

- Status: active
- Last updated: 2026-05-04

## 2026-05-04 택배 분류 센터 다중 결과 컷신

- `택배 분류 센터`의 핵심 선택을 전용 성공/실패 컷신으로 분리했다.
- 새 AI 생성 컷신 2장을 추가했다.
  - `indoor_story_parcel_route_map_success.png`: 상자를 덜 열고 배송 철망과 라벨을 읽어 다음 목적지를 찾는 장면.
  - `indoor_story_parcel_random_boxes_failure.png`: 무작위 상자를 빠르게 뜯어 작은 물건은 얻지만 포장재 소음과 불확실성을 남기는 장면.
- `mapx_parcel_sorting_center_01.json`에서 아래 선택지에 전용 결과 일러스트와 전체화면 스토리 컷신을 연결했다.
  - `map_parcel_routes`: 우연한 상자보다 다음 이동 정보를 얻는 전략 선택.
  - `open_random_parcels`: 당장 작은 물건을 얻지만 더 큰 배송 흐름을 놓치는 선택.
- 검증: 이벤트 JSON 파싱, 신규 이미지 960x480 확인, `test_outdoor_map_expansion.gd`, `test_indoor_director.gd`, `test_ui_kit_resolver.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 고속도로 휴게소 다중 결과 컷신

- `고속도로 휴게소`의 자판기 선택을 장소 전용 성공/실패 컷신으로 분리했다.
- 새 AI 생성 컷신 2장을 추가했다.
  - `indoor_story_rest_stop_vending_panel_success.png`: 철사 고리로 서비스 패널을 조용히 열어 유리와 소리를 아끼는 장면.
  - `indoor_story_rest_stop_vending_glass_failure.png`: 자판기 유리를 깨고 간식을 빠르게 챙기지만 유리 파편과 굴러가는 캔 소리를 남기는 장면.
- `mapx_highway_rest_stop_vending_01.json`에서 아래 선택지에 전용 결과 일러스트와 전체화면 스토리 컷신을 연결했다.
  - `open_vending_service_panel`: 시간이 걸리지만 휴게소 안의 고요를 유지하는 선택.
  - `smash_vending_glass`: 빠르게 물자를 얻지만 국도 휴게소의 노출과 소음을 키우는 선택.
- 검증: 이벤트 JSON 파싱, 신규 이미지 960x480 확인, `test_outdoor_map_expansion.gd`, `test_indoor_director.gd`, `test_ui_kit_resolver.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 대피선 급수 초소 다중 결과 컷신

- `대피선 급수 초소`의 물 선택을 장소 전용 성공/실패 컷신으로 분리했다.
- 새 AI 생성 컷신 2장을 추가했다.
  - `indoor_story_shelter_water_prefilter_success.png`: 프리필터를 고치고 가져갈 물과 남길 물을 표시하는 장면.
  - `indoor_story_shelter_water_heavy_take_failure.png`: 너무 많은 물을 챙기다 문턱과 눈길에서 물의 무게를 체감하는 장면.
- `mapx_shelter_water_checkpoint_01.json`에서 아래 선택지에 전용 결과 일러스트와 전체화면 스토리 컷신을 연결했다.
  - `repair_prefilter_and_mark_share`: 물을 얻는 동시에 다음 이동자와 다음 생존자의 가능성을 남기는 선택.
  - `take_all_checkpoint_water`: 확실한 생존 자원을 얻지만 이동력과 판단 여지를 잃는 선택.
- 검증: 이벤트 JSON 파싱, 신규 이미지 960x480 확인, `test_outdoor_map_expansion.gd`, `test_indoor_director.gd`, `test_ui_kit_resolver.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 임시 대피 등록소 다중 결과 컷신

- `임시 대피 등록소`의 공동 보급 상자 선택을 성공/실패가 서로 다른 장면으로 남도록 확장했다.
- 새 AI 생성 컷신 2장을 추가했다.
  - `indoor_story_shelter_personal_share_success.png`: 내가 들 수 있는 몫만 챙기고 남은 공동 보급 상자를 다시 묶는 장면.
  - `indoor_story_shelter_empty_boxes_failure.png`: 보급품을 빠르게 쓸어 담아 방이 비고, 빈 상자와 흩어진 물건만 남는 장면.
- `mapx_west_shelter_registration_01.json`에서 아래 선택지에 전용 결과 일러스트와 전체화면 스토리 컷신을 연결했다.
  - `take_only_personal_share`: 당장은 덜 가져가지만 대피소의 의미를 남기는 선택.
  - `empty_relief_boxes_fast`: 빠르게 물자를 얻지만 다음 생존자의 가능성을 지우는 선택.
- 검증: 이벤트 JSON 파싱, 신규 이미지 960x480 확인, `test_outdoor_map_expansion.gd`, `test_indoor_director.gd`, `test_ui_kit_resolver.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 응급 분류 진료소 다중 결과 컷신

- `응급 분류 진료소`의 약품 선택을 성공/실패가 서로 다른 장면으로 남도록 확장했다.
- 새 AI 생성 컷신 2장을 추가했다.
  - `indoor_story_civic_triage_gloved_sort_success.png`: 장갑을 끼고 젖은 약품을 하나씩 걸러내 쓸 수 있는 약만 남기는 성공 장면.
  - `indoor_story_civic_triage_fast_sweep_failure.png`: 급하게 약품을 쓸어 담다가 플라스틱 통과 약봉지가 흩어져 소음과 손실을 남기는 실패 장면.
- `mapx_civic_triage_clinic_01.json`에서 아래 선택지에 전용 결과 일러스트와 전체화면 스토리 컷신을 연결했다.
  - `sort_safe_medicine_with_gloves`: 느리지만 안전하게 가져갈 수 있는 약만 남기는 선택.
  - `sweep_medicine_fast`: 빠르지만 무엇을 망쳤는지 확인하지 못하는 선택.
- 검증: 이벤트 JSON 파싱, 신규 이미지 960x480 확인, `test_outdoor_map_expansion.gd`, `test_indoor_director.gd`, `test_ui_kit_resolver.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 국도 검문소 다중 결과 컷신

- `국도 검문소`에도 한 건물 다중 컷신 패턴을 확장했다.
- 새 AI 생성 컷신 2장을 추가했다.
  - `indoor_story_checkpoint_exposed_crossing_failure.png`: 바리케이드를 넘어 빠른 큰길로 나섰을 때 눈보라와 노출 위험을 체감하는 장면.
  - `indoor_story_checkpoint_bus_seat_cache_success.png`: 버려진 버스 좌석 밑에서 생수, 담요, 보조배터리 같은 작은 승객 흔적을 찾는 장면.
- `mapx_highway_checkpoint_01.json`에서 아래 선택지에 전용 결과 일러스트와 전체화면 스토리 컷신을 연결했다.
  - `cross_roadblock_now`: 빠른 길이지만 너무 드러난 선택.
  - `search_bus_seats`: 큰 결정은 아니지만 생활감 있는 작은 보급을 얻는 선택.
- 검증: 이벤트 JSON 파싱, 신규 이미지 960x480 확인, `test_outdoor_map_expansion.gd`, `test_indoor_director.gd`, `test_ui_kit_resolver.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 비닐하우스 다중 결과 컷신

- `눈 묻은 비닐하우스`에도 한 건물 다중 컷신 패턴을 확장했다.
- 새 AI 생성 컷신 2장을 추가했다.
  - `indoor_story_greenhouse_fast_strip_failure.png`: 모종 선반을 빠르게 훑다가 상토와 얼음 조각을 쏟아 손실과 소음을 남기는 실패 장면.
  - `indoor_story_greenhouse_water_barrel_success.png`: 얼어붙은 물통 가장자리를 조심히 깨 쓸 수 있는 물을 확보하는 장면.
- `mapx_rural_greenhouse_01.json`에서 아래 선택지에 전용 결과 일러스트와 전체화면 스토리 컷신을 연결했다.
  - `strip_seedling_trays_fast`: 당장 먹을 것을 빠르게 챙기는 대신 다음 가능성을 망치는 선택.
  - `chip_water_barrel_ice`: 둔탁한 소리와 피로를 감수하고 물을 확보하는 실용적 선택.
- 검증: 이벤트 JSON 파싱, 신규 이미지 960x480 확인, `test_outdoor_map_expansion.gd`, `test_indoor_director.gd`, `test_ui_kit_resolver.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 발전소 제어동 다중 결과 컷신

- `열병합 발전소 제어동`에도 한 건물 다중 컷신 패턴을 확장했다.
- 새 AI 생성 컷신 2장을 추가했다.
  - `indoor_story_power_heat_trace_note_success.png`: 죽은 계기판 옆 정비 기록에서 작은 온기의 단서를 발견하는 장면.
  - `indoor_story_power_pipe_gallery_slip_failure.png`: 배관 점검 통로에서 부품을 떼어내다 빙판에 미끄러지는 위험 결과 장면.
- `mapx_power_plant_control_01.json`에서 아래 선택지에 전용 결과 일러스트와 전체화면 스토리 컷신을 연결했다.
  - `read_heat_trace_note`: 단순 문서 읽기가 아니라 다음 큰 결정을 여는 발견 컷신이 된다.
  - `salvage_pipe_parts`: 유용한 부품을 얻는 대신 피로와 위험을 체감하는 결과 컷신이 된다.
- 검증: 이벤트 JSON 파싱, 신규 이미지 960x480 확인, `test_outdoor_map_expansion.gd`, `test_indoor_director.gd`, `test_ui_kit_resolver.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 백색 물류 허브 다중 결과 컷신

- 한 건물에 하나의 일러스트만 붙는 느낌을 줄이기 위해 `백색 물류 허브`를 다중 장면 컷신 패턴의 첫 사례로 확장했다.
- 새 AI 생성 컷신 2장을 추가했다.
  - `indoor_story_logistics_dispatch_routes_success.png`: 배차 데스크에서 상자보다 값진 운송 경로를 베껴 적는 성공 장면.
  - `indoor_story_logistics_pallet_crash_failure.png`: 큰 팔레트를 욕심내다 소음과 피로를 키우는 실패 장면.
- `mapx_logistics_cold_chain_hub_01.json`에서 아래 선택지에 전용 결과 일러스트와 전체화면 스토리 컷신을 연결했다.
  - `copy_dispatch_routes`: 즉시 아이템보다 다음 이동 정보를 얻는 조용한 전략 선택.
  - `drag_full_pallet`: 대량 물자를 욕심냈을 때 소음과 후회를 보여 주는 실패 선택.
- 검증: 이벤트 JSON 파싱, 신규 이미지 960x480 확인, `test_outdoor_map_expansion.gd`, `test_indoor_director.gd`, `test_ui_kit_resolver.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 대지역 이동 사건 1차

- 야외 맵이 넓어졌을 때 “새 구역에 들어섰다”는 안내만 뜨고 실제 플레이 압박은 기존 위험 타일에만 의존하던 문제를 보완했다.
- `OutdoorController`에 대지역별 이동 사건을 추가했다.
  - 북부 시장가, 의료·관공 지구, 주거지, 공업지대, 물류 벨트, 발전소, 농촌·비닐하우스, 국도 검문 구역, 대피선, 중앙 환승로마다 서로 다른 짧은 사건과 체온·피로·부상·시간 비용을 갖는다.
  - 사건은 최초 진입 시 한 번만 발동해 넓은 맵 이동에 리듬과 비용을 주되, 같은 구역 안에서 반복 처벌처럼 느껴지지 않게 했다.
  - 기존 야외 위험 피드백 HUD와 서리 플래시를 재사용해 “지역 사건: …” 메시지가 즉시 보이도록 연결했다.
- 이번 변경의 의도는 대지역을 단순 배경 분류가 아니라 실제 플레이 상태를 흔드는 여행 압박으로 승격하는 것이다.
- 검증: `test_outdoor_controller.gd`, `test_outdoor_map_expansion.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 변전소·급식실·버스 차고 목적지 확장

- 야외 대지역 확장 콘텐츠의 실제 플레이 밀도를 높이기 위해 `변전소 제어동`, `폐교 급식실`, `버려진 버스 차고`를 전용 실내 이벤트로 승격했다.
- 세 장소 모두 전용 960x480 컷신 일러스트를 연결했고, 큰 결정 선택지 하나 이상을 포함한다.
  - 변전소는 절연 테이프를 이용한 차단기 조작, 빠른 배터리 회수, 송전 마당 바람길 확인을 다룬다.
  - 폐교 급식실은 무거운 쌀 포대와 실제 이동 가능한 식량 꾸러미 사이의 선택을 다룬다.
  - 버스 차고는 우회 노선, 연료, 보온 재료 중 무엇을 우선할지 고르게 한다.
- `tools/generate_outdoor_map_expansion.py`의 특수 건물 오버라이드에 세 목적지를 추가했다. 이후 맵 재생성 시 각 건물이 전용 이벤트 파일과 `big_decision` 태그를 유지한다.
- 작업 원칙: 지역이 단순히 넓어지는 것이 아니라, 발전소 지대·농촌 외곽·국도 구역마다 서로 다른 판단과 파밍 기대감을 갖도록 목적지를 계속 깊게 채운다.
- 검증: `test_outdoor_map_expansion.gd`, `test_indoor_director.gd`, `test_content_library.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 보건소·급수 초소·지게차 정비고 확장

- 의료·관공 지구, 서쪽 대피선, 남부 물류 벨트가 서로 다른 플레이 질문을 갖도록 `보건소 냉장 약품실`, `대피선 급수 초소`, `지게차 정비고`를 전용 실내 이벤트로 승격했다.
- 보건소는 보냉 운반 조건이 있는 약품과 바로 쓸 수 있는 처치품 사이의 선택을 만든다.
- 급수 초소는 깨끗한 물을 모두 가져가는 선택과, 필터를 고치고 다음 생존자의 몫을 남기는 선택을 나눈다.
- 지게차 정비고는 공구·배터리 회수와 임시 운반 보조 장치 제작 사이의 선택으로, 물류 구역의 핵심인 “많이 찾았지만 어떻게 들고 나갈 것인가”를 직접 다룬다.
- 세 장소 모두 전용 960x480 컷신 일러스트를 연결했고, 야외 맵 생성 오버라이드와 시나리오 테스트에 추가했다.
- 검증: `test_outdoor_map_expansion.gd`, `test_indoor_director.gd`, `test_content_library.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 무리한 선택 결과 컷신 패턴

- 성공 컷신뿐 아니라 무리한 선택의 대가도 전체화면으로 보이도록 실패감 있는 결과 컷신 2장을 추가했다.
  - `indoor_story_noisy_scavenge_failure.png`: 유리 파손, 배터리 탈거, 시트 절단처럼 빠르지만 소리를 키우는 선택에 사용한다.
  - `indoor_story_overburdened_exit_failure.png`: 쌀 포대, 물통처럼 생존에는 확실하지만 이동을 망가뜨리는 과적 선택에 사용한다.
- 아래 선택지에 `result_illustration_asset`과 `story_cutscene`을 붙였다.
  - 휴게소 자판기 유리 파손, 변전소 배터리팩 강제 회수, 버스 차고 시트 절단, 지게차 배터리 탈거.
  - 폐교 급식실 쌀 포대 욕심, 농가 창고 큰 쌀 포대, 대피선 급수 초소 물 전량 회수.
- 검증: `test_outdoor_map_expansion.gd`, `test_indoor_director.gd`, `test_ui_kit_resolver.gd`, `test_first_playable_loop.gd` 통과.

## 2026-05-04 가방 필터와 장착 후보 UX 확장

- 가방 탭에 빠른 분류 필터를 추가했다.
  - `전체`, `생존`, `도구`, `장착`, `읽을 것`, `무거움` 필터로 아이템 풀이 커져도 원하는 물건군을 빠르게 좁혀 볼 수 있다.
  - 필터는 조합 모드에서는 숨겨져 조합 가능 재료 목록을 방해하지 않는다.
- 장착 탭을 단순 슬롯 확인 화면에서 장비 교체 화면으로 확장했다.
  - 장착 가능한 인벤토리 아이템을 `장착 후보`로 따로 보여 준다.
  - 후보 행에서 바로 `장착`하거나, 이미 해당 슬롯에 장비가 있으면 `교체`할 수 있다.
  - 장착 후보는 슬롯 순서와 아이템 이름 기준으로 정렬된다.
- 아이템 상세 행동의 우선순위를 조정했다.
  - `먹는다`, `마신다`, `사용한다`, `장착한다`, `읽는다`는 주요 행동으로 유지한다.
  - `버린다`는 실수 터치를 줄이기 위해 `조합 시작`과 같은 보조 행동 영역으로 내렸다.
- AI 이미지 생성으로 가방 필터 전용 컨트롤 레일 `inventory_filter_rail.png`를 만들고 `resources/ui/master/sheet/`에 연결했다.
- 검증
  - `res://tests/unit/test_survival_sheet.gd`
  - `res://tests/unit/test_ui_kit_resolver.gd`
  - `res://tests/unit/test_equipment_loadout.gd`
  - `res://tests/unit/test_run_controller_live_transition.gd`
  - `res://tests/smoke/test_first_playable_loop.gd`

## 2026-05-04 가방·장착 UX 분리 패스

- 아이템 장착 UI가 가방 목록 공간을 잡아먹던 문제를 해결하기 위해 생존 시트를 `가방 / 장착 / 도감` 3탭 구조로 재편했다.
  - `가방` 탭은 아이템 목록과 선택 상세에 집중한다.
  - `장착` 탭은 등, 손짐, 몸, 외투, 머리, 손, 발, 주머니 등 전체 장착 슬롯을 별도 화면에서 관리한다.
  - `도감` 탭은 기존 조합 지식 흐름을 유지한다.
- 장비 슬롯은 가방 목록 위에 끼워 넣지 않고 전용 장착 탭의 2열 카드 그리드로 이동했다.
  - 기본 가방 화면의 스크롤 영역을 520px 기준으로 넓혀 파밍 후 아이템을 더 많이 한 번에 볼 수 있게 했다.
  - 장착 화면에서는 착용 수량과 전체 슬롯 수를 먼저 보여 주고, 장착 중인 슬롯은 바로 `해제`할 수 있게 유지했다.
- AI 이미지 생성으로 장착 전용 패널 배경 `loadout_panel_expanded.png`를 만들고 `resources/ui/master/sheet/`에 연결했다.
- 검증
  - `res://tests/unit/test_survival_sheet.gd`
  - `res://tests/unit/test_ui_kit_resolver.gd`
  - `res://tests/unit/test_equipment_loadout.gd`
  - `res://tests/smoke/test_first_playable_loop.gd`

## 2026-05-04 중간 목적지 이벤트와 컷신 확장

- 대지역 맵이 거대한 랜드마크만 띄엄띄엄 있는 느낌이 되지 않도록, 이동 중 들르게 되는 중간 목적지 3곳을 전용 실내 이벤트로 승격했다.
  - `mapx_08_04_a` 눈보라 휴게소 자판기 코너: 서비스 패널을 조용히 열어 필요한 것만 챙길지, 유리를 깨고 빠르게 털어 위험을 키울지 결정한다.
  - `mapx_06_07_b` 동결된 택배 분류 센터: 무작위 상자를 뜯을지, 송장과 노선을 읽어 다음 탐색 경로까지 얻을지 결정한다.
  - `mapx_05_11_a` 외곽 농가 창고: 쌀과 공구를 균형 있게 나눌지, 무거운 쌀 포대를 무리해서 들고 나갈지 결정한다.
- AI 이미지 생성으로 960x480 컷신 일러스트 3장을 만들고 `resources/ui/master/indoor/`에 연결했다.
  - `indoor_story_rest_stop_vending_choice.png`
  - `indoor_story_parcel_route_sort_choice.png`
  - `indoor_story_farm_storage_weight_choice.png`
- 새 이벤트는 단순 보급품 보상이 아니라 생활감 있는 판단, 위험 감수, 다음 이동 정보, 운반 무게 고민을 함께 주도록 설계했다.
- 검증
  - 신규 `mapx_` 실내 이벤트 JSON 15개 파싱 확인.
  - 신규 이벤트 안의 아이템 참조가 현재 아이템 풀에 존재하는지 확인.
  - 신규 컷신 이미지 3장 960x480 확인.
  - `res://tests/unit/test_outdoor_map_expansion.gd`
  - `res://tests/unit/test_indoor_director.gd`
  - `res://tests/unit/test_content_library.gd`
  - `res://tests/smoke/test_first_playable_loop.gd`

## 2026-05-04 야외 대지역 세계화 1차

- 야외 12x12 확장 맵의 외곽 135개 블록을 단순 도시 반복에서 대지역 기반 탐험 지도로 재생성했다.
  - 기존 중심 3x3 수작업 구역은 유지했다.
  - 새 대지역은 북부 시장가, 동부 의료·관공 지구, 중앙 환승로, 국도 검문·휴게 구역, 서부 대피선, 남서 외곽 주거지, 남서 농촌·비닐하우스, 남부 물류 벨트, 동남 발전소 지대로 나뉜다.
  - 각 대지역은 서로 다른 도로 실루엣, 눈더미, 빙판, 화이트아웃, 길거리 소품, 건물 앵커 배치를 갖는다.
- 자동화가 이후 일러스트와 실내 선택지를 붙일 수 있도록 지역별 큰 결정 랜드마크를 추가했다.
  - `mapx_07_08_a` 백색 물류 허브: 대량 보급품과 운반 무게 판단.
  - `mapx_10_10_a` 열병합 발전소 제어동: 열원·전력 흔적과 통제실 판단.
  - `mapx_03_11_a` 눈 묻은 비닐하우스: 식량 기대와 노출 위험 판단.
  - `mapx_09_05_a` 국도 검문소: 통과, 은폐, 기록 확인 판단.
- 전체 지도 UI와 야외 HUD가 새 대지역 이름과 색을 이해하도록 연결했다.
- 운영 규칙은 유지한다.
  - Codex는 `git add`, `git commit`, `git push`를 하지 않고 개발, 검증, 문서화만 진행한다.
  - 사용자가 직접 확인한 뒤 Git 처리를 한다.
- 검증
  - 전체 야외 블록 JSON 144개 UTF-8 파싱 확인.
  - `res://tests/unit/test_outdoor_map_expansion.gd`
  - `res://tests/unit/test_outdoor_controller.gd`
  - `res://tests/unit/test_outdoor_map_view.gd`
  - `res://tests/unit/test_content_library.gd`
  - `res://tests/smoke/test_first_playable_loop.gd`

## 2026-05-04 대지역 랜드마크 이벤트와 컷신 1차

- 대지역 세계화에서 추가한 핵심 랜드마크 4곳을 범용 실내 이벤트에서 전용 이벤트로 승격했다.
  - `mapx_07_08_a` 백색 물류 허브: 냉동 도크, 정지한 냉동 컨테이너, 배차 데스크, 무너진 팔레트 통로를 가진다.
  - `mapx_10_10_a` 열병합 발전소 제어동: 어두운 제어실, 정비 배터리함, 배관 점검 통로, 정비 사물함을 가진다.
  - `mapx_03_11_a` 눈 묻은 비닐하우스: 처진 비닐 입구, 모종 선반, 농기구 모서리, 얼어붙은 물통을 가진다.
  - `mapx_09_05_a` 국도 검문소: 검문 부스, 국도 차단선, 무전 기록 책상, 버려진 버스를 가진다.
- 각 랜드마크에 사용자의 방향성과 맞는 큰 결정 선택지를 추가했다.
  - 물류 허브는 많은 보급품 중 실제로 들 수 있는 것만 고르는 판단을 다룬다.
  - 발전소는 위험한 제어실에서 아주 작은 온기를 살릴지 결정한다.
  - 비닐하우스는 당장 먹을 것과 다음 가능성을 나누는 판단을 다룬다.
  - 검문소는 빠른 큰길과 안전한 우회로 사이의 판단을 다룬다.
- AI 이미지 생성으로 960x480 컷신 일러스트 4장을 만들고 `resources/ui/master/indoor/`에 연결했다.
  - `indoor_story_logistics_cold_chain_choice.png`
  - `indoor_story_power_control_warmth_success.png`
  - `indoor_story_greenhouse_seed_cache_success.png`
  - `indoor_story_checkpoint_detour_choice.png`
- `UiKitResolver` 별칭과 UI 마스터 매니페스트를 갱신해 새 컷신 이미지가 게임에서 로드되도록 했다.
- 검증
  - 신규 `mapx_` 실내 이벤트 JSON 9개 파싱 확인.
  - 신규 랜드마크 이벤트 안의 아이템 참조가 현재 아이템 풀에 존재하는지 확인.
  - `res://tests/unit/test_outdoor_map_expansion.gd`
  - `res://tests/unit/test_indoor_director.gd`
  - `res://tests/unit/test_content_library.gd`
  - `res://tests/unit/test_outdoor_controller.gd`
  - `res://tests/smoke/test_first_playable_loop.gd`

## 2026-05-04 의료·대피·외곽 주거 랜드마크 확장

- 대지역 콘텐츠가 물류, 발전소, 농촌, 검문소에만 쏠리지 않도록 의료·관공 지구, 서부 대피선, 남서 외곽 주거지에도 전용 랜드마크 이벤트를 추가했다.
  - `mapx_09_01_b` 응급 분류 진료소: 장갑을 끼고 안전한 약품만 분류할지, 빠르게 쓸어 담을지 결정한다.
  - `mapx_00_05_a` 임시 대피 등록소: 공동 보급품을 전부 털지, 내 몫만 챙기고 남길 물자를 다시 묶을지 결정한다.
  - `mapx_02_09_b` 차고 딸린 연립 주택: 가족 비상 상자와 생활 공구를 이용해 손짐 슬링을 만들지 결정한다.
- AI 이미지 생성으로 960x480 컷신 일러스트 3장을 만들고 `resources/ui/master/indoor/`에 연결했다.
  - `indoor_story_civic_triage_sort_choice.png`
  - `indoor_story_shelter_registration_choice.png`
  - `indoor_story_outer_garage_sling_success.png`
- 이 패스의 디자인 의도는 파밍지를 "전리품 상자"가 아니라 생활 윤리, 운반 방식, 위험 분류를 판단하는 장소로 만드는 것이다.
- 검증
  - 신규 `mapx_` 실내 이벤트 JSON 12개 파싱 확인.
  - 신규 이벤트 안의 아이템 참조가 현재 아이템 풀에 존재하는지 확인.
  - 신규 컷신 이미지 3장 960x480 확인.
  - `res://tests/unit/test_outdoor_map_expansion.gd`
  - `res://tests/unit/test_indoor_director.gd`
  - `res://tests/unit/test_content_library.gd`
  - `res://tests/smoke/test_first_playable_loop.gd`

## 2026-05-03 야외 지도 UI와 지구 내부 반복감 보정

- 전체 지도 상단에 범례 텍스트가 좁은 폭에서 세로로 찢겨 보이는 문제를 막기 위해, 현재 전체 지도에서는 범례 행을 숨기고 상태줄과 지도 본문만 남겼다.
- 12x12 맵 확장 생성기에서 `layout_id`가 실제 도로 배치에 반영되도록 바꿨다.
  - 북부 시장가는 `market_arcade`, `market_plaza`, `market_back_alley`가 서로 다른 도로 실루엣을 가진다.
  - 중앙 환승로는 `bus_loop`, `station_crossing`, `underpass_detour`로 나뉘어 모든 블록이 같은 순환도로처럼 보이지 않는다.
  - 동부 의료지구, 남부 주거지, 남동 공업지대, 서부 대피선, 외곽 혼합지대도 각 레이아웃별 도로 모양이 갈라진다.
  - 건물 앵커 후보도 지구별 2종에서 4종 중심으로 늘려, 같은 지구 안에서도 건물 위치가 덜 반복된다.
- 생성기를 다시 실행해 외곽 135개 블록 파일을 갱신했다. 핵심 3x3 수동 블록은 건드리지 않았다.
- 운영 규칙 변경:
  - 앞으로 자동 배치 작업은 `git add`, `git commit`, `git push`를 하지 않는다.
  - 사용자가 직접 확인한 뒤 Git 처리를 한다. Codex는 변경 파일과 테스트 결과만 보고한다.
- 검증:
  - 전체 야외 블록 JSON 144개 UTF-8 파싱 확인.
  - `res://tests/unit/test_outdoor_map_expansion.gd`
  - `res://tests/unit/test_outdoor_controller.gd`
  - `res://tests/unit/test_outdoor_map_view.gd`
  - `res://tests/smoke/test_first_playable_loop.gd`

## 2026-05-03 야외 지구 지도 피드백

- 12x12로 넓어진 야외 맵이 전체 지도에서 단순한 회색 방문 영역처럼 보이지 않도록, 방문한 블록을 지구별 색면으로 구분하기 시작했다.
  - 북부 시장가, 동부 의료지구, 남부 주거지, 남동 공업지대, 서부 대피선, 중앙 환승로, 외곽 혼합지대가 서로 다른 은은한 색을 가진다.
  - 아직 안 가본 블록은 기존처럼 안개로 가려져, 지도 색이 미탐색 지역의 정체를 미리 스포일하지 않는다.
  - 전체 지도 스냅샷에 `district_blocks`를 추가해, 이후 지구 이름 라벨, 범례, 선택지/시나리오 연결을 붙이기 쉬운 구조로 정리했다.
- 이번 변경은 맵 대확장 이후 사용자가 "여기가 어디쯤이고, 다음에는 어느 성격의 지역으로 가는지"를 더 빨리 판단하게 만드는 1차 피드백이다.
- 검증:
  - `res://tests/unit/test_outdoor_map_view.gd`
  - `res://tests/unit/test_outdoor_controller.gd`
  - `res://tests/unit/test_outdoor_map_expansion.gd`
  - `res://tests/smoke/test_first_playable_loop.gd`

## 2026-05-03 야외 지구 차별화와 스트리밍 최적화

- 12x12 야외 확장 맵의 반복감을 줄이기 위해 생성 규칙을 지구별로 다시 나누었다.
  - 북부 시장가는 상점가 도로, 뒷골목, 진열대/카트 소품이 중심이다.
  - 중앙 환승로는 버스 루프, 언더패스, 정류장 소품이 중심이다.
  - 남동 공업지는 적재 야드, 연료 앞마당, 드럼통/상자/차량 소품이 중심이다.
  - 동부 의료지구, 남부 주거지, 서부 대피선도 각자 다른 도로 구조, 눈밭, 위험 배치를 가진다.
- 생성 건물 수는 168개에서 282개로 늘었다. 다만 실제 야외 화면은 현재 주변 스트리밍 창만 그리도록 최적화했기 때문에 화면 노드 수가 맵 전체 크기에 비례하지 않는다.
- 야외 성능 병목을 줄였다.
  - 플레이어가 조금 움직일 때마다 지형, 건물, 소품, 위협 노드를 전부 지우고 다시 만들던 구조를 고쳤다.
  - 활성 블록 창이 바뀔 때만 야외 지형/건물/소품/위협을 재구성한다.
  - 눈 배경도 전체 12x12 크기 대신 현재 활성 블록 주변만 덮도록 축소했다.
  - 전체 지도 오버레이는 매 프레임 갱신하지 않고, 열 때 또는 실제로 갱신이 필요할 때만 재구성한다.
- 실내 행동 렉도 1차로 줄였다.
  - 가방 시트가 닫혀 있는데도 행동마다 인벤토리와 도감 UI를 다시 그리던 흐름을 막았다.
  - 아이템 선택 시 전체 목록을 재생성하지 않고 선택 상태, 상세 패널, 스크롤 여백만 갱신한다.
- 지구 차별화가 플레이 중에도 읽히도록 야외 HUD와 전체 지도에 현재 지구 피드백을 연결했다.
  - 다른 지구로 이동하면 잠시 `진입: 지구명` 안내가 나오고, 위험 경고나 건물 진입 안내가 없을 때는 현재 지구명이 기본 이동 힌트에 붙는다.
  - 전체 지도 상태줄에는 현재 플레이어가 있는 지구명이 함께 표시된다.
- 테스트용 이동속도 부스트는 `--playtest-speed` 실행 인자에서만 켜진다. 일반 실행에서는 기본 이동속도를 유지한다.
 
## 2026-05-03 야외 맵 대확장 1차

- 야외 월드를 8x8 선언/3x3 실제 구현 상태에서 12x12 실제 도시로 확장했다.
  - 기존 중심 3x3 블록은 손대지 않고 보존했다.
  - 외곽 135개 블록을 새로 생성해 전체 블록 파일이 144개가 되었다.
  - 각 새 블록은 지구 ID, 도로/골목/주차 공간, 눈밭, 빙판/틈바람/눈더미/화이트아웃 위험, 소품, 랜드마크를 가진다.
- 새 건물 168개를 추가해 총 건물 수가 197개가 되었다.
  - 북쪽 상권, 동쪽 의료/업무 지구, 남쪽 주거 밀집지, 남동쪽 창고/정비 지대, 서쪽 대피 흔적, 중앙 환승로 같은 지구 감각을 나누었다.
  - 새 건물은 기존 실내 이벤트 템플릿을 재사용하지만, 각 건물 ID별로 독립된 방문 기억과 위치를 가진다.
  - 모든 새 건물은 진입 브리핑, 지구/파밍 태그, 향후 이벤트 심화를 위한 `scenario_hook`을 가진다.
- 이번 배치는 “넓어진 도시를 실제로 걸을 수 있게 만드는 기반”이다.
  - 다음 배치에서는 새 지구별 대표 건물부터 전용 실내 사건, 큰 결정 선택지, 성공/실패 일러스트를 붙여 복붙 느낌을 줄여야 한다.
- 지구별 대표 건물 5곳에는 전용 실내 사건을 바로 연결했다.
  - `mapx_03_00_a` 재난 안내 서점: 대피소 전단, 무너진 책장, 안쪽 자료실 선택지.
  - `mapx_06_06_a` 환승로 구멍가게: 큰길/골목 우회를 판단하게 하는 정류장 안내판과 뒤쪽 문.
  - `mapx_11_11_a` 멈춘 연료 야드: 호스와 빈 통으로 연료 잔량을 조용히 받을지 결정하는 고가치 선택.
  - `mapx_00_08_a` 임시 대피 잡화점: 보급 상자를 전부 가져갈지 일부만 남길지 고르는 도덕적 선택.
  - `mapx_09_04_a` 의료지구 편의점: 오염된 처치대에서 장갑을 쓰고 안전하게 의료품을 분류하는 선택.
  - 각 대표 사건은 기존 일러스트 자산을 활용한 `story_cutscene`을 포함한다. 전용 AI 일러스트는 다음 시각 패스에서 교체할 수 있다.

## 2026-05-03 생활 아이템 이벤트 선택지 1차 연결

- 새 생활 아이템 레이어를 실제 실내 선택지로 연결했다.
  - 편의점 계산대는 `evd_glass_search_gloves`가 있으면 깨진 유리 체력 손실 없이 안쪽까지 더 깊게 뒤질 수 있다.
  - 편의점 유리 계산대 성공 선택지는 AI 생성 960x480 스토리 일러스트를 띄워, 큰 결정을 눌렀을 때 장면 보상을 확인할 수 있다.
  - 카페는 `evd_clean_water_prefilter`로 커피 머신 물통을 걸러 물 보급원을 확보하고, `evd_window_gap_roll`로 창가 틈바람을 막은 뒤 좌석 아래를 더 오래 탐색할 수 있다.
  - 카페 창문 틈막이 성공 선택지도 AI 생성 스토리 일러스트를 띄워, 준비한 생활 아이템이 장소를 잠깐 안전하게 바꾸는 감각을 강화했다.
  - 코인 세탁소는 `evd_foot_dry_kit`로 젖은 바닥을 버티며 세탁기 하부를 뒤지고, 장갑류 중 하나가 있으면 새는 세제통 뒤쪽을 안전하게 뒤질 수 있다.
  - 낡은 아파트는 `evd_door_draft_snake`로 101호 문 밑을 막아 방 안쪽을 깊게 뒤지고, `evd_foot_dry_kit`로 공용 세탁실의 젖은 빨랫감 더미를 더 안정적으로 확인한다.
- 목표는 “아이템을 주웠다”에서 끝나지 않고, “이걸 지금 여기서 어떻게 써먹을까”라는 판단이 실내 탐색 중에 바로 떠오르게 하는 것이다.

## 2026-05-03 손짐 장착 슬롯 보정

- 손에 드는 수납품을 실제 장착 장비로 해석하도록 `hand_carry` 슬롯을 추가했다.
  - `plastic_bag` 기본 아이템을 새로 정의했고, 비닐봉투/장바구니 봉투/시장 바구니/보냉 가방/종이봉투가 손짐 슬롯에 장착되어 운반 한계를 올린다.
  - 장착 UI와 실내 인벤토리 상세 설명은 `hand_carry`를 `손짐`으로 표시한다.
  - 확장 아이템 생성기에서도 봉투, 에코백, 바구니, 보냉백, 작은 캐리어 등 일부 컨테이너 계열에 손짐/등/허리 장착 규칙을 부여한다.
- 이 보정은 “손보다 비닐봉투가 더 많은 물품을 담기 쉽다”는 현실감을 장착 UX에 반영하기 위한 작업이다.

## 2026-05-03 생활 아이템/응용 조합 레이어

- 자동 생성 500개와 별개로, 수작업 설계 생활 아이템 레이어를 추가했다.
  - `game/data/items_everyday_expansion.json`에 마트, 집, 사무실, 약국, 카페에서 흔히 볼 수 있는 일상 물건 118개를 넣었다.
  - 예시는 랩 포장 필름, 냉동용 지퍼백, 커피 필터, 빨대, 알루미늄 포장 뚜껑, 머리끈, 치실, 손거울, 가족사진, 방전된 보조배터리, 베개커버, 세탁망, 실리카겔 봉지 같은 물건이다.
  - 일부 물건은 생존 성능이 낮아도 `story`, `barter`, `personal`, `electronics` 같은 태그로 “사람이 살던 세계”의 흔적을 남긴다.
- 수작업 응용 조합 56개를 추가했다.
  - 비닐봉투+신문지로 방수 점화재 파우치, 립밤+화장솜으로 왁스 먹인 솜 점화재, 커피 필터+빈 커피 캔으로 임시 물 거름 필터, LED 열쇠고리+머리끈으로 손목 고정 LED, 베개커버+신발끈으로 손짐 운반끈을 만든다.
  - 조합의 목표는 “아이템 이름만 봐도 왜 되는지 납득되는 생활 응용”이며, 이후 건물 이벤트 선택지와 더 깊게 엮어 갈 기반이다.
- 생활 아이템 전용 루팅 프로필과 24px/32px 아이콘 236개를 추가했다.
  - 마트/편의점/아파트/사무실/약국/카페/세탁소/창고 등 현재 구현된 파밍지에서 새 아이템이 맥락에 맞게 섞인다.

## 2026-05-03 생존 아이템 확장 체크포인트

- 아이템 풀의 방향을 한 번 수정했다.
  - 첫 500개 확장안은 생존 장비와 식량 변주에 너무 치우쳐 “목록을 늘린다”는 느낌이 강했다.
  - 현재 확장 데이터는 음식/의료/장비뿐 아니라 지갑, 영수증, 직원 메모, 아이 장난감, 고장난 전자기기, 가정용품, 사적인 물건을 포함해 파밍지가 생활 공간처럼 느껴지도록 재구성했다.
  - 신규 테스트는 `ordinary_world`, `personal`, `electronics`, `household`, `story` 계열 물건이 충분히 포함되는지 확인한다.
- 생존 아이템 풀 1차 대확장을 적용했다.
  - `game/data/items_survival_expansion.json`에 신규 아이템 500개를 분리 데이터로 추가했다.
  - 음식, 음료, 의료품, 도구, 생활/보온 재료, 가방/수납, 착용 장비, 지식/문서, 조합 결과물까지 미래 맵 확장을 전제로 폭넓게 넣었다.
  - 기존 `items.json`은 건드리지 않고 `ContentLibrary`가 기본 아이템과 확장 아이템을 함께 병합해 읽도록 바꿨다.
- 조합 그래프를 함께 확장했다.
  - `game/data/crafting_combinations_survival_expansion.json`에 신규 조합식 240개를 추가했다.
  - 같은 장비 계열, 보온 재료, 묶는 재료, 수납/정리 재료를 우선 엮어 “이 조합이 왜 되는지”가 크게 어긋나지 않도록 규칙 기반으로 구성했다.
  - 이번 조합식은 1차 대량 기반이며, 이후 대표 조합부터 더 손맛 있는 개별 서술과 선택지로 고도화할 수 있다.
- 현재 구현된 건물 파밍에도 확장 아이템이 섞이도록 만들었다.
  - `game/data/loot_profiles_survival_expansion.json`을 추가하고, 건물 분류/사이트 태그/건물 ID 기준으로 적합한 아이템 후보를 보강했다.
  - `IndoorActionResolver`는 기존 손작성 루트 테이블을 유지하면서, 문맥형 루트 프로필을 추가 후보로 합쳐 반복 파밍 피로를 줄인다.
- 아이템 이미지 리소스 1차 팩을 제작했다.
  - 신규 아이템 500개에 대해 24px/32px 컷아웃 PNG 아이콘을 각각 생성하고 `resources/items/icons/item_icons_manifest.json`에 등록했다.
  - 이번 배치는 모든 아이템을 즉시 식별 가능하게 만드는 대량 아이콘 팩이며, 고가치/스토리 핵심 아이템은 이후 AI 생성 고품질 일러스트로 개별 교체하는 것이 좋다.
- 장착 UX의 첫 기반을 강화했다.
  - 가방 탭 상단의 장비 슬롯을 4열 그리드로 바꾸고, `등/몸/외투/머리/목/얼굴/손/발/양말/장갑 안감/허리/주머니`까지 전체 착용 칸을 한눈에 보이게 했다.
  - 착용 중인 장비와 빈 슬롯을 바로 읽을 수 있게 해, 아이템 풀이 커져도 “무엇을 들고 있고 무엇을 입고 있는지”의 판단선을 분리했다.
  - 착용 중인 장비에는 `해제` 버튼을 제공하고, 새 장비를 고르면 현재 같은 칸에 입고 있는 장비와 교체된다는 안내를 보여준다.
  - 장비 해제 시 아이템은 가방으로 돌아가며, 운반 한계/야외 속도/냉기 저항 같은 파생 수치가 즉시 다시 계산된다.
- 검증 기준선을 추가했다.
  - `res://tests/unit/test_survival_item_expansion.gd`가 확장 아이템 수, 조합 수, 병합 로딩, 대표 조합, 건물별 루트 프로필을 검증한다.
  - `res://tests/unit/test_item_icon_resolver.gd`가 신규 아이템 아이콘 해석을 함께 확인한다.


## Product Direction

- Portrait-first mobile presentation.
- Outdoor play keeps continuous travel risk and long-distance survival pressure active.
- Indoor play is text-heavy and decision-driven.
- Inventory is bag-first, with crafting triggered contextually from what is in the bag and where the survivor is.

## Implemented Baseline

Systems already integrated in `main`:

- 2026-05-02 야외 가시 리소스 대격변 1차가 들어갔다.
  - AI 생성 스타일 보드, 건물 시트, 소품 시트, 지형 타일 시트를 `resources/world/city/reference/`에 보관한다.
  - 실제 런타임 야외 건물/소품/도로/눈/보도 PNG는 `scripts/generate_world_visual_overhaul_assets.ps1`로 재생성한다.
  - 보조 건물 2차 AI 시트로 세탁소, 주택, 수리점, 차고, 물류 보관소, 구내 식당, 찻집, 호스텔, 식당 계열까지 같은 밀도의 외형을 갖게 했다.
  - 주요 3x3 야외 블록은 직선 십자 도로만 반복하지 않도록 전면 공간, 골목, 서비스 차선, 눈더미, 가로등, 쇼핑카트, 바리케이드, 덤프스터 등 시각 소품을 추가했다.
  - `OutdoorArtResolver`는 건물 ID별 외형과 블록 데이터의 명시적 `asset_id` 소품을 해석한다.
- 2026-05-02 실내 UX에 추천 행동 스트립을 추가했다.
  - 실내 행동 목록 위에서 현재 방의 낮은 위험 탐색, 획득, 이동 중 먼저 누르기 좋은 선택지를 요약한다.
  - 추천 행동은 한 번에 실행할 수 있어 긴 행동 목록을 읽기 전에 플레이 흐름을 잡아준다.
- Life-world item and recipe expansion.
- Building-specific indoor loot.
- Shared crafting baseline.
- Warmth system.
- Carry-weight baseline.
- Heat-source-gated recovery baseline.
- First quantity-bearing supply sources in high-stock indoor sites.
- Indoor site memory plus drop/re-entry persistence.
- Crafting codex, note-based unlocks, lighter charges, and tool requirements.
- Portrait phase 1 shell and indoor survival sheet work.
- First generated frozen-city art replacement checkpoint.
- Image-backed outdoor frost screen feedback.
- First authored indoor pressure outcomes for cold, noise, fatigue, and small injuries.
- First outdoor terrain hazard zones for black ice and wind-gap pressure.
- First branching indoor resolution option using tools versus brute force.
- First improvised indoor access rules using key-or-setup requirements and material consumption.
- Wearable warmth gear now reduces outdoor cold drain through equipment effects.
- Outdoor black-ice and wind-gap hazards now cover multiple nearby city blocks.
- Clinic medicine storage now has rushed versus flashlight-assisted search risk.
- Gas station fuel salvage now turns empty jerrycans into heavy portable-heat fuel.
- Indoor loot profiles now use validated practical household item ids, and the mart back hall has a listen-first clue action.
- Equipped footwear and face/neck gear can now mitigate authored outdoor hazard pressure.
- Convenience-store counter search now branches between rushed broken-glass risk and safer work-glove handling.
- Convenience-store fridge stock now uses quantity supply pickup for bottled water.
- 야외 위험 접촉은 새 휴대폰 결빙 오버레이, 경고 데칼, 짧은 카메라 흔들림으로 즉시 체감되게 했다.
- 실내 읽기 카드에는 AI 생성 재난 편의점 일러스트와 결과 태그를 붙여 탐색 화면의 장소감을 강화했다.
- 실내 읽기 카드는 건물 분류에 따라 편의점, 의료, 주거, 작업장, 식당 주방 일러스트를 골라 보여준다.
- 실내 읽기 카드는 사무실, 파출소/경비실, 서점, 예배당/대피 공간 계열도 별도 AI 생성 일러스트로 구분한다.
- 실내 행동 버튼은 필요한 도구, 소란, 체력 손실, 피로 증가 같은 위험 미리보기를 보조 라벨로 보여준다.
- 작은 식당은 홀, 주방, 안쪽 보관실 구조와 빠른 위험 수색/장갑을 쓴 안전 수색 분기를 가진다.
- 야외 HUD는 위험 구역에 닿기 전에도 근처 빙판, 틈바람, 눈더미, 시야 불량의 예상 손실을 미리 경고한다.
- 남쪽/동쪽 외곽 블록에는 눈더미와 시야 불량 위험을 추가해 긴 이동 경로의 공백을 줄였다.
- 빵집, 중고 서점, 정육점, 폐교 정문은 4구역 구조와 빠른 위험 수색/도구 기반 안전 수색 분기를 가진다.
- 빵집에서 얻는 코코아 믹스는 뜨거운 물, 보온병 조합으로 따뜻한 코코아와 보온병 코코아 생존 루프에 연결된다.
- 빵집, 서점, 정육점, 폐교 정문 주변 야외 블록에는 건물 진입 전 판단 압력을 주는 눈더미, 빙판, 틈바람 위험이 추가되었다.
- 주인공 야외 스프라이트는 64px 기반 4방향 idle + 8프레임 walk로 교체해 큰 픽셀 덩어리감을 줄였고, 선형 필터링과 부드러운 상하 bob으로 배경 톤에 더 맞는 이동 애니메이션을 만든다.
- 구멍가게, 반찬 가게, 수리점, 물류 보관소는 4구역 구조와 빠른 위험 수색/도구 기반 안전 수색 분기로 확장했고, 각 진입 블록에는 건물 앞 빙판, 틈바람, 눈더미 위험을 추가했다.
- HUD, 실내 행동 카드, 생존 시트의 주요 UI PNG를 새 AI 방향 레퍼런스 기반의 결빙 휴대폰 UI 톤으로 재생성했고, 실내 행동은 `이동/탐색/획득/위험/막힘` 칩과 시간/위험/보상 보조 라벨을 함께 보여준다.
- 가방 시트는 무게, 운반 상태, 야외 이동속도를 한 줄로 요약하고, 인벤토리 행에는 아이템 태그 칩을 붙여 조합/장착/소모 판단에 필요한 정보를 더 빨리 읽게 했다.
- 주인공 걷기 스프라이트는 방향별 발 배치를 다시 생성해 좌/우/상/하 이동이 모두 같은 오른쪽 보행처럼 보이는 문제를 고쳤다.
- 실내 화면은 `여기서 할 일 -> 챙길 물건 -> 다른 구역 -> 막힌 길` 순서로 재배치해, 먼저 현재 장소에서 판단하고 그다음 이동하는 흐름을 강화했다.
- 실내 장소 상태는 본문 문장에 섞지 않고 별도 칩으로 분리해 남은 물건, 설치물, 소란, 수색 완료 여부를 더 빨리 읽게 했다.
- HUD, 생존 시트, 실내 카드의 기본 글자 크기와 대비를 올려 노트북 해상도에서도 읽히도록 했다.
- 타이틀과 생존자 생성 화면은 결빙 휴대폰 UI 톤으로 맞추고, 생존자 생성은 직업/난이도/특성의 생존 의미와 출발 가능 여부를 한눈에 보여주는 선택 요약 구조로 바꾸었다.
- 야외 지도 오버레이는 탐색한 블록 수, 표시 가능한 건물 수, 지도 범례, 현재 위치 복귀 버튼을 제공해 단순 그림이 아니라 이동 계획 도구로 읽히게 했다.
- 가방 목록은 획득 순서 나열에서 벗어나 `먹고 마실 것`, `불과 도구`, `입고 버틸 것`, `읽을 것`, `무거운 짐`, `재료와 기타` 같은 생존 의도별 섹션으로 재정렬된다.
- 조합 모드의 가방 목록은 `기준 재료`, `조합 가능`, `다른 물건` 순서로 바뀌어 두 번째 재료를 더 빨리 고르게 했다.
- 수량 보급 팝업은 선택 수량의 무게 증가를 미리 보여주고, `최대` 버튼으로 여러 번 누르지 않고 최대 유효 수량을 바로 고를 수 있다.
- 실내 행동 카드는 기본 문구도 `물건/단서 확인`, `단서 확인`, `조용한 확인`, `짧은 회복`처럼 선택 의미를 직접 보여주며, 같은 섹션 안에서는 안전한 선택, 위험한 선택, 잠긴 대안을 더 자연스러운 판단 순서로 정렬한다.
- 실내 행동 결과는 필요한 경우 전용 스토리 일러스트로 읽기 카드 이미지를 교체할 수 있으며, 마트 식품 진열대 수색은 `무엇부터 챙길지`를 보여주는 AI 생성 장면 배너를 표시한다.

## 2026-05-02 Checkpoint

- Stable local checkpoint: `8c469a9` (`feat: tune outdoor pressure and refresh city art`).
- Current playability uplift continues from that checkpoint with generated cold-screen feedback and indoor pressure consequences.
- Indoor `outcomes.pressure` is now the preferred first-pass authoring hook for deterministic search risk.
- Noise is visible, persistent, and now resolves deterministic danger thresholds at 3/6/9.
- Recent stabilization also refreshed stale indoor/action UI tests against the current branching gate and loot-profile behavior.

## Active Specs

Canonical active-doc inventory lives in `docs/INDEX.md`. The list below is the current working set that most directly affects the game direction right now.

- [Carry, Heat, and Loot Pressure Design](superpowers/specs/2026-04-27-carry-heat-loot-pressure-design.md)
- [Toast Feedback System Design](superpowers/specs/2026-04-20-toast-feedback-system-design.md)
- [Indoor Depth and Item Expansion Design](superpowers/specs/2026-04-20-indoor-depth-item-expansion-design.md)
- [Outdoor 3x3 Authored Slice Design](superpowers/specs/2026-04-17-outdoor-3x3-authored-slice-design.md)
- [Portrait UI Framework Design](superpowers/specs/2026-04-17-portrait-ui-framework-design.md)
- [Outdoor Art Integration Pass 1 Design](superpowers/specs/2026-04-16-outdoor-art-integration-pass1-design.md)
- [Inventory Craft Slot Bar Design](superpowers/specs/2026-04-16-inventory-craft-slot-bar-design.md)
- [Inventory Bottom Sheet Redesign](superpowers/specs/2026-04-16-inventory-bottom-sheet-redesign.md)
- [Outdoor Spatial Map UI Design](superpowers/specs/2026-04-15-outdoor-spatial-map-ui-design.md)
- [Outdoor Map And Fog UI Design](superpowers/specs/2026-04-15-outdoor-map-and-fog-ui-design.md)
- [Outdoor Threat and Cold Feedback Design](superpowers/specs/2026-04-13-outdoor-threat-and-cold-feedback-design.md)
- [Outdoor World Architecture Design](superpowers/specs/2026-04-15-outdoor-world-architecture-design.md)
- [Outdoor 2x2 Block Expansion Design](superpowers/specs/2026-04-15-outdoor-2x2-block-expansion-design.md) (superseded)
- [Context Routing Docs Design](superpowers/specs/2026-04-10-context-routing-docs-design.md)
- [Contextual Crafting UI Design](superpowers/specs/2026-04-09-contextual-crafting-ui-design.md)
- [Portrait Phase 1 Shell Design](superpowers/specs/2026-04-07-portrait-phase1-shell-design.md)
- [Indoor Portrait Survival Sheet Design](superpowers/specs/2026-04-07-indoor-portrait-survival-sheet-design.md)
- [Crafting Codex Lighter Design](superpowers/specs/2026-04-06-crafting-codex-lighter-design.md)

## Active Plans

For the full active plan inventory, use `docs/INDEX.md`. The list below is the near-term plan stack currently driving implementation.

- [Carry, Heat, and Loot Pressure](superpowers/plans/2026-04-27-carry-heat-loot-pressure.md)
- [Toast Feedback System](superpowers/plans/2026-04-20-toast-feedback-system.md)
- [Indoor Depth and Item Expansion](superpowers/plans/2026-04-20-indoor-depth-item-expansion.md)
- [Outdoor 3x3 Authored Slice](superpowers/plans/2026-04-17-outdoor-3x3-authored-slice.md)
- [Portrait UI Framework](superpowers/plans/2026-04-17-portrait-ui-framework.md)
- [Outdoor Art Integration Pass 1](superpowers/plans/2026-04-16-outdoor-art-integration-pass1.md)
- [Inventory Craft Slot Bar](superpowers/plans/2026-04-16-inventory-craft-slot-bar.md)
- [Inventory Bottom Sheet Redesign](superpowers/plans/2026-04-16-inventory-bottom-sheet-redesign.md)
- [Outdoor Map And Fog UI](superpowers/plans/2026-04-15-outdoor-map-and-fog-ui.md)
- [Outdoor World Architecture](superpowers/plans/2026-04-15-outdoor-world-architecture.md)
- [Outdoor 2x2 Block Expansion](superpowers/plans/2026-04-15-outdoor-2x2-block-expansion.md) (superseded)
- [Outdoor Threat and Cold Feedback](superpowers/plans/2026-04-13-outdoor-threat-and-cold-feedback.md)
- [Context Routing Docs](superpowers/plans/2026-04-10-context-routing-docs.md)
- [Contextual Crafting UI](superpowers/plans/2026-04-09-contextual-crafting-ui.md)
- [Portrait Phase 1 Shell](superpowers/plans/2026-04-07-portrait-phase1-shell.md)
- [Indoor Portrait Survival Sheet](superpowers/plans/2026-04-07-indoor-portrait-survival-sheet.md)
- [Crafting Codex Lighter](superpowers/plans/2026-04-06-crafting-codex-lighter.md)

## Immediate Priorities

- Tighten outdoor cold pressure now that the first carry-weight, heat-source, and quantity-supply scaffolding is in place.
- Make `적정 / 과중 / 과적` meaningfully affect risky outdoor travel, not just inventory presentation.
- Broaden quantity-bearing supply sources past the first `mart / hardware / warehouse` pass where it materially improves scavenging decisions.
- Expand portable heat-source setup and recovery affordances so “go there and come back” versus “establish warmth there” becomes a real decision.
- Deepen the existing building set before pushing outdoor radius again: anchor four buildings into real multi-zone sites and lift the rest out of one-zone shells.
- Expand the item compendium with more believable site-specific finds, not just more raw crafting materials.
- Expand crafted items and cross-recipes so new and existing items can coexist in a deeper authored crafting graph.
- Maintain a separate resource-request ledger for newly introduced buildings and items so art generation can track content growth cleanly.
- Replace placeholder outdoor geometry with frozen-city terrain, buildings, props, and player art while keeping the streamed city runtime stable.
- Build the first outdoor pressure loop with animal pursuit, cold feedback, and more game-like real-time tension.
- Replace the temporary outdoor district scaffolding with a fixed-city streamed block runtime built on fixed-size blocks.
- Expand the first authored city slice from `2x2` to a full contiguous `3x3` so outdoor travel stops feeling tiny before deeper loot/story passes land.
- Keep the city globally open while revealing map knowledge per run from visited blocks only.
- Replace the mismatched outdoor minimap/full-map split with a coherent spatial map stack: local minimap, draggable full outdoor map, fog-of-war, and separate indoor building-detail layer.
- Keep the codex, note unlocks, lighter charges, and tool requirements aligned with the active crafting UI.
- 새 결빙 휴대폰 UI 키트 기준으로 타이틀, 생존자 생성, 지도 오버레이, 수량 선택, 도감, 스토리 일러스트 패널까지 같은 `결정 우선` 시각 언어로 계속 끌어올린다.
- 전용 스토리/결과 일러스트는 단순 장식이 아니라 의미 있는 선택, 위험, 서사 순간을 강화할 때 우선 추가한다.
- Continuously remove dead code, obsolete UI paths, temporary scaffolding, and other local junk that would otherwise pollute future implementation patterns.
- 2026-05-03 마트 실내 선택지에는 큰 결정 성공 컷신의 첫 구현이 들어갔다.
  - 실내 액션 결과에 `story_cutscene` 훅을 추가해, 특정 선택 성공 후 읽기 카드 이미지와 별도로 전체화면 일러스트 연출을 띄울 수 있다.
  - 마트 냉장고 줄 탐색은 새 AI 생성 일러스트와 추위 압박 결과를 보여 주며, 보관실은 빠른 수색과 긴 비상 캐시 재분류 중 하나를 고르는 결정 구조로 바뀌었다.
  - 보관실 비상 캐시 재분류 성공 시 물자 확보 결과와 함께 전체화면 컷신이 한 번만 재생되고, 같은 캐시를 다시 훑는 대체 선택지는 닫힌다.
  - 의원 약품 보관실의 손전등 기반 신중한 선별 선택도 새 AI 생성 약품 보관실 일러스트와 전체화면 성공 컷신을 사용한다.
  - 낡은 아파트 보일러실은 빠른 선반 수색과 긴 배관/온수병 정리 선택으로 갈라지고, 큰 결정을 택하면 피로와 추위 압박을 받는 대신 보온 준비물과 전용 보일러실 성공 컷신을 얻는다.
  - 다가구 주택 베란다의 우비 기반 신중한 정리 선택은 얼어붙은 세탁물과 포장재를 단열재로 바꾸는 전용 성공 컷신을 사용한다.
  - 연립 주택은 현관/위층 2구역에서 계단 밑 수납장, 잠긴 바닥 저장칸, 옥탑 문 앞까지 5구역 구조로 확장되었고, 작은 드라이버로 조용히 비상 저장칸을 여는 선택과 전용 성공 컷신을 가진다.
  - 소형 여관은 로비/객실 2구역에서 프런트 열쇠함, 잠긴 린넨실, 창문 깨진 객실까지 5구역 구조로 확장되었고, 린넨실 열쇠를 찾아 보온 물자를 분류하는 큰 결정과 전용 성공 컷신을 가진다.
  - 현재 로컬 Git 커밋은 생성되지만 이 Windows 환경의 GitHub 인증이 없어 `git push`는 사용자명/자격증명 프롬프트에서 멈춘다. Codex GitHub 앱도 현재 저장소에 `pull` 권한만 있어 원격 쓰기는 인증 보강 전까지 보류된다.
  - 주인공 상하 걷기 프레임은 좌우로만 벌어지는 하체가 아니라 앞뒤 보폭이 교차하도록 다시 그렸고, 테스트도 상하 보행의 세로 발 디딤을 검증한다.

## Temporary Development Conditions

- Dev-only starter items and shortcut grants are still enabled for playtesting.
- Treat them as temporary scaffolding, not production behavior.
- Keep them in place until balance and survival pressure are stable enough to remove them cleanly.
