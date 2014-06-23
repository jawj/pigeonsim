window.load = load = (opts, callback) ->
  url = opts.url
  opts.method ?= 'GET'
  if opts.search?
    kvps = ("#{escape(k)}=#{escape(v)}" for own k, v of opts.search)
    url += '?' + kvps.join('&')
  xhr = new XMLHttpRequest()
  xhr.overrideMimeType('text/xml') if opts.type is 'xml'
  xhr.onreadystatechange = ->
    if xhr.readyState is 4
      obj = if opts.type is 'json' then JSON.parse(xhr.responseText)
      else if opts.type is 'xml' then xhr.responseXML
      else xhr.responseText
      callback(obj)
  xhr.open(opts.method, url, yes)
  xhr.send(opts.data)

mergeObj = (o1, o2) ->
  (o1[k] = v) for own k, v of o2
  o1

oneEightyOverPi = 180 / Math.PI
box = null

class @FeatureManager
  constructor: (@ge, @lonRatio, @cam, @params) ->
    @featureTree = new RTree()
    @visibleFeatures = {}
    @updateMoment = 0
    
  addFeature: (f) ->
    f.fm = @
    @featureTree.insert(f.rect(), f)
    
  removeFeature: (f) ->
    @hideFeature(f)
    @featureTree.remove(f.rect(), f)
    delete f.fm
  
  showFeature: (f) ->
    return no if @visibleFeatures[f.id]?
    @visibleFeatures[f.id] = f
    f.show()
    return yes
  
  hideFeature: (f) ->
    return no unless @visibleFeatures[f.id]?
    delete @visibleFeatures[f.id]
    f.hide()
    return yes
  
  featuresInBBox: (lat1, lon1, lat2, lon2) ->  # ones must be SW of (i.e. lower than) twos
    @featureTree.search({x: lon1, y: lat1, w: lon2 - lon1, h: lat2 - lat1})
  
  reset: ->
    @hideFeature(f) for own id, f of @visibleFeatures
    @update()
  
  update: ->
    cam = @cam
    lookAt = @ge.getView().copyAsLookAt(ge.ALTITUDE_ABSOLUTE)
    lookLat = lookAt.getLatitude()
    lookLon = lookAt.getLongitude()
    midLat = (cam.lat + lookLat) / 2
    midLon = (cam.lon + lookLon) / 2
    
    latDiff = Math.abs(cam.lat - midLat)
    lonDiff = Math.abs(cam.lon - midLon)
    
    sizeFactor = 1.2  # 1 = a box with the camera and lookAt points on its borders
    latSize = Math.max(latDiff, lonDiff / @lonRatio) * sizeFactor
    lonSize = latSize * @lonRatio
    
    lat1 = midLat - latSize
    lat2 = midLat + latSize
    lon1 = midLon - lonSize
    lon2 = midLon + lonSize
    
    if @params.debugBox
      @ge.getFeatures().removeChild(box) if box
      kml = "<?xml version='1.0' encoding='UTF-8'?><kml xmlns='http://www.opengis.net/kml/2.2'><Document><Placemark><name>lookAt</name><Point><coordinates>#{lookLon},#{lookLat},0</coordinates></Point></Placemark><Placemark><name>camera</name><Point><coordinates>#{cam.lon},#{cam.lat},0</coordinates></Point></Placemark><Placemark><name>middle</name><Point><coordinates>#{midLon},#{midLat},0</coordinates></Point></Placemark><Placemark><LineString><altitudeMode>absolute</altitudeMode><coordinates>#{lon1},#{lat1},100 #{lon1},#{lat2},100 #{lon2},#{lat2},100 #{lon2},#{lat1},50 #{lon1},#{lat1},100</coordinates></LineString></Placemark></Document></kml>"
      box = @ge.parseKml(kml)
      @ge.getFeatures().appendChild(box)
    
    for f in @featuresInBBox(lat1, lon1, lat2, lon2)
      @showFeature(f)
      f.updateMoment = @updateMoment
    
    for own id, f of @visibleFeatures
      @hideFeature(f) if f.updateMoment < @updateMoment
    
    @updateMoment += 1
    


