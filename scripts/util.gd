extends Node

#returns min value in array
static func min_arr(var arr):
	var minVal = arr[0]
	for val in arr:
		if val < minVal:
			minVal = val
	return minVal

#returns centroid of polygon defined by array of points in form [[x1, y1,], [x2, y2], ...]
static func centroid(var points):
	var x = 0
	var y = 0
	for point in points:
		x += point[0]
		y += point[1]
	x /= float(points.size())
	y /= float(points.size())
	return Vector2(x, y)
#returns midpoint of 2 points, each formatted [x, y]
static func midpoint(var p1, var p2):
	return [(float(p1[0]) + p2[0]) / 2, (float(p1[1]) + p2[1]) / 2]
	
#returns true if v is within bounds = [v1, v2] (inclusive)
static func within(var v, var bounds):
	return (v >= bounds[0] and v <= bounds[1]) or (v >= bounds[1] and v <= bounds[0])

# returns merged polygon if successful, null otherwise
# WARNING: CAN FAIL ON POLYGONS WITH MORE THAN 2 SHARED POINTS
static func merge(var poly1, var poly2):
    poly1 = Array(poly1)
    poly2 = Array(poly2)

    #print(poly1)
    #print(poly2)
    var shared = commonPoints(poly1, poly2)
    var output = []
    # attempt merge if polygons adjacent
    if shared.size() >= 2:
        #start at index 0 of polygon 1, add points until first shared point, and then add that
        var curr = 0
        while not poly1[curr] in shared:
            var a = poly1[curr]
            var b = poly1.size()

            var a0 = poly1[0]
            var a1 = poly1[1]
            var a2 = poly1[2]
            var a3 = poly1[3]

            output.append(poly1[curr])
            curr += 1
        var share1 = poly1[curr]
        output.append(share1)

        #start at index of first shared point in polygon 2
        curr = poly2.find(share1)
        var direction = 1
        #if line would be drawn between 2 shared points, reverse direction of travel
        if poly2[nextIndex(poly2, curr, direction)] in shared:
            direction *= -1
        curr = nextIndex(poly2, curr, direction)

        #add points until second shared point, and then add that
        while not poly2[curr] in shared:
            output.append(poly2[curr])
            curr = nextIndex(poly2, curr, direction)

        var share2 = poly2[curr]
        output.append(share2)

        #go to index of second shared point in 2
        curr = poly1.find(share2)

        #if line would be drawn between 2 shared points, reverse direction of travel
        if poly1[nextIndex(poly1, curr, direction)] in shared:
            direction *= -1
        curr = nextIndex(poly1, curr, direction)

        #add points from polygon 1 until you return to the first added point (poly1[curr])
        while curr != 0:
            output.append(poly1[curr])
            curr = nextIndex(poly1, curr, direction)

        return output
    return null

static func nextIndex(poly, i, direction):
	#mod function seems to work differently in gdscript
	
	#return (i + direction) % poly.size()
	if i + direction < 0:
		return poly.size() + direction
	elif i + direction >= poly.size():
		return i + direction - poly.size()
	else:
		return i + direction
	
static func commonPoints(poly1, poly2):
	#if two triangles share 2 points, they are adjacent
	var points = []
	for p1 in poly1:
		for p2 in poly2:
			if p1 == p2:
				points.append(p1)
	return points

# gets the euclidian distance between two points
static func distance(pos1, pos2):
	return sqrt(pow((pos1[0] - pos2[0]), 2) + pow((pos1[1] - pos2[1]), 2))

#NOTE: not without errors (won't doesn't account for 4-point long contiguous parallel lines)
static func remove_redundant_points(var poly):
	#used in case there is redundant point from poly[-2] to poly[0] (two lines that could be merged into one)
	poly.append(poly[0])
	var output = []
	var i = 0
	while i < poly.size() - 2:
		var vector1 = poly[i + 1] - poly[i]
		var vector2 = poly[i + 2] - poly[i + 1]
		var angle = vector1.angle_to(vector2)
		output.append(poly[i])
		if angle == 0:
			#output.append(poly[i + 2])
			i += 2
		else:
			i += 1
	output.append(poly[i])
	return output

#TODO: predict where bullet will be in specified delta
static func predict_location(var pos, var direction, var speed, var delta):
	var increment = direction * speed * delta
	return Vector2(pos[0] + increment[0], pos[1] + increment[1])
	
static func predict_navigator_location(var navigator, var delta):
	return predict_location(navigator.get_global_pos(), navigator.velocity.normalized(), navigator.speed, delta)

static func predict_bullet_location(var bullet, var delta):
	return predict_location(bullet.get_global_pos(), bullet.direction, bullet.speed, delta)
	
#returns closest object in objs to pos
static func get_closest_object(var pos, var objs):
	if objs.size() == 0:
		return null
		
	var minDist = pos.distance_to(objs[0].get_global_pos())
	var closest = objs[0]
	for i in range(1, objs.size()):
		var obj = objs[i]
		var dist = pos.distance_to(obj.get_global_pos())
		if dist < minDist:
			minDist = dist
			closest = obj
	return closest
	
static func get_closest_object_within_radius(var pos, var objs, var radius):
	if objs.size() == 0:
		return null

	var minDist = global.inf
	var closest = null
	
	for obj in objs:
		var dist = pos.distance_to(obj.get_global_pos())
		if dist < minDist and dist < radius:
			minDist = dist
			closest = obj
	return closest

static func get_objects_within_radius(var pos, var objs, var radius):
	var output = []
	for obj in objs:
		if obj.get_global_pos().distance_to(pos) < radius:
			output.append(obj)
	return output

#rotates point around origin by specified radians (rads)
static func rotate(var pos, var rads):
	var output = Vector2()
	output.x = pos.x * cos(rads) - pos.y * sin(rads)
	output.y = pos.x * sin(rads) + pos.y * cos(rads)
	return output
	
static func rotate_around_point(var pos, var rads, var point):
	var output = pos - point
	output = rotate(output, rads)
	return output + point

#returns agent with lowest health percentage (0 health agents excluded)
static func weakest_agent(var agents):
	if agents == null:
		return null
	
	var minHealth = 1.1
	var weakest = null
	for agent in agents:
		var ratio = float(agent.hp) / agent.max_hp
		if ratio < minHealth and agent.hp != 0:
			minHealth = ratio
			weakest = agent
	return weakest