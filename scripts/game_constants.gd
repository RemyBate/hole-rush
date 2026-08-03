extends Node

## Autoload singleton: GameConstants (no class_name — avoids Godot Theme-style conflicts).

## Global tuning values for Hole Rush.


const GAME_TIME_SECONDS: float = 90.0
## Grow the hole on every collect so size tracks what the player sees.
const GROWTH_EVERY: int = 1
const GROWTH_RADIUS: float = 3.0
## Extra growth proportional to swallowed item visual radius.
const GROWTH_FROM_ITEM_RADIUS: float = 0.06
const MAX_HOLE_SIZE: int = 5

const INITIAL_HOLE_RADIUS: float = 48.0
const MIN_HOLE_RADIUS: float = 48.0
const MAX_HOLE_RADIUS: float = 200.0

const HOLE_SIZE_2_RADIUS: float = 66.0
const HOLE_SIZE_3_RADIUS: float = 88.0
const HOLE_SIZE_4_RADIUS: float = 114.0
const HOLE_SIZE_5_RADIUS: float = 146.0

## Hole must be at least this fraction of the item's visual radius to swallow it.
const SWALLOW_FIT_RATIO: float = 1.0

const PLAY_AREA_SIZE: Vector2 = Vector2(3200.0, 3200.0)
const FOOD_MARGIN: float = 100.0

const COLLECT_ANIM_DURATION: float = 0.38
const TOO_LARGE_FEEDBACK_DURATION: float = 0.45
const OBSTACLE_PUSH_STRENGTH: float = 240.0

## Star bonus coins awarded at level completion (configurable).
const STAR_1_COIN_REWARD: int = 20
const STAR_2_COIN_REWARD: int = 50
const STAR_3_COIN_REWARD: int = 100

## Public legal & support — keep in sync with store/privacy-policy.md and store/play-store-listing.md.
const SUPPORT_EMAIL := "remymbu12@gmail.com"
const PRIVACY_POLICY_URL := "https://remydev.de/games/privacy-policy"
const LEGAL_LAST_UPDATED := "June 9, 2026"


static func star_coin_reward(stars: int) -> int:
	match clampi(stars, 1, 3):
		3:
			return STAR_3_COIN_REWARD
		2:
			return STAR_2_COIN_REWARD
		_:
			return STAR_1_COIN_REWARD


static func radius_for_hole_size(size: int) -> float:
	match clampi(size, 1, MAX_HOLE_SIZE):
		1:
			return INITIAL_HOLE_RADIUS
		2:
			return HOLE_SIZE_2_RADIUS
		3:
			return HOLE_SIZE_3_RADIUS
		4:
			return HOLE_SIZE_4_RADIUS
		_:
			return HOLE_SIZE_5_RADIUS