class @FeatureSet
  constructor: (@featureManager) ->
    @features = {}
  
  addFeature: (f) ->
    @features[f.id] = f
    @featureManager.addFeature(f)
    
  removeFeature: (f) ->
    @featureManager.removeFeature(f)
    delete @features[f.id]
  
  clearFeatures: -> 
    @removeFeature(f) for own k, f of @features


class @Feature
  alt: 100
  nameTextOpts: {}
  descTextOpts: {}
  
  constructor: (@id, @lat, @lon, @opts) ->
  
  rect: -> {x: @lon, y: @lat, w: 0, h: 0}
    
  show: ->
    fm  = @fm
    cam = fm.cam
    ge  = fm.ge
    angleToCamRad = Math.atan2(@lon - cam.lon, @lat - cam.lat)
    angleToCamDeg = angleToCamRad * oneEightyOverPi
    st = new SkyText(@lat, @lon, @alt, @opts)
    st.text(@name, mergeObj({bearing: angleToCamDeg}, @nameTextOpts)) if @name
    st.text(@desc, mergeObj({bearing: angleToCamDeg}, @descTextOpts)) if @desc
    geNode = ge.parseKml(st.kml())
    ge.getFeatures().appendChild(geNode)
    @hide() 
    @geNode = geNode
    
  hide: ->
    if @geNode?
      @fm.ge.getFeatures().removeChild(@geNode)
      delete @geNode

class @RailStationSet extends FeatureSet
  constructor: (featureManager) ->
    super(featureManager)
    for row in @csv.split("\n")
      [code, name, lat, lon] = row.split(',')
      continue if lat < 51.253320526331336 or lat > 51.73383267274113 or lon < -0.61248779296875 or lon > 0.32684326171875
      station = new RailStation("rail-#{code}", parseFloat(lat), parseFloat(lon))
      station.name = "\uF001 #{name}"
      @addFeature(station)

class @RailStation extends Feature
  alt: 130
  nameTextOpts: {size: 3}

#################################### DISTANCE ##############################################
class @DistanceSensorSet extends FeatureSet
  constructor: (featureManager) ->
    super(featureManager)

    dis_event = new DistanceEventLocation("excel center", 51.508208, 0.030958)
    dis_event.name = "ExCeL London"
    dis_event.desc = "International Convention Centre"
    @addFeature(dis_event)

    dis_crystal = new DistanceEventLocation("The Crystal", 51.507474, 0.01633)
    dis_crystal.name = "The Crystal"
    dis_crystal.alt = 150
    @addFeature(dis_crystal)

    dis_sensor = new DistanceTempSensor("Temp Sensor", 51.508168, 0.026473)
    @addFeature(dis_sensor)
    dis_sensor.update()

    distance_wind_sensor = new DistanceWindSensor("Wind Sensor", 51.508762, 0.028759)
    @addFeature(distance_wind_sensor)
    distance_wind_sensor.update()

    dis_sound_sensor = new DistanceSoundSensor("Sound Sensor",  51.508208, 0.030459)
    @addFeature(dis_sound_sensor)
    dis_sound_sensor.update()

    #Loop around CSV with Distance features
    for row in @csv.split("\n")
        [lat, lon, name] = row.split(',')
        lfs = new LeedsFeature(name, parseFloat(lat), parseFloat(lon))
        lfs.name = name;
        @addFeature(lfs)

class @DistanceEventLocation extends Feature
  alt: 210 
  nameTextOpts: {size: 3, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}

class @DistanceFeature extends Feature
  alt: Math.floor(Math.random()*(300-200+1)+200)
  nameTextOpts: {size: 3, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}

class @DistanceTempSensor extends Feature
  alt: 200
  nameTextOpts: {size: 3, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}
  name: "Intel Weather Station"

  update: -> 
    @show() if @geNode?
    load {url: 'http://ios.stevenjamesgray.com/dataFeed/?feed=491325353&stream=Inside_air_temperature.json', type: 'json'}, (data) =>
      @desc = "Temperature: "  + data.current_value + data.unit.symbol
      @show() if @geNode?
    self = arguments.callee.bind(@)
    @interval = setInterval(self, 10 * 1000) unless @interval?  # update every minute

