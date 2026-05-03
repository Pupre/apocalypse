from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
GAME_DATA = ROOT / "game" / "data"
WORLD_LAYOUT_PATH = GAME_DATA / "outdoor" / "world_layout.json"
BLOCKS_DIR = GAME_DATA / "outdoor" / "blocks"
BUILDINGS_PATH = GAME_DATA / "buildings.json"

CITY_WIDTH = 12
CITY_HEIGHT = 12
BLOCK_SIZE = 960
GENERATED_PREFIX = "mapx_"
CORE_COORDS = {(x, y) for y in range(3) for x in range(3)}


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def rect(x: int, y: int, width: int, height: int) -> dict[str, int]:
    return {"x": x, "y": y, "width": width, "height": height}


def point(x: int, y: int) -> dict[str, int]:
    return {"x": x, "y": y}


DISTRICT_RULES: list[dict[str, Any]] = [
    {
        "key": "north_market",
        "label": "북쪽 상권",
        "condition": lambda x, y: y <= 2 and x >= 3,
        "landmark": "눈 덮인 상가 거리",
        "themes": ["retail", "food_service", "office"],
    },
    {
        "key": "east_medical",
        "label": "동쪽 의료/업무 지구",
        "condition": lambda x, y: x >= 8 and y <= 6,
        "landmark": "정전된 업무지구",
        "themes": ["medical", "office", "retail"],
    },
    {
        "key": "south_residential",
        "label": "남쪽 주거 밀집지",
        "condition": lambda x, y: y >= 8 and x <= 5,
        "landmark": "얼어붙은 주택가",
        "themes": ["residential", "retail", "food_service"],
    },
    {
        "key": "south_industrial",
        "label": "남동쪽 창고/정비 지대",
        "condition": lambda x, y: y >= 7 and x >= 6,
        "landmark": "멈춘 물류 차고",
        "themes": ["industrial", "retail", "office"],
    },
    {
        "key": "west_shelter",
        "label": "서쪽 대피 흔적",
        "condition": lambda x, y: x <= 2 and y >= 3,
        "landmark": "흩어진 임시 대피선",
        "themes": ["residential", "security", "food_service"],
    },
    {
        "key": "central_transfer",
        "label": "중앙 환승로",
        "condition": lambda x, y: 3 <= x <= 7 and 3 <= y <= 7,
        "landmark": "막힌 환승 교차로",
        "themes": ["retail", "food_service", "industrial", "office"],
    },
]


