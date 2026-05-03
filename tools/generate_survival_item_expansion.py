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


GROUPS: list[dict[str, Any]] = [
    {
        "key": "food",
        "category": "food",
        "tags": ["food", "consumable", "ordinary_world"],
        "spawn": ["global", "retail", "residential", "food_service"],
        "weight": 0.7,
        "names": [
            "즉석밥 작은 컵", "삼각김밥 포장", "컵라면 매운맛", "통조림 복숭아", "통조림 햄",
            "닭가슴살 팩", "건빵 봉지", "초코바", "사탕 봉지", "껌 한 통",
            "땅콩 봉지", "믹스너트 파우치", "육포 봉지", "김자반 팩", "라면사리",
            "즉석 카레", "즉석 짜장", "미역국 블록", "분말 스프", "설탕 스틱 묶음",
            "소금 소포장", "고추장 튜브", "참기름 소병", "식용유 소병", "시리얼 지퍼백",
            "어린이 과자 상자", "식빵 봉지", "냉동 만두 봉지", "감자칩 통", "단백질 쉐이크 파우더",
            "에너지 젤", "말린 대추", "건포도 봉지", "컵죽", "쌀 소포대",
            "밀가루 봉지", "통조림 콩", "연유 튜브", "인스턴트 오트밀", "통조림 옥수수",
            "도시락 김", "초콜릿 파우치", "분유 캔", "미숫가루 팩", "떡국떡 봉지",
        ],
    },
    {
        "key": "drink",
        "category": "drink",
        "tags": ["drink", "consumable", "ordinary_world"],
        "spawn": ["global", "retail", "residential", "food_service", "medical"],
        "weight": 0.8,
        "names": [
            "생수병", "보리차 페트병", "이온음료", "캔커피", "홍차 티백 상자", "코코아 믹스",
            "두유 팩", "멸균우유", "탄산수", "과일주스 팩", "꿀물 스틱", "생강차 스틱",
            "커피믹스 봉지", "온수 보온병", "반쯤 언 생수", "에너지 드링크", "녹차 병", "정수 필터 병",
        ],
    },
    {
        "key": "medical",
        "category": "medical",
        "tags": ["medical", "hygiene", "consumable", "ordinary_world"],
        "spawn": ["global", "medical", "retail", "residential"],
        "weight": 0.45,
        "names": [
            "캐릭터 밴드", "거즈 패드", "소독약 병", "해열제 판", "감기약 봉투", "진통제 통",
            "위장약 파우치", "붙이는 파스", "멀미약", "전자 체온계", "알레르기약", "소독 솜",
            "의료용 테이프", "일회용 장갑", "치실", "식염수 앰플", "인공눈물", "화상 젤",
            "냉찜질 팩", "온열 패치", "핀셋", "작은 의료 가위", "마스크 묶음", "생리대 파우치",
            "립밤", "핸드크림", "구강청결제", "혈당 시험지 통",
        ],
    },
    {
        "key": "tool",
        "category": "tool",
        "tags": ["tool", "craft_tool", "ordinary_world"],
        "spawn": ["global", "industrial", "repair", "office", "security", "residential"],
        "weight": 1.1,
        "names": [
            "접이식 칼", "멀티툴", "드라이버 세트", "펜치", "망치", "소형 톱", "몽키스패너",
            "육각렌치 묶음", "커터칼", "재단 가위", "줄자", "가스 라이터", "방수 성냥통",
            "손전등", "헤드랜턴", "휴대용 라디오", "보조배터리", "충전 케이블", "멀티탭",
            "작은 자물쇠", "열쇠고리", "바느질 키트", "안전핀 통", "낚싯줄", "나침반",
            "호루라기", "유리 긁개", "끌", "송곳", "페인트 붓", "타이어 게이지", "접이식 삽",
            "휴대용 펌프", "실리콘 건", "작은 저울",
        ],
    },
    {
        "key": "utility",
        "category": "utility",
        "tags": ["utility", "craft_component", "ordinary_world"],
        "spawn": ["global", "retail", "residential", "industrial", "repair", "living_goods", "logistics"],
        "weight": 0.55,
        "names": [
            "투명 지퍼백 묶음", "우산 비닐 커버", "뽁뽁이 조각", "알루미늄 호일", "종량제 봉투",
            "쓰레기봉투 롤", "비닐랩", "고무줄 뭉치", "철사 조각", "노끈 묶음",
            "빨랫줄", "케이블 타이", "신문지", "오래된 잡지", "종이컵 묶음",
            "일회용 젓가락", "빨대 묶음", "보온 시트", "은박 돗자리", "핫팩",
            "양초", "향초", "파라핀 조각", "숯 봉지", "부탄가스 캔",
            "라이터 기름", "마른 수건 조각", "헌 티셔츠 조각", "커튼 천 조각", "베갯잇",
            "침대 시트", "고무 패킹", "문풍지 롤", "실리카겔 봉지", "방수 스프레이",
            "작은 카라비너", "금속 S고리", "찍찍이 테이프", "접착식 후크", "포장용 완충재",
            "택배 완충 종이", "투명 파일", "두꺼운 종이판", "폼보드 조각", "플라스틱 뚜껑",
            "빈 페트병", "빈 유리병", "철제 캔", "빨래집게", "옷걸이",
            "샤워캡", "일회용 비닐장갑", "마스킹 테이프", "목공풀", "순간접착제",
            "에폭시 퍼티", "실리콘 튜브", "고무 장판 조각", "작은 자석", "클립 묶음",
            "압정 통", "스티커 라벨", "방수 네임펜", "연필", "볼펜",
            "메모지", "영수증 롤심", "깨끗한 키친타월", "비누 조각", "여행용 샴푸",
        ],
    },
    {
        "key": "container",
        "category": "container",
        "tags": ["container", "carry", "ordinary_world"],
        "spawn": ["global", "retail", "residential", "office", "logistics"],
        "weight": 0.9,
        "names": [
            "에코백", "종이 쇼핑백", "비닐봉투 묶음", "접이식 장바구니", "낡은 백팩",
            "보냉백", "공구함", "플라스틱 박스", "유리 밀폐병", "반찬통",
            "스테인리스 보온병", "물통", "도시락통", "화장품 파우치", "필통",
            "알약 케이스", "서류 봉투", "신발 상자", "쿠키 틴케이스", "작은 캐리어",
            "배달 보온가방", "허리색", "손가방", "택배 상자", "세탁망",
        ],
    },
    {
        "key": "equipment",
        "category": "equipment",
        "tags": ["equipment", "wearable", "ordinary_world"],
        "spawn": ["global", "retail", "residential", "living_goods", "security", "logistics"],
        "weight": 1.0,
        "names": [
            "검은 롱패딩", "회사 지급 점퍼", "후드티", "두꺼운 니트", "내복 상의", "내복 하의",
            "목도리", "니트 비니", "귀마개", "면 마스크", "겨울 장갑", "고무장갑",
            "작업 장갑", "두꺼운 양말", "등산 양말", "운동화", "방한 부츠", "슬리퍼",
            "우비", "접이식 우산", "앞치마", "안전 조끼", "무릎 담요", "야구모자",
            "자전거 헬멧", "선글라스", "수면양말", "손목 보호대", "허리 보호대", "무릎 보호대",
            "배달 조끼", "교복 재킷", "학생 체육복", "경량 패딩 조끼", "목폴라", "플리스 집업",
            "작업복 상의", "방수 바지", "스카프", "귀달이 모자", "스키 장갑", "목 토시",
            "안전모", "방진 마스크", "등산 배낭", "힙색", "작은 크로스백", "메신저백",
            "넥워머", "발열 내의", "손등 워머", "방수 신발 커버", "장화", "덧신",
            "비닐 우의", "담요 망토", "가죽 벨트", "수건 두건", "얇은 카디건", "털 실내화",
            "정비공 앞치마", "택배 기사 장갑", "낚시 조끼", "오토바이 토시", "방한 마스크",
            "모직 코트", "기모 트레이닝복", "보온 물주머니 벨트", "플라스틱 고글", "반사띠",
        ],
    },
    {
        "key": "knowledge",
        "category": "knowledge",
        "tags": ["knowledge", "readable", "ordinary_world", "story"],
        "spawn": ["global", "office", "residential", "retail", "medical", "staff_only"],
        "weight": 0.15,
        "names": [
            "건물 비상 배치도", "낡은 영수증 묶음", "직원 근무표", "약 복용 메모", "손글씨 동네 지도",
            "아파트 관리일지", "라디오 주파수 쪽지", "대피소 전단", "반상회 공지", "택배 송장 묶음",
            "가족사진 뒷면 메모", "아이 일기장", "찢어진 수첩", "정비 매뉴얼", "응급처치 책자",
            "조리 레시피 카드", "학교 안내장", "병원 예약표", "주유소 외상장부", "편의점 발주표",
            "창고 재고표", "경비 순찰 기록", "분실물 대장", "손때 묻은 성경책", "차량 정비 영수증",
            "폐업 안내문", "임대 계약서 사본", "오래된 여행 지도", "약국 상담 기록", "냉장고 자석 메모",
            "연락처가 적힌 명함", "아이 그림 편지",
        ],
    },
    {
        "key": "personal",
        "category": "personal",
        "tags": ["ordinary_world", "personal", "barter", "story"],
        "spawn": ["global", "residential", "office", "retail", "staff_only"],
        "weight": 0.35,
        "names": [
            "가죽 지갑", "동전 지퍼백", "교통카드", "깨진 손목시계", "결혼반지 케이스",
            "가족사진 액자", "향수병", "립스틱", "면도기", "휴대용 거울",
            "머리끈", "손톱깎이", "작은 빗", "캐릭터 키링", "인형 열쇠고리",
            "아이 장난감 자동차", "낡은 봉제인형", "색연필 통", "스티커북", "게임 카드 묶음",
            "이어폰 케이스", "손편지 봉투", "기념 엽서", "영화 티켓 반쪽", "부적",
            "작은 불상", "십자가 목걸이", "졸업 배지", "회사 출입증", "학생증",
            "도장 케이스", "반려견 목줄", "고양이 장난감", "반려동물 사료 컵", "담배갑",
            "라이터 장식품", "복권 용지", "현금 봉투", "화장솜", "클렌징 티슈",
            "핸드폰 스트랩", "수첩 속 사진", "아이 이름표", "약속이 적힌 포스트잇", "작은 오르골",
            "기념 열쇠", "깨진 안경",
        ],
    },
    {
        "key": "electronics",
        "category": "electronics",
        "tags": ["ordinary_world", "electronics", "barter", "repair_part"],
        "spawn": ["global", "office", "residential", "retail", "repair", "security"],
        "weight": 0.7,
        "names": [
            "금 간 스마트폰", "배터리 없는 휴대폰", "오래된 노트북", "태블릿 PC", "무선 이어폰 한쪽",
            "USB 메모리", "SD 카드", "디지털 카메라", "일회용 카메라", "AA 배터리 묶음",
            "휴대용 게임기", "탁상 알람시계", "전기면도기", "헤어드라이어", "전기장판 조절기",
            "공유기", "무선 키보드", "마우스", "웹캠", "블루투스 스피커",
            "스마트워치", "고장난 드론", "차량 블랙박스", "보이스레코더", "라디오 안테나",
            "휴대용 선풍기", "LED 무드등", "충전식 손난로", "멀티 충전 어댑터", "케이블 정리함",
        ],
    },
    {
        "key": "household",
        "category": "household",
        "tags": ["ordinary_world", "household", "craft_component"],
        "spawn": ["global", "residential", "retail", "food_service", "living_goods"],
        "weight": 1.0,
        "names": [
            "프라이팬", "냄비", "주전자", "머그컵", "접시", "숟가락 묶음", "젓가락 묶음",
            "행주", "목욕 수건", "얇은 담요", "커튼", "침대 패드", "베개", "세탁세제",
            "주방세제", "수세미", "걸레 자루", "빗자루", "쓰레받기", "작은 러그",
            "벽시계", "화분", "사진 액자", "옷걸이 묶음", "구둣주걱", "현관 매트",
            "샤워 커튼", "욕실 매트", "양동이", "분무기", "집게", "쟁반",
            "도마", "플라스틱 국자", "보온 도시락", "쿠션", "서랍 칸막이", "빨래 바구니",
            "스테인리스 그릇", "작은 접이식 의자",
        ],
    },
    {
        "key": "crafted",
        "category": "crafted",
        "tags": ["crafted", "improvised"],
        "spawn": [],
        "weight": 0.8,
        "names": [
            "방수 소지품 파우치", "은박 단열 깔개", "신문지 착화 묶음", "천 조각 마스크", "양말 손난로 주머니",
            "젖은 신발 임시 건조대", "노끈 어깨끈", "호일 반사판", "테이프 보강 장갑", "커튼 방풍막",
            "문틈 막이 뭉치", "페트병 온수팩", "비닐 우의 보강판", "가방 방수 덮개", "휴대폰 방수 봉투",
            "유리병 촛불등", "깡통 미니 스토브", "수건 압박 붕대", "메모 방수 케이스", "임시 열쇠 묶음",
            "담요 침낭 롤", "책상 서랍 잠금 쐐기", "호루라기 목걸이", "배터리 보관 케이스", "작은 응급 세트",
            "식기 정리 묶음", "소리 줄인 열쇠고리", "반사띠 팔찌", "방한 목가리개", "고글 김서림 닦개",
            "종이 지도 커버", "즉석 식사 꾸러미", "물병 보온 커버", "양초 바람막이", "침대시트 들것",
            "전선 고정 후크", "전단지 불쏘시개", "보온병 충격 완충대", "간이 신발 덧대기", "비상 표시 깃발",
            "작은 수리 파우치", "손전등 손목끈", "병뚜껑 소리 덫", "조용한 문고리 묶음", "젖은 장갑 건조줄",
            "파손 창문 보강막", "주머니 난방팩 홀더", "비닐 식수 깔때기", "가벼운 허리 수납대", "수첩 방수 표지",
            "금속 그릇 반사 난로", "빗자루 창문 받침", "카드보드 바람막이", "신발 속 단열 깔창", "작은 거래 꾸러미",
            "응급 위생 파우치", "충전 케이블 정리끈", "서류 은닉 봉투", "아이 장난감 미끼", "라디오 안테나 보강",
        ],
    },
]