class @DistanceWindSensor extends Feature
  alt: 110
  nameTextOpts: {size: 3, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}
  name: "Intel Weather Station"

  update: -> 
    @show() if @geNode?
    load {url: 'http://ios.stevenjamesgray.com/dataFeed/?feed=491325353&stream=Wind_Speed.json', type: 'json'}, (data) =>
      @desc = "Wind Speed: "  + data.current_value + data.unit.symbol
      @show() if @geNode?
    self = arguments.callee.bind(@)
    @interval = setInterval(self, 10 * 1000) unless @interval?  # update every minute

class @DistanceSoundSensor extends Feature
  alt: 150
  nameTextOpts: {size: 3, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}
  name: "GPRS LogBook"

  update: -> 
    @show() if @geNode?
    load {url: 'http://ios.stevenjamesgray.com/dataFeed/?feed=804611207&stream=230908.json', type: 'json'}, (data) =>
      @desc = "Sound Level: "  + data.current_value + data.unit.symbol
      @show() if @geNode?
    self = arguments.callee.bind(@)
    @interval = setInterval(self, 10 * 1000) unless @interval?  # update every minute


#################################### PARIS ##############################################

class @ParisCitySet extends FeatureSet
  constructor: (featureManager) ->
    super(featureManager)

    #Loop around CSV with Leeds features
    for row in @csv.split("\n")
        [lat, lon, name] = row.split(',')
        lfs = new ParisFeature(name, parseFloat(lat), parseFloat(lon))
        lfs.name = name;
        @addFeature(lfs)

class @ParisFeature extends Feature
  alt: Math.floor(Math.random()*(300-200+1)+200)
  nameTextOpts: {size: 3, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}

#################################### LEEDS ##############################################

class @LeedsCitySet extends FeatureSet
  constructor: (featureManager) ->
    super(featureManager)
    
    lch = new LeedsCivicHall("civic-hall",  53.80210025576234, -1.5485385060310364)
    @addFeature(lch)

    unileeds = new UniLeeds("uni-of-leeds", 53.80786737971994, -1.5527737140655518)
    @addFeature(unileeds)

    railLeeds = new RailLeeds("RailStation", 53.79437097083624, -1.5475326776504517)
    railLeeds.update()
    @addFeature(railLeeds)
    
    bb = new LeedsTownHallClock('TownHallClock', 53.80005678340009, -1.5497106313705444)
    bb.update()
    @addFeature(bb)

    #Loop around CSV with Leeds features
    for row in @csv.split("\n")
        [lat, lon, name] = row.split(',')
        lfs = new LeedsFeature(name, parseFloat(lat), parseFloat(lon))
        lfs.name = name;
        @addFeature(lfs)

class @LeedsFeature extends Feature
  alt: Math.floor(Math.random()*(300-200+1)+200)
  nameTextOpts: {size: 3, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}

class @LeedsCivicHall extends Feature
  alt: 150
  nameTextOpts: {size: 3, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}
  name: "Leeds Civic Hall"
  desc: ""

class @RailLeeds extends Feature
  alt: 200
  nameTextOpts: {size: 3, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}
  name: "\uF001 Leeds Rail Station"
  desc: "Next Train: "

  update: -> 
    load {url: 'http://www.maptube.org/realtime/leedsdeparturesservice.svc/leeds', type: 'json'}, (data) =>
      @desc = "Next Train: " + data.text.replace "Platform \?\? " , "" 
      @show() if @geNode?
    self = arguments.callee.bind(@)
    @interval = setInterval(self, 3 * 60 * 1000) unless @interval?  # update every 3 minutes

class @UniLeeds extends Feature
  alt: 200
  nameTextOpts: {size: 3, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}
  name: "University of Leeds"
  desc: ""

