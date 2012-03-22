
google.load 'earth', '1.x'

window.onload = ->
  unless window.WebSocket
    alert('This app needs browser WebSocket support')
    return
  
  params = 
    startLat:      51.520113
    startLon:      -0.130956
    startHeading:  55       # degrees
    startAlt:      80       # metres above "sea level"
    speed:          4       # = when flying straight
    maxSpeed:      10       # = when diving
    diveThreshold:  1.5     # degrees -- don't start diving until leaning forward this much
    diveSpeed:      0.1     # speed multiplier for diving (dive speed also a function of lean angle and general speed)
    diveAccel:      0.05    # rate at which diving increases general speed
    diveDecel:      0.025   # rate at which speed decreases again after levelling out
    flapSize:       2       # controls size of flap effect
    flapDecay:      0.8     # controls duration of flap effect
    maxRoll:       80       # max degrees left or right
    turnSpeed:      0.075   # controls how tight a turn is produced by a given roll
    credits:        0
    ws:            "ws://127.0.0.1:8888/p5websocket"
    
  wls = window.location.search
  for kvp in wls.substring(1).split('&')
    [k, v] = kvp.split('=')
    params[k] = if k is 'ws' then v else parseFloat(v)
    
  document.getElementById('creditOuter').show() if params.credits
  
  ge = flown = null  # scoping
  
  pi          = Math.PI
  twoPi       = pi * 2
  piOver180   = pi / 180
  
  speedFactor = 0.00001
  lonFactor   = 1 / Math.cos(params.startLat * piOver180)
  
  latFactor = speedFactor
  lonFactor = speedFactor * lonFactor
  
  moveCam = (o = {}) ->
    c = ge.getView().copyAsCamera(ge.ALTITUDE_ABSOLUTE)
    
    c.setLatitude(o.lat) if o.lat
    c.setLongitude(o.lon) if o.lon
    c.setAltitude(o.alt) if o.alt
    c.setHeading(o.heading) if o.heading
    c.setTilt(o.tilt) if o.tilt
    c.setRoll(o.roll) if o.roll
    
    c.setLatitude(c.getLatitude() + o.latDelta) if o.latDelta
    c.setLongitude(c.getLongitude() + o.lonDelta) if o.lonDelta
    c.setAltitude(c.getAltitude() + o.altDelta) if o.altDelta
    c.setHeading(c.getHeading() + o.headingDelta) if o.headingDelta
    c.setTilt(c.getTilt() + o.tiltDelta) if o.tiltDelta
    c.setRoll(c.getRoll() + o.rollDelta) if o.rollDelta
    
    ge.getOptions().setFlyToSpeed(o.speed) if o.speed
    ge.getView().setAbstractView(c)
  
  addLayers = (layers...) -> ge.getLayerRoot().enableLayerById(l, yes) for l in layers
  
  goToStart = ->
    flown = no
    moveCam(
      lat:     params.startLat
      lon:     params.startLon
      heading: params.startHeading
      alt:     params.startAlt
      tilt:    90
      roll:    0.0000001  # a plain 0 is ignored
      speed:   4.5        # fast but not teleport
    )
    
  speed = params.speed
  lastFlap = flapAmount = 0

  tick = ->    
    if data.reset && flown
      goToStart()
  
    altDelta = tilt = 0
    if data.dive and data.dive > params.diveThreshold
      dive = data.dive - params.diveThreshold
      altDelta = - dive * params.diveSpeed * speed
      tilt = 90 - dive
      speed += dive * params.diveAccel
      speed = params.maxSpeed if speed > params.maxSpeed  # TODO: max should depend on angle of dive?
    
    else
      speed -= params.diveAccel
      speed = params.speed if speed < params.speed
    
    if data.flap
      flapDiff = data.flap - lastFlap
      flapAmount += params.flapSize * flapDiff if flapDiff > 0
      lastFlap = data.flap
    
    altDelta += flapAmount if flapAmount > 0
    flapAmount *= params.flapDecay
    
    if data.roll
      flown = yes
    
      roll = data.roll
      roll =   params.maxRoll if roll >   params.maxRoll
      roll = - params.maxRoll if roll < - params.maxRoll
    
      rollRad = roll * piOver180
      heading = ge.getView().copyAsCamera(ge.ALTITUDE_ABSOLUTE).getHeading()
      headingDelta = - roll * params.turnSpeed
      headingRad = heading * piOver180      
    
      latDelta = Math.cos(headingRad) * speed * latFactor
      lonDelta = Math.sin(headingRad) * speed * lonFactor
    
      moveCam({altDelta, tilt, latDelta, lonDelta, headingDelta, roll, speed: ge.SPEED_TELEPORT})  

  data = {}  # scoping
  connect = ->
    reconnectDelay = 2
    ws = new WebSocket(params.ws)
    ws.onopen = -> console.log('Connected')
    ws.onclose = ->
      console.log("Disconnected: retrying in #{reconnectDelay}s")
      setTimeout(connect, reconnectDelay * 1000)
    ws.onmessage = (e) -> data = JSON.parse(e.data)
    
  connect()
  
  earthInitCallback = (instance) ->
    window.ge = ge = instance
    console.log("Google Earth plugin v#{ge.getPluginVersion()}, API v#{ge.getApiVersion()}")
    addLayers(ge.LAYER_TERRAIN, ge.LAYER_TREES, ge.LAYER_BUILDINGS, ge.LAYER_BUILDINGS_LOW_RESOLUTION)
    goToStart()
    ge.getOptions().setStatusBarVisibility(yes)
    ge.getOptions().setAtmosphereVisibility(yes)
    ge.getSun().setVisibility(yes)
    ge.getTime().getControl().setVisibility(ge.VISIBILITY_HIDE)
    ge.getWindow().setVisibility(yes)
    google.earth.addEventListener(ge, 'frameend', tick)

  google.earth.createInstance('earth', earthInitCallback, -> alert("Google Earth error: #{errorCode}"))
  
