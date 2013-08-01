
###

# webkitSpeechRecognition asks for permission EVERY TIME unless run from SSL, so:

# 1) create a 100-year self-signed SSL cert for localhost:

openssl genrsa -passout pass:dummy -out snakeoil.secure.key 1024
openssl rsa -passin pass:dummy -in snakeoil.secure.key -out snakeoil.key
openssl req -new -subj "/commonName=localhost" -key snakeoil.key -out snakeoil.csr
openssl x509 -req -days 36500 -in snakeoil.csr -signkey snakeoil.key -out snakeoil.crt
rm snakeoil.secure.key snakeoil.csr

# 2) run with an SSL equivalent of 'python -m SimpleHTTPServer'

twistd --nodaemon web --path=. -c snakeoil.crt -k snakeoil.key --https=8443

# 3) open Chrome (Mac)

open -a "Google Chrome" --args --disable-web-security https://localhost:8443

###

google.setOnLoadCallback ->
  unless window.WebSocket
    alert('This app needs browser WebSocket support')
    return

  el  = (id)  -> document.getElementById(id)
  els = (sel) -> document.querySelectorAll(sel)
  w = (s) -> s.split(/\s+/)
  objsEq = (o1, o2 = {}) -> (return no if o2[k] isnt v) for own k, v of o1; yes
  objClone = (o1, o2 = {}) -> (o2[k] = v) for own k, v of o1; o2
  truncNum = (n, dp = 2) -> if typeof n is 'number' then parseFloat(n.toFixed(dp)) else n
  wrapDegs360 = (d) -> d += 360 while d <    0; d -= 360 while d >= 360; d
  wrapDegs180 = (d) -> d += 360 while d < -180; d -= 360 while d >= 180; d

  params =  # all these default params may be over-ridden in the query string
    startLat:      51.5035
    startLon:      -0.0742
    startHeading:  302       # degrees
    city:          "London"
    startAlt:      80       # metres above "sea level"
   
    minAlt:         5       # metres above "sea level"
    maxAlt:       400       # ditto
    speed:          4       # = when flying straight
    maxSpeed:       5       # = when diving
    cruiseTilt:    87       # degrees up from straight down
    diveSpeed:      0.15    # speed multiplier for diving (dive speed also a function of lean angle and general speed)
    diveAccel:      0.05    # rate at which diving increases general speed
    diveDecel:      0.1     # rate at which speed decreases again after levelling out
    flapSize:       1       # controls size of flap effect
    flapDecay:      0.8     # controls duration of flap effect
    maxRoll:       80       # max degrees left or right
    turnSpeed:      0.075   # controls how tight a turn is produced by a given roll
    status:         1       # show status bar with title, heading, altitude
    debugData:      0       # show debug data in status bar
    atmosphere:     1       # show atmosphere
    sun:            0       # show sun
    timeControl:    0       # show Google Earth time controller (if sun is 1)
    resetTimeout:  60       # seconds, after which to reset if no flight
    featureSkip:   12       # update features every n movement frames
    debugBox:       0       # show the box that determines visibility of features
    
    reconnectWait:  2       # seconds to wait between connection attempts
    ws:            'ws://127.0.0.1:8888/p5websocket'  # websocket URL of OpenNI-derived data feed
    
    leapOptions:    {enableGestures: true}
    timeStampDelta: 4
    enableLeap:     0
    leapOptions:    {enableGestures: true}
    rollMultiplier: 40

    geocodeSuffix:  ', london'
    beamLatOffset:  -0.0075


    features:      'air,rail,traffic,tide,twitter,olympics,misc'

  # Parse city so we can alter it using search string 

  for kvp in window.location.search.substring(1).split('&')
    [k, v] = kvp.split('=')
    params[k] = if k in ['ws', 'features', 'geocodeSuffix', 'city'] then v.toLowerCase() else parseFloat(v)  # ignore case
 
  if params.city is "leeds" 
    params.startLat = 53.79852807423503
    params.startLon = -1.5497589111328125
    params.startHeading = 12
    params.startAlt = 100 
    params.speed = 3  # Helen G feels sick flying around Leeds too fast!
    params.features += ',leeds'
    
  features = params.features.split(',')
  
  el('statusOuter').style.display = 'block' if params.status
  el('credit').style.display = 'none' if params.debugData
  
  [titleStatus, altStatus, debugDataStatus, debugEarthAPIStatus, debugTicksStatus, headingStatus] =
    (el(id) for id in w('title alt debugData debugEarthAPI debugTicks heading'))

  window.cam = cam = {}
  ge = seenCam = flown = animTimeout = fm = lastMove = null
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
  
  resetCam = (lat, lon, heading) ->
    cam.lat     = lat ? params.startLat
    cam.lon     = lon ? params.startLon
    cam.heading = heading ? params.startHeading
    cam.alt     = params.startAlt
    cam.roll    = 0.0000001  # a plain 0 is ignored
    cam.tilt    = params.cruiseTilt
    lastMove    = new Date()
    flown = no
  
  moveCam = ->
    camMoves += 1
    debugEarthAPIStatus.innerHTML = camMoves if params.debugData
    unmoved = objsEq(cam, seenCam)
    return no if unmoved
    
    lastMove = new Date()
    
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


  sprecListening = no

  sprStartSound = make tag: 'audio', src: 'http://www.stdimension.org/MediaLib/effects/technology/federation/commbadge.wav', preload: 'auto'
  sprBeamSound  = make tag: 'audio', src: 'http://www.stdimension.org/MediaLib/effects/technology/federation/beam1a.wav', preload: 'auto'

  areYouThereScotty = (recognition) ->
    console.log 'Speech recognition results: ', recognition
    result = recognition.results?[0]?[0]
    return unless result
    conf = result.confidence
    return unless result.confidence > 0.33
    transcript = result.transcript
    if transcript is 'u c l' then transcript = 'ucl'
    if transcript is 'home' then transcript = '80 tottenham court road'
    console.log 'Scotty heard: ', transcript
    baseURL = 'https://maps.googleapis.com/maps/api/geocode/json'
    load {url: "#{baseURL}?sensor=false&components=country:GB&address=#{encodeURIComponent transcript}#{params.geocodeSuffix}", type: 'json'}, beamMeUp

  beamMeUp = (geocoding) ->
    console.log 'Geocoding results: ', geocoding
    return unless geocoding.status is 'OK'
    loc = geocoding.results?[0]?.geometry?.location
    return unless loc
    sprBeamSound.play()
    {lat, lng} = loc
    lat += params.beamLatOffset
    console.log 'Beaming you to: ', lat, lng
    resetCam lat, lng, 0
    fm.reset()

  window.sprec = sprec = new webkitSpeechRecognition()
  sprec.lang = 'en-gb'

  sprec.onstart = (e) ->
    sprec.stop()
    sprec.onstart = null
  sprec.start()  # make permission bar appear on load (if at all)
  
  sprec.onresult = areYouThereScotty
  sprec.onerror = sprec.onnomatch = (e) -> console.log e


  updateCam = (data) ->
    if data.reset is 1 and not sprecListening
      sprecListening = yes
      sprStartSound.play()
      sprec.start()
      console.log 'sprec started'

    if data.reset isnt 1 and sprecListening
      sprecListening = no
      sprec.stop()
      console.log 'sprec stopped'

    if data.reset is 2
      window.location.reload()
    
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
    alt          = params.maxAlt if alt > params.maxAlt
    
    cam.lat     += latDelta
    cam.lon     += lonDelta
    cam.heading  = heading
    cam.alt      = alt
    cam.roll     = roll
    cam.tilt     = params.cruiseTilt - data.dive
  
  animTick = ->    
    debugTicksStatus.innerHTML = animTicks if params.debugData
    headingStatus.innerHTML    = compassPts[Math.round(wrapDegs360(cam.heading) / 45)]
    altStatus.innerHTML        = "#{Math.round(cam.alt)}m"
    
    moved = moveCam()
    
    if animTicks % params.featureSkip is 0
      if flown and new Date() - lastMove > params.resetTimeout * 1000
        resetCam()
        fm.reset()
      else
        fm.update()
    
    clearTimeout(animTimeout) if animTimeout?
    animTimeout = null
    unless moved  # can't rely on frameend event if no movement made
      animTimeout = setTimeout(animTick, 200)
    
    animTicks += 1
    
  leapMotion = ->
    if params.enableLeap
      console.log "Leap Called!"
      controller = new Leap.Controller params.leapOptions
      controller.loop (frame) ->
          if frame.hands.length is 1
             if frame.timestamp % params.timeStampDelta is 0
               roll = Math.atan2(frame.hands[0].palmNormal[0], -frame.hands[0].palmNormal[1])
               palmHeight =  frame.hands[0].palmPosition[1]
               heightDelta = Math.round adjustMapping(palmHeight, 0, 300, 0, 2)
               dive = 0
               flap = 0
               dive = 1 if heightDelta < 1
               flap = 1 if heightDelta > 1
               updateCam {"roll": roll * params.rollMultiplier, "flap": flap, "dive": dive}
          #if frame.gestures.length > 0
            #if frame.gestures[0].type == 'swipe'
              #console.log("going home");
              #updateCam({"reset": 1})

  adjustMapping = (value, r0, r1, r2, r3) ->
    mag = Math.abs(value - r0)
    sgn = if value < 0 then -1 else 1
    sgn * mag * (r3 - r2) / (r1 - r0)

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
    
    fm  = new FeatureManager(ge, lonRatio, cam, params)
    las = new LondonAirSet(fm)     if 'air'       in features
    tss = new TubeStationSet(fm)   if 'tube'      in features
    rss = new RailStationSet(fm)   if 'rail'      in features
    trs = new LondonTrafficSet(fm) if 'traffic'   in features
    tgs = new TideGaugeSet(fm)     if 'tide'      in features
    ccs = new MiscSet(fm)          if 'misc'      in features
    lts = new LondonTweetSet(fm)   if 'twitter'   in features
    ovs = new OlympicSet(fm)       if 'olympics'  in features and new Date("2012-08-12") - new Date() > 0
    lds = new LeedsCitySet(fm)     if 'leeds'     in features

    google.earth.addEventListener(ge, 'frameend', animTick)
    animTick()
    
    connect()
    leapMotion()

  google.earth.createInstance('earth', earthInitCallback, (errMsg) -> console.log("Google Earth error: #{errMsg}"))
    
google.load('earth', '1', {'other_params':'sensor=false'})

make = (opts = {}) -> 
  t = document.createElement opts.tag ? 'div'
  for own k, v of opts
    switch k
      when 'tag' then continue
      when 'parent' then v.appendChild t
      when 'kids' then t.appendChild c for c in v when c?
      when 'prevSib' then v.parentNode.insertBefore t, v.nextSibling
      when 'text' then t.appendChild text v
      when 'cls' then t.className = v
      else t[k] = v
  t
