from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
GAME_DATA = ROOT / "game" / "data"
ICON_ROOT = ROOT / "resources" / "items" / "icons"
MANIFEST_PATH = ICON_ROOT / "item_icons_manifest.json"

ITEM_OUTPUT = GAME_DATA / "items_everyday_expansion.json"
RECIPE_OUTPUT = GAME_DATA / "crafting_combinations_everyday_expansion.json"
LOOT_OUTPUT = GAME_DATA / "loot_profiles_everyday_expansion.json"

PREFIX = "evd_"


def write_json(path: Path, data: Any) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def item(
    item_id: str,
    name: str,
    category: str,
    weight: float,
    description: str,
    usage_hint: str,
    cold_hint: str,
    tags: list[str],
    spawns: list[str],
    bulk: int = 1,
    **extra: Any,
) -> dict[str, Any]:
    row: dict[str, Any] = {
        "id": item_id,
        "name": name,
        "bulk": bulk,
        "carry_weight": weight,
        "description": description,
        "usage_hint": usage_hint,
        "cold_hint": cold_hint,
        "category": category,
        "item_tags": sorted(set(tags + ["ordinary_world"])),
        "spawn_profiles": sorted(set(spawns)),
    }
    row.update(extra)
    return row


EVERYDAY_ITEMS: list[dict[str, Any]] = [
    item("evd_cling_film_roll", "랩 포장 필름", "utility", 0.25, "주방 서랍에서 흔히 나오는 얇은 랩 필름이다.", "젖으면 안 되는 물건을 감싸거나 틈을 임시로 막을 수 있다.", "바람이 새는 틈을 막을 때 생각보다 값어치가 크다.", ["plastic", "waterproof", "wrap"], ["retail", "residential", "food_service", "living_goods"]),
    item("evd_freezer_bag_box", "냉동용 지퍼백 상자", "container", 0.35, "두꺼운 지퍼백이 여러 장 들어 있는 상자다.", "작은 물건을 건조하게 나누어 담기 좋다.", "마른 양말, 성냥, 종이를 따로 보관하면 이동 중 실수가 줄어든다.", ["container", "waterproof", "sort"], ["retail", "residential", "food_service", "living_goods"]),
    item("evd_paper_cup_stack", "종이컵 묶음", "household", 0.2, "카운터나 정수기 옆에 쌓여 있던 종이컵 묶음이다.", "작은 부품을 나누거나 양초 받침으로 쓸 수 있다.", "작은 불씨를 바닥에서 띄우는 받침이 될 수 있다.", ["paper", "cup", "craft_component"], ["retail", "office", "food_service"]),
    item("evd_coffee_filter_pack", "커피 필터", "household", 0.15, "카페 선반에서 쉽게 볼 수 있는 종이 커피 필터다.", "먼지나 찌꺼기를 거르는 임시 필터로 쓸 수 있다.", "눈 녹인 물을 바로 마시기 전 최소한의 거름망이 된다.", ["paper", "filter", "hygiene"], ["retail", "residential", "food_service", "office"]),
    item("evd_straw_bundle", "빨대 묶음", "utility", 0.1, "비닐 포장된 플라스틱 빨대 묶음이다.", "작은 관, 임시 깔때기, 표시 막대 재료가 된다.", "손이 얼어도 액체를 조금 덜 흘리고 옮기는 데 도움 된다.", ["plastic", "tube", "craft_component"], ["retail", "food_service", "office"]),
    item("evd_aluminum_takeout_lid", "알루미늄 포장 뚜껑", "utility", 0.2, "배달 음식 용기에서 벗겨낸 얇은 알루미늄 뚜껑이다.", "열을 반사하거나 작은 받침으로 접어 쓸 수 있다.", "작은 열원을 벽 쪽으로 흩어지지 않게 되돌릴 수 있다.", ["metal", "reflector", "craft_component"], ["retail", "residential", "food_service"]),
    item("evd_takeout_chopsticks", "일회용 젓가락", "tool", 0.1, "포장지에 든 나무젓가락 한 벌이다.", "집게, 고정대, 작은 지지대로 쓸 수 있다.", "젖은 장갑을 벗지 않고 더러운 것을 건드리는 데도 쓸 만하다.", ["wood", "tool", "splint"], ["retail", "food_service", "office"]),
    item("evd_soy_sauce_packets", "간장 소포장", "food", 0.1, "도시락 옆에 굴러다니는 작은 간장 포장들이다.", "음식 맛을 살리거나 소금기 보충에 쓸 수 있다.", "체온을 직접 올리진 못해도 지친 식사를 넘기게 해 준다.", ["food", "seasoning", "consumable"], ["retail", "food_service"], hunger_restore=1, use_minutes=1),
    item("evd_salt_sachet", "소금 소포장", "food", 0.08, "작은 흰 소금 봉지 몇 개다.", "물이나 음식에 섞어 전해질을 조금 보충할 수 있다.", "땀을 흘렸거나 오래 걸은 뒤에는 작은 소금도 의미가 있다.", ["food", "seasoning", "electrolyte"], ["retail", "food_service", "residential"], hunger_restore=0, use_minutes=1),
    item("evd_sugar_sachet", "설탕 소포장", "food", 0.08, "카페에서 챙길 수 있는 작은 설탕 봉지들이다.", "뜨거운 물이나 음료에 넣어 빠른 열량을 보탤 수 있다.", "추운 길에서 당이 떨어질 때 작은 힘이 된다.", ["food", "sugar", "consumable"], ["retail", "food_service", "office"], hunger_restore=1, use_minutes=1),
    item("evd_peanut_butter_jar", "땅콩버터 병", "food", 0.8, "뚜껑이 단단한 땅콩버터 병이다.", "무겁지만 열량이 높고 오래 먹을 수 있다.", "몸이 식을수록 지방과 당분이 있는 음식의 가치가 커진다.", ["food", "calorie_dense", "jar"], ["retail", "residential", "food_service"], hunger_restore=18, thirst_restore=-1, use_minutes=5),
    item("evd_cereal_box", "시리얼 상자", "food", 0.5, "가볍지만 부피가 있는 시리얼 상자다.", "먹거나 속봉지를 따로 재료로 쓸 수 있다.", "당장은 든든하지 않아도 빠르게 씹어 넘기기 좋다.", ["food", "box", "paper"], ["retail", "residential"], hunger_restore=10, thirst_restore=-1, use_minutes=5),
    item("evd_instant_oatmeal_cup", "즉석 오트밀 컵", "food", 0.35, "물을 부어 먹는 일회용 오트밀 컵이다.", "그냥 먹을 수도 있고 뜨거운 물을 만나면 훨씬 낫다.", "따뜻하게 먹을 수 있다면 작은 식사가 회복으로 바뀐다.", ["food", "cup", "warm_meal"], ["retail", "residential", "food_service"], hunger_restore=9, thirst_restore=-1, use_minutes=5),
    item("evd_rice_bag_small", "소포장 쌀", "food", 1.2, "작은 비닐 포장에 담긴 쌀이다.", "그 자체로는 손이 가지만 오래 버틸 식량이다.", "거점에서 끓일 수 있다면 무게를 감수할 이유가 생긴다.", ["food", "grain", "bulk_food"], ["retail", "residential", "food_service"], hunger_restore=2, use_minutes=5, bulk=2),
    item("evd_pet_food_pouch", "반려동물 사료 파우치", "food", 0.4, "작은 파우치에 든 반려동물 사료다.", "먹고 싶진 않지만 극한 상황의 마지막 열량이다.", "사람 음식이 아니어도 굶주림 앞에서는 선택지가 된다.", ["food", "barter", "last_resort"], ["retail", "residential"], hunger_restore=5, thirst_restore=-1, use_minutes=5),
    item("evd_baby_formula_can", "분유 캔", "food", 0.7, "뚜껑이 남은 분유 캔이다.", "물과 섞으면 영양가 있는 음료가 된다.", "아이 물건이라는 감정적 무게도 같이 남아 있다.", ["food", "powder", "story"], ["retail", "residential", "medical"], hunger_restore=6, thirst_restore=-1, use_minutes=5),
    item("evd_sports_drink_powder", "스포츠음료 분말", "drink", 0.2, "물에 타 먹는 스포츠음료 분말이다.", "물과 섞으면 당과 전해질을 보충할 수 있다.", "오래 걷고 떨린 뒤에는 그냥 물보다 낫다.", ["drink", "powder", "electrolyte"], ["retail", "medical", "residential"], use_minutes=2),
    item("evd_canned_fruit_cup", "과일 컵", "food", 0.35, "시럽에 잠긴 작은 과일 컵이다.", "갈증과 허기를 동시에 조금 달랜다.", "차갑더라도 당분이 빠르게 들어온다.", ["food", "drink", "consumable"], ["retail", "residential", "food_service"], hunger_restore=5, thirst_restore=3, use_minutes=3),
    item("evd_bread_clip", "식빵 클립", "utility", 0.02, "식빵 봉지를 묶던 작은 플라스틱 클립이다.", "선, 봉투, 표시지를 작게 고정할 수 있다.", "사소해 보여도 손이 굳으면 작은 고정구가 시간을 아낀다.", ["plastic", "clip", "tiny"], ["retail", "residential", "food_service"]),
    item("evd_twist_tie_bundle", "철심 끈 묶음", "utility", 0.08, "비닐봉지 입구를 묶는 철심 끈 여러 개다.", "작은 물건을 묶거나 임시 고정하는 데 좋다.", "테이프를 아끼고 싶을 때 먼저 쓰기 좋은 재료다.", ["wire", "binding", "craft_component"], ["retail", "residential", "food_service", "office"]),
    item("evd_baking_soda_box", "베이킹소다 상자", "household", 0.6, "싱크대 아래에 있던 베이킹소다 상자다.", "냄새를 줄이거나 젖은 곳을 말리는 보조재로 쓸 수 있다.", "젖은 신발과 가방 냄새를 잡으면 장기 이동이 조금 편해진다.", ["powder", "cleaning", "odor_control"], ["retail", "residential", "living_goods"]),
    item("evd_vinegar_bottle", "식초 병", "household", 0.7, "반쯤 남은 식초 병이다.", "세척, 냄새 제거, 간단한 음식 보정에 쓸 수 있다.", "깨끗하지 않은 곳을 닦아낼 때 심리적인 안정감도 준다.", ["cleaning", "food", "liquid"], ["retail", "residential", "food_service"], thirst_restore=-1, use_minutes=2),
    item("evd_kitchen_sponge", "주방 스펀지", "household", 0.08, "싱크대 옆에 놓여 있던 새 주방 스펀지다.", "물기를 머금게 하거나 닦는 재료로 쓸 수 있다.", "젖은 바닥이나 작은 누수를 처리할 때 손보다 낫다.", ["sponge", "cleaning", "absorbent"], ["retail", "residential", "food_service", "living_goods"]),
    item("evd_dish_scrubber", "수세미", "household", 0.12, "거친 면이 있는 수세미다.", "녹, 때, 얼어붙은 찌꺼기를 긁어낼 수 있다.", "미끄러운 손잡이나 용기를 정리하는 데 도움이 된다.", ["cleaning", "abrasive"], ["retail", "residential", "food_service"]),
    item("evd_microfiber_cloth", "극세사 천", "household", 0.1, "안경이나 화면을 닦는 부드러운 극세사 천이다.", "렌즈, 손전등, 거울을 닦아 시야를 살릴 수 있다.", "시야가 흐리면 추위보다 먼저 판단이 무너진다.", ["cloth", "cleaning", "lens"], ["retail", "office", "residential"]),
    item("evd_pillowcase", "베개 커버", "household", 0.25, "침구에서 벗겨낸 면 베개 커버다.", "천 주머니, 보온 덧감, 임시 운반구 재료가 된다.", "마른 천 하나는 몸과 물건을 분리해 주는 얇은 안전선이다.", ["textile", "bag_shell", "cloth"], ["residential", "medical", "living_goods"]),
    item("evd_old_tshirt", "낡은 티셔츠", "household", 0.35, "누군가 입던 낡은 면 티셔츠다.", "찢어서 끈, 붕대, 보온 덧감으로 쓸 수 있다.", "마른 천은 추위와 상처 양쪽에 모두 값어치가 있다.", ["textile", "cloth", "craft_component"], ["residential", "retail", "living_goods"]),
    item("evd_shower_cap", "샤워캡", "utility", 0.05, "일회용 비닐 샤워캡이다.", "작은 물건이나 신발 입구를 씌워 물기를 막을 수 있다.", "발이 젖는 것을 늦추면 체온 손실도 늦어진다.", ["plastic", "waterproof", "cover"], ["residential", "medical", "retail"]),
    item("evd_hair_tie_pack", "머리끈 묶음", "utility", 0.05, "탄성이 남아 있는 머리끈 여러 개다.", "작은 물건을 묶거나 몸에 고정하는 데 좋다.", "손이 얼면 매듭보다 탄성 끈이 훨씬 빠르다.", ["elastic", "binding", "craft_component"], ["retail", "residential", "medical"]),
    item("evd_shoelace_pair", "여분 신발끈", "utility", 0.08, "새 신발끈 한 쌍이다.", "묶고, 걸고, 어깨끈을 보강하는 기본 재료다.", "끈은 거점 밖에서 항상 부족해지는 물건이다.", ["cord", "binding", "repair"], ["retail", "residential", "security"]),
    item("evd_wire_hanger", "철사 옷걸이", "tool", 0.18, "휘어진 철사 옷걸이다.", "걸이, 후크, 작은 프레임으로 구부릴 수 있다.", "손이 닿지 않는 곳의 물건을 끌어오는 데도 쓸 수 있다.", ["wire", "hook", "tool"], ["residential", "office", "medical"]),
    item("evd_clothespin_set", "빨래집게 묶음", "utility", 0.12, "플라스틱 빨래집게 몇 개가 묶여 있다.", "천이나 비닐을 빠르게 고정하는 데 쓸 수 있다.", "바람막이를 세울 때 손을 덜 쓰게 해 준다.", ["clip", "laundry", "craft_component"], ["residential", "retail", "living_goods"]),
    item("evd_rubber_doorstop", "고무 문쐐기", "tool", 0.22, "문 밑에 끼우는 작은 고무 문쐐기다.", "문을 벌려 두거나 닫히지 않게 고정할 수 있다.", "실내에서 퇴로를 확보하는 작은 안전장치가 된다.", ["door", "wedge", "tool"], ["office", "residential", "medical"]),
    item("evd_silicone_hot_pad", "실리콘 냄비받침", "household", 0.18, "열에 강한 실리콘 냄비받침이다.", "뜨거운 용기를 잡거나 미끄럼 방지 패드로 쓸 수 있다.", "작은 열원을 다룰 때 손을 덜 다치게 한다.", ["heat_safe", "grip", "craft_component"], ["residential", "food_service", "retail"]),
    item("evd_laundry_mesh_bag", "세탁망", "container", 0.12, "지퍼가 달린 얇은 세탁망이다.", "가벼운 물건을 한데 묶거나 젖은 옷을 분리할 수 있다.", "마른 것과 젖은 것을 나누면 추위가 덜 번진다.", ["container", "mesh", "sort"], ["residential", "retail", "living_goods"]),
    item("evd_dryer_sheet_box", "건조기 시트 상자", "household", 0.2, "향이 남아 있는 건조기 시트 상자다.", "냄새를 누르거나 마른 종이 재료로 쓸 수 있다.", "젖은 냄새와 불쾌감을 줄이면 오래 버티기 쉽다.", ["paper", "odor_control", "dry"], ["residential", "laundry", "retail"]),
    item("evd_candle_stub", "남은 양초 토막", "utility", 0.18, "반쯤 타다 남은 양초 토막이다.", "불씨, 왁스, 작은 빛으로 다시 쓸 수 있다.", "작아도 바람을 막아 주면 체감 가치가 커진다.", ["wax", "fire", "light"], ["residential", "office", "church", "retail"]),
    item("evd_empty_coffee_can", "빈 커피 캔", "container", 0.12, "뚜껑을 딴 빈 금속 커피 캔이다.", "작은 부품을 담거나 받침, 컵, 바람막이로 쓸 수 있다.", "금속 용기는 작은 열원 주변에서 쓸모가 많다.", ["metal", "can", "container"], ["retail", "office", "food_service"]),
    item("evd_plastic_lid_round", "둥근 플라스틱 뚜껑", "utility", 0.05, "컵이나 용기에서 남은 둥근 플라스틱 뚜껑이다.", "받침, 덮개, 표시판 재료가 된다.", "젖은 바닥과 물건 사이에 작은 층을 만들 수 있다.", ["plastic", "lid", "craft_component"], ["retail", "residential", "food_service"]),
    item("evd_freezer_pack", "녹은 아이스팩", "medical", 0.45, "차갑진 않지만 젤이 남은 아이스팩이다.", "충격 완충재나 압박 팩으로 다시 쓸 수 있다.", "체온을 빼앗기지 않게 천으로 감싸 써야 한다.", ["gel", "medical", "padding"], ["retail", "medical", "food_service"]),
    item("evd_binder_clip_large", "큰 집게 클립", "office", 0.08, "서류를 묶던 큰 검은 집게 클립이다.", "천, 비닐, 종이를 빠르게 물려 고정할 수 있다.", "추운 손으로도 매듭보다 빠르게 고정할 수 있다.", ["clip", "office", "craft_component"], ["office", "retail", "residential"]),
    item("evd_paper_clip_chain", "클립 줄", "office", 0.05, "종이 클립을 이어 만든 짧은 줄이다.", "작은 고리나 임시 연결부로 쓸 수 있다.", "끈이 부족할 때 작은 연결고리가 된다.", ["wire", "office", "link"], ["office", "retail"]),
    item("evd_plastic_file_folder", "투명 파일철", "office", 0.15, "얇은 투명 플라스틱 파일철이다.", "문서나 종이를 젖지 않게 감싸는 데 쓸 수 있다.", "지도와 메모가 젖지 않으면 길을 잃을 확률도 줄어든다.", ["plastic", "document", "waterproof"], ["office", "retail", "school"]),
    item("evd_lanyard", "목걸이 줄", "utility", 0.08, "사원증에 달려 있던 목걸이 줄이다.", "작은 도구를 몸에 묶어 잃어버리지 않게 할 수 있다.", "장갑을 낀 채 떨어뜨리기 쉬운 물건을 붙잡아 준다.", ["cord", "carry", "office"], ["office", "security", "retail"]),
    item("evd_permanent_marker", "유성 매직", "tool", 0.08, "뚜껑이 잘 닫힌 검은 유성 매직이다.", "표시, 경고문, 경로 표식에 쓸 수 있다.", "눈발 속에서는 작은 글씨보다 굵은 표시가 살아남는다.", ["marker", "signal", "tool"], ["office", "retail", "residential"]),
    item("evd_pencil_stub", "몽당연필", "office", 0.03, "짧게 닳은 연필 한 자루다.", "젖지 않은 종이에 기록을 남길 수 있다.", "배터리 없는 상황에서는 연필이 가장 오래 가는 기록 도구다.", ["writing", "office", "story"], ["office", "residential", "school"]),
    item("evd_sticky_note_pad", "포스트잇 묶음", "office", 0.08, "반쯤 남은 포스트잇 묶음이다.", "임시 표식이나 짧은 메모로 쓸 수 있다.", "실내 구조를 기억하기 위해 문에 붙여 두기 좋다.", ["paper", "marker", "office"], ["office", "retail", "school"]),
    item("evd_calendar_page", "찢어진 달력장", "paper", 0.06, "벽에서 찢겨 나온 큰 달력장이다.", "지도처럼 접거나 큼직한 표지로 쓸 수 있다.", "흰 바탕에 굵은 글씨를 쓰면 눈 속에서도 잘 보인다.", ["paper", "signal", "story"], ["office", "residential", "retail"]),
    item("evd_mouse_pad", "마우스패드", "office", 0.16, "얇은 고무 바닥이 붙은 마우스패드다.", "무릎, 손바닥, 바닥 미끄럼 방지 패드로 쓸 수 있다.", "차가운 바닥에 직접 닿는 시간을 줄여 준다.", ["rubber", "padding", "office"], ["office", "residential", "repair"]),
    item("evd_clear_tape_small", "투명 테이프", "utility", 0.12, "작은 사무용 투명 테이프다.", "종이, 비닐, 작은 포장을 고정할 수 있다.", "덕트테이프를 쓰기 아까운 작은 수리에 좋다.", ["tape", "repair", "office"], ["office", "retail", "residential"]),
    item("evd_hand_wipes_pack", "물티슈 팩", "medical", 0.25, "아직 마르지 않은 휴대용 물티슈 팩이다.", "손, 상처 주변, 더러운 물건을 닦을 수 있다.", "위생이 무너지면 작은 상처도 긴 문제가 된다.", ["hygiene", "wipe", "medical"], ["retail", "medical", "residential"], health_restore=1, use_minutes=3),
    item("evd_lip_balm_tube", "립밤", "medical", 0.04, "주머니에서 나온 작은 립밤이다.", "갈라진 피부를 막거나 종이에 왁스를 먹이는 데 쓸 수 있다.", "입술과 손끝이 갈라지면 모든 작업이 느려진다.", ["wax", "skin", "medical"], ["retail", "medical", "residential"], health_restore=1, use_minutes=2),
    item("evd_eye_drop_bottle", "인공눈물", "medical", 0.05, "일회용 인공눈물 몇 개가 들어 있다.", "눈이 따갑거나 먼지를 뒤집어썼을 때 쓸 수 있다.", "바람과 눈발 속에서 시야를 되찾는 데 도움이 된다.", ["medical", "eye", "consumable"], ["medical", "retail", "office"], health_restore=1, use_minutes=2),
    item("evd_disposable_gloves_pair", "일회용 장갑", "equipment", 0.05, "얇은 니트릴 일회용 장갑 한 쌍이다.", "더러운 물건이나 깨진 유리 주변을 다룰 때 쓸 수 있다.", "보온은 약하지만 젖은 오염을 손에서 떼어 놓는다.", ["equipment", "hands", "hygiene"], ["medical", "retail", "food_service"], equip_slot="hands_layer", equip_effects={"outdoor_exposure_drain_multiplier": 0.99}),
    item("evd_cotton_ball_pack", "화장솜 봉지", "medical", 0.08, "부드러운 화장솜이 든 작은 봉지다.", "상처 주변을 닦거나 불쏘시개로 만들 수 있다.", "마른 솜은 점화재로도, 위생 재료로도 쓸모가 있다.", ["cotton", "medical", "tinder"], ["medical", "retail", "residential"]),
    item("evd_sanitary_pad_pack", "생리대 팩", "medical", 0.18, "흡수력이 좋은 생리대 몇 개가 든 팩이다.", "압박 패드, 신발 습기 흡수, 응급 위생 재료가 된다.", "젖은 발과 작은 출혈 모두에 뜻밖의 해답이 된다.", ["medical", "absorbent", "hygiene"], ["medical", "retail", "residential"]),
    item("evd_dental_floss", "치실", "utility", 0.03, "작은 플라스틱 케이스에 든 치실이다.", "가는 끈, 묶음, 수리용 실로 쓸 수 있다.", "얇지만 질긴 선은 작은 수리에 아주 귀하다.", ["cord", "hygiene", "repair"], ["medical", "retail", "residential"]),
    item("evd_toothbrush", "칫솔", "hygiene", 0.05, "새 포장 그대로인 칫솔이다.", "위생을 지키거나 좁은 틈을 문질러 닦을 수 있다.", "몸을 완전히 버리지 않았다는 감각을 지켜 준다.", ["hygiene", "cleaning", "small_tool"], ["medical", "retail", "residential"]),
    item("evd_pill_organizer", "요일 약통", "container", 0.08, "요일별 칸이 나뉜 작은 약통이다.", "알약, 건전지, 바늘처럼 작은 물건을 나누어 담기 좋다.", "작은 물건을 잃지 않는 것이 장기 생존의 품질을 올린다.", ["container", "medical", "sort"], ["medical", "residential", "retail"]),
    item("evd_elastic_bandage_clip", "붕대 고정 클립", "medical", 0.02, "탄력붕대 끝을 물리는 작은 금속 클립이다.", "천이나 붕대를 빠르게 고정하는 부품이 된다.", "추운 손으로 매듭을 묶기 힘들 때 작은 클립 하나가 크다.", ["medical", "clip", "repair"], ["medical", "residential"]),
    item("evd_usb_cable_short", "짧은 USB 케이블", "electronics", 0.08, "짧고 낡은 충전 케이블이다.", "충전뿐 아니라 묶거나 고정하는 선으로도 쓸 수 있다.", "전기가 없더라도 케이블은 질긴 끈이다.", ["electronics", "cord", "repair_part"], ["office", "residential", "retail", "repair"]),
    item("evd_usb_wall_charger", "USB 충전기", "electronics", 0.08, "콘센트에 꽂는 작은 USB 충전기다.", "전기가 살아 있는 곳에서는 충전 수단이 된다.", "충전 가능한 거점을 찾으면 가치가 급격히 오른다.", ["electronics", "charger", "barter"], ["office", "residential", "retail"]),
    item("evd_dead_power_bank", "방전된 보조배터리", "electronics", 0.35, "불이 들어오지 않는 작은 보조배터리다.", "당장은 무겁지만 충전 거점을 찾으면 다시 가치가 생긴다.", "배터리는 추위에 약하지만 전력은 여전히 생존 자원이다.", ["electronics", "battery", "barter"], ["office", "residential", "retail"]),
    item("evd_led_keychain_light", "열쇠고리 LED", "electronics", 0.04, "작은 버튼을 누르면 약한 빛이 나는 LED 열쇠고리다.", "가까운 곳을 확인하거나 몸에 묶어 보조 조명으로 쓸 수 있다.", "어두운 실내에서 양손을 조금이라도 자유롭게 해 준다.", ["electronics", "light", "tool"], ["office", "retail", "residential"], charges_max=3, initial_charges=2, charge_label="전력"),
    item("evd_alarm_clock_battery", "탁상시계 건전지", "electronics", 0.05, "탁상시계에서 빼낸 작은 건전지다.", "소형 전자기기를 잠깐 살릴 수 있다.", "추위에 약해도 예비 전력은 버리기 어렵다.", ["electronics", "battery"], ["office", "residential"]),
    item("evd_broken_earbuds", "고장난 이어폰", "electronics", 0.04, "한쪽이 끊어진 유선 이어폰이다.", "가는 선과 작은 고리를 재료로 쓸 수 있다.", "소리는 안 나도 선은 남는다.", ["electronics", "wire", "repair_part"], ["office", "residential", "retail"]),
    item("evd_phone_case", "낡은 휴대폰 케이스", "personal", 0.08, "주인 없는 휴대폰 케이스다.", "작은 물건을 감싸거나 핫팩을 붙이는 외피가 된다.", "손에 쥐는 전자기기를 추위에서 조금 떼어 놓는다.", ["plastic", "personal", "padding"], ["office", "residential", "retail"]),
    item("evd_remote_control", "리모컨", "electronics", 0.12, "버튼이 많은 낡은 리모컨이다.", "건전지를 빼거나 작은 부품을 얻을 수 있다.", "전원이 끊긴 집에서도 부품은 남는다.", ["electronics", "battery_holder", "repair_part"], ["residential", "office", "retail"]),
    item("evd_small_speaker", "미니 스피커", "electronics", 0.35, "휴대용 블루투스 스피커다.", "소리를 내거나 부품과 배터리 케이스로 뜯을 수 있다.", "위치 유도나 주의 분산 같은 위험한 활용 가능성이 있다.", ["electronics", "noise", "barter"], ["office", "residential", "retail"]),
    item("evd_screen_cleaning_cloth", "화면 닦는 천", "household", 0.03, "작은 극세사 화면 청소 천이다.", "렌즈와 화면을 닦거나 작은 물건을 감싼다.", "흐린 화면과 렌즈를 닦으면 정보가 다시 보인다.", ["cloth", "lens", "cleaning"], ["office", "retail", "residential"]),
    item("evd_family_photo_strip", "가족사진", "personal", 0.03, "지갑 안쪽에서 나온 오래된 가족사진이다.", "기능은 거의 없지만 누군가의 삶이 남아 있다.", "버리기 어렵다는 마음도 무게가 된다.", ["personal", "story", "barter"], ["residential", "office", "retail"]),
    item("evd_kids_sticker_sheet", "아이 스티커", "personal", 0.03, "캐릭터 스티커가 반쯤 남은 시트다.", "표식이나 임시 봉인에 쓸 수 있다.", "밝은 색은 어두운 실내에서 작은 표시가 된다.", ["personal", "marker", "story"], ["residential", "retail", "school"]),
    item("evd_lottery_ticket", "긁지 않은 복권", "personal", 0.02, "아직 긁지 않은 복권 한 장이다.", "생존 기능은 없지만 거래나 심리적 버팀목이 될 수 있다.", "쓸모없는 희망도 가끔은 사람을 움직이게 한다.", ["personal", "barter", "story"], ["retail", "office", "residential"]),
    item("evd_transit_card_empty", "잔액 없는 교통카드", "personal", 0.03, "잔액이 거의 없는 교통카드다.", "얇고 단단해서 긁개나 표시판으로 쓸 수 있다.", "도시가 멈춰도 도시의 물건은 다른 용도를 찾는다.", ["personal", "plastic", "scraper"], ["office", "retail", "residential"]),
    item("evd_glasses_case", "안경 케이스", "container", 0.12, "단단한 플라스틱 안경 케이스다.", "깨지기 쉬운 작은 물건을 넣어 보호할 수 있다.", "건전지나 성냥 같은 작은 물건을 보호하기 좋다.", ["container", "hard_case", "personal"], ["medical", "office", "residential"]),
    item("evd_pocket_mirror", "손거울", "personal", 0.08, "작은 플라스틱 손거울이다.", "시야 밖을 보거나 빛을 반사해 신호로 쓸 수 있다.", "직접 고개를 내밀지 않아도 모서리 너머를 볼 수 있다.", ["mirror", "signal", "personal"], ["medical", "retail", "residential"]),
    item("evd_sewing_button_card", "여분 단추 카드", "utility", 0.03, "종이 카드에 여러 단추가 붙어 있다.", "옷 수리나 작은 고정 부품으로 쓸 수 있다.", "옷이 벌어지는 작은 틈도 추위에는 커진다.", ["sewing", "repair", "button"], ["residential", "retail", "living_goods"]),
    item("evd_safety_pin_card", "옷핀 카드", "utility", 0.04, "여러 크기의 옷핀이 꽂힌 카드다.", "천, 붕대, 가방을 빠르게 고정할 수 있다.", "매듭보다 빠르고 테이프보다 아낄 수 있는 고정 수단이다.", ["pin", "repair", "medical"], ["medical", "residential", "retail"]),
    item("evd_small_notebook", "작은 수첩", "knowledge", 0.1, "주머니에 들어가는 줄노트 수첩이다.", "지나온 길과 위험한 방을 적어 둘 수 있다.", "기억은 추위와 피로에 쉽게 흐려진다.", ["paper", "knowledge", "story"], ["office", "residential", "retail"]),
    item("evd_zipper_pull_tab", "지퍼 손잡이", "utility", 0.02, "떨어진 지퍼 손잡이와 작은 고리다.", "잃어버리기 쉬운 끈 끝이나 열쇠 묶음을 잡기 쉽게 만든다.", "장갑 낀 손으로 작은 지퍼를 잡는 시간을 줄인다.", ["metal", "handle", "repair"], ["residential", "retail", "laundry"]),
    item("evd_cheap_rain_poncho", "일회용 우비", "equipment", 0.18, "얇게 접힌 일회용 비닐 우비다.", "몸이나 가방을 잠깐 덮어 눈과 젖음을 늦출 수 있다.", "보온보다 젖지 않는 것이 먼저일 때가 있다.", ["equipment", "waterproof", "outer"], ["retail", "residential", "security"], equip_slot="outer", equip_effects={"outdoor_exposure_drain_multiplier": 0.97}),
    item("evd_vacuum_storage_bag", "압축팩", "container", 0.18, "이불을 넣어 압축하던 두꺼운 비닐팩이다.", "옷과 천을 젖지 않게 크게 싸는 데 쓸 수 있다.", "부피 큰 보온재를 마른 상태로 지키는 데 좋다.", ["container", "waterproof", "bulk_wrap"], ["residential", "retail", "living_goods"]),
    item("evd_foam_packaging", "완충 스티로폼", "utility", 0.16, "택배 상자에서 나온 가벼운 완충재다.", "냉기 차단, 충격 완충, 틈 메우기에 쓸 수 있다.", "바닥과 몸 사이에 얇은 공기층을 만들어 준다.", ["insulation", "padding", "packaging"], ["retail", "office", "logistics", "residential"]),
    item("evd_silica_gel_packets", "실리카겔 봉지", "utility", 0.05, "신발 상자에서 나온 작은 건조제 봉지들이다.", "작은 물건과 양말을 건조하게 보관하는 데 보탬이 된다.", "젖은 발을 피하는 준비는 체온 관리와 직결된다.", ["drying", "packet", "utility"], ["retail", "residential", "medical"]),
    item("evd_rubber_glove_single", "한 짝 고무장갑", "equipment", 0.08, "짝이 맞지 않는 노란 고무장갑 한 짝이다.", "젖고 더러운 것을 잠깐 만질 때 손을 보호한다.", "보온은 약하지만 오염과 물기를 손에서 떼어 놓는다.", ["equipment", "hands", "waterproof"], ["residential", "retail", "food_service"], equip_slot="hands_layer", equip_effects={"outdoor_exposure_drain_multiplier": 0.99}),
    item("evd_makeup_sponge", "화장 스펀지", "medical", 0.03, "작은 물방울 모양 화장 스펀지다.", "작은 상처 압박이나 물기 흡수에 쓸 수 있다.", "사소한 흡수재도 손끝이 얼면 귀해진다.", ["sponge", "medical", "absorbent"], ["medical", "retail", "residential"]),
    item("evd_luggage_tag", "여행가방 이름표", "personal", 0.04, "투명 창이 달린 작은 여행가방 이름표다.", "중요한 가방이나 문에 표시를 달 수 있다.", "눈 속에서 같은 가방을 다시 찾는 데 도움이 된다.", ["personal", "tag", "marker"], ["residential", "office", "hostel"]),
    item("evd_umbrella_sleeve", "우산 비닐 커버", "utility", 0.03, "입구에 있던 긴 우산 비닐 커버다.", "길고 좁은 물건을 젖지 않게 감쌀 수 있다.", "눈 묻은 도구를 가방 안의 마른 물건과 분리할 수 있다.", ["plastic", "waterproof", "sleeve"], ["office", "retail", "residential"]),
    item("evd_measuring_spoon", "계량스푼", "tool", 0.05, "작은 플라스틱 계량스푼이다.", "분말과 물을 대충이라도 일정하게 나눌 수 있다.", "조합이 반복될수록 일정한 양이 실패를 줄인다.", ["tool", "measure", "kitchen"], ["residential", "food_service", "retail"]),
]