def item_id(group_key: str, index: int) -> str:
    return f"{EXPANSION_PREFIX}{group_key}_{index:03d}"


def tag_set(*parts: list[str]) -> list[str]:
    tags: set[str] = {"survival_expansion"}
    for part in parts:
        tags.update(part)
    return sorted(tags)


def description_for(group_key: str, name: str) -> str:
    descriptions = {
        "food": f"{name}. 누군가 평범하게 사 두었던 먹을거리라서 더 현실적으로 느껴진다. 배를 채우는 값어치도 있지만, 남은 생활의 흔적이기도 하다.",
        "drink": f"{name}. 갈증을 줄이는 물건이면서 동시에 어디까지 전기와 유통이 버텼는지 보여 주는 작은 단서다.",
        "medical": f"{name}. 큰 수술 도구는 아니지만 상처, 감기, 위생 문제를 버티게 해 주는 생활 의료품이다.",
        "tool": f"{name}. 재난을 위해 준비된 물건이라기보다, 평소 누군가의 서랍이나 작업대에 있던 도구다.",
        "utility": f"{name}. 원래 목적은 사소하지만 찢고, 묶고, 막고, 감싸는 순간 생존 도구가 될 수 있다.",
        "container": f"{name}. 안에 무엇을 넣느냐에 따라 값어치가 달라지는 물건이다. 파밍은 결국 들고 나갈 수 있는 만큼만 의미가 있다.",
        "equipment": f"{name}. 완벽한 방한 장비는 아니더라도 몸에 걸치면 바람, 마찰, 시선 중 하나쯤은 줄여 준다.",
        "knowledge": f"{name}. 당장 먹거나 입을 수는 없지만, 공간과 사람과 남겨진 선택을 읽게 해 주는 단서다.",
        "personal": f"{name}. 생존용 물건이라기보다 누군가가 끝까지 가지고 있던 사적인 물건이다. 때로는 거래품이나 마음을 붙드는 물건이 된다.",
        "electronics": f"{name}. 전기가 끊기면 고철처럼 보이지만 배터리, 데이터, 부품, 신호 가능성을 아직 품고 있다.",
        "household": f"{name}. 집 안에 당연히 있던 물건이다. 재난 이후에는 그 당연함이 오히려 가장 낯설게 느껴진다.",
        "crafted": f"{name}. 원래 그런 상품은 아니지만 손에 잡힌 물건들을 맞춰 당장의 문제를 줄이도록 만든 임시 장비다.",
    }
    return descriptions[group_key]


