# Outdoor Art Integration Pass 1 Design

## Goal

현재 외부 월드의 임시 도형 렌더링을 `frozen_city_devpack_v2_alpha_verified` 자산으로 대체해, 플레이어가 실제 게임처럼 읽히는 첫 번째 외부 아트 패스를 만든다.

이번 패스는 `외부 월드 + 플레이어`까지만 포함한다. 체력바/스태미나바 같은 UI 바 교체는 포함하지 않는다.

## Scope

포함:
- 외부 지형 렌더링을 terrain 타일 기반으로 교체
- 건물 마커를 building sprite 기반으로 교체
- 주요 프롭을 sprite 기반으로 추가
- 플레이어 도형을 방향별 sprite 애니메이션으로 교체
- 기존 world/runtime 구조를 유지한 채 art layer만 교체

제외:
- HUD/가방/전체맵 UI 재스킨
- 실내 아트 교체
- 불/연료 시스템
- 오디오

## Asset Policy

런타임 기준은 dev pack의 메타를 따른다.

- terrain:
  - `resources/frozen_city_devpack_v2_alpha_verified/terrain/`
  - opaque tile로 사용
- player:
  - `resources/frozen_city_devpack_v2_alpha_verified/player/`
  - transparent sprite 사용
- props:
  - `resources/frozen_city_devpack_v2_alpha_verified/props_cutout/`
  - cutout variant를 기본값으로 사용
- buildings:
  - `resources/frozen_city_devpack_v2_alpha_verified/buildings_cutout/`
  - cutout variant를 기본값으로 사용
- decals:
  - `resources/frozen_city_devpack_v2_alpha_verified/decals/`
  - 1차에서는 `snow_patch`, `ice_patch`, `crack_overlay`만 제한적으로 사용

선택 이유:
- 현재 엔진 배치에서는 soft alpha shadow보다 cutout edge가 덜 탁하고 읽기 쉽다.
- terrain은 opaque이므로 ground layer에 그대로 깔기 적합하다.

## Rendering Direction

### Ground

외부 ground는 단일 asphalt polygon에서 벗어나 `tile strip + block patch` 기반으로 재구성한다.

기본 규칙:
- 도로:
  - `road_plain`
  - 필요 구간에 `road_lane_h`, `road_lane_v`
  - 교차점에 `road_intersection`
  - 일부 변주에 `road_cracked`, `slush_road`, `manhole_road`
- 보도:
  - `sidewalk_snow`
  - 가장자리 읽힘이 필요한 곳에 `curb_*`
- 공터/비포장 영역:
  - `snow_ground`
- 진입감 포인트:
  - `crosswalk_h`, `crosswalk_v`

이번 패스에서는 완전한 autotile 시스템을 만들지 않는다. 현재 authored world block 데이터를 읽어 필요한 타일을 명시적으로 배치한다.

### Buildings

현재 사각형 마커 대신 building sprite를 사용한다.

매핑 기준:
- `mart_01` -> `building_mart.png`
- `apartment_01`, `residence_01` -> `building_apartment.png`
- `clinic_01` -> `building_clinic.png`
- `office_01`, `repair_shop_01` -> `building_office.png`
- `pharmacy_01` -> `building_pharmacy.png`
- `cafe_01`, `restaurant_01`, `bakery_01` -> `building_cafe.png`
- `warehouse_01`, `hardware_01`, `gas_station_01`, `laundry_01` -> `building_warehouse.png`
- `police_box_01` -> `building_police.png`

건물 이름 라벨은 완전히 제거하지 않는다. 다만 sprite만으로도 식별되도록 라벨은 더 작고 보조적으로 유지한다.

피벗은 bottom-center 기준으로 둔다.

### Props

외부가 비어 보이지 않게 `props_cutout` 자산으로 밀도를 만든다.

1차 사용 프롭:
- `frozen_car`
- `roadblock`
- `sandbags`
- `street_lamp`
- `dumpster_snow`
- `dead_tree`
- `crate_stack`

프롭은 world block data의 obstacle row 또는 새 prop row에서 배치한다. 이번 패스에서는 최소한 현재 obstacle system이 렌더링 대상을 sprite로 가질 수 있게 만드는 쪽을 우선한다.

### Decals

1차는 가볍게만 넣는다.

사용 대상:
- `snow_patch`
- `ice_patch`
- `crack_overlay`

목적:
- 길 표면 반복감 줄이기
- 눈/얼음 세계관 강조

`wind_streak`, `frost_corner`, `warm_spill` 같은 감성 연출은 2차 폴리시로 미룬다.

## Player

현재 polygon player marker를 제거하고 방향별 sprite로 바꾼다.

자산:
- `player/down_idle.png`
- `player/down_walk1..4.png`
- `player/left_*`
- `player/right_*`
- `player/up_*`

동작:
- 정지 시 idle frame
- 이동 시 해당 방향 walk cycle
- 방향은 마지막 유효 입력 기준

이번 패스에서는 AnimationPlayer를 강하게 얹기보다, 현재 이동 벡터 기반으로 Sprite2D texture를 교체하는 단순 구조로 먼저 간다. 구현이 빠르고 유지가 쉽다.

## Architecture

기존 outdoor runtime과 authored block/world 구조는 유지한다.

새로 필요한 책임:
- outdoor art resolver:
  - building id/category -> sprite path
  - prop type -> sprite path
  - terrain token -> texture path
- outdoor renderer split:
  - ground tiles
  - buildings
  - props/obstacles
  - decals
  - player sprite

중요한 점:
- 지금 만든 `64x64 fixed city block + 3x3 runtime` 구조를 버리지 않는다.
- art는 runtime 위에 얹히는 presentation layer다.
- path/scale/pivot contract를 명시해서 나중에 자산이 늘어나도 구조가 안 무너지게 한다.

## Success Criteria

완료 기준:
- 외부에 들어가면 더 이상 임시 사각형 건물/삼각형 플레이어가 보이지 않는다.
- 도로/보도/눈 바닥이 타일 기반으로 읽힌다.
- 주요 프롭이 들어가서 거리 밀도가 생긴다.
- 기존 outdoor 테스트와 smoke 루프가 유지된다.

체감 기준:
- “개발용 도형 월드”가 아니라 “빙하기 도시 거리”처럼 보이기 시작해야 한다.
