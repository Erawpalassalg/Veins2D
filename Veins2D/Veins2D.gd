tool
extends Polygon2D

export var spacing: int = 7
export var minimum_distance: float = spacing/3.0
export var movement: float = 1.5 setget set_movement, get_movement
export var random_factor: Vector2 = Vector2(-1, 1)

export var petiole: Vector2 setget set_petiole, get_petiole
export var veins_color: Color = Color.black setget set_veins_color, get_veins_color

var living_points: PoolIntArray
var paths: Dictionary

func _calculate_veins():
	living_points = PoolIntArray([0])
	paths = {0: PoolVector2Array([petiole])}
	
	var minimum: Vector2
	var maximum: Vector2
	var current_point: Vector2
	
	# Calculate min and max
	for point in polygon:
		if not minimum:
			minimum = point
			maximum = point
			continue
		
		minimum.x = min(minimum.x, point.x)
		minimum.y = min(minimum.y, point.y)
		maximum.x = max(maximum.x, point.x)
		maximum.y = max(maximum.y, point.y)
	
	# Build the initial grid and initialize the paths
	current_point = minimum
	while current_point.y < maximum.y:
		while current_point.x < maximum.x:
			if _point_is_in(current_point):
				var id = len(paths)
				living_points.append(id)
				paths[id] = [current_point + Vector2(rand_range(random_factor.x, random_factor.y), rand_range(random_factor.x, random_factor.y))]
			current_point.x += spacing
		current_point.y += spacing
		current_point.x = minimum.x
	
	# Make the veins paths
	while len(living_points) > 1:
		
		var i = 0
		var point_id
		while i < len(living_points):
			point_id = living_points[i]
			
			# Don't move the petiole
			if point_id == 0:
				i += 1
				continue
			
			var nn_data: Dictionary = _nearest_neighbor(point_id)
			
			# If too close to its neighbor, move to it and remove the node
			if nn_data.distance < minimum_distance:
				paths[point_id].append(paths[nn_data.id][-1])
				living_points.remove(i)
				continue
			
			# Move to the nearest neighbor and the petiole at the same time
			var nearest_neighbor: Vector2 = paths[nn_data.id][-1]
			var temp: Vector2
			for target in [petiole, nearest_neighbor]:
				var dir = paths[point_id][-1] - target
				var mov = dir.clamped(movement)
				if not temp:
					temp = paths[point_id][-1] - mov
				else:
					paths[point_id].append(temp - mov)
			
			i +=1
	paths.erase(0)

func _draw():
	_calculate_veins()
	for path in paths.values():
		draw_polyline(path, veins_color)

func _position(edge0: Vector2, edge1: Vector2, point: Vector2) -> float:
	# > 0 left, = 0 on, < 0 right
	return (edge1.x - edge0.x) * (point.y - edge0.y) - (point.x - edge0.x) * (edge1.y - edge0.y)

func _point_is_in(point: Vector2) -> bool:
	# See geomalgorithms.com/a03-_inclusion.html
	var wn: int = 0
	
	for i in range(len(polygon)):
		var v0: Vector2 = polygon[i]
		var v1: Vector2
		if i == len(polygon) - 1:
			v1 = polygon[0]
		else:
			v1 = polygon[i+1]
		
		if v0.y <= point.y:
			if v1.y > point.y:
				if _position(v0, v1, point) > 0:
					wn += 1
		else:
			if v1.y <= point.y:
				if _position(v0, v1, point) < 0:
					wn -= 1
	
	return wn != 0

func _nearest_neighbor(point_id: int) -> Dictionary:
	var point: Vector2 = paths[point_id][-1]
	var nearest: int
	var distance: float
	
	for id in living_points:
		if id == point_id:
			continue
		
		var dist = point.distance_to(paths[id][-1])
		if not distance or dist < distance:
			distance = dist
			nearest = id
			continue
	return {"id": nearest, "distance": distance}

# --- Setter and getters
func set_petiole(point: Vector2) -> void:
	petiole = point
	update()

func get_petiole() -> Vector2:
	return petiole

func set_veins_color(color: Color) -> void:
	veins_color = color
	update()

func get_veins_color() -> Color:
	return veins_color

func set_movement(value: float) -> void:
	# Shouldn't be higher than minimum_distance, otherwise the program crashes
	if movement <= minimum_distance:
		movement = value
		update()

func get_movement() -> float:
	return movement
