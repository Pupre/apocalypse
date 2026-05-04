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


BUILDING_TEMPLATES.update({
    "logistics": [
        {
            "name": "냉동 물류 허브",
            "event": "storage_depot_01",
            "category": "industrial",
            "tags": ["logistics", "bulk_stock", "cold_chain", "forklift_lane"],
            "brief": "대형 도크와 냉동 컨테이너가 늘어서 있다. 양은 많지만 옮기는 순간 무게와 소음이 문제가 된다.",
        },
        {
            "name": "택배 분류 센터",
            "event": "warehouse_01",
            "category": "industrial",
            "tags": ["logistics", "parcel", "records", "route_info"],
            "brief": "주소 라벨과 파손된 박스가 산처럼 쌓여 있다. 쓸모 있는 물건을 찾으려면 시간을 크게 써야 한다.",
        },
        {
            "name": "차량 정비 차고",
            "event": "garage_01",
            "category": "industrial",
            "tags": ["repair", "vehicle", "fuel", "industrial"],
            "brief": "리프트는 멈췄지만 공구와 폐연료 흔적이 남아 있다. 정비 지식이 있으면 훨씬 깊게 털 수 있다.",
        },
    ],
    "utility": [
        {
            "name": "열병합 발전소",
            "event": "warehouse_01",
            "category": "industrial",
            "tags": ["power_plant", "utility", "heat_trace", "locked_storage"],
            "brief": "검은 굴뚝과 얼어붙은 배관이 멀리서도 보인다. 온기와 전력의 흔적이 있지만 위험도 크다.",
        },
        {
            "name": "변전소 제어동",
            "event": "repair_shop_01",
            "category": "industrial",
            "tags": ["substation", "electronics", "utility", "locked_storage"],
            "brief": "차단기와 제어반이 늘어서 있다. 전기 부품은 귀하지만 잘못 건드리면 크게 다칠 수 있다.",
        },
        {
            "name": "취수 펌프장",
            "event": "storage_depot_01",
            "category": "industrial",
            "tags": ["waterworks", "pump", "industrial", "route_info"],
            "brief": "얼어붙은 배수로 너머로 펌프실이 보인다. 물과 기계 부품을 동시에 노릴 수 있는 장소다.",
        },
    ],
    "rural": [
        {
            "name": "눈 묻은 비닐하우스",
            "event": "storage_depot_01",
            "category": "residential",
            "tags": ["rural", "greenhouse", "food_source", "fragile_cover"],
            "brief": "비닐 지붕이 눈 무게에 내려앉아 있다. 생식 가능한 작물보다 보온재와 끈, 물통이 더 현실적인 수확물이다.",
        },
        {
            "name": "외곽 농가 창고",
            "event": "garage_01",
            "category": "residential",
            "tags": ["rural", "tools", "fuel", "household"],
            "brief": "집은 비었지만 창고 문은 반쯤 열려 있다. 농기구, 장갑, 오래된 연료통이 눈에 띈다.",
        },
        {
            "name": "폐교 급식실",
            "event": "canteen_01",
            "category": "food_service",
            "tags": ["rural", "school", "bulk_food", "shelter"],
            "brief": "운동장엔 눈이 쌓였고 급식실 출입문만 바람에 흔들린다. 식량보다 큰 조리 도구와 담요가 핵심일 수 있다.",
        },
    ],
    "checkpoint": [
        {
            "name": "국도 검문소",
            "event": "police_box_01",
            "category": "security",
            "tags": ["checkpoint", "roadblock", "records", "danger"],
            "brief": "차량 바리케이드와 버려진 기록지가 남아 있다. 길을 여는 정보가 있을 수 있지만 오래 머물 곳은 아니다.",
        },
        {
            "name": "고속도로 휴게소",
            "event": "convenience_01",
            "category": "retail",
            "tags": ["roadside", "vending", "fuel", "public_floor"],
            "brief": "매장은 거의 털렸지만 자판기, 화장실, 주방 뒤쪽은 아직 확인할 가치가 있다.",
        },
        {
            "name": "버려진 버스 차고",
            "event": "garage_01",
            "category": "industrial",
            "tags": ["roadside", "vehicle", "shelter", "route_info"],
            "brief": "차고 안쪽은 바람을 막아 주지만 시야가 어둡다. 이동 경로와 부품을 동시에 찾을 수 있다.",
        },
    ],
})


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


SCENARIO_HOOKS.update({
    "logistics_belt": [
        "대형 물류창고에서 많은 물건을 발견하지만, 무엇을 포기하고 무엇을 들고 나갈지 결정하는 적재 루프",
        "택배 송장과 배송 지도를 뒤져 다음 목적지 단서를 얻는 경로 개척 루프",
    ],
    "power_plant": [
        "발전소 제어동의 잔열과 위험한 전기 설비 사이에서 온기와 부품을 동시에 노리는 고위험 루프",
        "얼어붙은 배관과 변전 설비를 우회해 전력 단서를 확보하는 장기 목표 루프",
    ],
    "rural_greenbelt": [
        "비닐하우스와 농가 창고에서 식량보다 생활 재료와 보온재를 찾아내는 외곽 생존 루프",
        "도시에서 멀어질수록 상점은 줄지만 물, 연료통, 끈, 농기구 같은 현실적인 자원이 살아나는 탐험 루프",
    ],
    "highway_checkpoint": [
        "국도 검문소와 휴게소 사이에서 통제선 기록, 차량 부품, 남은 자판기 재고를 고르는 이동 루프",
        "큰길은 빠르지만 노출이 심하고, 우회로는 느리지만 다음 지형 정보를 주는 경로 선택 루프",
    ],
    "outer_residential": [
        "도심 아파트와 달리 낮은 주택, 작은 창고, 마당 흔적을 뒤져 생활 재료를 찾아내는 외곽 주거 루프",
        "누군가 급히 떠난 집에서 사적인 흔적과 실용적인 물건 사이의 무게를 고르는 루프",
    ],
    "civic_medical": [
        "응급 진료소와 관공서 기록 사이에서 약, 열쇠, 지역 정보를 고르는 공공 지구 루프",
        "잠긴 보관함과 안내 데스크를 두고 시간과 안전을 저울질하는 의료·관공 루프",
    ],
})