def usage_hint_for(group_key: str) -> str:
    hints = {
        "food": "먹어서 허기를 줄이거나, 다른 재료와 묶어 한 끼 분량의 꾸러미로 만들 수 있다.",
        "drink": "마셔서 갈증을 줄이거나 따뜻하게 데울 수 있다면 체감 가치가 훨씬 커진다.",
        "medical": "상태 회복, 위생 관리, 응급 조합의 재료로 쓸 수 있다.",
        "tool": "직접 사용하기도 하고 다른 물건을 고정하거나 분해하는 조합 도구로도 쓸 수 있다.",
        "utility": "겉보기에는 잡동사니지만 방수, 고정, 단열, 표시, 포장 조합에 자주 엮인다.",
        "container": "가볍고 중요한 물건을 분리하거나, 장비 조합의 외피로 쓸 수 있다.",
        "equipment": "장착해서 몸을 보호하거나, 더 나은 임시 장비로 보강할 수 있다.",
        "knowledge": "읽을 수 있다면 건물, 사람, 물자 위치에 대한 단서를 줄 수 있다.",
        "personal": "직접적인 성능은 낮지만 거래, 이야기, 심리적 선택의 재료가 될 수 있다.",
        "electronics": "전원과 부품 상태에 따라 신호, 기록, 조명, 수리 재료가 될 수 있다.",
        "household": "그 자체로도 쓸모가 있고, 천과 금속과 플라스틱 재료로 다시 쪼개 쓸 수 있다.",
        "crafted": "완제품처럼 믿을 수는 없지만 지금 당장의 위험을 한 단계 낮춘다.",
    }
    return hints[group_key]