BUILDING_TEMPLATES: dict[str, list[dict[str, Any]]] = {
    "retail": [
        {
            "name": "얼어붙은 할인점",
            "event": "mart_01",
            "tags": ["living_goods", "bulk_stock", "public_floor"],
            "brief": "넓은 매대와 직원 구역이 남아 있지만 인기 물품은 이미 많이 털렸다.",
        },
        {
            "name": "골목 편의점",
            "event": "convenience_01",
            "tags": ["counter", "fridge_stock", "glass_risk"],
            "brief": "계산대 안쪽과 냉장고 뒤편에 손대기 어려운 물건이 남아 있다.",
        },
        {
            "name": "작은 철물 코너",
            "event": "hardware_01",
            "tags": ["repair", "materials", "gated_backroom"],
            "brief": "진열대보다 안쪽 자재함과 공구함이 더 중요해 보인다.",
        },
        {
            "name": "중고 서점",
            "event": "bookstore_01",
            "tags": ["paper", "quiet", "records"],
            "brief": "책장 사이가 어둡고, 카운터 밑 기록 상자가 유난히 눈에 띈다.",
        },
        {
            "name": "골목 구멍가게",
            "event": "corner_store_01",
            "tags": ["living_goods", "small_stock", "neighborhood"],
            "brief": "작은 공간이라 빨리 훑을 수 있지만 사장만 아는 숨은 선반이 있다.",
        },
    ],
    "food_service": [
        {
            "name": "문 닫은 카페",
            "event": "cafe_01",
            "tags": ["warm_drink", "seating", "window_gap"],
            "brief": "창가 틈바람이 세지만 머신 주변과 좌석 아래에 쓸 만한 것이 있다.",
        },
        {
            "name": "작은 식당",
            "event": "restaurant_01",
            "tags": ["kitchen", "pantry", "food_service"],
            "brief": "홀은 비었고, 위험한 주방과 잠긴 안쪽 창고가 판단을 요구한다.",
        },
        {
            "name": "동네 빵집",
            "event": "bakery_01",
            "tags": ["food_service", "warm_drink", "back_kitchen"],
            "brief": "진열대보다 오븐 뒤와 재료 선반 쪽이 더 깊은 수색지가 된다.",
        },
        {
            "name": "기사식당",
            "event": "canteen_01",
            "tags": ["bulk_food", "kitchen", "truckers"],
            "brief": "급히 떠난 흔적이 남아 있어 조리대와 휴게실 선택지가 갈린다.",
        },
        {
            "name": "작은 찻집",
            "event": "tea_shop_01",
            "tags": ["warm_drink", "quiet", "personal"],
            "brief": "조용한 실내지만 찬 바람과 깨진 찻장이 시간을 잡아먹는다.",
        },
        {
            "name": "정육점",
            "event": "butcher_01",
            "tags": ["cold_storage", "sharp_tools", "food_service"],
            "brief": "냉장실 문이 얼어붙어 있고, 안쪽 수색은 손과 시간을 많이 쓴다.",
        },
    ],
    "residential": [
        {
            "name": "낡은 다세대 주택",
            "event": "residence_01",
            "tags": ["living_trace", "household", "personal"],
            "brief": "생활 흔적이 많아 사소한 물건까지 쓸모를 판단해야 한다.",
        },
        {
            "name": "얼어붙은 빌라",
            "event": "apartment_01",
            "tags": ["vertical_site", "keys", "living_trace"],
            "brief": "공동 현관 뒤로 계단과 잠긴 문들이 이어져 한 번에 끝나지 않는다.",
        },
        {
            "name": "연립 주택",
            "event": "row_house_01",
            "tags": ["living_trace", "neighbors", "basement"],
            "brief": "옆집까지 이어진 흔적 때문에 어느 문부터 열지 결정해야 한다.",
        },
        {
            "name": "싸구려 여관",
            "event": "hostel_01",
            "tags": ["temporary_home", "bedding", "lost_items"],
            "brief": "객실마다 남은 물건의 성격이 달라 오래 뒤질수록 위험도 커진다.",
        },
        {
            "name": "작은 예배당",
            "event": "chapel_01",
            "tags": ["shelter", "quiet", "community"],
            "brief": "임시 대피 흔적이 있으나 조용한 공간일수록 소란이 크게 울린다.",
        },
        {
            "name": "동네 교회",
            "event": "church_01",
            "tags": ["shelter", "community_stock", "records"],
            "brief": "구호품과 사람들의 흔적이 섞여 있어 수색의 감정적 무게가 크다.",
        },
    ],
    "industrial": [
        {
            "name": "폐창고",
            "event": "warehouse_01",
            "tags": ["stockroom", "materials", "industrial"],
            "brief": "큰 물건은 많지만 들고 나갈 수 있는 것과 없는 것을 가려야 한다.",
        },
        {
            "name": "정비 차고",
            "event": "garage_01",
            "tags": ["repair", "vehicle", "tools"],
            "brief": "기름 냄새와 얼어붙은 셔터 때문에 안전한 접근이 필요하다.",
        },
        {
            "name": "소형 수리점",
            "event": "repair_shop_01",
            "tags": ["repair", "electronics", "gated_backroom"],
            "brief": "고장 난 전자기기와 공구가 뒤섞여 조합 재료를 건질 만하다.",
        },
        {
            "name": "물류 보관소",
            "event": "storage_depot_01",
            "tags": ["bulk_stock", "locked_storage", "industrial"],
            "brief": "상자는 많지만 모두 열 수는 없다. 소리와 시간의 값을 따져야 한다.",
        },
        {
            "name": "주유소",
            "event": "gas_station_01",
            "tags": ["fuel", "counter", "roadside"],
            "brief": "연료 흔적은 위험하지만, 빈 통과 열원 재료가 남아 있을 수 있다.",
        },
    ],
    "medical": [
        {
            "name": "작은 약국",
            "event": "pharmacy_01",
            "tags": ["medical", "locked_storage", "counter"],
            "brief": "진열대는 비었지만 카운터 안쪽과 약품 보관함이 아직 닫혀 있다.",
        },
        {
            "name": "임시 진료소",
            "event": "clinic_01",
            "tags": ["medical", "records", "quiet"],
            "brief": "진료실과 약품함을 뒤질수록 얻는 것과 다치는 위험이 함께 커진다.",
        },
        {
            "name": "동네 세탁소",
            "event": "laundry_01",
            "tags": ["hygiene", "wet_floor", "household"],
            "brief": "젖은 바닥이 발을 식히지만 세탁망과 건조대 주변이 유용해 보인다.",
        },
    ],
    "office": [
        {
            "name": "관리 사무실",
            "event": "office_01",
            "tags": ["office", "records", "electronics"],
            "brief": "책상 서랍과 캐비닛은 흔하지만, 쓸모 있는 정보는 안쪽에 있다.",
        },
        {
            "name": "폐교 정문",
            "event": "school_gate_01",
            "tags": ["public_building", "records", "shelter"],
            "brief": "정문 주변 안내문과 경비실 흔적이 다음 이동 판단을 흔든다.",
        },
        {
            "name": "파출소",
            "event": "police_box_01",
            "tags": ["security", "records", "locked_storage"],
            "brief": "잠긴 보관함과 상황판이 남아 있지만 오래 머물수록 들키기 쉽다.",
        },
    ],
    "security": [
        {
            "name": "순찰 초소",
            "event": "police_box_01",
            "tags": ["security", "records", "roadblock"],
            "brief": "도로 통제 흔적과 기록지가 남아 다음 구역 위험을 암시한다.",
        },
        {
            "name": "대피 안내소",
            "event": "chapel_01",
            "tags": ["shelter", "community", "records"],
            "brief": "구호품은 적지만 사람들이 남긴 선택의 흔적이 있다.",
        },
    ],
}


