
google.load 'earth', '1.x'

window.onload = ->
  unless window.WebSocket
    alert('This app needs browser WebSocket support')
    return
  
  el = (id) -> document.getElementById(id)
  w = (s) -> s.split(/\s+/)
  objsEq = (o1, o2 = {}) -> (return no if o2[k] isnt v) for own k, v of o1; yes
  objClone = (o1, o2 = {}) -> (o2[k] = v) for own k, v of o1; o2
  truncNum = (n, dp = 2) -> if typeof n is 'number' then parseFloat(n.toFixed(dp)) else n
  wrapDegs360 = (d) -> d += 360 while d <    0; d -= 360 while d >= 360; d
  wrapDegs180 = (d) -> d += 360 while d < -180; d -= 360 while d >= 180; d
  
  params =  # all these default params may be over-ridden in the query string
    startLat:      51.520113
    startLon:      -0.130956
    startHeading:  55       # degrees
    startAlt:      80       # metres above "sea level"

    minAlt:         5       # metres above "sea level"
    speed:          3       # = when flying straight
    maxSpeed:       6       # = when diving
    cruiseTilt:    85       # degrees up from straight down
    diveSpeed:      0.15    # speed multiplier for diving (dive speed also a function of lean angle and general speed)
    diveAccel:      0.05    # rate at which diving increases general speed
    diveDecel:      0.05    # rate at which speed decreases again after levelling out
    flapSize:       1       # controls size of flap effect
    flapDecay:      0.8     # controls duration of flap effect
    maxRoll:       80       # max degrees left or right
    turnSpeed:      0.075   # controls how tight a turn is produced by a given roll
    status:         1       # show status bar with title, heading, altitude
    debugData:      0       # show debug data in status bar
    atmosphere:     1       # show atmosphere
    sun:            0       # show sun
    timeControl:    0       # show Google Earth time controller (if sun is 1)
    
    reconnectWait:  2       # seconds to wait between connection attempts
    ws:            'ws://127.0.0.1:8888/p5websocket'  # websocket URL of OpenNI-derived data feed
    
  for kvp in window.location.search.substring(1).split('&')
    [k, v] = kvp.split('=')
    params[k] = if k is 'ws' then v else parseFloat(v)
  
  el('statusOuter').style.display = 'block' if params.status
  el('credit').style.display = 'none' if params.debugData
  
  [titleStatus, altStatus, debugDataStatus, debugEarthAPIStatus, debugTicksStatus, headingStatus] =
    (el(id) for id in w('title alt debugData debugEarthAPI debugTicks heading'))

  ge = cam = seenCam = flown = animTimeout = null
  animTicks = camMoves = inMsgs = 0
  lastFlap = flapAmount = 0
  
  pi          = Math.PI
  twoPi       = pi * 2
  piOver180   = pi / 180
  compassPts  = w('N NE E SE S SW W NW N')
  
  speed       = params.speed
  latFactor   = 0.00001
  lonRatio    = 1 / Math.cos(params.startLat * piOver180)
  lonFactor   = latFactor * lonRatio
  
  resetCam = ->
    cam = 
      lat:      params.startLat
      lon:      params.startLon
      heading:  params.startHeading
      alt:      params.startAlt
      roll:     0.0000001  # a plain 0 is ignored
      tilt:     params.cruiseTilt
    flown = no
  
  moveCam = ->
    camMoves += 1
    debugEarthAPIStatus.innerHTML = camMoves if params.debugData
    unmoved = objsEq(cam, seenCam)
    return no if unmoved
    view = ge.getView()
    c = view.copyAsCamera(ge.ALTITUDE_ABSOLUTE)
    c.setLatitude(cam.lat)
    c.setLongitude(cam.lon)
    c.setAltitude(cam.alt)
    c.setHeading(cam.heading)
    c.setTilt(cam.tilt)
    c.setRoll(cam.roll)
    view.setAbstractView(c)
    seenCam = objClone(cam)
    debugEarthAPIStatus.innerHTML +=  ' ' + JSON.stringify(cam, (k, v) -> truncNum(v)) if params.debugData
    yes
  
  addLayers = (layers...) -> ge.getLayerRoot().enableLayerById(l, yes) for l in layers

  updateCam = (data) ->
    resetCam() if data.reset and flown
    return unless data.roll?
    
    flown        = yes  # since last resetCam()
    altDelta     = 0
    
    if data.dive > 0
      altDelta   = - data.dive * params.diveSpeed * speed
      speed     += data.dive * params.diveAccel
      speed      = params.maxSpeed if speed > params.maxSpeed  # TODO: max should depend on angle of dive?
    else
      speed     -= params.diveDecel
      speed      = params.speed if speed < params.speed
    
    flapDiff     = data.flap - lastFlap
    flapAmount  += params.flapSize * flapDiff if flapDiff > 0
    altDelta    += flapAmount if flapAmount > 0
    flapAmount  *= params.flapDecay
    lastFlap     = data.flap
    
    roll         = data.roll
    roll         =   params.maxRoll if roll >   params.maxRoll
    roll         = - params.maxRoll if roll < - params.maxRoll
    
    headingDelta = - roll * params.turnSpeed
    heading      = wrapDegs360(cam.heading + headingDelta)
    
    headingRad   = heading * piOver180
    latDelta     = Math.cos(headingRad) * speed * latFactor
    lonDelta     = Math.sin(headingRad) * speed * lonFactor
    
    alt          = cam.alt + altDelta
    alt          = params.minAlt if alt < params.minAlt
    
    cam.lat     += latDelta
    cam.lon     += lonDelta
    cam.heading  = heading
    cam.alt      = alt
    cam.roll     = roll
    cam.tilt     = params.cruiseTilt - data.dive
  
  animTick = ->
    animTicks += 1
    debugTicksStatus.innerHTML = animTicks if params.debugData
    headingStatus.innerHTML    = compassPts[Math.round(wrapDegs360(cam.heading) / 45)]
    altStatus.innerHTML        = "#{Math.round(cam.alt)}m"
    
    moved = moveCam()
    
    clearTimeout(animTimeout) if animTimeout?
    animTimeout = null
    unless moved  # can't rely on frameend event if no movement made
      animTimeout = setTimeout(animTick, 200)
  
  connect = ->
    ws = new WebSocket(params.ws)
    titleStatus.style.color = '#ff0'                      # yellow when connecting
    ws.onopen = -> 
      titleStatus.style.color = '#fff'                    # white when connected
      ge.getNavigationControl().setVisibility(ge.VISIBILITY_HIDE)
    ws.onclose = ->
      titleStatus.style.color = '#f00'                    # red when disconnected
      setTimeout(connect, params.reconnectWait * 1000)
      ge.getNavigationControl().setVisibility(ge.VISIBILITY_AUTO)
    ws.onmessage = (e) ->
      inMsgs += 1
      data = JSON.parse(e.data)
      debugDataStatus.innerHTML = "#{inMsgs} #{JSON.stringify(data, (k, v) -> truncNum(v))}" if params.debugData
      updateCam(data)
  
  earthInitCallback = (instance) ->
    window.ge = ge = instance
    console.log("Google Earth plugin v#{ge.getPluginVersion()}, API v#{ge.getApiVersion()}")
    addLayers(ge.LAYER_TERRAIN, ge.LAYER_TREES, ge.LAYER_BUILDINGS, ge.LAYER_BUILDINGS_LOW_RESOLUTION)
    ge.getOptions().setAtmosphereVisibility(params.atmosphere)
    ge.getSun().setVisibility(params.sun)
    ge.getTime().getControl().setVisibility(if params.timeControl then ge.VISIBILITY_SHOW else ge.VISIBILITY_HIDE)
    ge.getOptions().setFlyToSpeed(ge.SPEED_TELEPORT)
    resetCam()
    ge.getWindow().setVisibility(yes)
    animTick()
    google.earth.addEventListener(ge, 'frameend', animTick)
    
    s = new SkyText(51.52120111222482, -0.12885332107543945, 140)
    s.line('CASA Smart Cities', bearing: -params.startHeading, size: 3, lineWidth: 3)
    s.line('Next session: Steve Gray', bearing: -params.startHeading, size: 2, lineWidth: 2)    
    ge.getFeatures().appendChild(ge.parseKml(s.kml()))
    
    s = new SkyText(51.52038666343198, -0.13435721397399902, 140)
    s.line('ø Goodge Street', bearing: params.startHeading, size: 3, lineWidth: 3)
    s.line('W  West Ruislip  2 mins',  bearing: params.startHeading, size: 2, lineWidth: 2)
    s.line('E  Hainault via Newbury Park  due', bearing: params.startHeading, size: 2, lineWidth: 2)   
    ge.getFeatures().appendChild(ge.parseKml(s.kml()))
    
    connect()
  
  google.earth.createInstance('earth', earthInitCallback, -> console.log("Google Earth error: #{errorCode}"))
    