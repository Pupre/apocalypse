# 2026-05-04 중간 목적지 이벤트와 컷신 확장

## 목적

- 12x12 야외 대지역 맵이 큰 랜드마크만 있는 구조로 느껴지지 않도록, 이동 중 들르는 중간 목적지를 실제 플레이 콘텐츠로 채운다.
- 사용자가 원한 "건물마다 다른 일러스트, 깊어진 선택지, 큰 결정의 감성"을 주요 랜드마크 바깥까지 확장한다.
- 단순히 보급품을 더 주는 장소가 아니라, 생활감 있는 물건과 위험 판단, 운반 무게, 다음 이동 계획을 함께 묻는 장소로 만든다.

## 구현

- `mapx_08_04_a`를 `눈보라 휴게소 자판기 코너`로 승격했다.
  - 서비스 패널을 조용히 열어 필요한 것만 챙기는 선택과, 유리를 깨고 빠르게 털어 소음과 위험을 키우는 선택을 넣었다.
  - 컷신: `resources/ui/master/indoor/indoor_story_rest_stop_vending_choice.png`
- `mapx_06_07_b`를 `동결된 택배 분류 센터`로 승격했다.
  - 무작위 택배 상자를 뜯는 선택과, 송장/노선을 읽어 다음 탐색 경로까지 얻는 선택을 넣었다.
  - 컷신: `resources/ui/master/indoor/indoor_story_parcel_route_sort_choice.png`
- `mapx_05_11_a`를 `외곽 농가 창고`로 승격했다.
  - 쌀과 공구를 균형 있게 챙기는 선택과, 무거운 쌀 포대를 무리해서 들고 나가는 선택을 넣었다.
  - 컷신: `resources/ui/master/indoor/indoor_story_farm_storage_weight_choice.png`
- `tools/generate_outdoor_map_expansion.py`의 특수 건물 오버라이드를 갱신해 자동 재생성 후에도 세 장소가 전용 이벤트를 유지하게 했다.
- `UiKitResolver`, 실내 매니페스트, 마스터 매니페스트를 갱신해 새 컷신 이미지가 게임에서 로드되도록 연결했다.
- 검수용 임시 이미지와 Godot 로컬 유저 데이터는 삭제하지 않고 `.gitignore`에 추가했다.
  - 사용자가 장시간 자동화 중 허가 팝업에 막히지 않도록, 앞으로도 임시/캐시 정리는 삭제보다 무시 처리 또는 최종 보고 방식으로 다룬다.

## 검증

- 신규 `mapx_` 실내 이벤트 JSON 15개 파싱 확인.
- 신규 이벤트 안의 아이템 참조가 현재 아이템 풀에 존재하는지 확인.
- 신규 컷신 이미지 3장 960x480 확인.
- Godot 실행은 현재 앱 샌드박스에서 기본 유저 데이터 경로 생성이 막혀 있어, 워크스페이스 내부 `godot_user_data/`로 `APPDATA`와 `LOCALAPPDATA`를 돌려 실행했다.
- 통과한 테스트
  - `res://tests/unit/test_outdoor_map_expansion.gd`
  - `res://tests/unit/test_indoor_director.gd`
  - `res://tests/unit/test_content_library.gd`
  - `res://tests/smoke/test_first_playable_loop.gd`

## 다음 작업 후보

- 같은 방식으로 발전소 외곽, 의료·관공 지구 골목, 대피선 주변, 농촌 샛길에 소형 목적지를 더 촘촘히 배치한다.
- 각 목적지에 컷신을 1장씩만 두지 말고, 큰 결정 성공/실패 결과 화면을 별도 일러스트로 분리한다.
- 야외 맵에서 대지역 내부 패턴이 아직 도식적으로 보이는 구간을 줄이기 위해 자연 지형, 외곽 도로, 공업 시설, 농지 사이 경계선을 더 불규칙하게 만든다.