SCENARIO_HOOKS: dict[str, list[str]] = {
    "north_market": [
        "처음 사재기가 지나간 뒤에도 사람들이 놓친 생활 도구를 찾는 상권 루프",
        "깨진 유리와 냉장고 뒤쪽을 감수할지 판단하는 빠른 파밍 루프",
    ],
    "east_medical": [
        "약과 기록을 얻기 위해 잠긴 보관함을 열지, 시간을 아낄지 고르는 의료 루프",
        "정전된 업무지구에서 지도와 열쇠 단서를 찾아 다음 동선을 여는 루프",
    ],
    "south_residential": [
        "남겨진 생활 공간에서 사적인 물건과 실용 물건 사이의 무게를 고르는 주거 루프",
        "가족 흔적과 임시 대피 흔적이 섞인 방을 어디까지 뒤질지 결정하는 루프",
    ],
    "south_industrial": [
        "무겁지만 결정적인 공구와 연료 재료를 운반 한계 안에 담는 정비 루프",
        "소리를 감수하고 셔터/상자를 열지 포기할지 고르는 창고 루프",
    ],
    "west_shelter": [
        "구호품이 거의 사라진 대피선에서 남은 기록과 작은 도구를 모으는 루프",
        "조용한 공간의 소란 리스크와 체온 회복 가능성을 맞바꾸는 루프",
    ],
    "central_transfer": [
        "큰 길은 빠르지만 노출이 크고, 골목은 느리지만 파밍지가 촘촘한 이동 루프",
        "추적과 결빙 위험 속에서 다음 실내 진입 지점을 고르는 환승 루프",
    ],
}


SPECIAL_BUILDING_OVERRIDES: dict[str, dict[str, Any]] = {
    "mapx_03_00_a": {
        "name": "재난 안내 서점",
        "category": "retail",
        "event_path": "res://data/events/indoor/mapx_north_market_bookstore_01.json",
        "tags": ["bookstore", "route_info", "paper", "big_decision"],
        "brief": "대피소 안내 전단과 무너진 책장 뒤 자료실이 있어 이동 정보를 얻을 수 있다.",
        "scenario_hook": "무너진 책장을 소리 내어 밀지, 도구를 써서 조용히 치울지 결정하는 상권 정보 루프",
    },
    "mapx_06_06_a": {
        "name": "환승로 구멍가게",
        "category": "retail",
        "event_path": "res://data/events/indoor/mapx_central_transfer_corner_store_01.json",
        "tags": ["detour", "route_info", "corner_store", "big_decision"],
        "brief": "창밖 정류장 안내판과 뒤쪽 문이 큰길을 피하는 우회 판단을 만든다.",
        "scenario_hook": "빠른 큰길과 느린 골목 우회 중 어느 위험을 감수할지 고르는 환승로 루프",
    },
    "mapx_11_11_a": {
        "name": "멈춘 연료 야드",
        "category": "industrial",
        "event_path": "res://data/events/indoor/mapx_industrial_fuel_yard_01.json",
        "tags": ["fuel", "industrial", "vehicle", "big_decision"],
        "brief": "잔량 연료를 얻을 수 있지만 냄새와 소음, 운반 무게를 함께 감수해야 한다.",
        "scenario_hook": "무거운 연료를 챙겨 밤을 버틸지, 짐을 가볍게 유지할지 고르는 정비 지대 루프",
    },
    "mapx_00_08_a": {
        "name": "임시 대피 잡화점",
        "category": "retail",
        "event_path": "res://data/events/indoor/mapx_west_shelter_general_store_01.json",
        "tags": ["shelter", "community", "personal", "big_decision"],
        "brief": "남겨진 보급 상자를 전부 가져갈지 일부만 챙길지 마음까지 시험하는 장소다.",
        "scenario_hook": "내 생존과 다음 생존자의 몫 사이를 고르는 서쪽 대피선 루프",
    },
    "mapx_09_04_a": {
        "name": "의료지구 편의점",
        "category": "medical",
        "event_path": "res://data/events/indoor/mapx_east_medical_convenience_01.json",
        "tags": ["medical", "hygiene", "delivery_crates", "big_decision"],
        "brief": "일반 매대보다 임시 처치대와 약국 배달 상자가 중요한 의료 지구 파밍지다.",
        "scenario_hook": "오염된 처치대를 빨리 뒤질지, 장갑으로 안전하게 분류할지 결정하는 의료 루프",
    },
}


