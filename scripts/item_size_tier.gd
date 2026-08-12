class_name ItemSizeTier
extends RefCounted

## Dynamic collectible size tiers (randomized per spawn).

enum Tier {
	TINY,
	SMALL,
	MEDIUM,
	LARGE,
	HUGE,
	GIANT,
}

const TIER_COUNT: int = 6

const VISUAL_SCALES: Array[float] = [0.7, 0.9, 1.0, 1.5, 2.0, 2.5]
const REQUIRED_HOLE_SIZES: Array[int] = [1, 1, 2, 3, 4, 5]
const SCORE_VALUES: Array[int] = [5, 8, 10, 15, 25, 40]
const TIER_NAMES: Array[String] = ["Tiny", "Small", "Medium", "Large", "Huge", "Giant"]


static func visual_scale(tier: int) -> float:
	return VISUAL_SCALES[clampi(tier, 0, TIER_COUNT - 1)]


static func required_hole_size(tier: int) -> int:
	return REQUIRED_HOLE_SIZES[clampi(tier, 0, TIER_COUNT - 1)]


static func score_value(tier: int) -> int:
	return SCORE_VALUES[clampi(tier, 0, TIER_COUNT - 1)]


static func tier_name(tier: int) -> String:
	return TIER_NAMES[clampi(tier, 0, TIER_COUNT - 1)]


## Returns Vector2(approach_seconds, inside_hole_seconds) before fade-out.
## Totals (with ~0.12s fade) stay ~0.25–0.45s for playable tiers.
static func collect_phase_times(tier: int) -> Vector2:
	var approach: Array[float] = [0.12, 0.14, 0.16, 0.18, 0.20, 0.22]
	var inside: Array[float] = [0.10, 0.12, 0.16, 0.20, 0.26, 0.30]
	var idx := clampi(tier, 0, TIER_COUNT - 1)
	return Vector2(approach[idx], inside[idx])


static func collect_duration(tier: int) -> float:
	var phases := collect_phase_times(tier)
	const FADE_TIME: float = 0.12
	return phases.x + phases.y + FADE_TIME


static func roll_tier(level: int, theme: int, rng: RandomNumberGenerator, mission_highlight: bool = false) -> int:
	var weights := _tier_weights_for_level(level, theme)
	if mission_highlight:
		# Mission clusters skew slightly smaller so goals stay reachable early.
		weights[0] *= 1.35
		weights[1] *= 1.25
		weights[4] *= 0.55
		weights[5] *= 0.35
	return _pick_weighted(weights, rng)


static func _tier_weights_for_level(level: int, theme: int) -> Array[float]:
	var difficulty := clampf(float(level - 1) / float(LevelTheme.MAX_LEVEL - 1), 0.0, 1.0)
	# Theme adds a small variance seed so each world feels different.
	var theme_shift := float(theme) * 0.04
	var w: Array[float] = [
		lerpf(38.0, 4.0, difficulty) + theme_shift,
		lerpf(36.0, 10.0, difficulty),
		lerpf(16.0, 22.0, difficulty),
		lerpf(7.0, 28.0, difficulty) - theme_shift,
		lerpf(2.5, 22.0, difficulty),
		lerpf(0.5, 16.0, difficulty),
	]
	return w


static func _pick_weighted(weights: Array[float], rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for w in weights:
		total += w
	if total <= 0.0:
		return Tier.SMALL
	var roll := rng.randf() * total
	var acc := 0.0
	for i in weights.size():
		acc += weights[i]
		if roll <= acc:
			return i
	return weights.size() - 1
