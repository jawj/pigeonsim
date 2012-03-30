
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
    
  text: (text, o) ->
    @line(line, o) for line in text.split("\n")
    
  line: (text, o = {}) ->
    o.bearing   ?= 0
    o.size      ?= 2
    o.lineWidth ?= 2
    o.colour    ?= 'ffffffff'
    o.lineSpace ?= 1
    o.charSpace ?= 1
    o.font      ?= window.font

    xCursor = o.charSpace * 3
    bRad = o.bearing * @piOver180
    latFactor = Math.sin(bRad) * o.size * @latFactor
    lonFactor = Math.cos(bRad) * o.size * @lonFactor
    
    lineCoordSets = []
    
    for char in text.split('')
      if char is ' '
        xCursor += 2 + o.charSpace
        continue
      paths = o.font[char]
      maxX = 0
      for path in paths
        coords = for x, i in path by 2
          y = path[i + 1]
          maxX = x if x > maxX
          lat = @lat + (x + xCursor) * latFactor
          lon = @lon + (x + xCursor) * lonFactor
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
    