CRAFTED_ITEMS: list[dict[str, Any]] = [
    item("evd_dry_tinder_pouch", "방수 점화재 파우치", "crafted", 0.18, "마른 종이와 작은 불쏘시개를 비닐에 나눠 넣은 파우치다.", "성냥이나 라이터를 찾았을 때 바로 불씨를 키울 준비가 된다.", "마른 불쏘시개를 지키는 것만으로도 추위 대응 시간이 줄어든다.", ["crafted", "tinder", "waterproof", "fire"], []),
    item("evd_waxed_cotton_tinder", "왁스 먹인 솜 점화재", "crafted", 0.12, "솜에 기름기와 왁스를 먹여 만든 작은 점화재다.", "작지만 불씨를 오래 붙잡는다.", "젖지만 않으면 짧은 휴식의 열원이 될 수 있다.", ["crafted", "tinder", "fire"], []),
    item("evd_waterproof_document_pack", "방수 문서 팩", "crafted", 0.12, "문서와 메모를 젖지 않게 묶은 얇은 팩이다.", "지도, 수첩, 가족사진처럼 버리기 어려운 종이를 보호한다.", "길을 잃지 않는 정보는 식량만큼 중요해질 수 있다.", ["crafted", "document", "waterproof"], []),
    item("evd_window_gap_roll", "창문 틈막이 롤", "crafted", 0.35, "천과 비닐을 길게 말아 창문 틈을 막기 좋게 만든 롤이다.", "실내 거점의 찬바람을 줄이는 데 쓴다.", "바람이 멈추면 같은 열원도 더 오래 버틴다.", ["crafted", "wind_block", "insulation"], []),
    item("evd_door_draft_snake", "문풍지 대용 긴 막대", "crafted", 0.55, "천을 길게 말아 문 밑에 밀어 넣을 수 있게 만든 막대다.", "문틈 바람을 줄여 실내 회복 효율을 올린다.", "실내에서도 계속 빠져나가던 온기를 붙잡아 준다.", ["crafted", "wind_block", "insulation"], [], bulk=2),
    item("evd_hand_loop_light", "손목 고정 LED", "equipment", 0.08, "작은 LED를 손목이나 손등에 묶어 둔 보조 조명이다.", "손전등을 계속 쥐지 않고 가까운 곳을 비출 수 있다.", "어두운 실내에서 수색 실수를 줄이는 심리적 안정감이 있다.", ["crafted", "equipment", "light", "hands"], [], equip_slot="hands", charges_max=3, initial_charges=2, charge_label="전력"),
    item("evd_phone_warmer_pouch", "휴대폰 보온 파우치", "crafted", 0.16, "케이스와 천으로 만든 작은 보온 파우치다.", "작은 전자기기나 배터리를 체온 가까이에 둘 수 있다.", "배터리가 빨리 죽는 추위에서 전자기기를 조금 더 버티게 한다.", ["crafted", "electronics", "warmth"], []),
    item("evd_clean_water_prefilter", "임시 물 거름 필터", "tool", 0.1, "종이 필터와 작은 용기를 맞춘 임시 거름 필터다.", "눈 녹인 물이나 탁한 물의 큰 찌꺼기를 먼저 거른다.", "살균은 아니지만 마시기 전 한 번 더 걸러낼 수 있다.", ["crafted", "filter", "water"], []),
    item("evd_glass_search_gloves", "유리 수색 장갑", "equipment", 0.16, "얇은 장갑 위에 테이프와 덧감을 보강한 임시 장갑이다.", "깨진 유리나 날카로운 포장재를 뒤질 때 손을 보호한다.", "손을 다치면 이후 모든 행동이 느려진다.", ["crafted", "equipment", "hands", "glass_safety"], [], equip_slot="hands", equip_effects={"outdoor_exposure_drain_multiplier": 0.98}),
    item("evd_quiet_key_bundle", "소리 죽인 열쇠묶음", "utility", 0.08, "작은 금속 물건을 천과 고무줄로 감아 소리를 줄인 묶음이다.", "움직일 때 딸그락거리는 소리를 줄인다.", "조용히 수색해야 할 때 불필요한 소음을 덜 낸다.", ["crafted", "quiet", "stealth"], []),
    item("evd_marker_route_flags", "경로 표시 키트", "utility", 0.12, "굵은 글씨와 밝은 종이로 만든 경로 표시 묶음이다.", "이미 본 방, 위험한 통로, 되돌아갈 문을 표시한다.", "피로가 쌓일수록 기억보다 표식이 믿을 만해진다.", ["crafted", "signal", "navigation"], []),
    item("evd_cordage_bundle", "생활용 끈 묶음", "utility", 0.15, "치실, 끈, 케이블 등을 길게 이어 만든 묶음이다.", "묶고 걸고 임시 수리를 하는 기본 재료가 된다.", "끈 하나가 부족해서 포기하는 상황을 줄여 준다.", ["crafted", "cord", "repair"], []),
    item("evd_thermal_bottle_sleeve", "보온병 덧싸개", "crafted", 0.22, "천과 완충재로 병 주변을 감싼 덧싸개다.", "따뜻한 물이나 음료가 식는 속도를 조금 늦춘다.", "따뜻한 한 모금의 시간을 늘려 준다.", ["crafted", "warmth", "container"], []),
    item("evd_reflector_panel_small", "작은 열 반사판", "crafted", 0.25, "알루미늄과 판지를 접어 세운 작은 반사판이다.", "작은 열원의 열을 한쪽으로 모아 준다.", "바람 없는 곳에서는 작은 불씨도 더 쓸모 있어진다.", ["crafted", "reflector", "fire_heat"], []),
    item("evd_foot_dry_kit", "발 건조 키트", "equipment", 0.16, "건조제와 얇은 비닐을 묶은 발 관리 키트다.", "젖은 양말과 신발 안쪽을 분리해 발을 덜 젖게 한다.", "젖은 발은 추위와 물집을 동시에 부른다.", ["crafted", "equipment", "feet", "drying"], [], equip_slot="feet_layer", equip_effects={"outdoor_exposure_drain_multiplier": 0.97}),
    item("evd_windproof_match_sleeve", "성냥 방풍 슬리브", "crafted", 0.08, "성냥갑을 얇은 비닐과 왁스로 감싼 작은 슬리브다.", "젖음과 바람에서 성냥을 조금 더 지켜 준다.", "불씨를 만들 기회 자체를 잃지 않게 해 준다.", ["crafted", "fire", "waterproof"], []),
    item("evd_signal_mirror_tag", "반사 신호 이름표", "utility", 0.1, "거울이나 반사판을 줄에 묶어 몸에 달 수 있게 만든 표식이다.", "멀리서 빛을 반사하거나 모서리 너머를 확인한다.", "직접 모습을 드러내기 전에 주변을 살필 수 있다.", ["crafted", "signal", "mirror"], []),
    item("evd_food_hanging_bundle", "식량 매달기 묶음", "container", 0.2, "냄새 나는 식량을 끈으로 묶어 높이 걸기 좋게 만든 묶음이다.", "실내 거점에서 음식과 쓰레기를 분리해 둔다.", "음식 냄새와 쓰레기가 한곳에 뭉치지 않게 한다.", ["crafted", "container", "food_storage"], []),
    item("evd_padded_shoulder_wrap", "어깨 패드 덧감", "equipment", 0.18, "가방끈이 닿는 어깨에 덧대는 천과 완충재다.", "무거운 짐을 멨을 때 피로를 조금 줄인다.", "같은 무게라도 어깨가 덜 아프면 더 멀리 간다.", ["crafted", "equipment", "carry"], [], equip_slot="neck", fatigue_gain_bonus=-0.03),
    item("evd_bag_repair_patch", "가방 수선 패치", "utility", 0.08, "비닐과 테이프를 겹쳐 만든 작은 수선 패치다.", "찢어진 봉투나 가방 구석을 임시로 막는다.", "물건을 떨어뜨리는 작은 구멍을 막는 데 쓴다.", ["crafted", "repair", "waterproof"], []),
    item("evd_map_marker_kit", "지도 표시 묶음", "knowledge", 0.12, "수첩, 스티커, 굵은 펜을 묶은 표시 키트다.", "루트와 위험 구역을 표시해 다음 이동을 정리한다.", "복잡한 도시에서 기억을 종이에 맡길 수 있다.", ["crafted", "knowledge", "navigation"], []),
    item("evd_blister_foot_wrap", "물집 방지 발 감개", "equipment", 0.12, "흡수 패드와 끈으로 발에 감기 쉽게 만든 응급 덧감이다.", "오래 걷기 전 발가락과 뒤꿈치를 보호한다.", "발이 망가지면 좋은 식량도 멀리 옮길 수 없다.", ["crafted", "equipment", "medical", "feet"], [], equip_slot="feet_layer", move_speed_bonus=2, equip_effects={"outdoor_exposure_drain_multiplier": 0.98}),
    item("evd_taped_battery_pack", "테이프로 묶은 예비 전지", "electronics", 0.12, "흩어진 건전지를 극성이 보이게 테이프로 묶은 팩이다.", "필요할 때 바로 꺼내 쓰기 쉽다.", "추위 속에서 작은 전지를 찾느라 시간을 잃지 않는다.", ["crafted", "electronics", "battery"], []),
    item("evd_can_scoop", "캔 손삽", "tool", 0.16, "빈 캔 가장자리를 접어 만든 작은 손삽이다.", "눈, 흙, 재를 조금씩 퍼낼 수 있다.", "맨손으로 차가운 눈을 긁는 일을 줄여 준다.", ["crafted", "tool", "scoop"], []),
    item("evd_rainproof_hand_wrap", "비닐 손 덮개", "equipment", 0.08, "비닐과 고무줄로 손등을 덮은 임시 방수 덮개다.", "젖은 물건을 잠깐 만질 때 장갑 위를 보호한다.", "손이 젖는 순간 체감 추위가 빠르게 올라간다.", ["crafted", "equipment", "hands", "waterproof"], [], equip_slot="hands_layer", equip_effects={"outdoor_exposure_drain_multiplier": 0.98}),
    item("evd_disposable_funnel", "일회용 깔때기", "tool", 0.06, "빨대와 비닐을 맞춰 만든 작은 깔때기다.", "액체나 작은 알갱이를 흘리지 않고 옮긴다.", "손이 떨릴 때 흘리는 양을 줄여 준다.", ["crafted", "tool", "liquid"], []),
    item("evd_odor_mask_pack", "냄새 억제 파우치", "utility", 0.16, "건조 시트와 베이킹소다를 천에 넣어 묶은 파우치다.", "쓰레기나 젖은 옷 냄새를 조금 눌러 준다.", "거점의 불쾌감과 식량 냄새를 분리하는 데 도움 된다.", ["crafted", "odor_control", "hygiene"], []),
    item("evd_shoulder_carry_sling", "천 어깨 운반끈", "equipment", 0.25, "베개커버와 끈으로 만든 어깨걸이 운반끈이다.", "손에만 들던 봉투를 어깨에 걸어 조금 더 안정적으로 옮긴다.", "양손이 완전히 자유롭진 않아도 무게 부담이 줄어든다.", ["crafted", "equipment", "carry"], [], equip_slot="hand_carry", carry_capacity_bonus=2.0, ideal_carry_bonus=0.8),
    item("evd_mixed_sports_drink", "탄 스포츠음료", "drink", 0.5, "분말을 물에 타 만든 달고 짭짤한 스포츠음료다.", "갈증과 피로를 동시에 조금 덜어 준다.", "오래 걸은 뒤에는 그냥 물보다 회복감이 크다.", ["crafted", "drink", "electrolyte", "consumable"], [], thirst_restore=12, fatigue_restore=3, use_minutes=3),
]