def cold_hint_for(group_key: str) -> str:
    hints = {
        "food": "추위 속에서는 맛보다 열량, 씹는 시간, 휴대성이 더 중요해진다.",
        "drink": "수분이 부족하면 피로와 추위가 더 빨리 온다. 얼지 않게 챙기는 것도 일이다.",
        "medical": "작은 상처와 건조함은 추운 날씨에서 더 쉽게 큰 문제로 번진다.",
        "tool": "손이 굳기 전에 빠르게 처리할 수 있는 도구는 체온만큼이나 귀하다.",
        "utility": "바람을 막거나 젖은 것을 분리하는 데 성공하면 체감 추위가 크게 줄어든다.",
        "container": "젖은 것과 마른 것, 먹을 것과 더러운 것을 나누는 것만으로도 생존성이 오른다.",
        "equipment": "완벽하지 않아도 노출 부위를 하나 줄이면 밖에서 버틸 시간이 늘어난다.",
        "knowledge": "따뜻한 곳, 막힌 길, 위험한 방을 미리 아는 것은 체온 손실을 줄이는 정보다.",
        "personal": "성능은 없어도 버릴지 들고 갈지 고민하게 만드는 무게가 있다.",
        "electronics": "차가운 배터리는 빨리 죽는다. 몸 가까이 두거나 부품으로 돌릴 판단이 필요하다.",
        "household": "집 안 물건은 바람막이, 깔개, 보온재가 되는 순간 값어치가 바뀐다.",
        "crafted": "임시 장비는 오래 버티기보다 한 번의 이동, 한 번의 밤을 넘기기 위한 물건이다.",
    }
    return hints[group_key]


def weight_for(group: dict[str, Any], index: int, name: str) -> float:
    base = float(group["weight"])
    if any(word in name for word in ["냄비", "프라이팬", "공구함", "캐리어", "쌀", "밀가루", "노트북", "배낭", "박스"]):
        base += 1.4
    if any(word in name for word in ["카드", "쪽지", "메모", "티켓", "반지", "USB", "SD", "립밤", "열쇠"]):
        base = max(0.1, base - 0.35)
    return round(base + (index % 4) * 0.15, 2)


def apply_stats(row: dict[str, Any], group_key: str, index: int, name: str) -> None:
    if group_key == "food":
        row["hunger_restore"] = 6 + (index % 12)
        row["thirst_restore"] = -1 if any(word in name for word in ["건빵", "감자칩", "육포", "라면"]) else 0
        row["use_minutes"] = 5 + (index % 3) * 5
    elif group_key == "drink":
        row["thirst_restore"] = 10 + (index % 8) * 2
        if any(word in name for word in ["커피", "에너지"]):
            row["fatigue_restore"] = 4
        row["use_minutes"] = 5
    elif group_key == "medical":
        if not any(word in name for word in ["립밤", "핸드크림", "치실", "마스크"]):
            row["health_restore"] = 3 + (index % 7)
        row["use_minutes"] = 5
    elif group_key == "knowledge":
        row["readable"] = True
        row["read_time_minutes"] = 5 + (index % 4) * 5
    elif group_key == "electronics":
        if any(word in name for word in ["손난로", "무드등", "라디오", "보조"]):
            row["charges_max"] = 3
            row["initial_charges"] = 1 + (index % 2)
            row["charge_label"] = "전력"
    elif group_key == "crafted":
        if any(word in name for word in ["온수팩", "난방팩", "촛불등", "손난로"]):
            row["use_effects"] = {
                "exposure_restore": 4.0,
                "warmth_minutes": 25,
                "outdoor_exposure_drain_multiplier": 0.92,
            }


