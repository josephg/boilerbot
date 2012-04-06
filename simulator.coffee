fill = (initial_squares, f) ->
	visited = {}
	visited[[x,y]] = true for {x, y} in initial_squares
	to_explore = initial_squares.slice()
	hmm = (x,y, from_x, from_y) ->
		if not visited[[x,y]]
			visited[[x,y]] = true
			to_explore.push {x,y,from_x,from_y}
	while n = to_explore.shift()
		ok = f n.x, n.y, n.from_x, n.from_y
		if ok
			hmm n.x+1, n.y, 1, 0
			hmm n.x-1, n.y,-1, 0
			hmm n.x, n.y+1, 0, 1
			hmm n.x, n.y-1, 0,-1
	return

class Simulator
  constructor: ->
    @grid = {}
    @engines = {}
    @delta = {}

  set: (x, y, v) ->
    if v?
      @grid[[x,y]] = v
      @delta[[x,y]] = v
      if v in ['positive', 'negative']
        @engines[[x,y]] = {x,y}
    else
      if @grid[[x,y]] in ['positive', 'negative']
        delete @engines[[x,y]]
      delete @grid[[x,y]]
      @delta[[x,y]] = null
  get: (x,y) -> @grid[[x,y]]

  tryMove: (points, dx, dy) ->
    dx = if dx < 0 then -1 else if dx > 0 then 1 else 0
    dy = if dy < 0 then -1 else if dy > 0 then 1 else 0
    throw new Error('one at a time, fellas') if dx and dy
    return unless dx or dy
    for {x,y} in points
      if @get(x+dx, y+dy) not in ['nothing', 'shuttle', 'thinshuttle']
        return false

    shuttle = {}
    for {x,y} in points
      shuttle[[x,y]] = @get x, y
      @set x, y, 'nothing'
    for {x,y} in points
      @set x+dx, y+dy, shuttle[[x,y]]

    true

  step: ->
    pressure = {}

    shuttleMap = {}
    shuttles = []
    getShuttle = (x, y) =>
      return null unless @get(x, y) in ['shuttle', 'thinshuttle']
      s = shuttleMap[[x,y]]
      return s if s

      shuttles.push (s = {points:[], force:{x:0,y:0}})

      # Flood fill the shuttle
      fill [{x,y}], (x, y) =>
        if @get(x, y) in ['shuttle', 'thinshuttle']
          shuttleMap[[x,y]] = s
          s.points.push {x,y}
          true
        else
          false

      s

    for k,v of @engines
      direction = if 'positive' is @get v.x, v.y then 1 else -1
      fill [v], (x, y, dx, dy) =>
        cell = @get x, y
        switch cell
          when 'positive', 'negative'
            true
          when 'shuttle'
            s = getShuttle x, y
            s.force.x += dx * direction
            s.force.y += dy * direction
            false
          when 'nothing', 'thinshuttle', 'thinsolid'
            pressure[[x,y]] = (pressure[[x,y]] ? 0) + direction
            true
          else
            false

    #console.log pressure, shuttles, @engines

    for {points, force} in shuttles
      movedX = @tryMove points, force.x, 0
      @tryMove points, 0, force.y unless movedX

    thisDelta = @delta
    @delta = {}

    thisDelta


module.exports = Simulator