class @LeedsTownHallClock extends Feature
  alt: 200
  nameTextOpts: {size: 2, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}
  
  update: ->
    @name = new Date().strftime('%H.%M')
    @desc = 'Leeds Town Hall'
    @show() if @geNode?
    self = arguments.callee.bind(@)
    @interval = setInterval(self, 1 * 60 * 1000) unless @interval?  # update every minute

class @LeedsTweetSet extends FeatureSet
  maxTweets: 500
  
  constructor: (featureManager) ->
    super(featureManager)
    @update()
      
  update: ->
    load {url: 'http://www.casa.ucl.ac.uk/tom/ajax-live/leeds_last_hour.json', type: 'json'}, (data) =>
      @clearFeatures()
      dedupedTweets = {}
      for t, i in data.results.slice(-@maxTweets)
        dedupedTweets["#{parseFloat(t.lat).toFixed(4)}/#{parseFloat(t.lon).toFixed(4)}"] = t
      for own k, t of dedupedTweets
        lat = parseFloat(t.lat)
        lon = parseFloat(t.lon)
        continue if isNaN(lat) or isNaN(lon)
        tweet = new Tweet("tweet-#{t.twitterID}", lat, lon)
        tweet.name = "#{t.name} — #{t.dateT.match(/\d?\d:\d\d/)}"
        tweet.desc = t.twitterPost.replace(/&gt;/g, '>').replace(/&lt;/g, '<')
                      .match(/.{1,35}(\s|$)|\S+?(\s|$)/g).join('\n').replace(/\n+/g, '\n')  # bug: many \ns collapsed to one
        @addFeature(tweet)
    self = arguments.callee.bind(@)
    setTimeout(self, 5 * 60 * 1000)  # update every 5 mins

#######################################################################################

class @TubeStationSet extends FeatureSet
  constructor: (featureManager) ->
    super(featureManager)
    for row in @csv.split("\n")
      [code, dummy, lon, lat, name] = row.split(',')
      station = new TubeStation("tube-#{code}", parseFloat(lat), parseFloat(lon))
      station.name = "\uF000 #{name}"
      @addFeature(station)

class @TubeStation extends Feature
  alt: 100
  nameTextOpts: {size: 2, lineWidth: 1}


class @MiscSet extends FeatureSet
  constructor: (featureManager) ->
    super(featureManager)
    
    ch = new CityHall("city-hall", 51.50477580586208, -0.07864236831665039)
    @addFeature(ch)
    
    logo = new CASALogo("casa-logo", 51.52192375643773, -0.13593167066574097)
    @addFeature(logo)
    
    # conf = new CASAConf('casa-conf', 51.5210609212573, -0.1287245750427246)
    # conf.update()
    # @addFeature(conf)
    
    bb = new BigBen('big-ben', 51.5007286626542, -0.12459531426429749)
    bb.update()
    @addFeature(bb)
    
    tb = new TowerBridge('twr-brdg', 51.50558385576479, -0.0754237174987793)
    tb.update()
    @addFeature(tb)

class @CityHall extends Feature
  alt: 120
  nameTextOpts: {size: 3, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}
  name: "City Hall"
  desc: "More London"

class @CASALogo extends Feature
  alt: 220
  nameTextOpts: {size: 1, lineWidth: 1}
  name: "\uF002"

class @CASAConf extends Feature
  alt: 130
  nameTextOpts: {size: 2, lineWidth: 3}
  descTextOpts: {size: 1, lineWidth: 2}
  name: 'CASA Smart Cities'
  
  update: ->
    d = new Date()  # testing: d = new Date(2012, 4, 13, 10, 25)
    d0 = new Date(d.getFullYear(), d.getMonth(), d.getDate())
    dayMs = d - d0
    dayHrs = dayMs / 1000 / 60 / 60
    for session, i in @schedule
      if dayHrs < session[0]
        desc = "Now:\t#{@schedule[i - 1][1]}\nNext:\t#{session[1]}"
        break
    changed = @desc isnt desc
    @desc = desc
    @show() if changed and @geNode?
    self = arguments.callee.bind(@)
    @interval = setInterval(self, 1 * 60 * 1000) unless @interval? # update every minute

class @TubeStation extends Feature
  alt: 100
  nameTextOpts: {size: 2, lineWidth: 1}

