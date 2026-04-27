# Resources Layout

이 디렉터리는 `런타임에서 실제 쓰는 자산`만 남긴 상태다.

## Active Runtime Roots

- `world/city`
  - 외부 월드 아트
  - 사용처: `game/scripts/outdoor/outdoor_art_resolver.gd`
  - 포함: `terrain`, `buildings_cutout`, `props_cutout`, `decals`, `player`

- `items/icons`
  - 아이템 아이콘
  - 사용처: `game/scripts/ui/item_icon_resolver.gd`
  - 포함: `item_icons_manifest.json`, `icons_24_cutout`

- `ui/base`
  - 공용 UI fallback
  - 사용처: `game/scripts/ui/ui_kit_resolver.gd`
  - 현재 유지 자산:
    - `ui_manifest.json`
    - `indoor/indoor_action_row_compact_idle.png`
    - `indoor/indoor_action_row_compact_pressed.png`
    - `icons/light_24/{map,bag,close,structure}.png`

- `ui/master`
  - 현재 메인 UI 팩
  - 사용처: `game/scripts/ui/ui_kit_resolver.gd`
  - 하위 구조:
    - `hud`
    - `indoor`
    - `sheet`
    - `overlay`
    - `structure`
    - `feedback`

## Rule

- `resources/` 루트에는 의미 있는 런타임 카테고리만 둔다.
- preview, proof, zip, atlas, csv, 구버전 실험본은 커밋 전에 제거한다.
- 새 리소스는 먼저 `world / items / ui` 중 어디에 속하는지 정한 뒤 배치한다.