def recipe(
    primary: str,
    secondary: str,
    result: str,
    text: str,
    category: str,
    minutes: int,
    keep: list[str] | None = None,
    required_tags: list[str] | None = None,
    required_tool_ids: list[str] | None = None,
    tool_charge_costs: dict[str, int] | None = None,
) -> dict[str, Any]:
    keep_ids = set(keep or [])
    ingredients = [primary, secondary]
    sorted_id = "__".join(sorted(ingredients))
    return {
        "id": sorted_id,
        "ingredients": ingredients,
        "contexts": ["indoor", "outdoor"],
        "codex_category": category,
        "codex_order": 6500,
        "required_tags": required_tags or [],
        "minutes": minutes,
        "ingredient_rules": {
            primary: "keep" if primary in keep_ids else "consume",
            secondary: "keep" if secondary in keep_ids else "consume",
        },
        "result_items": [{"id": result, "count": 1}],
        "result_type": "success",
        "result_item_id": result,
        "indoor_minutes": minutes,
        "required_tool_ids": required_tool_ids or [],
        "tool_charge_costs": tool_charge_costs or {},
        "result_text": text,
    }


RECIPES: list[dict[str, Any]] = [
    recipe("plastic_bag", "newspaper", "evd_dry_tinder_pouch", "신문지를 비닐봉투 안에 나눠 넣어 젖지 않는 점화재 파우치를 만들었다.", "fire_heat", 6),
    recipe("evd_freezer_bag_box", "receipt_bundle", "evd_dry_tinder_pouch", "영수증을 지퍼백에 말아 넣어 작고 마른 불쏘시개 묶음을 만들었다.", "fire_heat", 5),
    recipe("evd_lip_balm_tube", "evd_cotton_ball_pack", "evd_waxed_cotton_tinder", "솜에 립밤을 문질러 불씨가 오래 붙는 작은 점화재를 만들었다.", "fire_heat", 6),
    recipe("evd_candle_stub", "evd_cotton_ball_pack", "evd_waxed_cotton_tinder", "양초 토막의 왁스를 솜에 먹여 작은 점화재를 만들었다.", "fire_heat", 8),
    recipe("evd_plastic_file_folder", "evd_small_notebook", "evd_waterproof_document_pack", "수첩을 투명 파일철 안에 넣고 접어 물에 덜 젖는 문서 팩으로 만들었다.", "repair_fortify", 4),
    recipe("evd_freezer_bag_box", "evd_family_photo_strip", "evd_waterproof_document_pack", "사진을 두꺼운 지퍼백에 넣어 버리기 어려운 종이를 보호했다.", "repair_fortify", 3),
    recipe("evd_cling_film_roll", "towel", "evd_window_gap_roll", "수건을 길게 말고 랩으로 감싸 창문 틈에 밀어 넣을 롤을 만들었다.", "repair_fortify", 10),
    recipe("clear_plastic_sheet", "evd_binder_clip_large", "evd_window_gap_roll", "투명 비닐을 집게로 접어 고정해 찬바람이 새는 창가를 막을 조각을 만들었다.", "repair_fortify", 7, keep=["evd_binder_clip_large"]),
    recipe("evd_pillowcase", "evd_old_tshirt", "evd_door_draft_snake", "베개커버 안에 티셔츠를 말아 넣어 문 밑을 막는 긴 덧감을 만들었다.", "repair_fortify", 9),
    recipe("evd_rubber_doorstop", "towel", "evd_door_draft_snake", "문쐐기와 수건을 묶어 문 밑에서 밀리지 않는 틈막이를 만들었다.", "repair_fortify", 7, keep=["evd_rubber_doorstop"]),
    recipe("evd_led_keychain_light", "evd_hair_tie_pack", "evd_hand_loop_light", "작은 LED를 머리끈으로 손목에 고정해 양손을 덜 가로막는 조명으로 만들었다.", "repair_fortify", 5),
    recipe("evd_led_keychain_light", "evd_lanyard", "evd_hand_loop_light", "목걸이 줄에 LED를 묶어 손 가까이에 매달리는 보조 조명을 만들었다.", "repair_fortify", 5),
    recipe("evd_phone_case", "hand_warmer_pack", "evd_phone_warmer_pouch", "휴대폰 케이스 안쪽에 핫팩을 붙여 작은 전자기기를 품을 보온 파우치를 만들었다.", "repair_fortify", 6),
    recipe("evd_freezer_bag_box", "hand_warmer_pack", "evd_phone_warmer_pouch", "지퍼백 안에 핫팩을 분리해 넣어 배터리를 잠깐 보온할 파우치를 만들었다.", "repair_fortify", 5),
    recipe("evd_coffee_filter_pack", "evd_empty_coffee_can", "evd_clean_water_prefilter", "커피 캔 위에 필터를 걸쳐 큰 찌꺼기를 거르는 임시 필터를 만들었다.", "food_drink", 6),
    recipe("evd_coffee_filter_pack", "evd_plastic_lid_round", "evd_clean_water_prefilter", "플라스틱 뚜껑에 필터를 고정해 컵 위에 올릴 거름망을 만들었다.", "food_drink", 5),
    recipe("evd_disposable_gloves_pair", "duct_tape", "evd_glass_search_gloves", "얇은 장갑 손가락에 테이프를 덧대 깨진 유리를 뒤질 때 쓸 장갑으로 보강했다.", "hygiene_medical", 7),
    recipe("evd_rubber_glove_single", "evd_clear_tape_small", "evd_glass_search_gloves", "고무장갑 한 짝을 투명 테이프로 보강해 날카로운 조각을 만질 손 보호구로 만들었다.", "hygiene_medical", 6),
    recipe("evd_zipper_pull_tab", "evd_hair_tie_pack", "evd_quiet_key_bundle", "금속 고리를 머리끈으로 감아 움직일 때 나는 작은 소리를 줄였다.", "repair_fortify", 3),
    recipe("evd_safety_pin_card", "evd_old_tshirt", "evd_quiet_key_bundle", "옷핀과 천 조각을 묶어 금속 물건끼리 부딪히는 소리를 줄일 덮개를 만들었다.", "repair_fortify", 5),
    recipe("evd_permanent_marker", "evd_sticky_note_pad", "evd_marker_route_flags", "포스트잇에 굵은 화살표를 그려 수색한 방을 표시할 묶음을 만들었다.", "repair_fortify", 4, keep=["evd_permanent_marker"]),
    recipe("evd_permanent_marker", "evd_calendar_page", "evd_marker_route_flags", "찢어진 달력장에 큰 표시를 그려 눈에 띄는 경로 표식을 만들었다.", "repair_fortify", 4, keep=["evd_permanent_marker"]),
    recipe("evd_dental_floss", "evd_paper_clip_chain", "evd_cordage_bundle", "치실과 클립 줄을 이어 가볍지만 질긴 생활용 끈 묶음을 만들었다.", "repair_fortify", 6),
    recipe("evd_shoelace_pair", "evd_lanyard", "evd_cordage_bundle", "신발끈과 목걸이 줄을 이어 묶고 걸기 쉬운 끈 묶음으로 정리했다.", "repair_fortify", 4),
    recipe("evd_microfiber_cloth", "evd_foam_packaging", "evd_thermal_bottle_sleeve", "천 안에 완충재를 넣어 작은 병을 감싸는 보온 덧싸개를 만들었다.", "food_drink", 7),
    recipe("evd_old_tshirt", "evd_silicone_hot_pad", "evd_thermal_bottle_sleeve", "티셔츠 천과 냄비받침을 겹쳐 뜨거운 병을 잡고 감쌀 덧싸개를 만들었다.", "food_drink", 7),
    recipe("evd_aluminum_takeout_lid", "cardboard_sheet", "evd_reflector_panel_small", "알루미늄 뚜껑을 골판지에 펴 붙여 작은 열 반사판을 만들었다.", "fire_heat", 7),
    recipe("aluminum_foil", "evd_plastic_lid_round", "evd_reflector_panel_small", "플라스틱 뚜껑에 포일을 감아 작은 양초 뒤에 세울 반사판을 만들었다.", "fire_heat", 6),
    recipe("evd_silica_gel_packets", "evd_shower_cap", "evd_foot_dry_kit", "샤워캡 안에 건조제를 넣어 젖은 발 주변 물기를 늦추는 키트를 만들었다.", "hygiene_medical", 5),
    recipe("evd_sanitary_pad_pack", "evd_shoelace_pair", "evd_blister_foot_wrap", "흡수 패드를 신발끈으로 고정해 오래 걸을 때 쓸 발 감개를 만들었다.", "hygiene_medical", 6),
    recipe("matchbox", "evd_umbrella_sleeve", "evd_windproof_match_sleeve", "성냥갑을 우산 비닐 커버 조각으로 감싸 젖음과 바람을 조금 막았다.", "fire_heat", 4),
    recipe("matchbox", "evd_lip_balm_tube", "evd_windproof_match_sleeve", "성냥갑 모서리에 립밤을 발라 습기를 덜 먹는 작은 슬리브를 만들었다.", "fire_heat", 5),
    recipe("evd_pocket_mirror", "evd_lanyard", "evd_signal_mirror_tag", "손거울에 목걸이 줄을 묶어 떨어뜨리지 않는 반사 신호 도구를 만들었다.", "repair_fortify", 4),
    recipe("evd_wire_hanger", "evd_aluminum_takeout_lid", "evd_signal_mirror_tag", "철사 옷걸이에 반사 뚜껑을 고정해 손에 들기 쉬운 신호판을 만들었다.", "repair_fortify", 6),
    recipe("evd_pet_food_pouch", "evd_shoelace_pair", "evd_food_hanging_bundle", "냄새 나는 파우치를 끈으로 묶어 바닥에서 띄워 둘 수 있게 정리했다.", "repair_fortify", 5),
    recipe("evd_cereal_box", "plastic_bag", "evd_food_hanging_bundle", "시리얼 속봉지와 비닐봉투를 묶어 마른 식량을 따로 걸어 둘 묶음을 만들었다.", "repair_fortify", 5),
    recipe("evd_foam_packaging", "evd_safety_pin_card", "evd_padded_shoulder_wrap", "완충재를 옷핀으로 천에 고정해 가방끈 아래 덧댈 어깨 패드를 만들었다.", "repair_fortify", 6),
    recipe("evd_mouse_pad", "evd_clear_tape_small", "evd_padded_shoulder_wrap", "마우스패드 고무면을 테이프로 감아 어깨에 덧댈 미끄럼 방지 패드를 만들었다.", "repair_fortify", 6),
    recipe("evd_cling_film_roll", "evd_clear_tape_small", "evd_bag_repair_patch", "랩과 투명 테이프를 겹쳐 찢어진 봉투에 붙일 작은 패치를 만들었다.", "repair_fortify", 4),
    recipe("evd_twist_tie_bundle", "evd_freezer_bag_box", "evd_bag_repair_patch", "지퍼백 조각과 철심 끈을 묶어 다시 여닫을 수 있는 작은 수선 패치를 만들었다.", "repair_fortify", 5),
    recipe("evd_small_notebook", "evd_permanent_marker", "evd_map_marker_kit", "수첩 첫 장에 굵은 범례를 적어 반복 수색용 지도 표시 키트로 정리했다.", "repair_fortify", 5, keep=["evd_permanent_marker"]),
    recipe("evd_kids_sticker_sheet", "evd_permanent_marker", "evd_map_marker_kit", "스티커와 매직을 묶어 문과 지도에 함께 쓰는 표시 키트로 만들었다.", "repair_fortify", 4, keep=["evd_permanent_marker"]),
    recipe("evd_alarm_clock_battery", "evd_clear_tape_small", "evd_taped_battery_pack", "작은 전지를 극성이 보이게 테이프로 묶어 잃어버리지 않게 정리했다.", "repair_fortify", 3),
    recipe("spare_batteries", "evd_bread_clip", "evd_taped_battery_pack", "건전지를 작은 클립으로 묶어 가방 안에서 흩어지지 않게 했다.", "repair_fortify", 3),
    recipe("evd_empty_coffee_can", "evd_takeout_chopsticks", "evd_can_scoop", "빈 커피 캔 한쪽을 접고 젓가락을 손잡이처럼 끼워 작은 손삽을 만들었다.", "repair_fortify", 7),
    recipe("steel_food_can", "evd_binder_clip_large", "evd_can_scoop", "깡통 가장자리를 접고 집게를 물려 차가운 눈을 퍼낼 손잡이로 만들었다.", "repair_fortify", 6, keep=["evd_binder_clip_large"]),
    recipe("evd_shower_cap", "evd_hair_tie_pack", "evd_rainproof_hand_wrap", "샤워캡 비닐을 손등에 씌우고 머리끈으로 고정해 임시 방수 덮개를 만들었다.", "repair_fortify", 4),
    recipe("plastic_bag", "evd_hair_tie_pack", "evd_rainproof_hand_wrap", "비닐봉투를 손 모양으로 접고 머리끈으로 묶어 젖은 물건을 만질 덮개를 만들었다.", "repair_fortify", 4),
    recipe("evd_straw_bundle", "evd_cling_film_roll", "evd_disposable_funnel", "빨대를 중심으로 랩을 말아 작은 액체용 깔때기를 만들었다.", "food_drink", 4),
    recipe("evd_straw_bundle", "plastic_bag", "evd_disposable_funnel", "비닐봉투 귀퉁이와 빨대를 맞춰 흘리지 않고 따를 깔때기를 만들었다.", "food_drink", 4),
    recipe("evd_dryer_sheet_box", "evd_baking_soda_box", "evd_odor_mask_pack", "건조기 시트와 베이킹소다를 작은 파우치로 묶어 냄새를 눌러 줄 물건을 만들었다.", "hygiene_medical", 5),
    recipe("evd_old_tshirt", "evd_baking_soda_box", "evd_odor_mask_pack", "티셔츠 조각 안에 베이킹소다를 넣고 묶어 젖은 냄새를 줄일 파우치를 만들었다.", "hygiene_medical", 5),
    recipe("evd_pillowcase", "evd_shoelace_pair", "evd_shoulder_carry_sling", "베개커버 입구에 신발끈을 꿰어 어깨에 걸 수 있는 운반끈을 만들었다.", "repair_fortify", 8),
    recipe("evd_laundry_mesh_bag", "evd_lanyard", "evd_shoulder_carry_sling", "세탁망에 목걸이 줄을 달아 가볍게 어깨에 걸 수 있는 손짐 가방으로 바꿨다.", "repair_fortify", 6),
    recipe("evd_sports_drink_powder", "bottled_water", "evd_mixed_sports_drink", "스포츠음료 분말을 물에 타 갈증과 피로를 조금 덜어 줄 음료로 만들었다.", "food_drink", 3),
    recipe("evd_sugar_sachet", "evd_salt_sachet", "evd_sports_drink_powder", "설탕과 소금을 비율 맞춰 섞어 물에 탈 수 있는 간단한 전해질 분말을 만들었다.", "food_drink", 3),
]