class @BigBen extends Feature
  alt: 200
  nameTextOpts: {size: 2, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}
  
  update: ->
    @name = new Date().strftime('%H.%M')
    @desc = 'Big Ben'
    @show() if @geNode?
    self = arguments.callee.bind(@)
    @interval = setInterval(self, 1 * 60 * 1000) unless @interval?  # update every minute

class @TowerBridge extends Feature
  alt: 150
  nameTextOpts: {size: 2, lineWidth: 3}
  name: 'Tower Bridge'
  
  update: ->
    load {url: 'http://www.towerbridge.org.uk/TBE/EN/BridgeLiftTimes/', type: 'xml'}, (data) =>
      cells = (x.innerHTML for x in data.querySelectorAll('td'))  # arrayify the node list
      descs = for i in [0..5] by 5
        "#{cells[i + 4]} on #{cells[i]} #{cells[i + 1]} at #{cells[i + 2]} for vessel #{cells[i + 3]}"
      desc = descs.join('\n')
      changed = @desc isnt desc
      @desc = desc
      @show() if changed and @geNode?
    self = arguments.callee.bind(@)
    @interval = setInterval(self, 4 * 60 * 60 * 1000) unless @interval?  # update every 4 hours
    
    
    

class @LondonTweetSet extends FeatureSet
  maxTweets: 500
  
  constructor: (featureManager) ->
    super(featureManager)
    @update()
      
  update: ->
    load {url: 'http://www.casa.ucl.ac.uk/tom/ajax-live/lon_last_hour.json', type: 'json'}, (data) =>
      @clearFeatures()
      dedupedTweets = {}
      for t, i in data.results.slice(-@maxTweets)
        dedupedTweets["#{parseFloat(t.lat).toFixed(4)}/#{parseFloat(t.lon).toFixed(4)}"] = t
      for own k, t of dedupedTweets
        lat = parseFloat(t.lat)
        lon = parseFloat(t.lon)
        continue if isNaN(lat) or isNaN(lon)
        tweet = new Tweet("tweet-#{t.twitterID}", lat, lon)
        tweet.name = "#{t.name} — #{t.dateT.match(/\d?\d:\d\d/)}"
        tweet.desc = t.twitterPost.replace(/&gt;/g, '>').replace(/&lt;/g, '<')
                      .match(/.{1,35}(\s|$)|\S+?(\s|$)/g).join('\n').replace(/\n+/g, '\n')  # bug: many \ns collapsed to one
        @addFeature(tweet)
    self = arguments.callee.bind(@)
    setTimeout(self, 5 * 60 * 1000)  # update every 5 mins

class @Tweet extends Feature
  alt: 160
  nameTextOpts: {size: 1}
  descTextOpts: {size: 1, lineWidth: 1}


class @LondonAirSet extends FeatureSet
  constructor: (featureManager) ->
    super(featureManager)
    @update()
  
  update: ->
    load {url: 'http://www.citydashboard.org/modules/airquality.php?city=london&format=csv'}, (csv) =>
      @clearFeatures()
      lines = csv.split('\n')
      metadata = lines.shift()
      headers  = lines.shift()
      for line in lines
        cells = line.split(',')
        continue if cells.length < 10
        a = new LondonAir("air-#{cells[0]}", parseFloat(cells[3]), parseFloat(cells[4]))
        a.name = cells[1]
        desc = ''
        pm10ugm3 = cells[21]
        if pm10ugm3 isnt ''
          pm10desc = cells[23]
          desc += "PM10:\t#{pm10ugm3} μg/m³ (#{pm10desc})\n"
        no2ugm3 = cells[9]
        if no2ugm3 isnt ''
          no2desc = cells[11]
          desc += "NO₂:\t#{no2ugm3} μg/m³ (#{no2desc})\n"
        o3ugm3 = cells[5]
        if o3ugm3 isnt ''
          o3desc = cells[7]
          desc += "O₃: \t#{o3ugm3} μg/m³ (#{o3desc})\n"
        a.desc = desc
        @addFeature(a)
    self = arguments.callee.bind(@)
    setTimeout(self, 10 * 60 * 1000)  # update every 10 mins
  