SPECIAL_BUILDING_OVERRIDES.update({
    "mapx_07_08_a": {
        "name": "백색 물류 허브",
        "category": "industrial",
        "event_path": "res://data/events/indoor/mapx_logistics_cold_chain_hub_01.json",
        "tags": ["logistics", "bulk_stock", "cold_chain", "big_decision"],
        "brief": "도크마다 냉동 컨테이너가 멈춰 있다. 많은 물건이 보이지만 한 번에 들고 갈 수 있는 양은 잔인하게 적다.",
        "scenario_hook": "팔레트 단위 보급품 앞에서 무게, 시간, 소음을 계산해 정말 가져갈 것을 고르는 물류 허브 루프",
    },
    "mapx_10_10_a": {
        "name": "열병합 발전소 제어동",
        "category": "industrial",
        "event_path": "res://data/events/indoor/mapx_power_plant_control_01.json",
        "tags": ["power_plant", "utility", "heat_trace", "big_decision"],
        "brief": "멀리서도 굴뚝과 송전탑이 보인다. 살아 있는 온기의 흔적이 있지만 잘못 들어가면 빠져나오기 어렵다.",
        "scenario_hook": "잔열이 남은 제어동에서 온기, 전기 부품, 감전 위험 사이의 큰 결정을 내리는 발전소 루프",
    },
    "mapx_03_11_a": {
        "name": "눈 묻은 비닐하우스",
        "category": "residential",
        "event_path": "res://data/events/indoor/mapx_rural_greenhouse_01.json",
        "tags": ["rural", "greenhouse", "food_source", "big_decision"],
        "brief": "도시 소음이 멀어지고 비닐하우스 뼈대만 눈 속에 남아 있다. 식량보다 재료와 보온재가 먼저 보인다.",
        "scenario_hook": "무너지는 비닐하우스에서 작물, 물통, 비닐 보온재 중 무엇을 챙길지 고르는 농촌 탐험 루프",
    },
    "mapx_09_05_a": {
        "name": "국도 검문소",
        "category": "security",
        "event_path": "res://data/events/indoor/mapx_highway_checkpoint_01.json",
        "tags": ["checkpoint", "roadblock", "route_info", "big_decision"],
        "brief": "바리케이드와 버려진 차량이 국도를 막고 있다. 통제 기록을 얻으면 다음 지역의 위험을 먼저 알 수 있다.",
        "scenario_hook": "검문 기록을 뒤져 안전한 우회로를 열지, 빠른 큰길을 밀고 갈지 결정하는 국도 루프",
    },
})


SPECIAL_BUILDING_OVERRIDES.update({
    "mapx_09_01_b": {
        "name": "응급 분류 진료소",
        "category": "medical",
        "event_path": "res://data/events/indoor/mapx_civic_triage_clinic_01.json",
        "tags": ["civic_medical", "medical", "hygiene", "big_decision"],
        "brief": "관공서 로비를 임시 진료소로 바꾼 흔적이 남아 있다. 약품보다 분류와 윤리적 선택이 더 중요해 보인다.",
        "scenario_hook": "쓸 수 있는 약품과 남겨야 할 물자를 구분하며 내 생존과 공동체 흔적 사이를 재는 의료·관공 루프",
    },
    "mapx_00_05_a": {
        "name": "임시 대피 등록소",
        "category": "security",
        "event_path": "res://data/events/indoor/mapx_west_shelter_registration_01.json",
        "tags": ["west_shelter", "shelter", "community", "big_decision"],
        "brief": "접수 책상과 보급 상자가 남은 대피 등록소다. 물자를 챙길수록 누군가의 흔적을 밟고 지나가는 느낌이 강해진다.",
        "scenario_hook": "공동 보급품을 바로 가져갈지, 시간을 들여 기록을 정리하고 다음 생존자의 길을 남길지 고르는 대피선 루프",
    },
    "mapx_02_09_b": {
        "name": "차고 딸린 연립 주택",
        "category": "residential",
        "event_path": "res://data/events/indoor/mapx_outer_row_house_garage_01.json",
        "tags": ["outer_residential", "garage", "household", "big_decision"],
        "brief": "낮은 주택가의 차고 안에 가족 비상 상자와 생활 공구가 남아 있다. 당장 가져갈 것과 운반 방식을 함께 판단해야 한다.",
        "scenario_hook": "가정용 물자와 손짐 보조 장치를 조합해 다음 이동의 짐 문제를 푸는 외곽 주거 루프",
    },
})


SPECIAL_BUILDING_OVERRIDES.update({
    "mapx_08_04_a": {
        "name": "눈보라 휴게소 자판기 코너",
        "category": "retail",
        "event_path": "res://data/events/indoor/mapx_highway_rest_stop_vending_01.json",
        "tags": ["highway_checkpoint", "roadside", "vending", "food_source", "big_decision"],
        "brief": "자동문 틈으로 눈발이 밀려드는 휴게소다. 자판기와 간식 매대가 남아 있지만 소리를 어떻게 다룰지가 핵심이다.",
        "scenario_hook": "유리를 깨고 빠르게 챙길지, 시간을 써서 조용히 열지 결정하는 국도 휴게소 루프",
    },
    "mapx_06_07_b": {
        "name": "동결된 택배 분류 센터",
        "category": "industrial",
        "event_path": "res://data/events/indoor/mapx_parcel_sorting_center_01.json",
        "tags": ["logistics_belt", "logistics", "route_info", "parcel", "big_decision"],
        "brief": "멈춘 컨베이어와 배송 철망이 남은 분류 센터다. 상자를 뜯는 것보다 어느 방향의 물자를 읽을지가 더 큰 선택이다.",
        "scenario_hook": "무작위 상자 파밍과 배송 동선 해석 사이에서 다음 목적지의 기대값을 고르는 물류 루프",
    },
    "mapx_05_11_a": {
        "name": "외곽 농가 창고",
        "category": "residential",
        "event_path": "res://data/events/indoor/mapx_rural_farm_storage_01.json",
        "tags": ["rural_greenbelt", "rural", "food_source", "fuel", "big_decision"],
        "brief": "쌀 포대와 연료통, 농기구가 남은 창고다. 오래 버틸 무거운 식량과 길 위에서 쓸 가벼운 도구를 함께 저울질하게 된다.",
        "scenario_hook": "무게가 큰 식량과 이동에 필요한 도구·연료 사이의 절충을 고르는 농가 창고 루프",
    },
    "mapx_09_07_b": {
        "name": "변전소 제어동",
        "category": "industrial",
        "event_path": "res://data/events/indoor/mapx_substation_control_01.json",
        "tags": ["power_plant", "substation", "electricity", "risk", "big_decision"],
        "brief": "송전탑 아래 작은 제어동이다. 배터리와 차단기, 바람길 정보가 있지만 전기와 금속 소음이 위험을 만든다.",
        "scenario_hook": "절연 도구로 차단기를 다뤄 안전한 바람길을 읽을지, 빠르게 배터리만 뽑고 나올지 고르는 변전소 루프",
    },
    "mapx_03_07_c": {
        "name": "폐교 급식실",
        "category": "food_service",
        "event_path": "res://data/events/indoor/mapx_school_cafeteria_01.json",
        "tags": ["rural_greenbelt", "school", "food_source", "weight_decision", "big_decision"],
        "brief": "눈에 묻힌 폐교 급식실이다. 쌀과 통조림은 매력적이지만, 많이 챙길수록 다음 이동이 위험해진다.",
        "scenario_hook": "무거운 쌀 포대와 실제 이동 가능한 식량 꾸러미 사이에서 생존 시간을 계산하는 폐교 급식 루프",
    },
    "mapx_10_06_a": {
        "name": "버려진 버스 차고",
        "category": "industrial",
        "event_path": "res://data/events/indoor/mapx_bus_depot_garage_01.json",
        "tags": ["highway_checkpoint", "bus_depot", "route_info", "fuel", "big_decision"],
        "brief": "국도 옆 버스 차고다. 연료, 우회 노선도, 시트 보온재가 한 공간에 있지만 무엇부터 얻을지 정해야 한다.",
        "scenario_hook": "연료와 길 정보, 보온 재료 사이에서 현재 생존과 다음 목적지의 기대값을 저울질하는 버스 차고 루프",
    },
    "mapx_08_02_a": {
        "name": "보건소 냉장 약품실",
        "category": "medical",
        "event_path": "res://data/events/indoor/mapx_public_health_cold_room_01.json",
        "tags": ["civic_medical", "medical", "cold_chain", "hygiene", "big_decision"],
        "brief": "보건소 뒤편 냉장 약품실이다. 가치 있는 약품을 살릴지, 확실한 기본 처치품만 챙길지 판단해야 한다.",
        "scenario_hook": "보냉 운반 조건과 즉시 쓸 수 있는 처치품 사이에서 의료 물자의 현실성을 따지는 보건소 루프",
    },
    "mapx_01_05_c": {
        "name": "대피선 급수 초소",
        "category": "security",
        "event_path": "res://data/events/indoor/mapx_shelter_water_checkpoint_01.json",
        "tags": ["west_shelter", "shelter", "water_source", "community", "big_decision"],
        "brief": "서쪽 대피선 급수 초소다. 당장 마실 물과 여과 장치, 다음 생존자의 몫 사이를 고르게 된다.",
        "scenario_hook": "깨끗한 물을 모두 챙길지, 여과 장치를 살리고 공동 몫을 남길지 고르는 대피선 급수 루프",
    },
    "mapx_07_07_a": {
        "name": "지게차 정비고",
        "category": "industrial",
        "event_path": "res://data/events/indoor/mapx_logistics_forklift_workshop_01.json",
        "tags": ["logistics_belt", "logistics", "carry_solution", "tools", "big_decision"],
        "brief": "죽은 지게차와 팔레트가 남은 정비고다. 공구를 바로 챙길지, 시간을 들여 운반 보조 장치를 만들지 선택한다.",
        "scenario_hook": "발견한 물자를 실제로 들고 나가는 문제를 공구와 팔레트로 해결하는 물류 정비고 루프",
    },
})


