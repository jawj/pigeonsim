
google.load 'earth', '1.x'

window.onload = ->
  unless window.WebSocket
    alert('This app needs browser WebSocket support')
    return
  
  el = (id) -> document.getElementById(id)
  truncNum = (n, dp = 2) -> if typeof n is 'number' then parseFloat(n.toFixed(dp)) else n
  wrapDegs360 = (d) -> d += 360 while d <    0; d -= 360 while d >= 360; d
  wrapDegs180 = (d) -> d += 360 while d < -180; d -= 360 while d >= 180; d
  
  params = 
    startLat:      51.520113
    startLon:      -0.130956
    startHeading:  55       # degrees
    startAlt:      80       # metres above "sea level"
    speed:          4       # = when flying straight
    maxSpeed:      10       # = when diving
    diveSpeed:      0.15    # speed multiplier for diving (dive speed also a function of lean angle and general speed)
    diveAccel:      0.05    # rate at which diving increases general speed
    diveDecel:      0.025   # rate at which speed decreases again after levelling out
    flapSize:       2       # controls size of flap effect
    flapDecay:      0.8     # controls duration of flap effect
    maxRoll:       80       # max degrees left or right
    turnSpeed:      0.075   # controls how tight a turn is produced by a given roll
    credits:        0       # show credits at bottom
    status:         1       # show status bar with title, heading, altitude
    geStatusBar:    0       # show Google Earth plugin's own status bar at bottom
    geTimeCtrl:     0       # show Google Earth time controller
    debugData:      0       # show debug data in status bar
    reconnectWait:  1       # seconds to wait between connection attempts
    ws:            'ws://127.0.0.1:8888/p5websocket'
    
  wls = window.location.search
  for kvp in wls.substring(1).split('&')
    [k, v] = kvp.split('=')
    params[k] = if k is 'ws' then v else parseFloat(v)
  
  el('creditOuter').style.display = 'block' if params.credits
  el('statusOuter').style.display = 'block' if params.status
  
  titleStatus         = el('title')
  altStatus           = el('alt')
  debugDataStatus     = el('debugData')
  debugEarthAPIStatus = el('debugEarthAPI')
  debugTicksStatus    = el('debugTicks')
  headingStatus       = el('heading')

  ge = flown = null  # scoping
  
  pi          = Math.PI
  twoPi       = pi * 2
  piOver180   = pi / 180
  compassPts  = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N']
  
  speedFactor = 0.00001
  lonFactor   = 1 / Math.cos(params.startLat * piOver180)
  
  latFactor = speedFactor
  lonFactor = speedFactor * lonFactor
  
  apiSent = 0
  
  moveCam = (o = {}) ->
    apiSent += 1
    debugEarthAPIStatus.innerHTML = "#{apiSent} #{JSON.stringify(o, (k, v) -> truncNum(v))}" if params.debugData
    c = ge.getView().copyAsCamera(ge.ALTITUDE_ABSOLUTE)
    
    # absolute
    c.setLatitude(o.lat) if o.lat
    c.setLongitude(o.lon) if o.lon
    c.setAltitude(o.alt) if o.alt
    c.setHeading(o.heading) if o.heading
    c.setTilt(o.tilt) if o.tilt
    c.setRoll(o.roll) if o.roll
    
    # relative (deltas)
    c.setLatitude(c.getLatitude() + o.latDelta) if o.latDelta
    c.setLongitude(c.getLongitude() + o.lonDelta) if o.lonDelta
    c.setAltitude(c.getAltitude() + o.altDelta) if o.altDelta
    c.setHeading(c.getHeading() + o.headingDelta) if o.headingDelta
    c.setTilt(c.getTilt() + o.tiltDelta) if o.tiltDelta
    c.setRoll(c.getRoll() + o.rollDelta) if o.rollDelta
    
    ge.getOptions().setFlyToSpeed(o.speed) if o.speed
    ge.getView().setAbstractView(c)
  
  addLayers = (layers...) -> ge.getLayerRoot().enableLayerById(l, yes) for l in layers
  
  goToStart = (speed = ge.SPEED_TELEPORT) ->
    flown = no
    moveCam(
      lat:     params.startLat
      lon:     params.startLon
      heading: params.startHeading
      alt:     params.startAlt
      tilt:    90
      roll:    0.0000001  # a plain 0 is ignored
      speed:   speed
    )
  
  speed = params.speed
  lastFlap = flapAmount = tickNum = 0
  fallbackTimeout = null
  
  tick = ->
    clearTimeout(fallbackTimeout)
    
    tickNum += 1
    debugTicksStatus.innerHTML = tickNum if params.debugData
    
    view       = ge.getView().copyAsCamera(ge.ALTITUDE_ABSOLUTE)
    oldHeading = view.getHeading()
    oldAlt     = view.getAltitude()
    
    headingStatus.innerHTML = compassPts[Math.round(wrapDegs360(oldHeading) / 45)]
    altStatus.innerHTML     = "#{Math.round(oldAlt)}m"

    goToStart(4.5) if data.reset and flown
    
    if data.roll?
      flown = yes  # since last goToStart()
      
      dive = data.dive
      altDelta = tilt = 0
      if dive > 0
        altDelta = - dive * params.diveSpeed * speed
        tilt = 90 - dive
        speed += dive * params.diveAccel
        speed = params.maxSpeed if speed > params.maxSpeed  # TODO: max should depend on angle of dive?
      else
        speed -= params.diveDecel
        speed = params.speed if speed < params.speed
      
      # TODO -- flap calculations need to occur in response to data receipt, since this is more frequent than animation ticking
      
      flapDiff = data.flap - lastFlap
      flapAmount += params.flapSize * flapDiff if flapDiff > 0
      altDelta += flapAmount if flapAmount > 0
      flapAmount *= params.flapDecay
      lastFlap = data.flap
      
      roll = data.roll
      roll =   params.maxRoll if roll >   params.maxRoll
      roll = - params.maxRoll if roll < - params.maxRoll
      rollRad = roll * piOver180
      
      headingDelta = - roll * params.turnSpeed
      heading = oldHeading + headingDelta
      headingRad = heading * piOver180
      
      latDelta = Math.cos(headingRad) * speed * latFactor
      lonDelta = Math.sin(headingRad) * speed * lonFactor
      
      alt = oldAlt + altDelta
      
      moveCam({alt, tilt, latDelta, lonDelta, heading, roll, speed: ge.SPEED_TELEPORT})
   
    else
      fallbackTimeout = setTimeout(tick, 200)  # for if there are no frameends
  
  data = {}  # scoping
  connect = ->
    received = 0
    ws = new WebSocket(params.ws)
    ws.onopen = -> titleStatus.style.color = '#fff'
    ws.onclose = ->
      titleStatus.style.color = '#f00'
      setTimeout(connect, params.reconnectWait * 1000)
    ws.onmessage = (e) ->
      received += 1
      data = JSON.parse(e.data)
      debugDataStatus.innerHTML = "#{received} #{JSON.stringify(data, (k, v) -> truncNum(v))}" if params.debugData
    
  connect()
  
  earthInitCallback = (instance) ->
    window.ge = ge = instance
    console.log("Google Earth plugin v#{ge.getPluginVersion()}, API v#{ge.getApiVersion()}")
    addLayers(ge.LAYER_TERRAIN, ge.LAYER_TREES, ge.LAYER_BUILDINGS, ge.LAYER_BUILDINGS_LOW_RESOLUTION)
    goToStart()
    ge.getOptions().setAtmosphereVisibility(yes)
    ge.getSun().setVisibility(yes)
    ge.getOptions().setStatusBarVisibility(params.geStatusBar)
    ge.getTime().getControl().setVisibility(if params.geTimeCtrl then ge.VISIBILITY_SHOW else ge.VISIBILITY_HIDE)
    ge.getWindow().setVisibility(yes)
    google.earth.addEventListener(ge, 'frameend', tick)
  
  google.earth.createInstance('earth', earthInitCallback, -> console.log("Google Earth error: #{errorCode}"))
  