def district_for(x: int, y: int) -> dict[str, Any]:
    for district in DISTRICT_RULES:
        if district["condition"](x, y):
            return district
    return {
        "key": "mixed_edge",
        "label": "혼합 외곽",
        "landmark": "끊어진 외곽 도로",
        "themes": ["retail", "residential", "industrial", "food_service"],
    }


def choose_theme(district: dict[str, Any], x: int, y: int, slot: int) -> str:
    themes: list[str] = district["themes"]
    return themes[(x * 7 + y * 5 + slot) % len(themes)]


def choose_building_template(theme: str, x: int, y: int, slot: int) -> dict[str, Any]:
    templates = BUILDING_TEMPLATES[theme]
    return templates[(x * 11 + y * 3 + slot) % len(templates)]


def layout_id_for(x: int, y: int, district_key: str) -> str:
    variants_by_district = {
        "north_market": ["market_arcade", "market_back_alley", "market_plaza"],
        "east_medical": ["medical_campus", "clinic_drive", "pharmacy_court"],
        "south_residential": ["residential_courtyard", "row_house_lane", "frozen_backstreet"],
        "south_industrial": ["loading_yard", "fuel_service_lot", "warehouse_spur"],
        "west_shelter": ["shelter_checkpoint", "relief_lane", "barricaded_square"],
        "central_transfer": ["bus_loop", "station_crossing", "underpass_detour"],
        "mixed_edge": ["edge_service_road", "snowed_vacant_lot", "broken_grid"],
    }
    variants = variants_by_district.get(district_key, variants_by_district["mixed_edge"])
    return variants[(x * 5 + y * 3) % len(variants)]


def anchor_positions_for(x: int, y: int, district_key: str) -> list[dict[str, int]]:
    variants_by_district = {
        "north_market": [
            [point(170, 235), point(705, 300), point(520, 730)],
            [point(730, 220), point(215, 520), point(680, 735)],
        ],
        "east_medical": [
            [point(265, 250), point(690, 575)],
            [point(700, 255), point(245, 690)],
        ],
        "south_residential": [
            [point(215, 265), point(620, 705), point(795, 420)],
            [point(690, 255), point(230, 655), point(455, 760)],
        ],
        "south_industrial": [
            [point(735, 300), point(260, 690)],
            [point(245, 315), point(720, 695)],
        ],
        "west_shelter": [
            [point(205, 250), point(710, 655), point(430, 450)],
            [point(700, 260), point(215, 700), point(520, 580)],
        ],
        "central_transfer": [
            [point(250, 245), point(725, 265), point(500, 710)],
            [point(720, 700), point(230, 690), point(500, 235)],
        ],
        "mixed_edge": [
            [point(190, 240), point(710, 695)],
            [point(730, 250), point(210, 705)],
            [point(210, 690), point(735, 250)],
            [point(700, 690), point(225, 245)],
        ],
    }
    variants = variants_by_district.get(district_key, variants_by_district["mixed_edge"])
    return variants[(x + y * 2) % len(variants)]


def generated_building_count_for(x: int, y: int, district_key: str | None = None) -> int:
    if district_key is None:
        district_key = district_for(x, y)["key"]
    if district_key in ["north_market", "central_transfer", "west_shelter"]:
        return 3 if (x + y) % 3 == 0 else 2
    if district_key == "south_residential":
        return 3 if (x * 2 + y) % 4 == 0 else 2
    if district_key in ["east_medical", "south_industrial"]:
        return 2 if (x * 3 + y * 5) % 3 != 1 else 1
    return 2 if (x * 3 + y * 5) % 5 == 0 else 1


def building_anchor_id(x: int, y: int, slot: int) -> str:
    suffix = ["a", "b", "c"][slot] if slot < 3 else chr(ord("a") + slot)
    return f"{GENERATED_PREFIX}{x:02d}_{y:02d}_{suffix}_anchor"


def building_id(x: int, y: int, slot: int) -> str:
    suffix = ["a", "b", "c"][slot] if slot < 3 else chr(ord("a") + slot)
    return f"{GENERATED_PREFIX}{x:02d}_{y:02d}_{suffix}"


def road_texture(seed: int, vertical: bool = False) -> str:
    vertical_textures = ["road_lane_v", "slush_road", "road_plain", "road_cracked"]
    horizontal_textures = ["road_lane_h", "road_cracked", "slush_road", "road_plain"]
    choices = vertical_textures if vertical else horizontal_textures
    return choices[seed % len(choices)]