WORLD_REGION_RULES: list[dict[str, Any]] = [
    {
        "key": "north_market",
        "label": "북부 시장가",
        "condition": lambda x, y: y <= 2 and 3 <= x <= 6,
        "landmark": "얼어붙은 시장 아케이드",
        "themes": ["retail", "food_service", "office"],
    },
    {
        "key": "civic_medical",
        "label": "동부 의료·관공 지구",
        "condition": lambda x, y: x >= 7 and y <= 3,
        "landmark": "응급 진료소와 관공서 거리",
        "themes": ["medical", "office", "retail"],
    },
    {
        "key": "central_transfer",
        "label": "중앙 환승로",
        "condition": lambda x, y: 3 <= x <= 6 and 3 <= y <= 6,
        "landmark": "멈춰 선 환승 교차로",
        "themes": ["retail", "food_service", "industrial", "office"],
    },
    {
        "key": "highway_checkpoint",
        "label": "국도 검문·휴게 구역",
        "condition": lambda x, y: x >= 7 and 4 <= y <= 6,
        "landmark": "막힌 국도와 휴게소 불빛",
        "themes": ["checkpoint", "retail", "food_service", "industrial"],
    },
    {
        "key": "west_shelter",
        "label": "서부 대피선",
        "condition": lambda x, y: x <= 2 and 3 <= y <= 6,
        "landmark": "무너진 임시 대피선",
        "themes": ["residential", "security", "food_service"],
    },
    {
        "key": "outer_residential",
        "label": "남서 외곽 주거지",
        "condition": lambda x, y: x <= 4 and 7 <= y <= 9,
        "landmark": "낮은 주택과 골목 창고",
        "themes": ["residential", "rural", "retail"],
    },
    {
        "key": "rural_greenbelt",
        "label": "남서 농촌·비닐하우스",
        "condition": lambda x, y: x <= 5 and y >= 10,
        "landmark": "눈 묻은 비닐하우스 단지",
        "themes": ["rural", "food_service", "residential"],
    },
    {
        "key": "logistics_belt",
        "label": "남부 물류 벨트",
        "condition": lambda x, y: 5 <= x <= 8 and y >= 7,
        "landmark": "멈춰 선 냉동 물류창고",
        "themes": ["logistics", "industrial", "retail"],
    },
    {
        "key": "power_plant",
        "label": "동남 발전소 지대",
        "condition": lambda x, y: x >= 9 and y >= 7,
        "landmark": "열병합 발전소와 변전소",
        "themes": ["utility", "industrial", "logistics"],
    },
]


