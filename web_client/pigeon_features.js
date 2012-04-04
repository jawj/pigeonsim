(function() {
  var box, load, mergeObj, oneEightyOverPi,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  load = function(opts, callback) {
    var k, kvps, url, v, xhr;
    url = opts.url;
    if (opts.method == null) opts.method = 'GET';
    if (opts.search != null) {
      kvps = (function() {
        var _ref, _results;
        _ref = opts.search;
        _results = [];
        for (k in _ref) {
          if (!__hasProp.call(_ref, k)) continue;
          v = _ref[k];
          _results.push("" + (escape(k)) + "=" + (escape(v)));
        }
        return _results;
      })();
      url += '?' + kvps.join('&');
    }
    xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      var obj;
      if (xhr.readyState === 4) {
        obj = opts.json != null ? JSON.parse(xhr.responseText) : opts.xml != null ? xhr.responseXML : xhr.responseText;
        return callback(obj);
      }
    };
    xhr.open(opts.method, url, true);
    return xhr.send(opts.data);
  };

  mergeObj = function(o1, o2) {
    var k, v;
    for (k in o2) {
      if (!__hasProp.call(o2, k)) continue;
      v = o2[k];
      o1[k] = v;
    }
    return o1;
  };

  oneEightyOverPi = 180 / Math.PI;

  box = null;

  this.FeatureManager = (function() {

    function FeatureManager(ge, lonRatio) {
      this.ge = ge;
      this.lonRatio = lonRatio;
      this.featureTree = new RTree();
      this.visibleFeatures = {};
      this.updateMoment = 0;
    }

    FeatureManager.prototype.addFeature = function(f) {
      return this.featureTree.insert(f.rect(), f);
    };

    FeatureManager.prototype.removeFeature = function(f) {
      this.hideFeature(f);
      return this.featureTree.remove(f.rect(), f);
    };

    FeatureManager.prototype.showFeature = function(f, cam) {
      if (this.visibleFeatures[f.id] != null) return false;
      this.visibleFeatures[f.id] = f;
      f.show(this.ge, cam);
      return true;
    };

    FeatureManager.prototype.hideFeature = function(f) {
      if (this.visibleFeatures[f.id] == null) return false;
      delete this.visibleFeatures[f.id];
      f.hide(this.ge);
      return true;
    };

    FeatureManager.prototype.featuresInBBox = function(lat1, lon1, lat2, lon2) {
      return this.featureTree.search({
        x: lon1,
        y: lat1,
        w: lon2 - lon1,
        h: lat2 - lat1
      });
    };

    FeatureManager.prototype.update = function(cam) {
      var f, id, lat1, lat2, latDiff, latSize, lon1, lon2, lonDiff, lonSize, lookAt, lookLat, lookLon, midLat, midLon, sizeFactor, _i, _len, _ref, _ref2;
      lookAt = this.ge.getView().copyAsLookAt(ge.ALTITUDE_ABSOLUTE);
      lookLat = lookAt.getLatitude();
      lookLon = lookAt.getLongitude();
      midLat = (cam.lat + lookLat) / 2;
      midLon = (cam.lon + lookLon) / 2;
      latDiff = Math.abs(cam.lat - midLat);
      lonDiff = Math.abs(cam.lon - midLon);
      if (latDiff > lonDiff * this.lonRatio) {
        latSize = latDiff;
        lonSize = latDiff * this.lonRatio;
      } else {
        lonSize = lonDiff;
        latSize = lonDiff / this.lonRatio;
      }
      sizeFactor = 1;
      latSize *= sizeFactor;
      lonSize *= sizeFactor;
      lat1 = midLat - latSize;
      lat2 = midLat + latSize;
      lon1 = midLon - lonSize;
      lon2 = midLon + lonSize;
      /*
          ge.getFeatures().removeChild(box) if box
          kml = "<?xml version='1.0' encoding='UTF-8'?><kml xmlns='http://www.opengis.net/kml/2.2'><Document><Placemark><name>lookAt</name><Point><coordinates>#{lookLon},#{lookLat},0</coordinates></Point></Placemark><Placemark><name>camera</name><Point><coordinates>#{cam.lon},#{cam.lat},0</coordinates></Point></Placemark><Placemark><name>middle</name><Point><coordinates>#{midLon},#{midLat},0</coordinates></Point></Placemark><Placemark><LineString><altitudeMode>absolute</altitudeMode><coordinates>#{lon1},#{lat1},100 #{lon1},#{lat2},100 #{lon2},#{lat2},100 #{lon2},#{lat1},50 #{lon1},#{lat1},100</coordinates></LineString></Placemark></Document></kml>"
          box = ge.parseKml(kml)
          ge.getFeatures().appendChild(box)
          #console.log(kml)
      */
      _ref = this.featuresInBBox(lat1, lon1, lat2, lon2);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        f = _ref[_i];
        this.showFeature(f, cam);
        f.updateMoment = this.updateMoment;
      }
      _ref2 = this.visibleFeatures;
      for (id in _ref2) {
        if (!__hasProp.call(_ref2, id)) continue;
        f = _ref2[id];
        if (f.updateMoment < this.updateMoment) this.hideFeature(f);
      }
      return this.updateMoment += 1;
    };

    return FeatureManager;

  })();

  this.FeatureSet = (function() {

    function FeatureSet(featureManager) {
      this.featureManager = featureManager;
      this.features = {};
    }

    FeatureSet.prototype.addFeature = function(f) {
      this.features[f.id] = f;
      return this.featureManager.addFeature(f);
    };

    FeatureSet.prototype.removeFeature = function() {
      this.featureManager.removeFeature(f);
      return delete this.features[f.id];
    };

    FeatureSet.prototype.clearFeatures = function() {
      var f, _ref, _results;
      _ref = this.features;
      _results = [];
      for (f in _ref) {
        if (!__hasProp.call(_ref, f)) continue;
        _results.push(this.removeFeature(f));
      }
      return _results;
    };

    return FeatureSet;

  })();

  this.Feature = (function() {

    Feature.prototype.alt = 100;

    Feature.prototype.nameTextOpts = {};

    Feature.prototype.descTextOpts = {};

    function Feature(id, lat, lon) {
      this.id = id;
      this.lat = lat;
      this.lon = lon;
    }

    Feature.prototype.rect = function() {
      return {
        x: this.lon,
        y: this.lat,
        w: 0,
        h: 0
      };
    };

    Feature.prototype.show = function(ge, cam) {
      var angleToCamDeg, angleToCamRad, st;
      angleToCamRad = Math.atan2(this.lon - cam.lon, this.lat - cam.lat);
      angleToCamDeg = angleToCamRad * oneEightyOverPi;
      st = new SkyText(this.lat, this.lon, this.alt);
      if (this.name) {
        st.text(this.name, mergeObj({
          bearing: angleToCamDeg
        }, this.nameTextOpts));
      }
      if (this.desc) {
        st.text(this.desc, mergeObj({
          bearing: angleToCamDeg
        }, this.descTextOpts));
      }
      this.geNode = ge.parseKml(st.kml());
      return ge.getFeatures().appendChild(this.geNode);
    };

    Feature.prototype.hide = function(ge) {
      if (this.geNode) {
        ge.getFeatures().removeChild(this.geNode);
        return delete this.geNode;
      }
    };

    return Feature;

  })();

  this.TubeStation = (function(_super) {

    __extends(TubeStation, _super);

    function TubeStation() {
      TubeStation.__super__.constructor.apply(this, arguments);
    }

    TubeStation.prototype.alt = 100;

    return TubeStation;

  })(Feature);

  this.RailStation = (function(_super) {

    __extends(RailStation, _super);

    function RailStation() {
      RailStation.__super__.constructor.apply(this, arguments);
    }

    RailStation.prototype.alt = 130;

    RailStation.prototype.nameTextOpts = {
      size: 3
    };

    return RailStation;

  })(Feature);

  this.CASALogo = (function(_super) {

    __extends(CASALogo, _super);

    function CASALogo() {
      CASALogo.__super__.constructor.apply(this, arguments);
    }

    CASALogo.prototype.alt = 200;

    CASALogo.prototype.nameTextOpts = {
      size: 1
    };

    return CASALogo;

  })(Feature);

  this.Tweet = (function(_super) {

    __extends(Tweet, _super);

    function Tweet() {
      Tweet.__super__.constructor.apply(this, arguments);
    }

    Tweet.prototype.alt = 160;

    Tweet.prototype.nameTextOpts = {
      size: 1,
      lineWidth: 3
    };

    Tweet.prototype.descTextOpts = {
      size: 1
    };

    return Tweet;

  })(Feature);

  this.RailStationSet = (function(_super) {

    __extends(RailStationSet, _super);

    function RailStationSet(featureManager) {
      var code, lat, lon, name, row, station, _i, _len, _ref, _ref2;
      RailStationSet.__super__.constructor.call(this, featureManager);
      _ref = this.csv.split("\n");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        _ref2 = row.split(','), code = _ref2[0], name = _ref2[1], lat = _ref2[2], lon = _ref2[3];
        station = new RailStation("rail-" + code, parseFloat(lat), parseFloat(lon));
        station.name = "\uF001 " + name;
        this.addFeature(station);
      }
    }

    return RailStationSet;

  })(FeatureSet);

  this.TubeStationSet = (function(_super) {

    __extends(TubeStationSet, _super);

    function TubeStationSet(featureManager) {
      var code, dummy, lat, lon, name, row, station, _i, _len, _ref, _ref2;
      TubeStationSet.__super__.constructor.call(this, featureManager);
      _ref = this.csv.split("\n");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        _ref2 = row.split(','), code = _ref2[0], dummy = _ref2[1], lon = _ref2[2], lat = _ref2[3], name = _ref2[4];
        station = new TubeStation("tube-" + code, parseFloat(lat), parseFloat(lon));
        station.name = "\uF000 " + name;
        this.addFeature(station);
      }
    }

    return TubeStationSet;

  })(FeatureSet);

  this.CASALogoSet = (function(_super) {

    __extends(CASALogoSet, _super);

    function CASALogoSet(featureManager) {
      var logo;
      CASALogoSet.__super__.constructor.call(this, featureManager);
      logo = new CASALogo("casa-logo", 51.52192375643773, -0.13593167066574097);
      logo.name = "\uF002";
      this.addFeature(logo);
    }

    return CASALogoSet;

  })(FeatureSet);

  this.LondonTweetSet = (function(_super) {
    var lineChars;

    __extends(LondonTweetSet, _super);

    lineChars = 35;

    function LondonTweetSet(featureManager) {
      LondonTweetSet.__super__.constructor.call(this, featureManager);
      this.update();
    }

    LondonTweetSet.prototype.update = function() {
      var _this = this;
      return load({
        url: 'http://128.40.47.96/~sjg/LondonTwitterStream/',
        json: true
      }, function(data) {
        var dedupedTweets, i, k, t, tweet, _len, _ref;
        _this.clearFeatures();
        dedupedTweets = {};
        _ref = data.results.reverse();
        for (i = 0, _len = _ref.length; i < _len; i++) {
          t = _ref[i];
          dedupedTweets["" + t.lat + "/" + t.lon] = t;
          if (i > 150) break;
        }
        return _this.features = (function() {
          var _results;
          _results = [];
          for (k in dedupedTweets) {
            if (!__hasProp.call(dedupedTweets, k)) continue;
            t = dedupedTweets[k];
            tweet = new Tweet("tweet-" + t.twitterID, parseFloat(t.lat), parseFloat(t.lon));
            tweet.name = "@" + t.name + " — " + (t.dateT.split(' ')[1]);
            tweet.desc = t.twitterPost.match(/.{1,35}(\s|$)|\S+?(\s|$)/g).join('\n');
            _results.push(this.addFeature(tweet));
          }
          return _results;
        }).call(_this);
      });
    };

    return LondonTweetSet;

  })(FeatureSet);

}).call(this);