def generate_roads(x: int, y: int, district_key: str) -> list[dict[str, Any]]:
    vertical_x = 300 + ((x * 37 + y * 17) % 4) * 75
    horizontal_y = 280 + ((x * 19 + y * 31) % 4) * 80
    if district_key == "north_market":
        return [
            {"id": "market_main_street", "texture_id": road_texture(x + y, False), "rect": rect(0, 285 + (y % 2) * 35, BLOCK_SIZE, 165)},
            {"id": "market_back_alley", "texture_id": "alley_dark", "rect": rect(120 + (x % 2) * 60, 0, 105, BLOCK_SIZE)},
            {"id": "arcade_walk", "texture_id": "sidewalk_snow", "rect": rect(0, 170, BLOCK_SIZE, 78)},
            {"id": "delivery_cut", "texture_id": "road_plain", "rect": rect(620, 455, 150, 360)},
        ]
    if district_key == "east_medical":
        return [
            {"id": "clinic_drive", "texture_id": "road_plain", "rect": rect(165, 105, 630, 150)},
            {"id": "ambulance_lane", "texture_id": road_texture(x + y + 1, True), "rect": rect(660, 0, 145, BLOCK_SIZE)},
            {"id": "pharmacy_court", "texture_id": "sidewalk_snow", "rect": rect(225, 395, 470, 280)},
            {"id": "service_dropoff", "texture_id": "slush_road", "rect": rect(85, 665, 650, 120)},
        ]
    if district_key == "south_residential":
        return [
            {"id": "residential_lane_a", "texture_id": "alley_dark", "rect": rect(155, 0, 118, 575)},
            {"id": "residential_lane_b", "texture_id": "alley_dark", "rect": rect(155, 485, 610, 118)},
            {"id": "courtyard_walk", "texture_id": "sidewalk_snow", "rect": rect(520, 170, 250, 250)},
            {"id": "dead_end_snow_road", "texture_id": "road_cracked", "rect": rect(610, 585, 128, 300)},
        ]
    if district_key == "south_industrial":
        return [
            {"id": "loading_yard", "texture_id": "road_plain", "rect": rect(145, 175, 650, 475)},
            {"id": "warehouse_spur", "texture_id": "slush_road", "rect": rect(0, 660, BLOCK_SIZE, 150)},
            {"id": "service_lane", "texture_id": "alley_dark", "rect": rect(70, 75, 130, 765)},
            {"id": "fuel_apron", "texture_id": "road_cracked", "rect": rect(615, 55, 235, 170)},
        ]
    if district_key == "west_shelter":
        return [
            {"id": "relief_route", "texture_id": road_texture(x + y, False), "rect": rect(0, 360, BLOCK_SIZE, 150)},
            {"id": "checkpoint_chicane_a", "texture_id": "road_plain", "rect": rect(165, 205, 430, 115)},
            {"id": "checkpoint_chicane_b", "texture_id": "road_plain", "rect": rect(360, 505, 430, 115)},
            {"id": "chapel_walk", "texture_id": "sidewalk_snow", "rect": rect(100, 630, 300, 155)},
        ]
    if district_key == "central_transfer":
        return [
            {"id": "bus_loop_top", "texture_id": "road_plain", "rect": rect(155, 170, 650, 135)},
            {"id": "bus_loop_bottom", "texture_id": "road_plain", "rect": rect(155, 650, 650, 135)},
            {"id": "bus_loop_left", "texture_id": "slush_road", "rect": rect(155, 170, 135, 615)},
            {"id": "bus_loop_right", "texture_id": "slush_road", "rect": rect(670, 170, 135, 615)},
            {"id": "underpass_cut", "texture_id": "alley_dark", "rect": rect(390, 0, 175, BLOCK_SIZE)},
        ]
    return [
        {"id": "north_south", "texture_id": road_texture(x + y, True), "rect": rect(vertical_x, 0, 175, BLOCK_SIZE)},
        {"id": "east_west", "texture_id": road_texture(x * 2 + y, False), "rect": rect(0, horizontal_y, BLOCK_SIZE, 175)},
        {"id": "edge_service_walk", "texture_id": "sidewalk_snow", "rect": rect(90, 185, 290, 100)},
        {"id": "vacant_pullout", "texture_id": "road_plain", "rect": rect(615, 580, 270, 145)},
    ]


