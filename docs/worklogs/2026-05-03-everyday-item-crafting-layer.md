# 2026-05-03 생활 아이템/응용 조합 레이어

## 배경

- 사용자는 단순한 생존 장비 목록이 아니라, 일상에서 충분히 볼 수 있는 물건을 원한다고 정리했다.
- 핵심 재미는 “마트나 집에서 본 물건을 주웠을 때, 이걸 이렇게 쓰면 되지 않나?”라는 머릿속 재난 시뮬레이션이 실제 조합으로 이어지는 것이다.
- 기존 500개 확장 아이템은 범위를 넓히는 데는 성공했지만, 개별 조합의 납득감과 생활 응용의 밀도는 아직 부족했다.

## 변경

- `game/data/items_everyday_expansion.json`을 추가했다.
  - 수작업 생활 아이템 118개를 추가했다.
  - 랩 포장 필름, 냉동용 지퍼백, 커피 필터, 빨대, 알루미늄 포장 뚜껑, 머리끈, 치실, 베개커버, 세탁망, 손거울, 가족사진, 방전된 보조배터리처럼 실제 생활 공간에서 흔히 볼 수 있는 물건을 중심으로 구성했다.
- `game/data/crafting_combinations_everyday_expansion.json`을 추가했다.
  - 수작업 응용 조합 56개를 추가했다.
  - 비닐봉투+신문지, 립밤+화장솜, 커피 필터+빈 커피 캔, LED 열쇠고리+머리끈, 베개커버+신발끈처럼 아이템명만 보고도 쓰임을 상상할 수 있는 조합을 우선했다.
- `game/data/loot_profiles_everyday_expansion.json`을 추가했다.
  - 새 아이템이 마트, 편의점, 아파트, 사무실, 약국, 카페, 세탁소, 창고에 맥락에 맞게 섞인다.
- 생활 아이템 118개에 대한 24px/32px 아이콘 236개를 생성하고 아이콘 매니페스트에 등록했다.
- `ContentLibrary`가 생활 아이템, 생활 조합, 생활 루팅 프로필 파일을 병합하도록 연결했다.

## 설계 기준

- 아이템은 “생존용 물건”만이 아니라 “사람이 살던 세계의 물건”이어야 한다.
- 조합 결과는 의외성이 있어도 억지스럽지 않아야 한다.
- 기능이 약한 물건도 `story`, `barter`, `personal`, `electronics` 태그로 감정적/거래적/미래적 가치를 남긴다.
- 이번 레이어는 아이템과 조합의 기반이며, 다음 단계에서는 특정 건물 이벤트의 선택지와 직접 연결해 “왜 이 물건을 챙겼는지”가 플레이 중 드러나게 해야 한다.

## 대표 조합

- `plastic_bag` + `newspaper` → 방수 점화재 파우치
- `evd_lip_balm_tube` + `evd_cotton_ball_pack` → 왁스 먹인 솜 점화재
- `evd_coffee_filter_pack` + `evd_empty_coffee_can` → 임시 물 거름 필터
- `evd_led_keychain_light` + `evd_hair_tie_pack` → 손목 고정 LED
- `evd_pillowcase` + `evd_shoelace_pair` → 천 어깨 운반끈
- `evd_silica_gel_packets` + `evd_shower_cap` → 발 건조 키트
- `evd_pocket_mirror` + `evd_lanyard` → 반사 신호 이름표
- `evd_sports_drink_powder` + `bottled_water` → 탄 스포츠음료

## 검증

- `res://tests/unit/test_everyday_item_crafting_layer.gd`
- `res://tests/unit/test_content_library.gd`
- `res://tests/unit/test_item_icon_resolver.gd`
