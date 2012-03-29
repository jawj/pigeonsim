(function() {

  window.SkyText = (function() {

    SkyText.prototype.piOver180 = Math.PI / 180;

    SkyText.prototype.latFactor = 0.00001;

    SkyText.prototype.fontHeight = 5;

    function SkyText(lat, lon, alt, o, text, textOpts) {
      var line, lonRatio, _i, _len, _ref;
      this.lat = lat;
      this.lon = lon;
      this.alt = alt;
      if (o == null) o = {};
      if (o.lineWidth == null) o.lineWidth = 1;
      if (o.colour == null) o.colour = 'ffffffff';
      this.allCoordSets = [];
      this.lineOpts = [];
      if (o.lineWidth > 0) {
        this.allCoordSets.push([[[this.lon, this.lat, 0], [this.lon, this.lat, this.alt]]]);
        this.lineOpts.push(o);
      }
      lonRatio = 1 / Math.cos(this.lat * this.piOver180);
      this.lonFactor = this.latFactor * lonRatio;
      if (text != null) {
        _ref = text.split("\n");
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          line = _ref[_i];
          this.line(line, textOpts);
        }
      }
    }

    SkyText.prototype.line = function(text, o) {
      var alt, bRad, char, coords, i, lat, latFactor, lineCoordSets, lon, lonFactor, maxX, path, paths, x, xCursor, y, _i, _j, _len, _len2, _ref;
      if (o == null) o = {};
      if (o.bearing == null) o.bearing = 0;
      if (o.size == null) o.size = 2;
      if (o.lineWidth == null) o.lineWidth = 2;
      if (o.colour == null) o.colour = 'ffffffff';
      if (o.lineSpace == null) o.lineSpace = 1;
      if (o.charSpace == null) o.charSpace = 1;
      xCursor = o.charSpace * 2;
      bRad = o.bearing * this.piOver180;
      latFactor = Math.sin(bRad) * o.size * this.latFactor;
      lonFactor = Math.cos(bRad) * o.size * this.lonFactor;
      lineCoordSets = [];
      _ref = text.split('');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        char = _ref[_i];
        if (char === ' ') {
          xCursor += 2 + o.charSpace;
          continue;
        }
        paths = font[char];
        maxX = 0;
        for (_j = 0, _len2 = paths.length; _j < _len2; _j++) {
          path = paths[_j];
          coords = (function() {
            var _len3, _results, _step;
            _results = [];
            for (i = 0, _len3 = path.length, _step = 2; i < _len3; i += _step) {
              x = path[i];
              y = path[i + 1];
              if (x > maxX) maxX = x;
              lat = this.lat + (x + xCursor) * latFactor;
              lon = this.lon + (x + xCursor) * lonFactor;
              alt = this.alt - (y * o.size);
              _results.push([lon, lat, alt]);
            }
            return _results;
          }).call(this);
          lineCoordSets.push(coords);
        }
        xCursor += maxX + o.charSpace;
      }
      this.alt -= (o.size * this.fontHeight) + o.lineSpace;
      this.lineOpts.push(o);
      this.allCoordSets.push(lineCoordSets);
      return this;
    };

    SkyText.prototype.kml = function() {
      var coordStr, coordStrs, coords, i, k, lineCoordSets, lineCoords, o;
      k = [];
      k.push("<?xml version='1.0' encoding='UTF-8'?><kml xmlns='http://www.opengis.net/kml/2.2'><Document>");
      coordStrs = (function() {
        var _len, _ref, _results;
        _ref = this.allCoordSets;
        _results = [];
        for (i = 0, _len = _ref.length; i < _len; i++) {
          lineCoordSets = _ref[i];
          o = this.lineOpts[i];
          k.push("<Style id='l" + i + "'><LineStyle><color>" + o.colour + "</color><width>" + o.lineWidth + "</width></LineStyle></Style>");
          _results.push((function() {
            var _i, _len2, _results2;
            _results2 = [];
            for (_i = 0, _len2 = lineCoordSets.length; _i < _len2; _i++) {
              lineCoords = lineCoordSets[_i];
              coordStr = ((function() {
                var _j, _len3, _results3;
                _results3 = [];
                for (_j = 0, _len3 = lineCoords.length; _j < _len3; _j++) {
                  coords = lineCoords[_j];
                  _results3.push(coords.join(','));
                }
                return _results3;
              })()).join(' ');
              _results2.push(k.push("<Placemark>          <styleUrl>#l" + i + "</styleUrl>          <LineString><altitudeMode>absolute</altitudeMode><coordinates>" + coordStr + "</coordinates></LineString>        </Placemark>"));
            }
            return _results2;
          })());
        }
        return _results;
      }).call(this);
      k.push("</Document></kml>");
      return k.join('');
    };

    return SkyText;

  })();

}).call(this);