def district_for(x: int, y: int) -> dict[str, Any]:
    for district in WORLD_REGION_RULES:
        if district["condition"](x, y):
            return district
    return {
        "key": "mixed_edge",
        "label": "끊어진 외곽 혼합지",
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
        "civic_medical": ["medical_campus", "clinic_drive", "civic_records_court"],
        "east_medical": ["medical_campus", "clinic_drive", "pharmacy_court"],
        "outer_residential": ["outer_row_houses", "garage_courtyard", "frozen_backstreet"],
        "south_residential": ["residential_courtyard", "row_house_lane", "frozen_backstreet"],
        "logistics_belt": ["freight_yard", "cold_chain_depot", "parcel_sorter"],
        "power_plant": ["power_substation", "cooling_yard", "service_pipeway"],
        "rural_greenbelt": ["greenhouse_lane", "farmstead_track", "frozen_field_road"],
        "highway_checkpoint": ["highway_roadblock", "rest_stop_loop", "bus_depot_turnoff"],
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
            [point(245, 675), point(680, 210), point(790, 560)],
            [point(150, 320), point(520, 500), point(720, 745)],
        ],
        "east_medical": [
            [point(265, 250), point(690, 575)],
            [point(700, 255), point(245, 690)],
            [point(215, 650), point(710, 255)],
            [point(565, 445), point(285, 260)],
        ],
        "civic_medical": [
            [point(260, 250), point(700, 585)],
            [point(705, 255), point(245, 685)],
            [point(520, 430), point(250, 250), point(735, 705)],
            [point(210, 670), point(705, 250)],
        ],
        "outer_residential": [
            [point(215, 260), point(610, 695), point(795, 420)],
            [point(685, 250), point(235, 670), point(470, 770)],
            [point(285, 320), point(690, 620)],
            [point(160, 705), point(585, 250), point(790, 705)],
        ],
        "south_residential": [
            [point(215, 265), point(620, 705), point(795, 420)],
            [point(690, 255), point(230, 655), point(455, 760)],
            [point(210, 650), point(650, 250), point(780, 710)],
            [point(315, 305), point(560, 680), point(755, 335)],
        ],
        "logistics_belt": [
            [point(250, 285), point(705, 650)],
            [point(720, 290), point(300, 675)],
            [point(475, 235), point(760, 700), point(220, 720)],
            [point(650, 440), point(260, 270)],
        ],
        "power_plant": [
            [point(690, 260), point(280, 700)],
            [point(300, 300), point(720, 690)],
            [point(520, 470)],
            [point(745, 380), point(265, 600)],
        ],
        "rural_greenbelt": [
            [point(260, 275), point(690, 690)],
            [point(700, 250), point(250, 715)],
            [point(470, 365), point(735, 745)],
            [point(215, 640), point(620, 245)],
        ],
        "highway_checkpoint": [
            [point(220, 275), point(710, 660)],
            [point(720, 260), point(240, 690), point(500, 480)],
            [point(520, 235), point(760, 705)],
            [point(270, 680), point(720, 390)],
        ],
        "south_industrial": [
            [point(735, 300), point(260, 690)],
            [point(245, 315), point(720, 695)],
            [point(690, 215), point(310, 575)],
            [point(430, 705), point(760, 420)],
        ],
        "west_shelter": [
            [point(205, 250), point(710, 655), point(430, 450)],
            [point(700, 260), point(215, 700), point(520, 580)],
            [point(245, 690), point(620, 280), point(760, 650)],
            [point(465, 300), point(220, 570), point(700, 735)],
        ],
        "central_transfer": [
            [point(250, 245), point(725, 265), point(500, 710)],
            [point(720, 700), point(230, 690), point(500, 235)],
            [point(210, 455), point(735, 720), point(610, 210)],
            [point(520, 675), point(235, 235), point(755, 435)],
        ],
        "mixed_edge": [
            [point(190, 240), point(710, 695)],
            [point(730, 250), point(210, 705)],
            [point(210, 690), point(735, 250)],
            [point(700, 690), point(225, 245)],
        ],
    }
    variants = variants_by_district.get(district_key, variants_by_district["mixed_edge"])
    positions = list(variants[(x + y * 2) % len(variants)])
    while len(positions) < 3:
        fallback_points = [point(245, 255), point(700, 690), point(500, 470)]
        positions.append(fallback_points[len(positions)])
    return positions


def generated_building_count_for(x: int, y: int, district_key: str | None = None) -> int:
    if district_key is None:
        district_key = district_for(x, y)["key"]
    if district_key == "power_plant":
        return 2 if (x + y) % 4 == 0 else 1
    if district_key == "rural_greenbelt":
        return 2 if (x + y) % 2 == 0 else 1
    if district_key in ["logistics_belt", "highway_checkpoint", "outer_residential"]:
        return 3 if (x + y) % 5 == 0 else 2
    if district_key == "civic_medical":
        return 2 if (x * 3 + y * 5) % 3 != 1 else 1
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