EQUIP_SLOTS = ["outer", "body", "neck", "head", "face", "hands", "feet", "waist", "back", "hand_carry"]


def add_item_tags(row: dict[str, Any], *tags: str) -> None:
    existing_tags = set(row.get("item_tags", []))
    existing_tags.update(tags)
    row["item_tags"] = sorted(existing_tags)


def apply_container_loadout(row: dict[str, Any], index: int, name: str) -> None:
    del name

    back_carried_indices = {5, 21}
    waist_carried_indices = {14, 16}
    hand_carried_indices = {1, 2, 3, 4, 6, 7, 8, 20, 24, 25}

    if index in back_carried_indices:
        row["equip_slot"] = "back"
        row["carry_capacity_bonus"] = 3.0 if index == 5 else 2.5
        row["ideal_carry_bonus"] = 1.0
        add_item_tags(row, "equipment", "back_carry")
        return

    if index in waist_carried_indices:
        row["equip_slot"] = "waist"
        row["carry_capacity_bonus"] = 0.8
        row["ideal_carry_bonus"] = 0.35
        add_item_tags(row, "equipment", "waist_carry")
        return

    if index in hand_carried_indices:
        row["equip_slot"] = "hand_carry"
        row["carry_capacity_bonus"] = round(1.2 + float(index % 4) * 0.4, 2)
        row["ideal_carry_bonus"] = round(0.35 + float(index % 3) * 0.15, 2)
        add_item_tags(row, "equipment", "hand_carry")


def apply_equipment(row: dict[str, Any], index: int, name: str) -> None:
    if "배낭" in name or "백" in name or "가방" in name:
        row["equip_slot"] = "back"
        row["carry_capacity_bonus"] = 2.0 if "배낭" in name else 1.0
        row["ideal_carry_bonus"] = 1.0
        return
    if "허리" in name or "벨트" in name or "힙색" in name:
        row["equip_slot"] = "waist"
        row["carry_capacity_bonus"] = 0.8
        return
    if any(word in name for word in ["목도리", "넥워머", "목 토시"]):
        row["equip_slot"] = "neck"
    elif any(word in name for word in ["비니", "모자", "헬멧", "안전모"]):
        row["equip_slot"] = "head"
    elif any(word in name for word in ["마스크", "고글", "선글라스"]):
        row["equip_slot"] = "face"
    elif any(word in name for word in ["장갑", "토시", "워머"]):
        row["equip_slot"] = "hands"
    elif any(word in name for word in ["양말", "운동화", "부츠", "슬리퍼", "장화", "덧신", "실내화", "커버"]):
        row["equip_slot"] = "feet"
    elif any(word in name for word in ["내복", "체육복", "트레이닝복", "목폴라"]):
        row["equip_slot"] = "body"
    else:
        row["equip_slot"] = "outer"

    warmth = 0.94 if row["equip_slot"] in ["outer", "body", "neck", "head"] else 0.97
    if any(word in name for word in ["롱패딩", "방한", "발열", "담요", "모직"]):
        warmth -= 0.04
    row["equip_effects"] = {
        "outdoor_exposure_drain_multiplier": max(0.84, warmth),
        "outdoor_hazard_multipliers": {
            "wind_gap": {"exposure": 0.94 if row["equip_slot"] in ["outer", "neck", "face"] else 1.0},
            "black_ice": {"fatigue": 0.92 if row["equip_slot"] == "feet" else 1.0},
        },
    }