def generate_snow_fields(x: int, y: int, district_key: str) -> list[dict[str, Any]]:
    inset = (x * 23 + y * 41) % 70
    if district_key == "central_transfer":
        return [
            {"id": "terminal_plaza_snow", "rect": rect(315, 335, 330, 260)},
            {"id": "bus_stop_snowbank", "rect": rect(95, 95, 215 + inset, 110)},
            {"id": "underpass_drift", "rect": rect(395, 780, 170, 130)},
            {"id": "ticket_curb_snow", "rect": rect(685, 320, 195, 105)},
        ]
    if district_key == "south_industrial":
        return [
            {"id": "open_yard_snow", "rect": rect(190, 210, 560, 350)},
            {"id": "dock_drift", "rect": rect(735, 590, 180, 160)},
            {"id": "fence_snow", "rect": rect(35, 760, 450, 125)},
            {"id": "fuel_curb_snow", "rect": rect(610, 35, 260, 90)},
        ]
    if district_key == "south_residential":
        return [
            {"id": "courtyard_snow", "rect": rect(505, 155, 280, 280)},
            {"id": "garden_snow", "rect": rect(25, 620, 310, 240)},
            {"id": "stoop_snow", "rect": rect(300, 95, 170, 95)},
            {"id": "back_fence_snow", "rect": rect(690, 690, 215, 165)},
        ]
    if district_key == "east_medical":
        return [
            {"id": "clinic_plaza_snow", "rect": rect(240, 390, 440, 275)},
            {"id": "ambulance_bay_snow", "rect": rect(650, 235, 220, 145)},
            {"id": "pharmacy_curb_snow", "rect": rect(80, 690, 310, 95)},
            {"id": "records_walk_snow", "rect": rect(175, 60, 265, 95)},
        ]
    if district_key == "west_shelter":
        return [
            {"id": "relief_square_snow", "rect": rect(95, 610, 330, 215)},
            {"id": "checkpoint_snowbank", "rect": rect(520, 210, 300, 155)},
            {"id": "queue_line_snow", "rect": rect(50, 330, 210, 95)},
            {"id": "chapel_curb_snow", "rect": rect(560, 640, 260, 125)},
        ]
    if district_key == "north_market":
        return [
            {"id": "storefront_snow", "rect": rect(0, 150, 390 + inset, 120)},
            {"id": "market_plaza_snow", "rect": rect(500, 535, 340, 230)},
            {"id": "crate_curb_snow", "rect": rect(250, 640, 230, 105)},
            {"id": "awning_shadow_snow", "rect": rect(690, 60, 205, 125)},
        ]
    return [
        {"id": "northwest_snow", "rect": rect(0, 0, 285 + inset, 260)},
        {"id": "southeast_snow", "rect": rect(620, 680 - inset // 2, 340, 280)},
        {"id": "curb_snow", "rect": rect(260, 610, 230, 105)},
        {"id": "wind_packed_snow", "rect": rect(700, 55, 190, 120 + inset // 3)},
    ]


def hazard(kind: str, hazard_id: str, area: dict[str, int], message: str, exposure: float, fatigue: float, health: float = 0.0) -> dict[str, Any]:
    row: dict[str, Any] = {
        "id": hazard_id,
        "kind": kind,
        "rect": area,
        "message": message,
        "exposure_loss": exposure,
        "fatigue_gain": fatigue,
        "cooldown_seconds": 7.0,
    }
    if health > 0.0:
        row["health_loss"] = health
    return row


def generate_hazards(x: int, y: int, district_key: str) -> list[dict[str, Any]]:
    seed = x * 13 + y * 7
    district_hazard_areas = {
        "north_market": (
            rect(285 + seed % 90, 295, 135, 120),
            rect(585, 410 + seed % 90, 180, 210),
            rect(170, 610, 220, 125),
        ),
        "east_medical": (
            rect(230 + seed % 110, 145, 170, 120),
            rect(665, 270 + seed % 120, 160, 240),
            rect(255, 640, 270, 135),
        ),
        "south_residential": (
            rect(155, 460 + seed % 85, 150, 130),
            rect(500, 185 + seed % 115, 190, 210),
            rect(615, 680, 220, 135),
        ),
        "south_industrial": (
            rect(245 + seed % 150, 520, 190, 140),
            rect(695, 110 + seed % 160, 160, 260),
            rect(160, 690, 300, 135),
        ),
        "west_shelter": (
            rect(390 + seed % 100, 340, 170, 130),
            rect(125, 515 + seed % 110, 180, 220),
            rect(560, 205, 260, 135),
        ),
        "central_transfer": (
            rect(365 + seed % 90, 380, 200, 165),
            rect(665, 255 + seed % 130, 160, 245),
            rect(165, 655, 270, 135),
        ),
    }
    black_ice_area, wind_gap_area, snow_drift_area = district_hazard_areas.get(
        district_key,
        (
            rect(385 + seed % 80, 345 + (seed // 3) % 70, 150, 145),
            rect(610, 210 + seed % 180, 190, 230),
            rect(170 + seed % 120, 650, 240, 150),
        ),
    )
    hazards = [
        hazard(
            "black_ice",
            "intersection_black_ice",
            black_ice_area,
            "교차로 그늘에 숨어 있던 빙판이 발을 미끄러뜨렸다.",
            1.5,
            1.4,
            0.5 if (x + y) % 4 == 0 else 0.0,
        ),
        hazard(
            "wind_gap",
            "building_wind_gap",
            wind_gap_area,
            "건물 사이로 눌린 바람이 체온을 빠르게 빼앗았다.",
            2.6,
            1.1,
        ),
        hazard(
            "snow_drift",
            "packed_snow_drift",
            snow_drift_area,
            "허벅지까지 쌓인 눈을 헤치느라 숨이 거칠어졌다.",
            1.1,
            2.2,
        ),
    ]
    if district_key in ["central_transfer", "south_industrial", "east_medical"] or (x + y) % 3 == 0:
        whiteout_by_district = {
            "central_transfer": rect(330, 120 + seed % 90, 300, 230),
            "south_industrial": rect(510, 80 + seed % 120, 310, 250),
            "east_medical": rect(105, 315 + seed % 120, 260, 230),
            "west_shelter": rect(600, 455, 250, 210),
            "north_market": rect(455, 520, 250, 210),
            "south_residential": rect(290, 315, 220, 200),
        }
        hazards.append(hazard(
            "whiteout",
            "open_lot_whiteout",
            whiteout_by_district.get(district_key, rect(500, 40 + seed % 120, 260, 250)),
            "눈발이 시야를 지워 길과 출입구가 잠깐 구분되지 않았다.",
            2.0,
            1.6,
        ))
    return hazards


OBSTACLE_POOL: list[tuple[str, str, tuple[int, int]]] = [
    ("vehicle", "frozen_car", (58, 58)),
    ("rubble", "dumpster_snow", (118, 78)),
    ("cart", "shopping_cart", (70, 58)),
    ("light", "street_lamp", (42, 82)),
    ("barrier", "barricade_wood", (105, 48)),
    ("snow", "snow_drift", (132, 78)),
    ("utility", "utility_box", (76, 68)),
    ("crate", "crate_stack", (88, 76)),
    ("barrier", "traffic_cone", (42, 50)),
    ("rubble", "tire_pile", (94, 62)),
    ("tree", "dead_tree", (90, 110)),
    ("fuel", "barrel_empty", (54, 70)),
]


DISTRICT_OBSTACLE_POOLS: dict[str, list[tuple[str, str, tuple[int, int]]]] = {
    "north_market": [
        ("cart", "shopping_cart", (66, 54)),
        ("crate", "crate_stack", (90, 76)),
        ("sign", "bus_stop_sign", (48, 86)),
        ("barrier", "traffic_cone", (42, 50)),
        ("rubble", "dumpster_snow", (112, 76)),
    ],
    "east_medical": [
        ("vehicle", "frozen_car", (62, 58)),
        ("sign", "bus_stop_sign", (48, 86)),
        ("utility", "utility_box", (76, 68)),
        ("barrier", "sandbags", (108, 48)),
        ("light", "street_lamp", (42, 82)),
    ],
    "south_residential": [
        ("tree", "dead_tree", (92, 112)),
        ("snow", "snow_drift", (135, 78)),
        ("rubble", "tire_pile", (94, 62)),
        ("utility", "utility_box", (76, 68)),
        ("barrier", "barricade_wood", (104, 48)),
    ],
    "south_industrial": [
        ("fuel", "barrel_empty", (54, 70)),
        ("crate", "crate_stack", (96, 82)),
        ("rubble", "dumpster_snow", (124, 82)),
        ("barrier", "barricade_wood", (112, 50)),
        ("vehicle", "frozen_car", (64, 60)),
    ],
    "west_shelter": [
        ("barrier", "sandbags", (118, 52)),
        ("barrier", "barricade_wood", (112, 50)),
        ("fire", "barrel_fire", (56, 72)),
        ("sign", "bus_stop_sign", (48, 86)),
        ("crate", "crate_stack", (90, 76)),
    ],
    "central_transfer": [
        ("sign", "bus_stop_sign", (48, 86)),
        ("barrier", "traffic_cone", (42, 50)),
        ("cart", "shopping_cart", (66, 54)),
        ("light", "street_lamp", (42, 82)),
        ("rubble", "tire_pile", (94, 62)),
    ],
}


def obstacle_positions_for(district_key: str) -> list[tuple[int, int]]:
    if district_key == "central_transfer":
        return [(210, 335), (725, 335), (215, 625), (725, 625), (465, 115), (465, 825), (95, 500), (835, 500)]
    if district_key == "south_industrial":
        return [(245, 230), (715, 250), (250, 610), (700, 615), (105, 720), (820, 120), (525, 690), (430, 155)]
    if district_key == "south_residential":
        return [(120, 210), (355, 145), (735, 175), (525, 470), (210, 710), (815, 650), (625, 780), (330, 560)]
    if district_key == "west_shelter":
        return [(155, 330), (390, 315), (610, 285), (735, 515), (215, 665), (540, 690), (800, 660), (95, 525)]
    if district_key == "east_medical":
        return [(205, 300), (690, 320), (795, 520), (130, 690), (475, 705), (720, 115), (305, 120), (555, 450)]
    if district_key == "north_market":
        return [(120, 300), (300, 250), (725, 260), (620, 470), (210, 620), (780, 690), (465, 740), (845, 445)]
    return [(130, 410), (690, 150), (630, 420), (320, 300), (90, 300), (805, 620), (245, 735), (735, 745)]


def generate_obstacles(x: int, y: int, district_key: str) -> list[dict[str, Any]]:
    positions = obstacle_positions_for(district_key)
    pool = DISTRICT_OBSTACLE_POOLS.get(district_key, OBSTACLE_POOL)
    obstacles: list[dict[str, Any]] = []
    for index, (px, py) in enumerate(positions):
        kind, asset_id, size = pool[(x * 5 + y * 3 + index) % len(pool)]
        offset_x = ((x + index * 17) % 23) - 11
        offset_y = ((y + index * 19) % 27) - 13
        obstacles.append({
            "kind": kind,
            "asset_id": asset_id,
            "rect": rect(px + offset_x, py + offset_y, size[0], size[1]),
        })
    return obstacles


def generate_threat_spawns(x: int, y: int) -> list[dict[str, Any]]:
    if (x + y) % 3 != 0:
        return []
    return [
        {
            "id": f"pack_{x:02d}_{y:02d}_a",
            "position": point(140 + (x * 47) % 620, 140 + (y * 53) % 620),
            "forward": {"x": -1 if x % 2 == 0 else 1, "y": 0 if y % 2 == 0 else 1},
        }
    ]


def generate_block(x: int, y: int) -> dict[str, Any]:
    district = district_for(x, y)
    anchors: dict[str, dict[str, int]] = {}
    district_key = district["key"]
    anchor_positions = anchor_positions_for(x, y, district_key)
    for slot in range(generated_building_count_for(x, y, district_key)):
        anchors[building_anchor_id(x, y, slot)] = anchor_positions[slot]
    return {
        "block_coord": {"x": x, "y": y},
        "district_id": district_key,
        "district_label": district["label"],
        "layout_id": layout_id_for(x, y, district_key),
        "roads": generate_roads(x, y, district_key),
        "snow_fields": generate_snow_fields(x, y, district_key),
        "hazards": generate_hazards(x, y, district_key),
        "obstacles": generate_obstacles(x, y, district_key),
        "building_anchors": anchors,
        "threat_spawns": generate_threat_spawns(x, y),
        "landmarks": [
            {
                "id": f"{district_key}_{x:02d}_{y:02d}",
                "label": district["landmark"],
                "position": point(480, 470),
            }
        ],
    }


def scenario_hook_for(district_key: str, x: int, y: int, slot: int) -> str:
    hooks = SCENARIO_HOOKS.get(district_key, ["외곽 생존 루프"])
    return hooks[(x + y + slot) % len(hooks)]


def generate_building(x: int, y: int, slot: int) -> dict[str, Any]:
    district = district_for(x, y)
    theme = choose_theme(district, x, y, slot)
    template = choose_building_template(theme, x, y, slot)
    generated_id = building_id(x, y, slot)
    special = SPECIAL_BUILDING_OVERRIDES.get(generated_id, {})
    category = special.get("category", "industrial" if theme == "industrial" else theme)
    event_path = special.get("event_path", f"res://data/events/indoor/{template['event']}.json")
    special_tags = special.get("tags", [])
    return {
        "id": generated_id,
        "name": special.get("name", template["name"]),
        "category": category,
        "depth_tier": "tier_3",
        "site_tags": sorted(set(template["tags"] + special_tags + [district["key"], "map_expansion"])),
        "entry_briefing": special.get("brief", template["brief"]),
        "scenario_hook": special.get("scenario_hook", scenario_hook_for(district["key"], x, y, slot)),
        "base_candidate": False,
        "outdoor_block_coord": {"x": x, "y": y},
        "outdoor_anchor_id": building_anchor_id(x, y, slot),
        "indoor_event_path": event_path,
    }


def update_world_layout() -> None:
    layout = load_json(WORLD_LAYOUT_PATH)
    layout["city_blocks"] = {"width": CITY_WIDTH, "height": CITY_HEIGHT}
    write_json(WORLD_LAYOUT_PATH, layout)


def update_blocks() -> None:
    for y in range(CITY_HEIGHT):
        for x in range(CITY_WIDTH):
            if (x, y) in CORE_COORDS:
                continue
            write_json(BLOCKS_DIR / f"{x}_{y}.json", generate_block(x, y))


def update_buildings() -> None:
    buildings = load_json(BUILDINGS_PATH)
    preserved = [row for row in buildings if not str(row.get("id", "")).startswith(GENERATED_PREFIX)]
    generated: list[dict[str, Any]] = []
    for y in range(CITY_HEIGHT):
        for x in range(CITY_WIDTH):
            if (x, y) in CORE_COORDS:
                continue
            for slot in range(generated_building_count_for(x, y)):
                generated.append(generate_building(x, y, slot))
    write_json(BUILDINGS_PATH, preserved + generated)


def main() -> None:
    update_world_layout()
    update_blocks()
    update_buildings()
    generated_blocks = CITY_WIDTH * CITY_HEIGHT - len(CORE_COORDS)
    generated_buildings = sum(
        generated_building_count_for(x, y)
        for y in range(CITY_HEIGHT)
        for x in range(CITY_WIDTH)
        if (x, y) not in CORE_COORDS
    )
    print(f"expanded outdoor world to {CITY_WIDTH}x{CITY_HEIGHT}")
    print(f"generated/updated {generated_blocks} outer block files")
    print(f"generated {generated_buildings} building rows with prefix {GENERATED_PREFIX}")


if __name__ == "__main__":
    main()
