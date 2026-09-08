extends RefCounted

## Capsule / camera pivot from body.height + weight + proportions.

const MIN_HEIGHT := 0.9
const MAX_HEIGHT := 2.15
const MIN_RADIUS := 0.22
const MAX_RADIUS := 0.55


static func preview_scale(body: Dictionary) -> Vector3:
	var height := clampf(float(body.get("height", 0.5)), 0.0, 1.0)
	var weight := clampf(float(body.get("weight", 0.5)), 0.0, 1.0)
	var props: Dictionary = body.get("proportions", {})
	var torso := clampf(float(props.get("torso", 0.5)), 0.0, 1.0)
	var y := lerpf(0.72, 1.28, height)
	var xz := lerpf(0.82, 1.22, weight) * lerpf(0.94, 1.08, torso)
	return Vector3(xz, y, xz)


static func capsule_height(body: Dictionary) -> float:
	return lerpf(MIN_HEIGHT, MAX_HEIGHT, clampf(float(body.get("height", 0.5)), 0.0, 1.0))


static func capsule_radius(body: Dictionary) -> float:
	var weight := clampf(float(body.get("weight", 0.5)), 0.0, 1.0)
	return lerpf(MIN_RADIUS, MAX_RADIUS, weight)


static func camera_pivot_height(body: Dictionary) -> float:
	return capsule_height(body) * 0.72
