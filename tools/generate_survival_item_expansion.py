from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
GAME_DATA = ROOT / "game" / "data"
ICON_ROOT = ROOT / "resources" / "items" / "icons"
MANIFEST_PATH = ICON_ROOT / "item_icons_manifest.json"

ITEM_OUTPUT = GAME_DATA / "items_survival_expansion.json"
RECIPE_OUTPUT = GAME_DATA / "crafting_combinations_survival_expansion.json"
LOOT_PROFILE_OUTPUT = GAME_DATA / "loot_profiles_survival_expansion.json"

EXPANSION_PREFIX = "surv_"


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: Any) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def stable_hash(text: str) -> int:
    return int(hashlib.sha256(text.encode("utf-8")).hexdigest()[:12], 16)


def entry_id(category_key: str, index: int) -> str:
    return f"{EXPANSION_PREFIX}{category_key}_{index:03d}"


def name_for(modifiers: list[str], nouns: list[str], index: int) -> str:
    modifier = modifiers[index % len(modifiers)]
    noun = nouns[(index // len(modifiers)) % len(nouns)]
    return f"{modifier} {noun}".strip()


def add_common_fields(
    row: dict[str, Any],
    name: str,
    category: str,
    tags: list[str],
    spawn_profiles: list[str],
    weight: float,
    description: str,
    usage_hint: str,
    cold_hint: str,
) -> None:
    row.update(
        {
            "name": name,
            "bulk": max(1, round(weight)),
            "carry_weight": weight,
            "description": description,
            "usage_hint": usage_hint,
            "cold_hint": cold_hint,
            "category": category,
            "item_tags": sorted(set(tags + ["survival_expansion"])),
            "spawn_profiles": sorted(set(spawn_profiles)),
        }
    )


def generate_items(existing_ids: set[str]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []

    food_nouns = [
        "곡물바",
        "비상 비스킷",
        "단백질 젤",
        "육포 봉지",
        "견과 믹스",
        "동결건조 죽",
        "오트밀 컵",
        "레토르트 카레",
        "통조림 햄",
        "참깨 라면스프",
        "미숫가루 팩",
        "건조 과일",
        "즉석 누룽지",
    ]
    food_mods = ["밀봉", "고열량", "작은", "찌그러진", "오래된"]
    for i in range(65):
        item_id = entry_id("food", i + 1)
        name = name_for(food_mods, food_nouns, i)
        row = {"id": item_id}
        hunger = 7 + (i % 13)
        add_common_fields(
            row,
            name,
            "food",
            ["food", "consumable", "packaged", "ration"],
            ["global", "retail", "residential", "food_service"],
            0.6 if i % 5 in [0, 1] else 1.0,
            f"{name}이다. 포장이 온전하면 전기나 조리도구 없이도 바로 열량을 확보할 수 있다.",
            "바로 먹거나 따뜻한 물, 조미 재료와 엮어 한 끼로 키울 수 있다.",
            "한파에서는 맛보다 열량과 휴대성이 중요하다.",
        )
        row["hunger_restore"] = hunger
        row["thirst_restore"] = -1 if i % 4 == 0 else 0
        row["use_minutes"] = 5 + (i % 3) * 5
        rows.append(row)

    drink_nouns = [
        "정수 파우치",
        "이온 음료",
        "보리차 병",
        "꿀물 스틱",
        "코코아 파우더",
        "전해질 분말",
        "캔 식혜",
        "레몬차 분말",
        "스포츠 젤",
        "생강차 스틱",
    ]
    drink_mods = ["밀봉", "얼어붙은", "작은", "가벼운", "응급"]
    for i in range(25):
        item_id = entry_id("drink", i + 1)
        name = name_for(drink_mods, drink_nouns, i)
        row = {"id": item_id}
        add_common_fields(
            row,
            name,
            "drink",
            ["drink", "consumable", "hydration"],
            ["global", "retail", "residential", "food_service", "medical"],
            0.6 if i % 2 == 0 else 1.0,
            f"{name}이다. 갈증을 줄이거나 물을 더 먹기 쉽게 만드는 휴대 식수 자원이다.",
            "바로 마시거나 뜨거운 물과 섞어 회복용 음료로 바꿀 수 있다.",
            "수분이 부족해지면 추위와 피로를 동시에 버티기 어려워진다.",
        )
        row["thirst_restore"] = 10 + (i % 9) * 2
        if i % 5 == 0:
            row["fatigue_restore"] = 3 + (i % 4)
        row["use_minutes"] = 5
        rows.append(row)

    medical_nouns = [
        "멸균 패드",
        "상처 세척액",
        "압박 붕대",
        "화상 젤",
        "감기약 파우치",
        "해열제 카드",
        "위장약 팩",
        "전해질 정제",
        "소독 티슈",
    ]
    medical_mods = ["소형", "밀봉", "응급", "약국용", "여행용"]
    for i in range(45):
        item_id = entry_id("medical", i + 1)
        name = name_for(medical_mods, medical_nouns, i)
        row = {"id": item_id}
        add_common_fields(
            row,
            name,
            "medical",
            ["medical", "consumable", "hygiene"],
            ["medical", "retail", "residential", "global"],
            0.4 if i % 3 else 0.8,
            f"{name}이다. 제대로 된 치료는 아니어도 상처와 오염을 더 나빠지지 않게 붙잡는다.",
            "부상, 오염, 추위 속 감기 증상에 대비해 남겨 둘 가치가 있다.",
            "추위에서는 작은 상처도 회복을 갉아먹으므로 위생 자원이 곧 생존 자원이다.",
        )
        if i % 3 != 1:
            row["health_restore"] = 4 + (i % 10)
        if i % 5 == 0:
            row["thirst_restore"] = 2
        row["use_minutes"] = 5 + (i % 2) * 5
        rows.append(row)

    tool_nouns = [
        "접이식 칼",
        "소형 펜치",
        "비상 망치",
        "렌치",
        "멀티툴",
        "헤드랜턴",
        "절연 드라이버",
        "케이블 타이 커터",
        "휴대 라디오",
    ]
    tool_mods = ["낡은", "작은", "튼튼한", "주머니용", "정비용"]
    for i in range(45):
        item_id = entry_id("tool", i + 1)
        name = name_for(tool_mods, tool_nouns, i)
        row = {"id": item_id}
        add_common_fields(
            row,
            name,
            "tool",
            ["tool", "craft_tool", "utility"],
            ["industrial", "repair", "security", "office", "global"],
            0.8 + (i % 4) * 0.4,
            f"{name}이다. 문틈, 케이스, 배선, 고정물을 다루는 상황에서 손을 대신한다.",
            "조합 재료를 다듬거나 잠긴 구조물을 조심스럽게 처리할 때 쓴다.",
            "손을 다치지 않고 빠르게 처리하는 도구가 체온과 시간을 아낀다.",
        )
        if "랜턴" in name or "라디오" in name:
            row["charges_max"] = 4
            row["initial_charges"] = 3
            row["charge_label"] = "전력"
        rows.append(row)

    utility_nouns = [
        "보온 필름",
        "방수 테이프",
        "철사 묶음",
        "압축 스펀지",
        "고무 패킹",
        "알루미늄 판",
        "흡습제 봉투",
        "비닐 시트",
        "파라코드",
        "작은 자물쇠",
        "방풍 패널",
        "접착 패드",
        "연료 젤",
        "단열 폼",
        "방수 지퍼백",
    ]
    utility_mods = ["접은", "두꺼운", "정비용", "생활용", "비상"]
    for i in range(75):
        item_id = entry_id("utility", i + 1)
        name = name_for(utility_mods, utility_nouns, i)
        row = {"id": item_id}
        tags = ["utility", "craft_component"]
        if any(word in name for word in ["보온", "단열", "방풍"]):
            tags.append("insulation")
        if any(word in name for word in ["연료", "젤"]):
            tags.append("fuel_component")
        add_common_fields(
            row,
            name,
            "utility",
            tags,
            ["global", "retail", "industrial", "repair", "residential"],
            0.7 + (i % 5) * 0.35,
            f"{name}이다. 그대로는 사소해 보여도 다른 재료와 붙이면 생존 장치의 한 부분이 된다.",
            "밀봉, 결속, 보온, 수리 조합에 폭넓게 쓸 수 있다.",
            "추위는 틈과 습기에서 시작하므로 작은 보수 재료도 의미가 있다.",
        )
        rows.append(row)

    container_nouns = [
        "접이식 물통",
        "방수 파우치",
        "작은 공구함",
        "플라스틱 통",
        "압축 주머니",
        "보냉 가방",
        "접이식 바구니",
    ]
    container_mods = ["얇은", "튼튼한", "손잡이 달린", "밀봉", "현장용"]
    for i in range(35):
        item_id = entry_id("container", i + 1)
        name = name_for(container_mods, container_nouns, i)
        row = {"id": item_id}
        add_common_fields(
            row,
            name,
            "container",
            ["container", "logistics", "craft_component"],
            ["global", "retail", "residential", "industrial", "food_service"],
            0.8 + (i % 4) * 0.5,
            f"{name}이다. 손에 들고 다니기보다 물건을 분류하고 옮기는 데 가치가 있다.",
            "물, 연료, 작은 부품, 음식 재료를 분리해 보관할 때 쓴다.",
            "젖은 물건과 마른 물건을 나누는 것만으로도 체온 손실을 줄인다.",
        )
        rows.append(row)

    equipment_specs = [
        ("back", "등산 배낭", "back", 2.4),
        ("back", "허리 지지 배낭", "back", 2.8),
        ("body", "두꺼운 후드집업", "body", 1.8),
        ("body", "기모 작업복", "body", 2.2),
        ("outer", "방한 파카", "outer", 2.6),
        ("outer", "방수 외피", "outer", 2.0),
        ("head", "귀덮개 모자", "head", 0.6),
        ("head", "방한 바라클라바", "head", 0.7),
        ("neck", "넓은 목도리", "neck", 0.7),
        ("face", "방진 마스크", "face", 0.4),
        ("hands", "방수 장갑", "hands", 0.8),
        ("hands_layer", "얇은 장갑 안감", "hands_layer", 0.4),
        ("feet", "방한 부츠", "feet", 1.8),
        ("feet_layer", "두꺼운 양말", "feet_layer", 0.5),
        ("waist", "공구 벨트", "waist", 1.0),
        ("pocket", "가슴 파우치", "pocket", 0.5),
    ]
    equipment_mods = ["낡은", "마른", "튼튼한", "보강한", "방한"]
    for i in range(90):
        item_id = entry_id("equipment", i + 1)
        slot, noun, profile_hint, base_weight = equipment_specs[i % len(equipment_specs)]
        name = f"{equipment_mods[(i // len(equipment_specs)) % len(equipment_mods)]} {noun}"
        row = {"id": item_id}
        add_common_fields(
            row,
            name,
            "equipment",
            ["equipment", "wearable", "warming" if slot in ["body", "outer", "head", "neck", "feet", "feet_layer"] else "carry"],
            ["global", "residential", "retail", "industrial", "security", profile_hint],
            base_weight,
            f"{name}이다. 몸에 걸치면 가방 속 물건과 달리 즉시 이동과 노출에 영향을 준다.",
            "장착 슬롯을 차지하지만 무게, 보온, 위험 대응 중 하나를 확실히 바꾼다.",
            "좋은 장비는 추위를 없애진 못해도 실수할 시간을 조금 벌어 준다.",
        )
        row["equip_slot"] = slot
        if slot == "back":
            row["carry_capacity_bonus"] = 3.0 + float(i % 4)
            row["ideal_carry_bonus"] = 1.0 + float(i % 2)
        elif slot in ["waist", "pocket"]:
            row["carry_capacity_bonus"] = 1.0 + float(i % 2)
        elif slot == "feet":
            row["move_speed_bonus"] = 6 + (i % 5) * 2
            row["equip_effects"] = {
                "outdoor_hazard_multipliers": {
                    "black_ice": {"fatigue_gain": 0.78, "health_loss": 0.65}
                }
            }
        else:
            row["equip_effects"] = {
                "outdoor_exposure_drain_multiplier": max(0.82, 0.98 - (i % 7) * 0.02)
            }
            if slot in ["hands", "hands_layer"]:
                row["equip_effects"]["outdoor_hazard_multipliers"] = {
                    "wind_gap": {"exposure_loss": 0.82}
                }
        rows.append(row)

    knowledge_nouns = [
        "상가 배치 메모",
        "응급 처치 카드",
        "단열 보수 노트",
        "연료 관리 수첩",
        "수색 우선순위 쪽지",
    ]
    knowledge_mods = ["찢어진", "젖은", "연필로 쓴", "접힌"]
    for i in range(20):
        item_id = entry_id("knowledge", i + 1)
        name = name_for(knowledge_mods, knowledge_nouns, i)
        row = {"id": item_id}
        add_common_fields(
            row,
            name,
            "knowledge",
            ["knowledge", "readable"],
            ["office", "retail", "residential", "security"],
            0.2,
            f"{name}다. 누군가의 준비 과정이 짧은 문장과 표시로 남아 있다.",
            "읽으면 새 조합이나 파밍 판단을 떠올리는 단서가 된다.",
            "직접 따뜻하진 않지만 잘못된 선택을 줄여 체온과 시간을 아낀다.",
        )
        row["readable"] = True
        row["knowledge_title"] = name
        rows.append(row)

    crafted_nouns = [
        "방풍 목가리개",
        "단열 창문 패치",
        "응급 보온 꾸러미",
        "휴대 식수 키트",
        "소형 수리 키트",
        "압박 드레싱",
        "보온 물병 커버",
        "습기 차단 주머니",
        "조리용 포일 받침",
        "건조 점화 꾸러미",
        "정비용 소품 벨트",
        "가벼운 침낭 외피",
        "손난로 파우치",
        "연료 보관 병",
        "현장 위생 팩",
        "임시 문풍지",
        "배낭 압축 끈",
        "방수 식량 묶음",
        "차가운 손 보호대",
        "야간 수색 묶음",
    ]
    crafted_mods = ["조립한", "보강한", "말아 묶은", "밀봉한", "응급"]
    for i in range(100):
        item_id = entry_id("crafted", i + 1)
        name = name_for(crafted_mods, crafted_nouns, i)
        row = {"id": item_id}
        add_common_fields(
            row,
            name,
            "crafted",
            ["crafted_item", "survival_tool"],
            ["global", "retail", "residential", "industrial", "medical"],
            0.7 + (i % 5) * 0.3,
            f"{name}이다. 완제품은 아니지만 재난 상황에서 바로 쓸 수 있게 목적을 가진 형태로 묶었다.",
            "조합 결과물로, 상황에 따라 장착하거나 사용하거나 다음 조합의 재료가 된다.",
            "재료를 의미 있는 형태로 바꿨다는 점에서 단순 파밍보다 가치가 높다.",
        )
        if i % 4 == 0:
            row["use_minutes"] = 5
            row["use_effects"] = {"exposure_restore": 3 + (i % 6)}
        if i % 7 == 0:
            row["carry_capacity_bonus"] = 1.0
        rows.append(row)

    ids = [row["id"] for row in rows]
    if len(rows) != 500:
        raise RuntimeError(f"Expected exactly 500 generated items, got {len(rows)}")
    if len(set(ids)) != len(ids):
        raise RuntimeError("Generated duplicate item ids")
    duplicates = sorted(set(ids) & existing_ids)
    if duplicates:
        raise RuntimeError(f"Generated ids already exist: {duplicates[:10]}")
    return rows


def recipe_category_for(item: dict[str, Any]) -> str:
    category = item.get("category", "")
    tags = set(item.get("item_tags", []))
    if category in {"food", "drink"}:
        return "food_drink"
    if category == "medical" or "hygiene" in tags:
        return "hygiene_medical"
    if category == "equipment" or "warming" in tags or "insulation" in tags:
        return "fire_heat"
    return "repair_fortify"


def generate_recipes(
    items: list[dict[str, Any]],
    base_item_by_id: dict[str, dict[str, Any]],
    existing_recipe_pairs: set[tuple[str, str]],
) -> list[dict[str, Any]]:
    item_by_id = {row["id"]: row for row in items}
    all_item_names = {item_id: row.get("name", item_id) for item_id, row in base_item_by_id.items()}
    all_item_names.update({row["id"]: row.get("name", row["id"]) for row in items})
    by_category: dict[str, list[str]] = {}
    for row in items:
        by_category.setdefault(row["category"], []).append(row["id"])
    equipment_by_slot: dict[str, list[str]] = {}
    for row in items:
        if row.get("category") == "equipment":
            equipment_by_slot.setdefault(str(row.get("equip_slot", "")), []).append(row["id"])
    textile_ids = [row["id"] for row in items if row["category"] == "equipment" or "insulation" in row.get("item_tags", [])]
    repair_material_ids = [row["id"] for row in items if row["category"] in {"utility", "container"}]
    tool_ids = [row["id"] for row in items if row["category"] == "tool"]
    fuel_ids = [row["id"] for row in items if "fuel_component" in row.get("item_tags", []) or "insulation" in row.get("item_tags", [])]
    result_ids = (
        [row["id"] for row in items if row["category"] == "crafted"]
        + [row["id"] for row in items if row["category"] == "equipment"][:80]
        + [row["id"] for row in items if row["category"] == "medical"][:30]
        + [row["id"] for row in items if row["category"] == "food"][:30]
    )
    base_ingredients = [
        "duct_tape",
        "packing_tape",
        "rubber_band",
        "old_cloth_rag",
        "newspaper",
        "aluminum_foil",
        "zip_bag",
        "sewing_kit",
        "bottled_water",
        "lighter",
        "screwdriver",
        "work_gloves",
        "spare_batteries",
        "steel_wire",
        "towel",
        "medical_tape",
        "rubbing_alcohol",
        "paper_bag",
        "clear_plastic_sheet",
        "tea_light_candle",
    ]
    base_ingredients = [item_id for item_id in base_ingredients if item_id in base_item_by_id]
    base_sets = {
        "textile": [item_id for item_id in ["old_cloth_rag", "towel", "sewing_kit", "old_blanket", "fleece_blanket", "medical_tape"] if item_id in base_item_by_id],
        "binding": [item_id for item_id in ["duct_tape", "packing_tape", "rubber_band", "medical_tape", "steel_wire"] if item_id in base_item_by_id],
        "repair": [item_id for item_id in ["duct_tape", "screwdriver", "steel_wire", "epoxy_putty", "sealant_tube", "hose_clamp"] if item_id in base_item_by_id],
        "medical": [item_id for item_id in ["bandage", "medical_tape", "rubbing_alcohol", "sterile_gauze_roll", "alcohol_swab"] if item_id in base_item_by_id],
        "water": [item_id for item_id in ["bottled_water", "zip_bag", "paper_cup", "hot_water_bottle", "cling_wrap_roll"] if item_id in base_item_by_id],
        "food": [item_id for item_id in ["bottled_water", "paper_cup", "instant_soup_powder", "cooking_oil", "soy_sauce_bottle", "gochujang_tube"] if item_id in base_item_by_id],
        "light": [item_id for item_id in ["spare_batteries", "lighter", "flashlight", "tea_light_candle", "aluminum_foil"] if item_id in base_item_by_id],
        "container": [item_id for item_id in ["zip_bag", "paper_bag", "glass_jar", "empty_pet_bottle", "food_storage_container"] if item_id in base_item_by_id],
    }

    recipes: list[dict[str, Any]] = []
    used_pairs = set(existing_recipe_pairs)
    keep_tools = {"lighter", "screwdriver", "sewing_kit", "work_gloves"}
    recipe_index = 0

    def pick(pool: list[str], salt: int, exclude: str = "") -> str:
        candidates = [item_id for item_id in pool if item_id != exclude]
        if not candidates:
            return base_ingredients[salt % len(base_ingredients)]
        return candidates[salt % len(candidates)]

    def candidate_pair(result: dict[str, Any], salt: int) -> tuple[str, str]:
        result_name = str(result.get("name", ""))
        result_category = str(result.get("category", ""))
        result_id = str(result.get("id", ""))
        if result_category == "food":
            return pick(by_category.get("food", []), salt, result_id), pick(base_sets["food"], salt + 3)
        if result_category == "medical":
            return pick(by_category.get("medical", []), salt, result_id), pick(base_sets["medical"], salt + 5)
        if result_category == "equipment":
            slot = str(result.get("equip_slot", ""))
            same_slot_sources = equipment_by_slot.get(slot, [])
            if slot in {"back", "waist", "pocket"}:
                return pick(by_category.get("container", []) + same_slot_sources, salt, result_id), pick(base_sets["binding"] + base_sets["textile"], salt + 7)
            slot_sources = same_slot_sources if same_slot_sources else textile_ids
            return pick(slot_sources, salt, result_id), pick(base_sets["textile"] + base_sets["binding"], salt + 7)
        if "식수" in result_name or "물병" in result_name:
            return pick(by_category.get("container", []), salt, result_id), pick(base_sets["water"], salt + 9)
        if "수리" in result_name or "정비" in result_name or "문풍지" in result_name or "패치" in result_name or "끈" in result_name:
            return pick(repair_material_ids, salt, result_id), pick(base_sets["repair"] + base_sets["binding"], salt + 11)
        if "드레싱" in result_name or "위생" in result_name:
            return pick(by_category.get("medical", []), salt, result_id), pick(base_sets["medical"], salt + 13)
        if "조리" in result_name or "점화" in result_name or "연료" in result_name or "손난로" in result_name:
            return pick(fuel_ids + by_category.get("utility", []), salt, result_id), pick(base_sets["light"] + base_sets["container"], salt + 15)
        if "식량" in result_name:
            return pick(by_category.get("food", []), salt, result_id), pick(base_sets["container"], salt + 17)
        if "야간" in result_name:
            return pick(tool_ids, salt, result_id), pick(base_sets["light"], salt + 19)
        return pick(textile_ids + repair_material_ids, salt, result_id), pick(base_sets["binding"] + base_sets["container"], salt + 21)

    attempts = 0
    while len(recipes) < 240 and attempts < 20000:
        attempts += 1
        result_id = result_ids[recipe_index % len(result_ids)]
        result = item_by_id[result_id]
        primary, secondary = candidate_pair(result, recipe_index + attempts)
        if primary == secondary:
            recipe_index += 1
            continue
        pair = tuple(sorted([primary, secondary]))
        if pair in used_pairs:
            recipe_index += 1
            continue
        used_pairs.add(pair)
        recipe_id = f"{primary}__{secondary}"
        ingredient_rules = {
            primary: "consume",
            secondary: "keep" if secondary in keep_tools else "consume",
        }
        if primary in keep_tools:
            ingredient_rules[primary] = "keep"

        recipes.append(
            {
                "id": recipe_id,
                "ingredients": [primary, secondary],
                "contexts": ["indoor", "outdoor"],
                "codex_category": recipe_category_for(result),
                "codex_order": 5000 + len(recipes),
                "required_tags": [],
                "minutes": 8 + (len(recipes) % 5) * 3,
                "ingredient_rules": ingredient_rules,
                "result_items": [{"id": result_id, "count": 1}],
                "result_type": "success",
                "result_item_id": result_id,
                "indoor_minutes": 8 + (len(recipes) % 5) * 3,
                "required_tool_ids": [],
                "tool_charge_costs": {},
                "result_text": f"{all_item_names.get(primary, primary)} / {all_item_names.get(secondary, secondary)} 조합으로 {result.get('name', result_id)} 형태를 만들었다.",
            }
        )
        recipe_index += 1

    if len(recipes) != 240:
        raise RuntimeError(f"Expected 240 generated recipes, got {len(recipes)}")
    return recipes


def generate_loot_profiles(items: list[dict[str, Any]]) -> dict[str, Any]:
    profiles: dict[str, list[dict[str, Any]]] = {
        "global": [],
        "retail": [],
        "residential": [],
        "medical": [],
        "office": [],
        "food_service": [],
        "industrial": [],
        "security": [],
        "repair": [],
        "living_goods": [],
        "logistics": [],
        "staff_only": [],
    }
    for row in items:
        item_id = row["id"]
        for profile in row.get("spawn_profiles", []):
            if profile not in profiles:
                continue
            weight = 0.45 if profile == "global" else 1.0
            if row.get("category") == "equipment":
                weight *= 0.8
            if row.get("category") == "knowledge":
                weight *= 0.45
            profiles[profile].append({"id": item_id, "weight": round(weight, 2)})

    def first(profile: str, limit: int) -> list[dict[str, Any]]:
        return profiles.get(profile, [])[:limit]

    return {
        "global": first("global", 36),
        "building_categories": {
            "retail": first("retail", 90),
            "residential": first("residential", 84),
            "medical": first("medical", 64),
            "office": first("office", 52),
            "food_service": first("food_service", 72),
            "industrial": first("industrial", 90),
            "security": first("security", 58),
        },
        "site_tags": {
            "repair": first("repair", 50),
            "living_goods": first("living_goods", 50),
            "logistics": first("logistics", 50),
            "staff_only": first("staff_only", 36),
            "materials": first("industrial", 50),
            "stockroom": first("retail", 48),
        },
        "building_ids": {
            "mart_01": first("retail", 64),
            "convenience_01": first("retail", 48),
            "pharmacy_01": first("medical", 54),
            "clinic_01": first("medical", 54),
            "hardware_01": first("industrial", 72),
            "warehouse_01": first("industrial", 72),
            "garage_01": first("repair", 42) + first("industrial", 24),
            "hostel_01": first("residential", 58),
            "apartment_01": first("residential", 70),
        },
    }


ICON_COLORS = {
    "food": (191, 127, 65),
    "drink": (79, 146, 185),
    "medical": (194, 77, 84),
    "tool": (135, 150, 157),
    "utility": (143, 137, 93),
    "container": (101, 132, 118),
    "equipment": (96, 124, 153),
    "knowledge": (171, 154, 108),
    "crafted": (128, 158, 144),
}


def icon_color(category: str, item_id: str) -> tuple[int, int, int]:
    base = ICON_COLORS.get(category, (130, 140, 150))
    h = stable_hash(item_id)
    return tuple(max(30, min(235, channel + ((h >> shift) % 35) - 17)) for channel, shift in zip(base, [0, 8, 16]))


def draw_icon(item: dict[str, Any], size: int) -> Image.Image:
    scale = 4
    canvas = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    category = str(item.get("category", "utility"))
    color = icon_color(category, item["id"])
    accent = tuple(min(255, c + 45) for c in color)
    shadow = (22, 32, 40, 150)
    h = stable_hash(item["id"])

    def box(x0: float, y0: float, x1: float, y1: float) -> tuple[int, int, int, int]:
        return (int(x0 * scale), int(y0 * scale), int(x1 * scale), int(y1 * scale))

    draw.ellipse(box(size * 0.12, size * 0.14, size * 0.88, size * 0.88), fill=shadow)
    if category in {"food", "drink", "medical"}:
        draw.rounded_rectangle(box(size * 0.25, size * 0.18, size * 0.75, size * 0.82), radius=int(size * 0.14 * scale), fill=color + (255,), outline=(230, 238, 242, 190), width=max(1, scale))
        draw.rectangle(box(size * 0.32, size * 0.34, size * 0.68, size * 0.48), fill=accent + (230,))
        if category == "medical":
            draw.rectangle(box(size * 0.45, size * 0.25, size * 0.55, size * 0.72), fill=(245, 246, 242, 230))
            draw.rectangle(box(size * 0.32, size * 0.43, size * 0.68, size * 0.54), fill=(245, 246, 242, 230))
    elif category in {"tool", "utility"}:
        draw.rounded_rectangle(box(size * 0.20, size * 0.55, size * 0.82, size * 0.72), radius=int(size * 0.08 * scale), fill=color + (255,), outline=(224, 232, 236, 170), width=max(1, scale))
        draw.polygon([box(size * 0.25, size * 0.25, size * 0.32, size * 0.35)[:2], box(size * 0.77, size * 0.55, size * 0.85, size * 0.66)[:2], box(size * 0.70, size * 0.73, size * 0.78, size * 0.80)[:2], box(size * 0.18, size * 0.43, size * 0.25, size * 0.51)[:2]], fill=accent + (245,))
    elif category == "equipment":
        draw.rounded_rectangle(box(size * 0.28, size * 0.18, size * 0.72, size * 0.82), radius=int(size * 0.13 * scale), fill=color + (255,), outline=(225, 234, 240, 190), width=max(1, scale))
        draw.arc(box(size * 0.18, size * 0.20, size * 0.42, size * 0.72), 260, 90, fill=accent + (240,), width=max(2, int(scale * 1.5)))
        draw.arc(box(size * 0.58, size * 0.20, size * 0.82, size * 0.72), 90, 280, fill=accent + (240,), width=max(2, int(scale * 1.5)))
    elif category == "container":
        draw.rounded_rectangle(box(size * 0.20, size * 0.32, size * 0.80, size * 0.78), radius=int(size * 0.08 * scale), fill=color + (255,), outline=(225, 235, 238, 180), width=max(1, scale))
        draw.arc(box(size * 0.34, size * 0.18, size * 0.66, size * 0.48), 180, 360, fill=accent + (240,), width=max(2, scale))
    elif category == "knowledge":
        draw.polygon([box(size * 0.28, size * 0.18, size * 0.28, size * 0.18)[:2], box(size * 0.74, size * 0.25, size * 0.74, size * 0.25)[:2], box(size * 0.68, size * 0.82, size * 0.68, size * 0.82)[:2], box(size * 0.22, size * 0.73, size * 0.22, size * 0.73)[:2]], fill=color + (255,))
        for y in [0.38, 0.52, 0.66]:
            draw.line(box(size * 0.32, size * y, size * 0.62, size * y), fill=(245, 242, 224, 220), width=max(1, scale))
    else:
        draw.rounded_rectangle(box(size * 0.22, size * 0.22, size * 0.78, size * 0.78), radius=int(size * 0.12 * scale), fill=color + (255,), outline=(226, 236, 238, 190), width=max(1, scale))
        draw.line(box(size * 0.34, size * 0.34, size * 0.66, size * 0.66), fill=accent + (240,), width=max(2, scale))
        draw.line(box(size * 0.66, size * 0.34, size * 0.34, size * 0.66), fill=accent + (240,), width=max(2, scale))

    if h % 2 == 0:
        draw.ellipse(box(size * 0.60, size * 0.18, size * 0.78, size * 0.36), fill=(230, 244, 248, 80))
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def generate_icons(items: list[dict[str, Any]]) -> None:
    for size in [24, 32]:
        out_dir = ICON_ROOT / f"icons_{size}_cutout"
        out_dir.mkdir(parents=True, exist_ok=True)
        for item in items:
            draw_icon(item, size).save(out_dir / f"{item['id']}.png")


def update_manifest(items: list[dict[str, Any]]) -> None:
    manifest = load_json(MANIFEST_PATH) if MANIFEST_PATH.exists() else {"meta": {}, "items": []}
    existing_items = [row for row in manifest.get("items", []) if not str(row.get("id", "")).startswith(EXPANSION_PREFIX)]
    next_index = len(existing_items)
    for offset, item in enumerate(items):
        existing_items.append(
            {
                "index": next_index + offset,
                "id": item["id"],
                "name": item["name"],
                "category": item["category"],
                "file_32": f"icons_32_cutout/{item['id']}.png",
                "file_24": f"icons_24_cutout/{item['id']}.png",
                "sheet": "generated_survival_expansion",
                "x": 0,
                "y": 0,
                "w": 32,
                "h": 32,
                "col": 0,
                "row": 0,
            }
        )
    manifest["items"] = existing_items
    manifest.setdefault("meta", {})
    manifest["meta"]["survival_expansion_generated"] = True
    manifest["meta"]["survival_expansion_item_count"] = len(items)
    manifest["meta"]["item_count"] = len(existing_items)
    write_json(MANIFEST_PATH, manifest)


def main() -> None:
    base_items = load_json(GAME_DATA / "items.json")
    base_recipes = load_json(GAME_DATA / "crafting_combinations.json")
    base_item_by_id = {row["id"]: row for row in base_items}
    existing_item_ids = set(base_item_by_id.keys())
    existing_recipe_pairs = {tuple(sorted(row.get("ingredients", []))) for row in base_recipes if len(row.get("ingredients", [])) == 2}

    items = generate_items(existing_item_ids)
    recipes = generate_recipes(items, base_item_by_id, existing_recipe_pairs)
    loot_profiles = generate_loot_profiles(items)

    write_json(ITEM_OUTPUT, items)
    write_json(RECIPE_OUTPUT, recipes)
    write_json(LOOT_PROFILE_OUTPUT, loot_profiles)
    generate_icons(items)
    update_manifest(items)

    print(f"generated_items={len(items)}")
    print(f"generated_recipes={len(recipes)}")
    print(f"icon_files={len(items) * 2}")


if __name__ == "__main__":
    main()
