# 2026-04-20 Indoor Depth Expansion Ledger

이번 패스에서 정본 데이터에 추가되거나 실질적으로 비중이 커진 항목만 따로 분리한 리소스 요청용 목록이다.

## Anchor Sites

### `mart_01`
- 성격: 생활물자 허브, 직원 구역과 2층 보관실이 핵심
- 새/강화 공간:
  - `snack_aisle`
  - `freezer_row`
  - `back_hall`
  - `staff_corridor_gate`
  - `cold_storage`
  - `stair_landing`
  - `break_room`
  - `office`
  - `warehouse`
  - `locked_storage`
- 연출 메모:
  - 전면보다 후면과 2층이 더 중요하게 느껴져야 함
  - 포장재, 생활 보온품, 직원 흔적, 장부/열쇠 연출이 필요

### `hardware_01`
- 성격: 수리/밀봉/결속 자재 허브
- 새/강화 공간:
  - `parts_shelf`
  - `workbench`
  - `backroom_door`
  - `backroom`
  - `loading_corner`
- 연출 메모:
  - 작은 부품 서랍, 자재실 문, 적재 코너 시각 구분 필요

### `apartment_01`
- 성격: 생활 흔적, 층간 구조, 보일러실 루프
- 새/강화 공간:
  - `janitor_closet`
  - `unit_101_room`
  - `second_floor_hall`
  - `laundry_room`
  - `unit_201_room`
  - `boiler_stair`
  - `boiler_room`
  - `rooftop_door`
- 연출 메모:
  - 1층/2층/지하 관리구역의 생활 밀도 차이가 느껴져야 함
  - 메모, 열쇠, 세탁물, 보온 생활용품 비주얼 중요

### `warehouse_01` / `garage_01`
- 성격: 물류/정비 계열 확장 사이트
- 새/강화 공간:
  - `warehouse_01`
    - `pallet_lane`
    - `office_cage`
    - `shutter_gate`
    - `deep_storage`
  - `garage_01`
    - `parts_cabinet`
    - `service_pit`
    - `tool_locker`
- 연출 메모:
  - 큰 용기, 호스, 작업용 천, 정비 흔적이 구역별로 구분돼야 함

## Uplifted Existing Sites

아래 건물들은 `one-zone shell`에서 `입구 + 안쪽/후면 구역` 구조로 최소 보강됨.

- `bakery_01`
- `bookstore_01`
- `butcher_01`
- `cafe_01`
- `canteen_01`
- `chapel_01`
- `church_01`
- `corner_store_01`
- `deli_01`
- `hostel_01`
- `pharmacy_01`
- `police_box_01`
- `repair_shop_01`
- `residence_01`
- `restaurant_01`
- `row_house_01`
- `school_gate_01`
- `storage_depot_01`
- `tea_shop_01`

## New Items

| item_id | 표시명 | 분류 | 리소스 메모 |
| --- | --- | --- | --- |
| `butter_cookie_box` | 버터 쿠키 상자 | 단독 소비품 | 포장 과자 |
| `instant_cocoa_mix` | 즉석 코코아 믹스 | 식품 재료 | 따뜻한 음료 분말 |
| `cling_wrap_roll` | 랩 롤 | 생활 재료 | 얇은 포장 필름 |
| `foil_tray_pack` | 호일 트레이 묶음 | 생활 재료 | 작은 금속 용기 |
| `hand_warmer_pack` | 손난로 묶음 | 단독 보온품 | 소형 보온 생활품 |
| `mart_stock_note_01` | 마트 재고 메모 | 문서/단서 | 손메모/장부 쪽지 |
| `sealant_tube` | 실런트 튜브 | 조합 재료 | 틈막이 튜브 |
| `hose_clamp` | 호스 밴드 | 조합 재료 | 금속 클램프 |
| `rubber_gasket` | 고무 가스켓 | 조합 재료 | 원형 밀봉 부품 |
| `epoxy_putty` | 에폭시 퍼티 | 조합 재료 | 회색 보수 덩어리 |
| `hardware_backroom_key` | 철물점 자재실 열쇠 | 열쇠 | 금속 소형 열쇠 |
| `sewing_kit` | 바느질 도구 | 도구 | 실/바늘/작은 케이스 |
| `knit_cap` | 니트 모자 | 생활 보온품 | 겨울 모자 |
| `slippers` | 실내화 | 생활용품 | 간단한 슬리퍼 |
| `detergent_pod_pack` | 세제 캡슐 묶음 | 생활 소모품 | 세탁 세제 |
| `apartment_boiler_key` | 보일러실 열쇠 | 열쇠 | 오래된 관리실 열쇠 |
| `empty_jerrycan` | 빈 제리캔 | 용기 | 큰 휴대 용기 |
| `siphon_hose` | 사이펀 호스 | 조합 재료 | 유체 이송 호스 |
| `shop_towel_bundle` | 작업용 타월 묶음 | 생활/정비 재료 | 두꺼운 작업 천 |
| `tarp_sheet` | 방수포 | 생활/차단 재료 | 큰 덮개 시트 |
| `drain_funnel` | 깔때기 | 용기 보조재 | 작은 깔때기 |
| `warehouse_shutter_key` | 창고 셔터 열쇠 | 열쇠 | 셔터용 금속 열쇠 |

## New Crafted Outcomes

| item_id | 표시명 | 분류 | 리소스 메모 |
| --- | --- | --- | --- |
| `sealed_window_patch` | 밀봉 창문 패치 | 제작 결과물 | 임시 틈막이 패치 |
| `transfer_hose` | 이송 호스 | 제작 결과물 | 고정된 호스 장치 |
| `patched_blanket` | 기운 담요 | 제작 결과물 | 수선 흔적 있는 담요 |
| `solvent_wipes` | 세척용 와이프 | 제작 결과물 | 약품 적신 천/와이프 |
| `tarp_bedroll` | 방수 침낭말이 | 제작 결과물 | 방수포+담요 묶음 |
| `foil_tray_warmer` | 호일 트레이 워머 | 제작 결과물 | 작은 반사 보온 장치 |
| `wrapped_hot_water_bottle` | 감싼 온수병 | 제작 결과물 | 보온 처리한 온수병 |

## New Recipe Coverage

기존 아이템과 신규 아이템이 섞이는 대표 조합만 적는다.

- `sealant_tube + clear_plastic_sheet -> sealed_window_patch`
- `hose_clamp + siphon_hose -> transfer_hose`
- `sewing_kit + old_blanket -> patched_blanket`
- `shop_towel_bundle + rubbing_alcohol -> solvent_wipes`
- `tarp_sheet + old_blanket -> tarp_bedroll`
- `foil_tray_pack + tea_light_candle -> foil_tray_warmer`
- `cling_wrap_roll + hot_water_bottle -> wrapped_hot_water_bottle`

## Follow-up Art Targets

이번 패스 이후 별도 리소스로 있으면 바로 체감이 올라가는 대상:

- 마트 직원 구역/보관실 전용 소형 프롭
- 철물점 부품 서랍/자재실 소품
- 아파트 세탁실/보일러실 소품
- 물류용 큰 용기, 호스, 작업 천, 셔터 키 비주얼
- 신규 열쇠/문서/생활 보온품 아이콘 보강