def stable_color(text: str) -> tuple[int, int, int]:
    value = sum((index + 1) * ord(char) for index, char in enumerate(text))
    return (
        80 + value % 120,
        80 + (value // 7) % 120,
        80 + (value // 19) % 120,
    )


def draw_icon(row: dict[str, Any], size: int) -> Image.Image:
    scale = 4
    canvas = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    color = stable_color(row["id"])
    accent = tuple(min(255, channel + 45) for channel in color)
    shadow = (20, 28, 32, 135)
    category = str(row.get("category", "utility"))

    def box(x0: float, y0: float, x1: float, y1: float) -> tuple[int, int, int, int]:
        return (int(x0 * scale), int(y0 * scale), int(x1 * scale), int(y1 * scale))

    draw.ellipse(box(size * 0.12, size * 0.16, size * 0.88, size * 0.88), fill=shadow)
    if category in {"food", "drink", "medical", "hygiene"}:
        draw.rounded_rectangle(box(size * 0.26, size * 0.18, size * 0.74, size * 0.82), radius=int(size * 0.11 * scale), fill=color + (255,), outline=(236, 241, 230, 210), width=max(1, scale))
        draw.rectangle(box(size * 0.33, size * 0.38, size * 0.67, size * 0.52), fill=accent + (230,))
    elif category in {"container", "equipment"}:
        draw.rounded_rectangle(box(size * 0.20, size * 0.34, size * 0.80, size * 0.80), radius=int(size * 0.08 * scale), fill=color + (255,), outline=(225, 234, 238, 200), width=max(1, scale))
        draw.arc(box(size * 0.33, size * 0.18, size * 0.67, size * 0.52), 180, 360, fill=accent + (245,), width=max(2, scale))
    elif category in {"office", "knowledge", "paper", "personal"}:
        draw.polygon([box(size * 0.30, size * 0.18, size * 0.30, size * 0.18)[:2], box(size * 0.74, size * 0.25, size * 0.74, size * 0.25)[:2], box(size * 0.66, size * 0.82, size * 0.66, size * 0.82)[:2], box(size * 0.22, size * 0.74, size * 0.22, size * 0.74)[:2]], fill=color + (255,))
        for y in [0.42, 0.56, 0.68]:
            draw.line(box(size * 0.33, size * y, size * 0.61, size * y), fill=(245, 239, 218, 230), width=max(1, scale))
    elif category == "electronics":
        draw.rounded_rectangle(box(size * 0.24, size * 0.20, size * 0.76, size * 0.78), radius=int(size * 0.10 * scale), fill=color + (255,), outline=(230, 238, 245, 200), width=max(1, scale))
        draw.ellipse(box(size * 0.44, size * 0.62, size * 0.56, size * 0.74), fill=accent + (240,))
    elif category == "crafted":
        draw.rounded_rectangle(box(size * 0.20, size * 0.24, size * 0.80, size * 0.78), radius=int(size * 0.12 * scale), fill=color + (255,), outline=(230, 238, 232, 210), width=max(1, scale))
        draw.line(box(size * 0.32, size * 0.36, size * 0.68, size * 0.66), fill=accent + (245,), width=max(2, scale))
        draw.line(box(size * 0.68, size * 0.36, size * 0.32, size * 0.66), fill=accent + (245,), width=max(2, scale))
    else:
        draw.rounded_rectangle(box(size * 0.22, size * 0.26, size * 0.78, size * 0.76), radius=int(size * 0.10 * scale), fill=color + (255,), outline=(229, 236, 236, 190), width=max(1, scale))
        draw.rectangle(box(size * 0.34, size * 0.38, size * 0.66, size * 0.50), fill=accent + (235,))
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def generate_icons(rows: list[dict[str, Any]]) -> None:
    for size in [24, 32]:
        out_dir = ICON_ROOT / f"icons_{size}_cutout"
        out_dir.mkdir(parents=True, exist_ok=True)
        for old_icon in out_dir.glob(f"{PREFIX}*.png"):
            old_icon.unlink()
        for row in rows:
            draw_icon(row, size).save(out_dir / f"{row['id']}.png")


def update_manifest(rows: list[dict[str, Any]]) -> None:
    manifest = load_json(MANIFEST_PATH) if MANIFEST_PATH.exists() else {"meta": {}, "items": []}
    kept = [entry for entry in manifest.get("items", []) if not str(entry.get("id", "")).startswith(PREFIX)]
    next_index = len(kept)
    for offset, row in enumerate(rows):
        kept.append(
            {
                "index": next_index + offset,
                "id": row["id"],
                "name": row["name"],
                "category": row["category"],
                "file_32": f"icons_32_cutout/{row['id']}.png",
                "file_24": f"icons_24_cutout/{row['id']}.png",
                "sheet": "generated_everyday_item_layer",
                "x": 0,
                "y": 0,
                "w": 32,
                "h": 32,
                "col": 0,
                "row": 0,
            }
        )
    manifest["items"] = kept
    manifest.setdefault("meta", {})
    manifest["meta"]["everyday_item_layer_generated"] = True
    manifest["meta"]["everyday_item_layer_item_count"] = len(rows)
    manifest["meta"]["everyday_item_layer_recipe_count"] = len(RECIPES)
    manifest["meta"]["item_count"] = len(kept)
    write_json(MANIFEST_PATH, manifest)


def generate_loot_profiles(rows: list[dict[str, Any]]) -> dict[str, Any]:
    profiles: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        if row.get("category") == "crafted":
            continue
        for profile in row.get("spawn_profiles", []):
            profiles.setdefault(profile, []).append({"id": row["id"], "weight": 0.9})

    def pick(profile: str, limit: int = 80) -> list[dict[str, Any]]:
        return profiles.get(profile, [])[:limit]

    return {
        "global": [
            {"id": "evd_hair_tie_pack", "weight": 0.35},
            {"id": "evd_clear_tape_small", "weight": 0.35},
            {"id": "evd_freezer_bag_box", "weight": 0.35},
            {"id": "evd_lip_balm_tube", "weight": 0.3},
            {"id": "evd_safety_pin_card", "weight": 0.3},
        ],
        "building_categories": {
            "retail": pick("retail"),
            "residential": pick("residential"),
            "office": pick("office"),
            "medical": pick("medical"),
            "food_service": pick("food_service"),
            "industrial": pick("repair") + pick("logistics"),
            "security": pick("security"),
        },
        "site_tags": {
            "living_goods": pick("living_goods"),
            "stockroom": pick("retail", 32),
            "staff_only": pick("office", 24) + pick("food_service", 24),
            "repair": pick("repair"),
            "materials": pick("repair") + pick("logistics"),
            "logistics": pick("logistics"),
            "living_trace": pick("residential", 36),
        },
        "building_ids": {
            "mart_01": pick("retail", 55) + pick("living_goods", 25),
            "convenience_01": pick("retail", 45) + pick("food_service", 20),
            "apartment_01": pick("residential", 70),
            "residence_01": pick("residential", 60),
            "pharmacy_01": pick("medical", 45),
            "clinic_01": pick("medical", 45) + pick("office", 12),
            "office_01": pick("office", 55),
            "cafe_01": pick("food_service", 45) + pick("office", 10),
            "restaurant_01": pick("food_service", 50),
            "laundry_01": pick("residential", 18) + pick("living_goods", 28),
            "warehouse_01": pick("logistics", 45) + pick("retail", 18),
            "garage_01": pick("repair", 32) + pick("logistics", 18),
            "hardware_01": pick("repair", 36) + pick("retail", 18),
        },
    }


def main() -> None:
    rows = EVERYDAY_ITEMS + CRAFTED_ITEMS
    ids = [row["id"] for row in rows]
    if len(ids) != len(set(ids)):
        raise RuntimeError("duplicate everyday item id")
    recipe_ids = [row["id"] for row in RECIPES]
    if len(recipe_ids) != len(set(recipe_ids)):
        raise RuntimeError("duplicate everyday recipe id")

    for order, recipe_row in enumerate(RECIPES, start=1):
        recipe_row["codex_order"] = 6500 + order

    write_json(ITEM_OUTPUT, rows)
    write_json(RECIPE_OUTPUT, RECIPES)
    write_json(LOOT_OUTPUT, generate_loot_profiles(rows))
    generate_icons(rows)
    update_manifest(rows)
    print(f"everyday_items={len(rows)}")
    print(f"everyday_recipes={len(RECIPES)}")
    print(f"everyday_icons={len(rows) * 2}")


if __name__ == "__main__":
    main()