def generate_roads(x: int, y: int, district_key: str, layout_id: str) -> list[dict[str, Any]]:
    vertical_x = 300 + ((x * 37 + y * 17) % 4) * 75
    horizontal_y = 280 + ((x * 19 + y * 31) % 4) * 80
    if district_key == "civic_medical":
        if layout_id == "civic_records_court":
            return [
                {"id": "records_court", "texture_id": "sidewalk_snow", "rect": rect(210, 260, 520, 320)},
                {"id": "civic_frontage", "texture_id": "road_plain", "rect": rect(0, 640, BLOCK_SIZE, 135)},
                {"id": "service_archive_lane", "texture_id": "alley_dark", "rect": rect(125, 0, 115, 720)},
                {"id": "ambulance_lane", "texture_id": "slush_road", "rect": rect(690, 0, 130, BLOCK_SIZE)},
            ]
        if layout_id == "clinic_drive":
            return [
                {"id": "clinic_drive", "texture_id": "road_plain", "rect": rect(95, 175, 720, 145)},
                {"id": "ambulance_turnaround", "texture_id": "slush_road", "rect": rect(565, 320, 260, 260)},
                {"id": "records_walk", "texture_id": "sidewalk_snow", "rect": rect(195, 595, 540, 95)},
                {"id": "service_dropoff", "texture_id": "road_cracked", "rect": rect(85, 690, 675, 118)},
            ]
        return [
            {"id": "medical_campus_drive", "texture_id": "road_plain", "rect": rect(165, 105, 630, 150)},
            {"id": "ambulance_lane", "texture_id": road_texture(x + y + 1, True), "rect": rect(660, 0, 145, BLOCK_SIZE)},
            {"id": "civic_records_court", "texture_id": "sidewalk_snow", "rect": rect(225, 395, 470, 280)},
            {"id": "public_service_dropoff", "texture_id": "slush_road", "rect": rect(85, 665, 650, 120)},
        ]
    if district_key == "logistics_belt":
        if layout_id == "cold_chain_depot":
            return [
                {"id": "cold_chain_dock", "texture_id": "road_plain", "rect": rect(120, 225, 720, 250)},
                {"id": "reefer_lane", "texture_id": "slush_road", "rect": rect(0, 640, BLOCK_SIZE, 150)},
                {"id": "forklift_cut", "texture_id": "road_cracked", "rect": rect(620, 120, 145, 700)},
                {"id": "service_walk", "texture_id": "sidewalk_snow", "rect": rect(180, 520, 470, 95)},
            ]
        if layout_id == "parcel_sorter":
            return [
                {"id": "parcel_sorter_floor", "texture_id": "road_plain", "rect": rect(210, 180, 520, 390)},
                {"id": "truck_queue_lane", "texture_id": "slush_road", "rect": rect(0, 690, BLOCK_SIZE, 135)},
                {"id": "service_spur", "texture_id": "road_cracked", "rect": rect(95, 120, 125, 640)},
                {"id": "staff_walkway", "texture_id": "sidewalk_snow", "rect": rect(430, 585, 390, 90)},
            ]
        return [
            {"id": "freight_yard", "texture_id": "road_plain", "rect": rect(150, 205, 650, 430)},
            {"id": "loading_spur", "texture_id": "slush_road", "rect": rect(0, 645, BLOCK_SIZE, 150)},
            {"id": "dock_access", "texture_id": "road_cracked", "rect": rect(690, 0, 135, BLOCK_SIZE)},
            {"id": "side_service_cut", "texture_id": "alley_dark", "rect": rect(95, 120, 120, 690)},
        ]
    if district_key == "power_plant":
        if layout_id == "cooling_yard":
            return [
                {"id": "cooling_yard", "texture_id": "road_plain", "rect": rect(210, 180, 540, 430)},
                {"id": "pipe_service_road", "texture_id": "road_cracked", "rect": rect(660, 0, 150, BLOCK_SIZE)},
                {"id": "ash_service_lane", "texture_id": "slush_road", "rect": rect(0, 705, BLOCK_SIZE, 135)},
                {"id": "control_walk", "texture_id": "sidewalk_snow", "rect": rect(255, 620, 320, 85)},
            ]
        if layout_id == "service_pipeway":
            return [
                {"id": "pipeway_vertical", "texture_id": "alley_dark", "rect": rect(420, 0, 120, BLOCK_SIZE)},
                {"id": "transformer_apron", "texture_id": "road_cracked", "rect": rect(560, 205, 300, 285)},
                {"id": "maintenance_lane", "texture_id": "road_plain", "rect": rect(0, 610, 760, 130)},
                {"id": "snowed_control_walk", "texture_id": "sidewalk_snow", "rect": rect(135, 245, 300, 90)},
            ]
        return [
            {"id": "substation_yard", "texture_id": "road_cracked", "rect": rect(185, 185, 580, 410)},
            {"id": "service_pipeway", "texture_id": "alley_dark", "rect": rect(690, 0, 130, BLOCK_SIZE)},
            {"id": "plant_access_road", "texture_id": "slush_road", "rect": rect(0, 665, BLOCK_SIZE, 150)},
            {"id": "control_apron", "texture_id": "sidewalk_snow", "rect": rect(250, 95, 340, 100)},
        ]
    if district_key == "rural_greenbelt":
        if layout_id == "farmstead_track":
            return [
                {"id": "farmstead_track", "texture_id": "road_cracked", "rect": rect(90, 575, 780, 120)},
                {"id": "barn_access", "texture_id": "slush_road", "rect": rect(190, 190, 120, 500)},
                {"id": "greenhouse_walk", "texture_id": "sidewalk_snow", "rect": rect(480, 245, 320, 85)},
                {"id": "field_pullout", "texture_id": "road_plain", "rect": rect(610, 700, 240, 105)},
            ]
        if layout_id == "frozen_field_road":
            return [
                {"id": "frozen_field_road", "texture_id": "road_cracked", "rect": rect(0, 690, BLOCK_SIZE, 115)},
                {"id": "irrigation_track", "texture_id": "alley_dark", "rect": rect(430, 0, 110, 780)},
                {"id": "vinyl_house_walk", "texture_id": "sidewalk_snow", "rect": rect(135, 265, 650, 90)},
                {"id": "tractor_turnout", "texture_id": "slush_road", "rect": rect(620, 415, 225, 130)},
            ]
        return [
            {"id": "greenhouse_lane", "texture_id": "sidewalk_snow", "rect": rect(145, 250, 670, 95)},
            {"id": "snowed_farm_track", "texture_id": "road_cracked", "rect": rect(0, 650, BLOCK_SIZE, 125)},
            {"id": "irrigation_cut", "texture_id": "alley_dark", "rect": rect(310, 0, 105, 720)},
            {"id": "farmyard_pullout", "texture_id": "road_plain", "rect": rect(585, 475, 260, 140)},
        ]
    if district_key == "highway_checkpoint":
        if layout_id == "rest_stop_loop":
            return [
                {"id": "highway_main", "texture_id": "road_lane_h", "rect": rect(0, 390, BLOCK_SIZE, 175)},
                {"id": "rest_stop_loop", "texture_id": "road_plain", "rect": rect(520, 165, 320, 430)},
                {"id": "service_parking", "texture_id": "road_cracked", "rect": rect(120, 610, 420, 135)},
                {"id": "bathroom_walk", "texture_id": "sidewalk_snow", "rect": rect(580, 610, 260, 90)},
            ]
        if layout_id == "bus_depot_turnoff":
            return [
                {"id": "highway_main", "texture_id": "road_lane_h", "rect": rect(0, 365, BLOCK_SIZE, 165)},
                {"id": "bus_depot_turnoff", "texture_id": "slush_road", "rect": rect(210, 530, 560, 135)},
                {"id": "depot_yard", "texture_id": "road_plain", "rect": rect(520, 665, 330, 175)},
                {"id": "checkpoint_walk", "texture_id": "sidewalk_snow", "rect": rect(105, 255, 360, 90)},
            ]
        return [
            {"id": "highway_roadblock", "texture_id": "road_lane_h", "rect": rect(0, 405, BLOCK_SIZE, 175)},
            {"id": "checkpoint_chicane", "texture_id": "road_plain", "rect": rect(165, 245, 520, 120)},
            {"id": "blocked_shoulder", "texture_id": "road_cracked", "rect": rect(0, 595, 720, 120)},
            {"id": "inspection_walk", "texture_id": "sidewalk_snow", "rect": rect(620, 245, 220, 95)},
        ]
    if district_key == "outer_residential":
        if layout_id == "garage_courtyard":
            return [
                {"id": "garage_courtyard", "texture_id": "road_plain", "rect": rect(260, 260, 430, 260)},
                {"id": "outer_home_lane", "texture_id": "road_cracked", "rect": rect(0, 640, BLOCK_SIZE, 125)},
                {"id": "side_garage_cut", "texture_id": "alley_dark", "rect": rect(150, 190, 115, 560)},
                {"id": "yard_walk", "texture_id": "sidewalk_snow", "rect": rect(600, 520, 260, 90)},
            ]
        if layout_id == "outer_row_houses":
            return [
                {"id": "outer_row_house_lane", "texture_id": "alley_dark", "rect": rect(90, 220, 760, 110)},
                {"id": "back_lane", "texture_id": "road_cracked", "rect": rect(0, 625, BLOCK_SIZE, 120)},
                {"id": "shared_yard_walk", "texture_id": "sidewalk_snow", "rect": rect(250, 410, 460, 95)},
                {"id": "frozen_driveway", "texture_id": "slush_road", "rect": rect(700, 320, 115, 360)},
            ]
        return [
            {"id": "outer_frozen_backstreet", "texture_id": "alley_dark", "rect": rect(0, 620, BLOCK_SIZE, 125)},
            {"id": "crooked_driveway_cut", "texture_id": "slush_road", "rect": rect(245, 250, 135, 500)},
            {"id": "yard_walk", "texture_id": "sidewalk_snow", "rect": rect(475, 150, 310, 250)},
            {"id": "garage_dead_end", "texture_id": "road_plain", "rect": rect(610, 420, 240, 115)},
        ]
    if district_key == "north_market":
        if layout_id == "market_back_alley":
            alley_x = 130 + ((x + y) % 3) * 90
            return [
                {"id": "market_back_alley", "texture_id": "alley_dark", "rect": rect(alley_x, 0, 105, BLOCK_SIZE)},
                {"id": "market_delivery_lane", "texture_id": "road_plain", "rect": rect(0, 565 + (x % 2) * 55, BLOCK_SIZE, 135)},
                {"id": "market_side_passage", "texture_id": "sidewalk_snow", "rect": rect(325, 155, 425, 90)},
                {"id": "market_loading_cut", "texture_id": "slush_road", "rect": rect(630, 225, 145, 505)},
            ]
        if layout_id == "market_plaza":
            plaza_x = 255 + ((x * 11 + y) % 3) * 45
            return [
                {"id": "market_plaza_west", "texture_id": "sidewalk_snow", "rect": rect(plaza_x, 195, 360, 285)},
                {"id": "market_plaza_south", "texture_id": "road_plain", "rect": rect(0, 650, BLOCK_SIZE, 150)},
                {"id": "market_shopfront_lane", "texture_id": road_texture(x + y, False), "rect": rect(0, 285 + (y % 2) * 35, BLOCK_SIZE, 130)},
                {"id": "arcade_service_cut", "texture_id": "alley_dark", "rect": rect(105, 420, 120, 390)},
            ]
        return [
            {"id": "market_main_street", "texture_id": road_texture(x + y, False), "rect": rect(0, 285 + (y % 2) * 35, BLOCK_SIZE, 165)},
            {"id": "market_back_alley", "texture_id": "alley_dark", "rect": rect(120 + (x % 2) * 60, 0, 105, BLOCK_SIZE)},
            {"id": "arcade_walk", "texture_id": "sidewalk_snow", "rect": rect(0, 170, BLOCK_SIZE, 78)},
            {"id": "delivery_cut", "texture_id": "road_plain", "rect": rect(620, 455, 150, 360)},
        ]
    if district_key == "east_medical":
        if layout_id == "clinic_drive":
            return [
                {"id": "clinic_drive", "texture_id": "road_plain", "rect": rect(95, 175, 720, 145)},
                {"id": "ambulance_turnaround", "texture_id": "slush_road", "rect": rect(565, 320, 260, 260)},
                {"id": "records_walk", "texture_id": "sidewalk_snow", "rect": rect(195, 595, 540, 95)},
                {"id": "service_dropoff", "texture_id": "road_cracked", "rect": rect(85, 690, 675, 118)},
            ]
        if layout_id == "pharmacy_court":
            return [
                {"id": "pharmacy_court", "texture_id": "sidewalk_snow", "rect": rect(210, 270, 520, 330)},
                {"id": "pharmacy_curb", "texture_id": road_texture(x + y, False), "rect": rect(0, 650, BLOCK_SIZE, 135)},
                {"id": "clinic_service_lane", "texture_id": "alley_dark", "rect": rect(130, 0, 115, 720)},
                {"id": "ambulance_lane", "texture_id": "slush_road", "rect": rect(690, 0, 130, BLOCK_SIZE)},
            ]
        return [
            {"id": "clinic_drive", "texture_id": "road_plain", "rect": rect(165, 105, 630, 150)},
            {"id": "ambulance_lane", "texture_id": road_texture(x + y + 1, True), "rect": rect(660, 0, 145, BLOCK_SIZE)},
            {"id": "pharmacy_court", "texture_id": "sidewalk_snow", "rect": rect(225, 395, 470, 280)},
            {"id": "service_dropoff", "texture_id": "slush_road", "rect": rect(85, 665, 650, 120)},
        ]
    if district_key == "south_residential":
        if layout_id == "row_house_lane":
            return [
                {"id": "row_house_lane", "texture_id": "alley_dark", "rect": rect(90, 205, 780, 108)},
                {"id": "back_yard_passage", "texture_id": "sidewalk_snow", "rect": rect(165, 520, 610, 100)},
                {"id": "narrow_stair_cut", "texture_id": "alley_dark", "rect": rect(435, 0, 105, BLOCK_SIZE)},
                {"id": "dead_end_snow_road", "texture_id": "road_cracked", "rect": rect(610, 620, 125, 265)},
            ]
        if layout_id == "frozen_backstreet":
            return [
                {"id": "frozen_backstreet", "texture_id": "alley_dark", "rect": rect(0, 620, BLOCK_SIZE, 125)},
                {"id": "crooked_residential_cut", "texture_id": "slush_road", "rect": rect(245, 250, 135, 500)},
                {"id": "courtyard_walk", "texture_id": "sidewalk_snow", "rect": rect(475, 150, 310, 250)},
                {"id": "service_dead_end", "texture_id": "road_plain", "rect": rect(610, 420, 240, 115)},
            ]
        return [
            {"id": "residential_lane_a", "texture_id": "alley_dark", "rect": rect(155, 0, 118, 575)},
            {"id": "residential_lane_b", "texture_id": "alley_dark", "rect": rect(155, 485, 610, 118)},
            {"id": "courtyard_walk", "texture_id": "sidewalk_snow", "rect": rect(520, 170, 250, 250)},
            {"id": "dead_end_snow_road", "texture_id": "road_cracked", "rect": rect(610, 585, 128, 300)},
        ]
    if district_key == "south_industrial":
        if layout_id == "fuel_service_lot":
            return [
                {"id": "loading_yard", "texture_id": "road_plain", "rect": rect(160, 195, 520, 345)},
                {"id": "fuel_service_lot", "texture_id": "road_cracked", "rect": rect(560, 95, 300, 270)},
                {"id": "tanker_spur", "texture_id": "slush_road", "rect": rect(0, 650, BLOCK_SIZE, 145)},
                {"id": "service_lane", "texture_id": "alley_dark", "rect": rect(90, 75, 125, 760)},
            ]
        if layout_id == "warehouse_spur":
            return [
                {"id": "loading_yard", "texture_id": "road_plain", "rect": rect(180, 245, 640, 290)},
                {"id": "warehouse_spur", "texture_id": "slush_road", "rect": rect(0, 300, 520, 135)},
                {"id": "dock_access", "texture_id": "road_cracked", "rect": rect(685, 0, 140, BLOCK_SIZE)},
                {"id": "yard_pullout", "texture_id": "sidewalk_snow", "rect": rect(255, 625, 410, 115)},
            ]
        return [
            {"id": "loading_yard", "texture_id": "road_plain", "rect": rect(145, 175, 650, 475)},
            {"id": "warehouse_spur", "texture_id": "slush_road", "rect": rect(0, 660, BLOCK_SIZE, 150)},
            {"id": "service_lane", "texture_id": "alley_dark", "rect": rect(70, 75, 130, 765)},
            {"id": "fuel_apron", "texture_id": "road_cracked", "rect": rect(615, 55, 235, 170)},
        ]
    if district_key == "west_shelter":
        if layout_id == "relief_lane":
            return [
                {"id": "relief_route", "texture_id": road_texture(x + y, False), "rect": rect(0, 310, BLOCK_SIZE, 138)},
                {"id": "supply_queue_lane", "texture_id": "sidewalk_snow", "rect": rect(135, 500, 620, 95)},
                {"id": "checkpoint_cut", "texture_id": "road_plain", "rect": rect(570, 120, 125, 710)},
                {"id": "chapel_walk", "texture_id": "sidewalk_snow", "rect": rect(95, 675, 330, 140)},
            ]
        if layout_id == "barricaded_square":
            return [
                {"id": "barricaded_square", "texture_id": "road_plain", "rect": rect(275, 255, 390, 335)},
                {"id": "relief_route", "texture_id": road_texture(x + y, False), "rect": rect(0, 650, BLOCK_SIZE, 145)},
                {"id": "north_checkpoint", "texture_id": "slush_road", "rect": rect(110, 120, 610, 120)},
                {"id": "chapel_walk", "texture_id": "sidewalk_snow", "rect": rect(95, 590, 290, 115)},
            ]
        return [
            {"id": "relief_route", "texture_id": road_texture(x + y, False), "rect": rect(0, 360, BLOCK_SIZE, 150)},
            {"id": "checkpoint_chicane_a", "texture_id": "road_plain", "rect": rect(165, 205, 430, 115)},
            {"id": "checkpoint_chicane_b", "texture_id": "road_plain", "rect": rect(360, 505, 430, 115)},
            {"id": "chapel_walk", "texture_id": "sidewalk_snow", "rect": rect(100, 630, 300, 155)},
        ]
    if district_key == "central_transfer":
        if layout_id == "station_crossing":
            return [
                {"id": "station_crossing_main", "texture_id": road_texture(x + y, False), "rect": rect(0, 405, BLOCK_SIZE, 145)},
                {"id": "station_crossing_vertical", "texture_id": "slush_road", "rect": rect(430, 0, 140, BLOCK_SIZE)},
                {"id": "bus_bay_west", "texture_id": "road_plain", "rect": rect(80, 170, 310, 115)},
                {"id": "bus_bay_east", "texture_id": "road_plain", "rect": rect(570, 650, 310, 115)},
                {"id": "underpass_cut", "texture_id": "alley_dark", "rect": rect(685, 0, 130, 430)},
            ]
        if layout_id == "underpass_detour":
            return [
                {"id": "underpass_cut", "texture_id": "alley_dark", "rect": rect(360, 0, 160, BLOCK_SIZE)},
                {"id": "detour_lane_north", "texture_id": "road_plain", "rect": rect(0, 190, 650, 130)},
                {"id": "detour_lane_south", "texture_id": "road_plain", "rect": rect(280, 665, 680, 130)},
                {"id": "bus_turnout", "texture_id": "slush_road", "rect": rect(600, 315, 210, 270)},
            ]
        return [
            {"id": "bus_loop_top", "texture_id": "road_plain", "rect": rect(155, 170, 650, 135)},
            {"id": "bus_loop_bottom", "texture_id": "road_plain", "rect": rect(155, 650, 650, 135)},
            {"id": "bus_loop_left", "texture_id": "slush_road", "rect": rect(155, 170, 135, 615)},
            {"id": "bus_loop_right", "texture_id": "slush_road", "rect": rect(670, 170, 135, 615)},
            {"id": "underpass_cut", "texture_id": "alley_dark", "rect": rect(390, 0, 175, BLOCK_SIZE)},
        ]
    if layout_id == "snowed_vacant_lot":
        return [
            {"id": "vacant_lot_edge", "texture_id": "road_plain", "rect": rect(0, 610, BLOCK_SIZE, 150)},
            {"id": "service_cut", "texture_id": road_texture(x + y, True), "rect": rect(vertical_x, 0, 150, 690)},
            {"id": "edge_service_walk", "texture_id": "sidewalk_snow", "rect": rect(90, 185, 290, 100)},
            {"id": "snowed_pullout", "texture_id": "road_cracked", "rect": rect(615, 225, 270, 145)},
        ]
    if layout_id == "broken_grid":
        return [
            {"id": "broken_grid_vertical", "texture_id": road_texture(x + y, True), "rect": rect(vertical_x, 0, 165, BLOCK_SIZE)},
            {"id": "broken_grid_short", "texture_id": road_texture(x * 2 + y, False), "rect": rect(0, horizontal_y, 560, 150)},
            {"id": "vacant_pullout", "texture_id": "road_plain", "rect": rect(615, 580, 270, 145)},
            {"id": "edge_service_walk", "texture_id": "sidewalk_snow", "rect": rect(600, 180, 260, 95)},
        ]
    return [
        {"id": "north_south", "texture_id": road_texture(x + y, True), "rect": rect(vertical_x, 0, 175, BLOCK_SIZE)},
        {"id": "east_west", "texture_id": road_texture(x * 2 + y, False), "rect": rect(0, horizontal_y, BLOCK_SIZE, 175)},
        {"id": "edge_service_walk", "texture_id": "sidewalk_snow", "rect": rect(90, 185, 290, 100)},
        {"id": "vacant_pullout", "texture_id": "road_plain", "rect": rect(615, 580, 270, 145)},
    ]