def build_items(existing_ids: set[str]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    seen_names: set[str] = set()
    for group in GROUPS:
        names = group["names"]
        for index, name in enumerate(names, start=1):
            row_id = item_id(group["key"], index)
            if row_id in existing_ids:
                raise RuntimeError(f"Generated item id collides with base item: {row_id}")
            if name in seen_names:
                raise RuntimeError(f"Duplicate generated item name: {name}")
            seen_names.add(name)
            weight = weight_for(group, index, name)
            row: dict[str, Any] = {
                "id": row_id,
                "name": name,
                "bulk": max(1, round(weight)),
                "carry_weight": weight,
                "description": description_for(group["key"], name),
                "usage_hint": usage_hint_for(group["key"]),
                "cold_hint": cold_hint_for(group["key"]),
                "category": group["category"],
                "item_tags": tag_set(group["tags"]),
                "spawn_profiles": sorted(set(group["spawn"])),
            }
            apply_stats(row, group["key"], index, name)
            if group["key"] == "container":
                apply_container_loadout(row, index, name)
            if group["key"] == "equipment":
                apply_equipment(row, index, name)
            if group["key"] == "crafted":
                row["craft_kind"] = craft_kind_for_name(name)
                if index in [1, 5, 12, 29, 49, 54]:
                    apply_equipment(row, index, name)
            rows.append(row)

    if len(rows) != 500:
        raise RuntimeError(f"Expected 500 generated items, got {len(rows)}")
    return rows


CRAFT_KINDS = [
    "waterproof", "warmth", "fire", "medical", "carry", "repair", "signal", "quiet", "food", "document",
]


def craft_kind_for_name(name: str) -> str:
    if any(word in name for word in ["온수", "난방", "보온", "손난로", "침낭", "깔창", "단열"]):
        return "warmth"
    if "반사판" in name:
        return "reflector"
    if any(word in name for word in ["촛불", "스토브", "불쏘시개", "착화", "난로"]):
        return "fire"
    if any(word in name for word in ["붕대", "응급", "위생", "마스크", "닦개"]):
        return "medical"
    if any(word in name for word in ["방수", "방풍", "문틈", "창문", "바람막이", "우의", "커버"]):
        return "waterproof"
    if any(word in name for word in ["지도", "메모", "수첩", "서류", "표지", "은닉"]):
        return "document"
    if any(word in name for word in ["호루라기", "반사띠", "표시", "깃발", "라디오", "안테나"]):
        return "signal"
    if any(word in name for word in ["조용", "소리", "미끼", "덫", "문고리"]):
        return "quiet"
    if any(word in name for word in ["식사", "식수", "물병", "깔때기"]):
        return "food"
    if any(word in name for word in ["파우치", "어깨끈", "수납", "꾸러미", "케이스", "보관", "홀더"]):
        return "carry"
    return "repair"


def has_final_consonant(text: str) -> bool:
    if not text:
        return False
    code = ord(text[-1])
    if code < 0xAC00 or code > 0xD7A3:
        return False
    return (code - 0xAC00) % 28 != 0


def particle(text: str, consonant_form: str, vowel_form: str) -> str:
    return consonant_form if has_final_consonant(text) else vowel_form

PAIR_POOLS: dict[str, tuple[list[str], list[str]]] = {
    "waterproof": (
        ["surv_utility_001", "surv_utility_002", "surv_utility_003", "surv_utility_004", "surv_utility_005", "clear_plastic_sheet", "trash_bag_roll", "zip_bag"],
        ["rubber_band", "duct_tape", "packing_tape", "twine_bundle", "zip_ties", "surv_utility_012", "surv_container_014", "surv_household_27"],
    ),
    "warmth": (
        ["surv_household_010", "surv_household_011", "surv_household_012", "surv_household_036", "old_blanket", "fleece_blanket", "towel", "bed_sheet"],
        ["surv_utility_018", "surv_utility_019", "surv_utility_020", "surv_utility_029", "aluminum_foil", "bubble_wrap_roll", "hand_warmer_pack", "shoe_insole"],
    ),
    "fire": (
        ["surv_utility_013", "surv_utility_014", "surv_utility_021", "surv_utility_022", "newspaper", "old_magazine", "candle", "paraffin_block"],
        ["matchbox", "lighter", "rubbing_alcohol", "cooking_oil", "surv_tool_012", "surv_tool_013", "surv_utility_023", "surv_utility_024"],
    ),
    "medical": (
        ["surv_medical_001", "surv_medical_002", "surv_medical_012", "surv_medical_013", "gauze_pad", "sterile_gauze_roll", "sanitary_pad", "hand_sanitizer_gel"],
        ["medical_tape", "surv_utility_027", "surv_household_008", "surv_medical_014", "alcohol_swab", "cotton_swab_pack", "old_cloth_rag", "towel"],
    ),
    "carry": (
        ["surv_container_001", "surv_container_004", "surv_container_005", "surv_container_007", "surv_container_021", "shopping_bag", "market_basket", "cardboard_box"],
        ["rope_bundle", "twine_bundle", "surv_utility_010", "surv_utility_011", "duct_tape", "zip_ties", "surv_equipment_57", "surv_utility_036"],
    ),
    "repair": (
        ["surv_tool_003", "surv_tool_004", "surv_tool_007", "surv_tool_009", "screwdriver", "pliers", "hammer", "sewing_kit"],
        ["surv_utility_054", "surv_utility_055", "surv_utility_056", "surv_utility_057", "nails_pack", "screws_pack", "steel_wire", "epoxy_putty"],
    ),
    "signal": (
        ["surv_electronics_001", "surv_electronics_010", "surv_electronics_020", "surv_electronics_025", "portable_radio", "headlamp", "flashlight", "power_bank"],
        ["spare_batteries", "charging_cable", "surv_tool_018", "surv_tool_019", "surv_utility_004", "aluminum_foil", "surv_electronics_029", "surv_knowledge_007"],
    ),
    "quiet": (
        ["surv_personal_014", "surv_utility_027", "surv_utility_028", "surv_household_009", "old_cloth_rag", "dishcloth", "towel", "surv_equipment_12"],
        ["rubber_band", "twine_bundle", "surv_utility_008", "surv_utility_038", "binder_clip_box", "surv_utility_049", "surv_utility_050", "packing_tape"],
    ),
    "food": (
        ["surv_food_001", "surv_food_003", "surv_food_015", "surv_food_016", "surv_food_032", "instant_rice_bowl", "ramen_pack", "instant_soup_powder"],
        ["surv_drink_014", "hot_water", "warm_tea", "kettle", "pot", "surv_household_001", "surv_household_003", "surv_utility_044"],
    ),
    "document": (
        ["surv_knowledge_001", "surv_knowledge_005", "surv_knowledge_007", "surv_knowledge_010", "surv_knowledge_015", "notebook", "memo_pad", "file_folder"],
        ["surv_utility_001", "surv_utility_041", "zip_bag", "clear_plastic_sheet", "surv_container_017", "binder_clip_box", "surv_utility_064", "packing_tape"],
    ),
    "reflector": (
        ["surv_utility_004", "aluminum_foil", "foil_tray_pack", "surv_utility_042", "cardboard_sheet", "foam_board_piece", "surv_household_039", "surv_container_018"],
        ["duct_tape", "packing_tape", "surv_utility_039", "surv_utility_040", "surv_utility_042", "cardboard_sheet", "foam_board_piece", "binder_clip_box"],
    ),
}


def recipe_category(kind: str) -> str:
    if kind == "food":
        return "food_drink"
    if kind == "medical":
        return "hygiene_medical"
    if kind == "fire" or kind == "reflector":
        return "fire_heat"
    return "repair_fortify"


def generate_recipes(
    items: list[dict[str, Any]],
    base_item_by_id: dict[str, dict[str, Any]],
    existing_recipe_pairs: set[tuple[str, str]],
) -> list[dict[str, Any]]:
    item_by_id = {row["id"]: row for row in items}
    all_item_names = {item_id: row.get("name", item_id) for item_id, row in base_item_by_id.items()}
    all_item_names.update({item_id: row.get("name", item_id) for item_id, row in item_by_id.items()})
    known_ids = set(all_item_names)
    crafted_items = [row for row in items if row["id"].startswith("surv_crafted_")]
    recipes: list[dict[str, Any]] = []
    used_pairs = set(existing_recipe_pairs)
    pair_cache: dict[str, list[tuple[str, str]]] = {}
    pair_cursor: dict[str, int] = {}

    keep_tools = {item_id for item_id, row in base_item_by_id.items() if row.get("category") == "tool"}
    keep_tools.update({row["id"] for row in items if row.get("category") == "tool"})

    def add_recipe(result: dict[str, Any], primary: str, secondary: str) -> bool:
        if primary not in known_ids or secondary not in known_ids or primary == secondary:
            return False
        pair = tuple(sorted([primary, secondary]))
        if pair in used_pairs:
            return False
        used_pairs.add(pair)
        kind = str(result.get("craft_kind", "repair"))
        ingredient_rules = {
            primary: "keep" if primary in keep_tools else "consume",
            secondary: "keep" if secondary in keep_tools else "consume",
        }
        result_id = result["id"]
        result_name = str(result.get("name", result_id))
        primary_name = all_item_names[primary]
        secondary_name = all_item_names[secondary]
        recipes.append(
            {
                "id": f"{pair[0]}__{pair[1]}",
                "ingredients": [primary, secondary],
                "contexts": ["indoor", "outdoor"],
                "codex_category": recipe_category(kind),
                "codex_order": 5000 + len(recipes),
                "required_tags": [],
                "minutes": 7 + (len(recipes) % 5) * 3,
                "ingredient_rules": ingredient_rules,
                "result_items": [{"id": result_id, "count": 1}],
                "result_type": "success",
                "result_item_id": result_id,
                "indoor_minutes": 7 + (len(recipes) % 5) * 3,
                "required_tool_ids": [],
                "tool_charge_costs": {},
                "result_text": f"{primary_name}{particle(primary_name, '과', '와')} {secondary_name}{particle(secondary_name, '을', '를')} 맞춰 {result_name}{particle(result_name, '을', '를')} 만들었다. 원래 그런 용도는 아니지만 지금 상황에는 그럴듯하다.",
            }
        )
        return True

    def candidate_pairs(kind: str) -> list[tuple[str, str]]:
        if kind in pair_cache:
            return pair_cache[kind]
        primary_pool, secondary_pool = PAIR_POOLS[kind]
        pairs: list[tuple[str, str]] = []
        for primary in primary_pool:
            for secondary in secondary_pool:
                if primary not in known_ids or secondary not in known_ids or primary == secondary:
                    continue
                pairs.append((primary, secondary))
        pairs.sort(key=lambda pair: stable_hash(f"{kind}:{pair[0]}:{pair[1]}"))
        pair_cache[kind] = pairs
        pair_cursor[kind] = 0
        return pairs

    def add_next_kind_recipe(result: dict[str, Any], kind: str) -> bool:
        pairs = candidate_pairs(kind)
        if not pairs:
            return False
        start = pair_cursor.get(kind, 0)
        for offset in range(len(pairs)):
            index = (start + offset) % len(pairs)
            primary, secondary = pairs[index]
            if add_recipe(result, primary, secondary):
                pair_cursor[kind] = (index + 1) % len(pairs)
                return True
        return False

    add_recipe(crafted_items[0], "surv_utility_002", "rubber_band")

    for result_index, result in enumerate(crafted_items):
        kind = str(result.get("craft_kind", "repair"))
        target_per_result = 4
        made_for_result = 1 if result_index == 0 else 0
        while made_for_result < target_per_result:
            if not add_next_kind_recipe(result, kind):
                break
            made_for_result += 1
        if made_for_result != target_per_result:
            raise RuntimeError(f"Could not generate enough recipes for {result['id']}")

    if len(recipes) != 240:
        raise RuntimeError(f"Expected 240 generated recipes, got {len(recipes)}")
    return recipes


def generate_loot_profiles(items: list[dict[str, Any]]) -> dict[str, Any]:
    profile_ids = [
        "global", "retail", "residential", "medical", "office", "food_service", "industrial",
        "security", "repair", "living_goods", "logistics", "staff_only",
    ]
    profiles: dict[str, list[dict[str, Any]]] = {profile_id: [] for profile_id in profile_ids}
    for row in items:
        if row.get("category") == "crafted":
            continue
        for profile in row.get("spawn_profiles", []):
            if profile not in profiles:
                continue
            weight = 0.5 if profile == "global" else 1.0
            if row.get("category") in ["knowledge", "personal", "electronics"]:
                weight *= 0.65
            if row.get("category") == "equipment":
                weight *= 0.85
            profiles[profile].append({"id": row["id"], "weight": round(weight, 2)})

    def limited(profile: str, limit: int) -> list[dict[str, Any]]:
        rows = sorted(profiles.get(profile, []), key=lambda row: stable_hash(f"{profile}:{row['id']}"))
        return rows[:limit]

    return {
        "global": limited("global", 50),
        "building_categories": {
            "retail": limited("retail", 95),
            "residential": limited("residential", 95),
            "medical": limited("medical", 58),
            "office": limited("office", 64),
            "food_service": limited("food_service", 70),
            "industrial": limited("industrial", 80),
            "security": limited("security", 54),
        },
        "site_tags": {
            "repair": limited("repair", 52),
            "living_goods": limited("living_goods", 58),
            "logistics": limited("logistics", 54),
            "staff_only": limited("staff_only", 44),
            "materials": limited("industrial", 54),
            "stockroom": limited("retail", 55),
        },
        "building_ids": {
            "mart_01": limited("retail", 72),
            "convenience_01": limited("retail", 56),
            "pharmacy_01": limited("medical", 54),
            "clinic_01": limited("medical", 54),
            "hardware_01": limited("industrial", 66),
            "warehouse_01": limited("industrial", 66),
            "garage_01": limited("repair", 42) + limited("industrial", 24),
            "hostel_01": limited("residential", 70),
            "apartment_01": limited("residential", 78),
            "office_01": limited("office", 60),
        },
    }


ICON_COLORS = {
    "food": (187, 125, 69),
    "drink": (78, 142, 185),
    "medical": (194, 77, 84),
    "tool": (135, 150, 157),
    "utility": (143, 137, 93),
    "container": (101, 132, 118),
    "equipment": (96, 124, 153),
    "knowledge": (171, 154, 108),
    "personal": (168, 112, 142),
    "electronics": (94, 138, 160),
    "household": (142, 125, 101),
    "crafted": (128, 158, 144),
}


def icon_color(category: str, item_id_value: str) -> tuple[int, int, int]:
    base = ICON_COLORS.get(category, (130, 140, 150))
    h = stable_hash(item_id_value)
    return tuple(max(30, min(235, channel + ((h >> shift) % 35) - 17)) for channel, shift in zip(base, [0, 8, 16]))


def draw_icon(item: dict[str, Any], size: int) -> Image.Image:
    scale = 4
    canvas = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    category = str(item.get("category", "utility"))
    color = icon_color(category, item["id"])
    accent = tuple(min(255, c + 45) for c in color)
    shadow = (22, 32, 40, 145)
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
    elif category in {"tool", "utility", "electronics"}:
        draw.rounded_rectangle(box(size * 0.20, size * 0.55, size * 0.82, size * 0.72), radius=int(size * 0.08 * scale), fill=color + (255,), outline=(224, 232, 236, 170), width=max(1, scale))
        draw.polygon([box(size * 0.25, size * 0.25, size * 0.32, size * 0.35)[:2], box(size * 0.77, size * 0.55, size * 0.85, size * 0.66)[:2], box(size * 0.70, size * 0.73, size * 0.78, size * 0.80)[:2], box(size * 0.18, size * 0.43, size * 0.25, size * 0.51)[:2]], fill=accent + (245,))
    elif category == "equipment":
        draw.rounded_rectangle(box(size * 0.28, size * 0.18, size * 0.72, size * 0.82), radius=int(size * 0.13 * scale), fill=color + (255,), outline=(225, 234, 240, 190), width=max(1, scale))
        draw.arc(box(size * 0.18, size * 0.20, size * 0.42, size * 0.72), 260, 90, fill=accent + (240,), width=max(2, int(scale * 1.5)))
        draw.arc(box(size * 0.58, size * 0.20, size * 0.82, size * 0.72), 90, 280, fill=accent + (240,), width=max(2, int(scale * 1.5)))
    elif category == "container":
        draw.rounded_rectangle(box(size * 0.20, size * 0.32, size * 0.80, size * 0.78), radius=int(size * 0.08 * scale), fill=color + (255,), outline=(225, 235, 238, 180), width=max(1, scale))
        draw.arc(box(size * 0.34, size * 0.18, size * 0.66, size * 0.48), 180, 360, fill=accent + (240,), width=max(2, scale))
    elif category in {"knowledge", "personal"}:
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
        for old_icon in out_dir.glob(f"{EXPANSION_PREFIX}*.png"):
            old_icon.unlink()
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
                "sheet": "generated_world_item_expansion",
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
    manifest["meta"]["survival_expansion_direction"] = "ordinary-world scavenging, not pure survival gear"
    manifest["meta"]["item_count"] = len(existing_items)
    write_json(MANIFEST_PATH, manifest)


def main() -> None:
    base_items = load_json(GAME_DATA / "items.json")
    base_recipes = load_json(GAME_DATA / "crafting_combinations.json")
    base_item_by_id = {row["id"]: row for row in base_items}
    existing_item_ids = set(base_item_by_id.keys())
    existing_recipe_pairs = {tuple(sorted(row.get("ingredients", []))) for row in base_recipes if len(row.get("ingredients", [])) == 2}

    items = build_items(existing_item_ids)
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
