
class window.SkyText
  piOver180:  Math.PI / 180
  latFactor:  0.00001
  fontHeight: 5

  constructor: (@lat, @lon, @alt, o = {}) ->
    o.lineWidth ?= 1
    o.colour    ?= 'ffffffff'
    @allCoordSets = []
    @lineOpts = []
    if o.lineWidth > 0
      @allCoordSets.push([[[@lon, @lat, 0], [@lon, @lat, @alt]]])
      @lineOpts.push(o)
    lonRatio = 1 / Math.cos(@lat * @piOver180)
    @lonFactor = @latFactor * lonRatio
    
  text: (text, o) -> @line(line, o) for line in text.split("\n")
    
  line: (text, o = {}) ->
    o.bearing    ?= 0  # text will be readable straight on when viewed facing this way
    o.size       ?= 2
    o.lineWidth  ?= 2
    o.colour     ?= 'ffffffff'
    o.lineSpace  ?= 1  # vertical space between lines 
    o.charSpace  ?= 1  # horizontal space between chars
    o.spaceWidth ?= 2
    o.tabSpaces  ?= 4  # tabs are this many spaces wide
    o.offset     ?= 5  # horizontal space at start of line (independent of o.size)
    o.font       ?= window.font

    bRad = o.bearing * @piOver180
    sinB = Math.sin(bRad)
    cosB = Math.cos(bRad)
    latFactor = sinB * o.size * @latFactor
    lonFactor = cosB * o.size * @lonFactor
    latStart = @lat + sinB * o.offset * @latFactor
    lonStart = @lon + cosB * o.offset * @lonFactor
    
    xCursor = 0
    tabWidth = o.tabSpaces * o.spaceWidth
    lineCoordSets = []
    
    for char in text.split('')
      if char in [" ", "\n", "\r"]
        xCursor += o.spaceWidth
        continue
      if char is "\t"
        xCursor = Math.ceil((xCursor + 1) / tabWidth) * tabWidth
        continue
      paths = o.font[char] ? o.font['na']
      maxX = 0
      for path in paths
        coords = for x, i in path by 2
          y = path[i + 1]
          maxX = x if x > maxX
          absX = xCursor + x
          lat = latStart + absX * latFactor
          lon = lonStart + absX * lonFactor
          alt = @alt - (y * o.size)
          [lon, lat, alt]
        lineCoordSets.push(coords)
      xCursor += maxX + o.charSpace
        
    @alt -= (o.size * @fontHeight) + o.lineSpace
    
    @lineOpts.push(o)
    @allCoordSets.push(lineCoordSets)
    @
       
  kml: ->
    k = []
    k.push "<?xml version='1.0' encoding='UTF-8'?><kml xmlns='http://www.opengis.net/kml/2.2'><Document>"
    coordStrs = for lineCoordSets, i in @allCoordSets
      o = @lineOpts[i]
      k.push "<Style id='l#{i}'><LineStyle><color>#{o.colour}</color><width>#{o.lineWidth}</width></LineStyle></Style>"
      for lineCoords in lineCoordSets
        coordStr = ((coords.join(',') for coords in lineCoords).join(' '))
        k.push "<Placemark>
          <styleUrl>#l#{i}</styleUrl>
          <LineString><altitudeMode>absolute</altitudeMode><coordinates>#{coordStr}</coordinates></LineString>
        </Placemark>"
    k.push "</Document></kml>"
    k.join('')
    