def generate_snow_fields(x: int, y: int, district_key: str) -> list[dict[str, Any]]:
    inset = (x * 23 + y * 41) % 70
    if district_key == "logistics_belt":
        return [
            {"id": "container_roof_snow", "rect": rect(165, 145, 520, 150)},
            {"id": "dock_drift", "rect": rect(705, 560, 190, 170)},
            {"id": "yard_windrow", "rect": rect(35, 735, 480, 120)},
            {"id": "pallet_snow", "rect": rect(295, 520, 220, 95)},
        ]
    if district_key == "power_plant":
        return [
            {"id": "ash_yard_snow", "rect": rect(170, 210, 560, 330)},
            {"id": "pipe_shadow_snow", "rect": rect(650, 70, 230, 145)},
            {"id": "transformer_drift", "rect": rect(60, 710, 430, 125)},
            {"id": "control_curb_snow", "rect": rect(560, 620, 250, 105)},
        ]
    if district_key == "rural_greenbelt":
        return [
            {"id": "open_field_snow", "rect": rect(0, 0, BLOCK_SIZE, 280 + inset)},
            {"id": "greenhouse_roof_snow", "rect": rect(135, 255, 660, 110)},
            {"id": "frozen_irrigation_snow", "rect": rect(410, 430, 150, 385)},
            {"id": "farmyard_drift", "rect": rect(620, 675, 265, 150)},
        ]
    if district_key == "highway_checkpoint":
        return [
            {"id": "road_shoulder_snow", "rect": rect(0, 570, BLOCK_SIZE, 95)},
            {"id": "checkpoint_snowbank", "rect": rect(120, 230, 360, 125)},
            {"id": "rest_stop_curb_snow", "rect": rect(560, 150, 300, 115)},
            {"id": "blocked_lane_snow", "rect": rect(650, 675, 240, 130)},
        ]
    if district_key == "outer_residential":
        return [
            {"id": "yard_snow", "rect": rect(470, 145, 310, 260)},
            {"id": "garage_curb_snow", "rect": rect(55, 590, 340, 160)},
            {"id": "garden_drift", "rect": rect(30, 190, 250, 155)},
            {"id": "back_fence_snow", "rect": rect(680, 690, 220, 165)},
        ]
    if district_key == "civic_medical":
        return [
            {"id": "clinic_plaza_snow", "rect": rect(240, 390, 440, 275)},
            {"id": "ambulance_bay_snow", "rect": rect(650, 235, 220, 145)},
            {"id": "records_curb_snow", "rect": rect(80, 690, 310, 95)},
            {"id": "public_walk_snow", "rect": rect(175, 60, 265, 95)},
        ]
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
        "civic_medical": (
            rect(245 + seed % 90, 175, 180, 125),
            rect(690, 255 + seed % 105, 160, 245),
            rect(260, 620, 290, 145),
        ),
        "south_residential": (
            rect(155, 460 + seed % 85, 150, 130),
            rect(500, 185 + seed % 115, 190, 210),
            rect(615, 680, 220, 135),
        ),
        "outer_residential": (
            rect(130, 415 + seed % 100, 165, 135),
            rect(510, 160 + seed % 130, 190, 230),
            rect(625, 660, 235, 150),
        ),
        "south_industrial": (
            rect(245 + seed % 150, 520, 190, 140),
            rect(695, 110 + seed % 160, 160, 260),
            rect(160, 690, 300, 135),
        ),
        "logistics_belt": (
            rect(240 + seed % 155, 525, 205, 150),
            rect(710, 95 + seed % 165, 150, 285),
            rect(150, 680, 320, 150),
        ),
        "power_plant": (
            rect(420 + seed % 120, 495, 225, 145),
            rect(640, 95 + seed % 160, 205, 300),
            rect(165, 650, 330, 150),
        ),
        "rural_greenbelt": (
            rect(210 + seed % 130, 560, 205, 145),
            rect(585, 120 + seed % 170, 230, 280),
            rect(85, 705, 360, 155),
        ),
        "highway_checkpoint": (
            rect(365 + seed % 120, 350, 210, 150),
            rect(705, 185 + seed % 130, 145, 300),
            rect(175, 640, 340, 145),
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
    if district_key in [
        "central_transfer",
        "south_industrial",
        "east_medical",
        "civic_medical",
        "logistics_belt",
        "power_plant",
        "rural_greenbelt",
        "highway_checkpoint",
    ] or (x + y) % 3 == 0:
        whiteout_by_district = {
            "central_transfer": rect(330, 120 + seed % 90, 300, 230),
            "south_industrial": rect(510, 80 + seed % 120, 310, 250),
            "east_medical": rect(105, 315 + seed % 120, 260, 230),
            "civic_medical": rect(95, 285 + seed % 120, 280, 235),
            "logistics_belt": rect(485, 70 + seed % 130, 340, 270),
            "power_plant": rect(525, 65 + seed % 130, 320, 290),
            "rural_greenbelt": rect(250, 110 + seed % 150, 430, 310),
            "highway_checkpoint": rect(515, 150 + seed % 125, 300, 275),
            "outer_residential": rect(300, 315, 230, 210),
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
    "civic_medical": [
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
    "outer_residential": [
        ("tree", "dead_tree", (92, 112)),
        ("snow", "snow_drift", (138, 82)),
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
    "logistics_belt": [
        ("crate", "crate_stack", (102, 86)),
        ("rubble", "dumpster_snow", (124, 82)),
        ("fuel", "barrel_empty", (54, 70)),
        ("vehicle", "frozen_car", (64, 60)),
        ("barrier", "barricade_wood", (112, 50)),
    ],
    "power_plant": [
        ("fuel", "barrel_empty", (54, 70)),
        ("utility", "utility_box", (80, 72)),
        ("barrier", "sandbags", (116, 50)),
        ("light", "street_lamp", (42, 82)),
        ("crate", "crate_stack", (96, 82)),
    ],
    "rural_greenbelt": [
        ("tree", "dead_tree", (94, 116)),
        ("snow", "snow_drift", (142, 84)),
        ("fuel", "barrel_empty", (54, 70)),
        ("barrier", "barricade_wood", (108, 50)),
        ("crate", "crate_stack", (90, 76)),
    ],
    "highway_checkpoint": [
        ("barrier", "traffic_cone", (42, 50)),
        ("barrier", "sandbags", (118, 52)),
        ("vehicle", "frozen_car", (64, 60)),
        ("sign", "bus_stop_sign", (48, 86)),
        ("light", "street_lamp", (42, 82)),
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
    if district_key == "logistics_belt":
        return [(190, 245), (445, 205), (725, 240), (215, 585), (515, 645), (785, 610), (110, 745), (835, 130)]
    if district_key == "power_plant":
        return [(180, 210), (395, 155), (715, 195), (245, 580), (565, 620), (785, 520), (135, 745), (805, 725)]
    if district_key == "rural_greenbelt":
        return [(125, 250), (350, 175), (705, 230), (210, 560), (490, 645), (765, 590), (95, 760), (820, 760)]
    if district_key == "highway_checkpoint":
        return [(155, 335), (345, 315), (625, 310), (780, 385), (220, 635), (520, 675), (805, 660), (105, 520)]
    if district_key == "outer_residential":
        return [(120, 210), (340, 145), (735, 175), (505, 470), (210, 710), (815, 650), (615, 780), (330, 560)]
    if district_key == "civic_medical":
        return [(205, 300), (690, 320), (795, 520), (130, 690), (475, 705), (720, 115), (305, 120), (555, 450)]
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
    layout_id = layout_id_for(x, y, district_key)
    anchor_positions = anchor_positions_for(x, y, district_key)
    for slot in range(generated_building_count_for(x, y, district_key)):
        anchors[building_anchor_id(x, y, slot)] = anchor_positions[slot]
    return {
        "block_coord": {"x": x, "y": y},
        "district_id": district_key,
        "district_label": district["label"],
        "layout_id": layout_id,
        "roads": generate_roads(x, y, district_key, layout_id),
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
    category = special.get("category", template.get("category", "industrial" if theme == "industrial" else theme))
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