class @LondonAir extends Feature
  alt: 180
  nameTextOpts: {size: 2}
  descTextOpts: {size: 2, lineWidth: 1}
  
  
class @LondonTrafficSet extends FeatureSet
  constructor: (featureManager) ->
    super(featureManager)
    @update()
  
  update: ->
    load {url: 'http://www.citydashboard.org/modules/roadsigns.php?city=london&format=csv'}, (csv) =>
      @clearFeatures()
      lines = csv.split('\n')
      metadata = lines.shift()
      headers  = lines.shift()
      for line in lines
        cells = line.split(',')
        continue if cells.length < 5
        a = new LondonTraffic("trf-#{cells[0]}", parseFloat(cells[3]), parseFloat(cells[4]))
        a.name = cells[11]
        a.desc = (s.match(/^\s*(.*?)\s*$/)[1] for s in cells[5..8]).join('\n')
        @addFeature(a)
    self = arguments.callee.bind(@)
    setTimeout(self, 3 * 60 * 1000)  # update every 3 mins
  
class @LondonTraffic extends Feature
  alt: 150
  nameTextOpts: {size: 2, lineWidth: 2}
  descTextOpts: {size: 2, lineWidth: 1}


class @TideGaugeSet extends FeatureSet
  constructor: (featureManager) ->
    super(featureManager)
    @update()
  
  update: ->
    load {url: 'http://www.citydashboard.org/modules/tide.php?city=london&format=csv'}, (csv) =>
      @clearFeatures()
      lines = csv.split('\n')
      metadata = lines.shift()
      headers  = lines.shift()
      for line in lines
        cells = line.split(',')
        continue if cells.length < 3
        a = new TideGauge("tide-#{cells[0]}", parseFloat(cells[3]), parseFloat(cells[4]))
        a.name = cells[1]
        a.desc = "Height:\t#{cells[5]}m\nSurge:\t#{cells[6]}m"
        @addFeature(a)
    self = arguments.callee.bind(@)
    setTimeout(self, 3 * 60 * 1000)  # update every 3 mins
  
class @TideGauge extends Feature
  alt: 80
  nameTextOpts: {size: 2, lineWidth: 3}
  descTextOpts: {size: 2, lineWidth: 2}
  

class @OlympicSet extends FeatureSet
  constructor: (featureManager) ->
    super(featureManager)
    @venues = []
    @events = {}
    for row in @venueData.split("\n")
      [lat, lon, name] = row.split("\t")
      continue if name in ['Multiple Venues', 'Olympic Park']
      @venues.push({name, lat: parseFloat(lat), lon: parseFloat(lon)})
    for row in @eventData.split("\n")
      [day, date, times, sport, desc, code, venue] = row.split("\t")
      [t1, t2] = times.split("-")
      start = new Date("#{date} #{t1}")
      end   = new Date("#{date} #{t2}")
      @events[venue] ?= []
      @events[venue].push({start, end, sport, desc})
    @update()
    
  update: ->
    @clearFeatures()
    for venue, i in @venues
      a = new OlympicVenue("oly-#{venue.name}", venue.lat, venue.lon)
      a.name = "\uF003 #{venue.name}"
      a.alt += (i % 5) * 30
      
      if venue.name not in ['Orbit']
        now = new Date()
        nextEvent = null  # scope
        for event in @events[venue.name] ? []
          if event.end > now
            nextEvent = event
            break
        if nextEvent?
          a.desc =  if nextEvent.start < now
            "Now: #{nextEvent.sport}"
          else 
            "Next event: #{nextEvent.sport}, #{nextEvent.start.strftime("%a %d %b, %H:%M")}"
      @addFeature(a)
    self = arguments.callee.bind(@)
    setTimeout(self, 7 * 60 * 1000)  # update every 7 mins
    
class @OlympicVenue extends Feature
  alt: 120
  nameTextOpts: {size: 3, lineWidth: 3}
  descTextOpts: {size: 2, lineWidth: 2}
