(function() {
  var box, load, mergeObj, oneEightyOverPi;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  window.load = load = function(opts, callback) {
    var k, kvps, url, v, xhr, _ref;
    url = opts.url;
    if ((_ref = opts.method) == null) opts.method = 'GET';
    if (opts.search != null) {
      kvps = (function() {
        var _ref2, _results;
        _ref2 = opts.search;
        _results = [];
        for (k in _ref2) {
          if (!__hasProp.call(_ref2, k)) continue;
          v = _ref2[k];
          _results.push("" + (escape(k)) + "=" + (escape(v)));
        }
        return _results;
      })();
      url += '?' + kvps.join('&');
    }
    xhr = new XMLHttpRequest();
    if (opts.type === 'xml') xhr.overrideMimeType('text/xml');
    xhr.onreadystatechange = function() {
      var obj;
      if (xhr.readyState === 4) {
        obj = opts.type === 'json' ? JSON.parse(xhr.responseText) : opts.type === 'xml' ? xhr.responseXML : xhr.responseText;
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

    function FeatureManager(ge, lonRatio, cam, params) {
      this.ge = ge;
      this.lonRatio = lonRatio;
      this.cam = cam;
      this.params = params;
      this.featureTree = new RTree();
      this.visibleFeatures = {};
      this.updateMoment = 0;
    }

    FeatureManager.prototype.addFeature = function(f) {
      f.fm = this;
      return this.featureTree.insert(f.rect(), f);
    };

    FeatureManager.prototype.removeFeature = function(f) {
      this.hideFeature(f);
      this.featureTree.remove(f.rect(), f);
      return delete f.fm;
    };

    FeatureManager.prototype.showFeature = function(f) {
      if (this.visibleFeatures[f.id] != null) return false;
      this.visibleFeatures[f.id] = f;
      f.show();
      return true;
    };

    FeatureManager.prototype.hideFeature = function(f) {
      if (this.visibleFeatures[f.id] == null) return false;
      delete this.visibleFeatures[f.id];
      f.hide();
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

    FeatureManager.prototype.reset = function() {
      var f, id, _ref;
      _ref = this.visibleFeatures;
      for (id in _ref) {
        if (!__hasProp.call(_ref, id)) continue;
        f = _ref[id];
        this.hideFeature(f);
      }
      return this.update();
    };

    FeatureManager.prototype.update = function() {
      var cam, f, id, kml, lat1, lat2, latDiff, latSize, lon1, lon2, lonDiff, lonSize, lookAt, lookLat, lookLon, midLat, midLon, sizeFactor, _i, _len, _ref, _ref2;
      cam = this.cam;
      lookAt = this.ge.getView().copyAsLookAt(ge.ALTITUDE_ABSOLUTE);
      lookLat = lookAt.getLatitude();
      lookLon = lookAt.getLongitude();
      midLat = (cam.lat + lookLat) / 2;
      midLon = (cam.lon + lookLon) / 2;
      latDiff = Math.abs(cam.lat - midLat);
      lonDiff = Math.abs(cam.lon - midLon);
      sizeFactor = 1.2;
      latSize = Math.max(latDiff, lonDiff / this.lonRatio) * sizeFactor;
      lonSize = latSize * this.lonRatio;
      lat1 = midLat - latSize;
      lat2 = midLat + latSize;
      lon1 = midLon - lonSize;
      lon2 = midLon + lonSize;
      if (this.params.debugBox) {
        if (box) this.ge.getFeatures().removeChild(box);
        kml = "<?xml version='1.0' encoding='UTF-8'?><kml xmlns='http://www.opengis.net/kml/2.2'><Document><Placemark><name>lookAt</name><Point><coordinates>" + lookLon + "," + lookLat + ",0</coordinates></Point></Placemark><Placemark><name>camera</name><Point><coordinates>" + cam.lon + "," + cam.lat + ",0</coordinates></Point></Placemark><Placemark><name>middle</name><Point><coordinates>" + midLon + "," + midLat + ",0</coordinates></Point></Placemark><Placemark><LineString><altitudeMode>absolute</altitudeMode><coordinates>" + lon1 + "," + lat1 + ",100 " + lon1 + "," + lat2 + ",100 " + lon2 + "," + lat2 + ",100 " + lon2 + "," + lat1 + ",50 " + lon1 + "," + lat1 + ",100</coordinates></LineString></Placemark></Document></kml>";
        box = this.ge.parseKml(kml);
        this.ge.getFeatures().appendChild(box);
      }
      _ref = this.featuresInBBox(lat1, lon1, lat2, lon2);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        f = _ref[_i];
        this.showFeature(f);
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

    FeatureSet.prototype.removeFeature = function(f) {
      this.featureManager.removeFeature(f);
      return delete this.features[f.id];
    };

    FeatureSet.prototype.clearFeatures = function() {
      var f, k, _ref, _results;
      _ref = this.features;
      _results = [];
      for (k in _ref) {
        if (!__hasProp.call(_ref, k)) continue;
        f = _ref[k];
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

    function Feature(id, lat, lon, opts) {
      this.id = id;
      this.lat = lat;
      this.lon = lon;
      this.opts = opts;
    }

    Feature.prototype.rect = function() {
      return {
        x: this.lon,
        y: this.lat,
        w: 0,
        h: 0
      };
    };

    Feature.prototype.show = function() {
      var angleToCamDeg, angleToCamRad, cam, fm, ge, geNode, st;
      fm = this.fm;
      cam = fm.cam;
      ge = fm.ge;
      angleToCamRad = Math.atan2(this.lon - cam.lon, this.lat - cam.lat);
      angleToCamDeg = angleToCamRad * oneEightyOverPi;
      st = new SkyText(this.lat, this.lon, this.alt, this.opts);
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
      geNode = ge.parseKml(st.kml());
      ge.getFeatures().appendChild(geNode);
      this.hide();
      return this.geNode = geNode;
    };

    Feature.prototype.hide = function() {
      if (this.geNode != null) {
        this.fm.ge.getFeatures().removeChild(this.geNode);
        return delete this.geNode;
      }
    };

    return Feature;

  })();

  this.RailStationSet = (function() {

    __extends(RailStationSet, FeatureSet);

    function RailStationSet(featureManager) {
      var code, lat, lon, name, row, station, _i, _len, _ref, _ref2;
      RailStationSet.__super__.constructor.call(this, featureManager);
      _ref = this.csv.split("\n");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        _ref2 = row.split(','), code = _ref2[0], name = _ref2[1], lat = _ref2[2], lon = _ref2[3];
        if (lat < 51.253320526331336 || lat > 51.73383267274113 || lon < -0.61248779296875 || lon > 0.32684326171875) {
          continue;
        }
        station = new RailStation("rail-" + code, parseFloat(lat), parseFloat(lon));
        station.name = "\uF001 " + name;
        this.addFeature(station);
      }
    }

    return RailStationSet;

  })();

  this.RailStation = (function() {

    __extends(RailStation, Feature);

    function RailStation() {
      RailStation.__super__.constructor.apply(this, arguments);
    }

    RailStation.prototype.alt = 130;

    RailStation.prototype.nameTextOpts = {
      size: 3
    };

    return RailStation;

  })();

  this.LeedsCitySet = (function() {

    __extends(LeedsCitySet, FeatureSet);

    function LeedsCitySet(featureManager) {
      var bb, lat, lch, lfs, lon, name, railLeeds, row, unileeds, _i, _len, _ref, _ref2;
      LeedsCitySet.__super__.constructor.call(this, featureManager);
      lch = new LeedsCivicHall("civic-hall", 53.80210025576234, -1.5485385060310364);
      this.addFeature(lch);
      unileeds = new UniLeeds("uni-of-leeds", 53.80786737971994, -1.5527737140655518);
      this.addFeature(unileeds);
      railLeeds = new RailLeeds("RailStation", 53.79437097083624, -1.5475326776504517);
      railLeeds.update();
      this.addFeature(railLeeds);
      bb = new LeedsTownHallClock('TownHallClock', 53.80005678340009, -1.5497106313705444);
      bb.update();
      this.addFeature(bb);
      _ref = this.csv.split("\n");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        _ref2 = row.split(','), lat = _ref2[0], lon = _ref2[1], name = _ref2[2];
        lfs = new LeedsFeature(name, parseFloat(lat), parseFloat(lon));
        lfs.name = name;
        this.addFeature(lfs);
      }
    }

    return LeedsCitySet;

  })();

  this.LeedsFeature = (function() {

    __extends(LeedsFeature, Feature);

    function LeedsFeature() {
      LeedsFeature.__super__.constructor.apply(this, arguments);
    }

    LeedsFeature.prototype.alt = Math.floor(Math.random() * (300 - 200 + 1) + 200);

    LeedsFeature.prototype.nameTextOpts = {
      size: 3,
      lineWidth: 2
    };

    LeedsFeature.prototype.descTextOpts = {
      size: 2,
      lineWidth: 1
    };

    return LeedsFeature;

  })();

  this.LeedsCivicHall = (function() {

    __extends(LeedsCivicHall, Feature);

    function LeedsCivicHall() {
      LeedsCivicHall.__super__.constructor.apply(this, arguments);
    }

    LeedsCivicHall.prototype.alt = 150;

    LeedsCivicHall.prototype.nameTextOpts = {
      size: 3,
      lineWidth: 2
    };

    LeedsCivicHall.prototype.descTextOpts = {
      size: 2,
      lineWidth: 1
    };

    LeedsCivicHall.prototype.name = "Leeds Civic Hall";

    LeedsCivicHall.prototype.desc = "";

    return LeedsCivicHall;

  })();

  this.RailLeeds = (function() {

    __extends(RailLeeds, Feature);

    function RailLeeds() {
      RailLeeds.__super__.constructor.apply(this, arguments);
    }

    RailLeeds.prototype.alt = 200;

    RailLeeds.prototype.nameTextOpts = {
      size: 3,
      lineWidth: 2
    };

    RailLeeds.prototype.descTextOpts = {
      size: 2,
      lineWidth: 1
    };

    RailLeeds.prototype.name = "\uF001 Leeds Rail Station";

    RailLeeds.prototype.desc = "Next Train: ";

    RailLeeds.prototype.update = function() {
      var self;
      this.desc = "Next Train: " + new Date().strftime('%H.%M');
      if (this.geNode != null) this.show();
      self = arguments.callee.bind(this);
      if (this.interval == null) {
        return this.interval = setInterval(self, 1 * 60 * 1000);
      }
    };

    return RailLeeds;

  })();

  this.UniLeeds = (function() {

    __extends(UniLeeds, Feature);

    function UniLeeds() {
      UniLeeds.__super__.constructor.apply(this, arguments);
    }

    UniLeeds.prototype.alt = 200;

    UniLeeds.prototype.nameTextOpts = {
      size: 3,
      lineWidth: 2
    };

    UniLeeds.prototype.descTextOpts = {
      size: 2,
      lineWidth: 1
    };

    UniLeeds.prototype.name = "University of Leeds";

    UniLeeds.prototype.desc = "";

    return UniLeeds;

  })();

  this.LeedsTownHallClock = (function() {

    __extends(LeedsTownHallClock, Feature);

    function LeedsTownHallClock() {
      LeedsTownHallClock.__super__.constructor.apply(this, arguments);
    }

    LeedsTownHallClock.prototype.alt = 200;

    LeedsTownHallClock.prototype.nameTextOpts = {
      size: 2,
      lineWidth: 2
    };

    LeedsTownHallClock.prototype.descTextOpts = {
      size: 2,
      lineWidth: 1
    };

    LeedsTownHallClock.prototype.update = function() {
      var self;
      this.name = new Date().strftime('%H.%M');
      this.desc = 'Leeds Town Hall';
      if (this.geNode != null) this.show();
      self = arguments.callee.bind(this);
      if (this.interval == null) {
        return this.interval = setInterval(self, 1 * 60 * 1000);
      }
    };

    return LeedsTownHallClock;

  })();

  this.TubeStationSet = (function() {

    __extends(TubeStationSet, FeatureSet);

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

  })();

  this.TubeStation = (function() {

    __extends(TubeStation, Feature);

    function TubeStation() {
      TubeStation.__super__.constructor.apply(this, arguments);
    }

    TubeStation.prototype.alt = 100;

    TubeStation.prototype.nameTextOpts = {
      size: 2,
      lineWidth: 1
    };

    return TubeStation;

  })();

  this.MiscSet = (function() {

    __extends(MiscSet, FeatureSet);

    function MiscSet(featureManager) {
      var bb, ch, logo, tb;
      MiscSet.__super__.constructor.call(this, featureManager);
      ch = new CityHall("city-hall", 51.50477580586208, -0.07864236831665039);
      this.addFeature(ch);
      logo = new CASALogo("casa-logo", 51.52192375643773, -0.13593167066574097);
      this.addFeature(logo);
      bb = new BigBen('big-ben', 51.5007286626542, -0.12459531426429749);
      bb.update();
      this.addFeature(bb);
      tb = new TowerBridge('twr-brdg', 51.50558385576479, -0.0754237174987793);
      tb.update();
      this.addFeature(tb);
    }

    return MiscSet;

  })();

  this.CityHall = (function() {

    __extends(CityHall, Feature);

    function CityHall() {
      CityHall.__super__.constructor.apply(this, arguments);
    }

    CityHall.prototype.alt = 120;

    CityHall.prototype.nameTextOpts = {
      size: 3,
      lineWidth: 2
    };

    CityHall.prototype.descTextOpts = {
      size: 2,
      lineWidth: 1
    };

    CityHall.prototype.name = "City Hall";

    CityHall.prototype.desc = "More London";

    return CityHall;

  })();

  this.CASALogo = (function() {

    __extends(CASALogo, Feature);

    function CASALogo() {
      CASALogo.__super__.constructor.apply(this, arguments);
    }

    CASALogo.prototype.alt = 220;

    CASALogo.prototype.nameTextOpts = {
      size: 1,
      lineWidth: 1
    };

    CASALogo.prototype.name = "\uF002";

    return CASALogo;

  })();

  this.CASAConf = (function() {

    __extends(CASAConf, Feature);

    function CASAConf() {
      CASAConf.__super__.constructor.apply(this, arguments);
    }

    CASAConf.prototype.alt = 130;

    CASAConf.prototype.nameTextOpts = {
      size: 2,
      lineWidth: 3
    };

    CASAConf.prototype.descTextOpts = {
      size: 1,
      lineWidth: 2
    };

    CASAConf.prototype.name = 'CASA Smart Cities';

    CASAConf.prototype.update = function() {
      var changed, d, d0, dayHrs, dayMs, desc, i, self, session, _len, _ref;
      d = new Date();
      d0 = new Date(d.getFullYear(), d.getMonth(), d.getDate());
      dayMs = d - d0;
      dayHrs = dayMs / 1000 / 60 / 60;
      _ref = this.schedule;
      for (i = 0, _len = _ref.length; i < _len; i++) {
        session = _ref[i];
        if (dayHrs < session[0]) {
          desc = "Now:\t" + this.schedule[i - 1][1] + "\nNext:\t" + session[1];
          break;
        }
      }
      changed = this.desc !== desc;
      this.desc = desc;
      if (changed && (this.geNode != null)) this.show();
      self = arguments.callee.bind(this);
      if (this.interval == null) {
        return this.interval = setInterval(self, 1 * 60 * 1000);
      }
    };

    return CASAConf;

  })();

  this.TubeStation = (function() {

    __extends(TubeStation, Feature);

    function TubeStation() {
      TubeStation.__super__.constructor.apply(this, arguments);
    }

    TubeStation.prototype.alt = 100;

    TubeStation.prototype.nameTextOpts = {
      size: 2,
      lineWidth: 1
    };

    return TubeStation;

  })();

  this.BigBen = (function() {

    __extends(BigBen, Feature);

    function BigBen() {
      BigBen.__super__.constructor.apply(this, arguments);
    }

    BigBen.prototype.alt = 200;

    BigBen.prototype.nameTextOpts = {
      size: 2,
      lineWidth: 2
    };

    BigBen.prototype.descTextOpts = {
      size: 2,
      lineWidth: 1
    };

    BigBen.prototype.update = function() {
      var self;
      this.name = new Date().strftime('%H.%M');
      this.desc = 'Big Ben';
      if (this.geNode != null) this.show();
      self = arguments.callee.bind(this);
      if (this.interval == null) {
        return this.interval = setInterval(self, 1 * 60 * 1000);
      }
    };

    return BigBen;

  })();

  this.TowerBridge = (function() {

    __extends(TowerBridge, Feature);

    function TowerBridge() {
      TowerBridge.__super__.constructor.apply(this, arguments);
    }

    TowerBridge.prototype.alt = 150;

    TowerBridge.prototype.nameTextOpts = {
      size: 2,
      lineWidth: 3
    };

    TowerBridge.prototype.name = 'Tower Bridge';

    TowerBridge.prototype.update = function() {
      var self;
      var _this = this;
      load({
        url: 'http://www.towerbridge.org.uk/TBE/EN/BridgeLiftTimes/',
        type: 'xml'
      }, function(data) {
        var cells, changed, desc, descs, i, x;
        cells = (function() {
          var _i, _len, _ref, _results;
          _ref = data.querySelectorAll('td');
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            x = _ref[_i];
            _results.push(x.innerHTML);
          }
          return _results;
        })();
        descs = (function() {
          var _results;
          _results = [];
          for (i = 0; i <= 5; i += 5) {
            _results.push("" + cells[i + 4] + " on " + cells[i] + " " + cells[i + 1] + " at " + cells[i + 2] + " for vessel " + cells[i + 3]);
          }
          return _results;
        })();
        desc = descs.join('\n');
        changed = _this.desc !== desc;
        _this.desc = desc;
        if (changed && (_this.geNode != null)) return _this.show();
      });
      self = arguments.callee.bind(this);
      if (this.interval == null) {
        return this.interval = setInterval(self, 4 * 60 * 60 * 1000);
      }
    };

    return TowerBridge;

  })();

  this.LondonTweetSet = (function() {

    __extends(LondonTweetSet, FeatureSet);

    LondonTweetSet.prototype.maxTweets = 500;

    function LondonTweetSet(featureManager) {
      LondonTweetSet.__super__.constructor.call(this, featureManager);
      this.update();
    }

    LondonTweetSet.prototype.update = function() {
      var self;
      var _this = this;
      load({
        url: 'http://www.casa.ucl.ac.uk/tom/ajax-live/lon_last_hour.json',
        type: 'json'
      }, function(data) {
        var dedupedTweets, i, k, lat, lon, t, tweet, _len, _ref, _results;
        _this.clearFeatures();
        dedupedTweets = {};
        _ref = data.results.slice(-_this.maxTweets);
        for (i = 0, _len = _ref.length; i < _len; i++) {
          t = _ref[i];
          dedupedTweets["" + (parseFloat(t.lat).toFixed(4)) + "/" + (parseFloat(t.lon).toFixed(4))] = t;
        }
        _results = [];
        for (k in dedupedTweets) {
          if (!__hasProp.call(dedupedTweets, k)) continue;
          t = dedupedTweets[k];
          lat = parseFloat(t.lat);
          lon = parseFloat(t.lon);
          if (isNaN(lat) || isNaN(lon)) continue;
          tweet = new Tweet("tweet-" + t.twitterID, lat, lon);
          tweet.name = "" + t.name + " — " + (t.dateT.match(/\d?\d:\d\d/));
          tweet.desc = t.twitterPost.replace(/&gt;/g, '>').replace(/&lt;/g, '<').match(/.{1,35}(\s|$)|\S+?(\s|$)/g).join('\n').replace(/\n+/g, '\n');
          _results.push(_this.addFeature(tweet));
        }
        return _results;
      });
      self = arguments.callee.bind(this);
      return setTimeout(self, 5 * 60 * 1000);
    };

    return LondonTweetSet;

  })();

  this.Tweet = (function() {

    __extends(Tweet, Feature);

    function Tweet() {
      Tweet.__super__.constructor.apply(this, arguments);
    }

    Tweet.prototype.alt = 160;

    Tweet.prototype.nameTextOpts = {
      size: 1
    };

    Tweet.prototype.descTextOpts = {
      size: 1,
      lineWidth: 1
    };

    return Tweet;

  })();

  this.LondonAirSet = (function() {

    __extends(LondonAirSet, FeatureSet);

    function LondonAirSet(featureManager) {
      LondonAirSet.__super__.constructor.call(this, featureManager);
      this.update();
    }

    LondonAirSet.prototype.update = function() {
      var self;
      var _this = this;
      load({
        url: 'http://orca.casa.ucl.ac.uk/~ollie/citydb/modules/airquality.php?city=london&format=csv'
      }, function(csv) {
        var a, cells, desc, headers, line, lines, metadata, no2desc, no2ugm3, o3desc, o3ugm3, pm10desc, pm10ugm3, _i, _len, _results;
        _this.clearFeatures();
        lines = csv.split('\n');
        metadata = lines.shift();
        headers = lines.shift();
        _results = [];
        for (_i = 0, _len = lines.length; _i < _len; _i++) {
          line = lines[_i];
          cells = line.split(',');
          if (cells.length < 10) continue;
          a = new LondonAir("air-" + cells[0], parseFloat(cells[3]), parseFloat(cells[4]));
          a.name = cells[1];
          desc = '';
          pm10ugm3 = cells[21];
          if (pm10ugm3 !== '') {
            pm10desc = cells[23];
            desc += "PM10:\t" + pm10ugm3 + " μg/m³ (" + pm10desc + ")\n";
          }
          no2ugm3 = cells[9];
          if (no2ugm3 !== '') {
            no2desc = cells[11];
            desc += "NO₂:\t" + no2ugm3 + " μg/m³ (" + no2desc + ")\n";
          }
          o3ugm3 = cells[5];
          if (o3ugm3 !== '') {
            o3desc = cells[7];
            desc += "O₃: \t" + o3ugm3 + " μg/m³ (" + o3desc + ")\n";
          }
          a.desc = desc;
          _results.push(_this.addFeature(a));
        }
        return _results;
      });
      self = arguments.callee.bind(this);
      return setTimeout(self, 10 * 60 * 1000);
    };

    return LondonAirSet;

  })();

  this.LondonAir = (function() {

    __extends(LondonAir, Feature);

    function LondonAir() {
      LondonAir.__super__.constructor.apply(this, arguments);
    }

    LondonAir.prototype.alt = 180;

    LondonAir.prototype.nameTextOpts = {
      size: 2
    };

    LondonAir.prototype.descTextOpts = {
      size: 2,
      lineWidth: 1
    };

    return LondonAir;

  })();

  this.LondonTrafficSet = (function() {

    __extends(LondonTrafficSet, FeatureSet);

    function LondonTrafficSet(featureManager) {
      LondonTrafficSet.__super__.constructor.call(this, featureManager);
      this.update();
    }

    LondonTrafficSet.prototype.update = function() {
      var self;
      var _this = this;
      load({
        url: 'http://orca.casa.ucl.ac.uk/~ollie/citydb/modules/roadsigns.php?city=london&format=csv'
      }, function(csv) {
        var a, cells, headers, line, lines, metadata, s, _i, _len, _results;
        _this.clearFeatures();
        lines = csv.split('\n');
        metadata = lines.shift();
        headers = lines.shift();
        _results = [];
        for (_i = 0, _len = lines.length; _i < _len; _i++) {
          line = lines[_i];
          cells = line.split(',');
          if (cells.length < 5) continue;
          a = new LondonTraffic("trf-" + cells[0], parseFloat(cells[3]), parseFloat(cells[4]));
          a.name = cells[11];
          a.desc = ((function() {
            var _j, _len2, _ref, _results2;
            _ref = cells.slice(5, 9);
            _results2 = [];
            for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
              s = _ref[_j];
              _results2.push(s.match(/^\s*(.*?)\s*$/)[1]);
            }
            return _results2;
          })()).join('\n');
          _results.push(_this.addFeature(a));
        }
        return _results;
      });
      self = arguments.callee.bind(this);
      return setTimeout(self, 3 * 60 * 1000);
    };

    return LondonTrafficSet;

  })();

  this.LondonTraffic = (function() {

    __extends(LondonTraffic, Feature);

    function LondonTraffic() {
      LondonTraffic.__super__.constructor.apply(this, arguments);
    }

    LondonTraffic.prototype.alt = 150;

    LondonTraffic.prototype.nameTextOpts = {
      size: 2,
      lineWidth: 2
    };

    LondonTraffic.prototype.descTextOpts = {
      size: 2,
      lineWidth: 1
    };

    return LondonTraffic;

  })();

  this.TideGaugeSet = (function() {

    __extends(TideGaugeSet, FeatureSet);

    function TideGaugeSet(featureManager) {
      TideGaugeSet.__super__.constructor.call(this, featureManager);
      this.update();
    }

    TideGaugeSet.prototype.update = function() {
      var self;
      var _this = this;
      load({
        url: 'http://orca.casa.ucl.ac.uk/~ollie/citydb/modules/tide.php?city=london&format=csv'
      }, function(csv) {
        var a, cells, headers, line, lines, metadata, _i, _len, _results;
        _this.clearFeatures();
        lines = csv.split('\n');
        metadata = lines.shift();
        headers = lines.shift();
        _results = [];
        for (_i = 0, _len = lines.length; _i < _len; _i++) {
          line = lines[_i];
          cells = line.split(',');
          if (cells.length < 3) continue;
          a = new TideGauge("tide-" + cells[0], parseFloat(cells[3]), parseFloat(cells[4]));
          a.name = cells[1];
          a.desc = "Height:\t" + cells[5] + "m\nSurge:\t" + cells[6] + "m";
          _results.push(_this.addFeature(a));
        }
        return _results;
      });
      self = arguments.callee.bind(this);
      return setTimeout(self, 3 * 60 * 1000);
    };

    return TideGaugeSet;

  })();

  this.TideGauge = (function() {

    __extends(TideGauge, Feature);

    function TideGauge() {
      TideGauge.__super__.constructor.apply(this, arguments);
    }

    TideGauge.prototype.alt = 80;

    TideGauge.prototype.nameTextOpts = {
      size: 2,
      lineWidth: 3
    };

    TideGauge.prototype.descTextOpts = {
      size: 2,
      lineWidth: 2
    };

    return TideGauge;

  })();

  this.OlympicSet = (function() {

    __extends(OlympicSet, FeatureSet);

    function OlympicSet(featureManager) {
      var code, date, day, desc, end, lat, lon, name, row, sport, start, t1, t2, times, venue, _base, _i, _j, _len, _len2, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
      OlympicSet.__super__.constructor.call(this, featureManager);
      this.venues = [];
      this.events = {};
      _ref = this.venueData.split("\n");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        _ref2 = row.split("\t"), lat = _ref2[0], lon = _ref2[1], name = _ref2[2];
        if (name === 'Multiple Venues' || name === 'Olympic Park') continue;
        this.venues.push({
          name: name,
          lat: parseFloat(lat),
          lon: parseFloat(lon)
        });
      }
      _ref3 = this.eventData.split("\n");
      for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
        row = _ref3[_j];
        _ref4 = row.split("\t"), day = _ref4[0], date = _ref4[1], times = _ref4[2], sport = _ref4[3], desc = _ref4[4], code = _ref4[5], venue = _ref4[6];
        _ref5 = times.split("-"), t1 = _ref5[0], t2 = _ref5[1];
        start = new Date("" + date + " " + t1);
        end = new Date("" + date + " " + t2);
        if ((_ref6 = (_base = this.events)[venue]) == null) _base[venue] = [];
        this.events[venue].push({
          start: start,
          end: end,
          sport: sport,
          desc: desc
        });
      }
      this.update();
    }

    OlympicSet.prototype.update = function() {
      var a, event, i, nextEvent, now, self, venue, _i, _len, _len2, _ref, _ref2, _ref3, _ref4;
      this.clearFeatures();
      _ref = this.venues;
      for (i = 0, _len = _ref.length; i < _len; i++) {
        venue = _ref[i];
        a = new OlympicVenue("oly-" + venue.name, venue.lat, venue.lon);
        a.name = "\uF003 " + venue.name;
        a.alt += (i % 5) * 30;
        if ((_ref2 = venue.name) !== 'Orbit') {
          now = new Date();
          nextEvent = null;
          _ref4 = (_ref3 = this.events[venue.name]) != null ? _ref3 : [];
          for (_i = 0, _len2 = _ref4.length; _i < _len2; _i++) {
            event = _ref4[_i];
            if (event.end > now) {
              nextEvent = event;
              break;
            }
          }
          if (nextEvent != null) {
            a.desc = nextEvent.start < now ? "Now: " + nextEvent.sport : "Next event: " + nextEvent.sport + ", " + (nextEvent.start.strftime("%a %d %b, %H:%M"));
          }
        }
        this.addFeature(a);
      }
      self = arguments.callee.bind(this);
      return setTimeout(self, 7 * 60 * 1000);
    };

    return OlympicSet;

  })();

  this.OlympicVenue = (function() {

    __extends(OlympicVenue, Feature);

    function OlympicVenue() {
      OlympicVenue.__super__.constructor.apply(this, arguments);
    }

    OlympicVenue.prototype.alt = 120;

    OlympicVenue.prototype.nameTextOpts = {
      size: 3,
      lineWidth: 3
    };

    OlympicVenue.prototype.descTextOpts = {
      size: 2,
      lineWidth: 2
    };

    return OlympicVenue;

  })();

}).call(this);
