(function() {

  /*
  
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
  */

  var CountUpTimer, globalTimer, make;
  var __hasProp = Object.prototype.hasOwnProperty, __slice = Array.prototype.slice, __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (__hasProp.call(this, i) && this[i] === item) return i; } return -1; };

  google.setOnLoadCallback(function() {
    var addLayers, adjustMapping, altStatus, animTick, animTicks, animTimeout, areYouThereScotty, beamMeUp, cam, camMoves, compassPts, connect, counterlastFlap, debugDataStatus, debugEarthAPIStatus, debugTicksStatus, earthInitCallback, el, els, features, flapAmount, flapsCount, flown, fm, ge, headingStatus, id, inMsgs, k, kvp, lastFlap, lastMove, latFactor, leapMotion, lonFactor, lonRatio, moveCam, objClone, objsEq, params, pi, piOver180, resetCam, seenCam, speed, sprBeamSound, sprStartSound, sprec, sprecListening, titleStatus, truncNum, twoPi, updateCam, v, w, wrapDegs180, wrapDegs360, _i, _len, _ref, _ref2, _ref3;
    if (!window.WebSocket) {
      alert('This app needs browser WebSocket support');
      return;
    }
    el = function(id) {
      return document.getElementById(id);
    };
    els = function(sel) {
      return document.querySelectorAll(sel);
    };
    w = function(s) {
      return s.split(/\s+/);
    };
    objsEq = function(o1, o2) {
      var k, v;
      if (o2 == null) o2 = {};
      for (k in o1) {
        if (!__hasProp.call(o1, k)) continue;
        v = o1[k];
        if (o2[k] !== v) return false;
      }
      return true;
    };
    objClone = function(o1, o2) {
      var k, v;
      if (o2 == null) o2 = {};
      for (k in o1) {
        if (!__hasProp.call(o1, k)) continue;
        v = o1[k];
        o2[k] = v;
      }
      return o2;
    };
    truncNum = function(n, dp) {
      if (dp == null) dp = 2;
      if (typeof n === 'number') {
        return parseFloat(n.toFixed(dp));
      } else {
        return n;
      }
    };
    wrapDegs360 = function(d) {
      while (d < 0) {
        d += 360;
      }
      while (d >= 360) {
        d -= 360;
      }
      return d;
    };
    wrapDegs180 = function(d) {
      while (d < -180) {
        d += 360;
      }
      while (d >= 180) {
        d -= 360;
      }
      return d;
    };
    flapsCount = 0;
    params = {
      startLat: 51.5035,
      startLon: -0.0742,
      startHeading: 302,
      city: "London",
      startAlt: 80,
      minAlt: 5,
      maxAlt: 400,
      speed: 4,
      maxSpeed: 5,
      cruiseTilt: 87,
      diveSpeed: 0.15,
      diveAccel: 0.05,
      diveDecel: 0.1,
      flapSize: 1,
      flapDecay: 0.8,
      maxRoll: 80,
      turnSpeed: 0.075,
      status: 1,
      debugData: 0,
      atmosphere: 1,
      sun: 0,
      timeControl: 0,
      resetTimeout: 60,
      featureSkip: 12,
      debugBox: 0,
      reconnectWait: 2,
      ws: 'ws://127.0.0.1:8888/p5websocket',
      leapOptions: {
        enableGestures: true
      },
      timeStampDelta: 4,
      enableLeap: 0,
      leapOptions: {
        enableGestures: true
      },
      rollMultiplier: 40,
      geocodeSuffix: '',
      beamLatOffset: -0.0075,
      features: 'air,rail,traffic,tide,twitter,olympics,misc,distance',
      teleport: 0,
      timer: 0,
      flapCounter: 0
    };
    _ref = window.location.search.substring(1).split('&');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      kvp = _ref[_i];
      _ref2 = kvp.split('='), k = _ref2[0], v = _ref2[1];
      params[k] = k === 'ws' || k === 'features' || k === 'geocodeSuffix' || k === 'city' ? v.toLowerCase() : parseFloat(v);
      if (k === 'startLng') params['startLon'] = parseFloat(v);
    }
    if (params.city === "leeds") {
      params.startLat = 53.79852807423503;
      params.startLon = -1.5497589111328125;
      params.startHeading = 12;
      params.startAlt = 100;
      params.speed = 3;
      params.features += ',leeds';
    } else if (params.city === "london") {
      params.startLat = 51.5035;
      params.startLon = -0.0742;
      params.startHeading = 302;
      params.startAlt = 80;
    }
    features = params.features.split(',');
    if (params.status) el('statusOuter').style.display = 'block';
    if (params.debugData) el('credit').style.display = 'none';
    _ref3 = (function() {
      var _j, _len2, _ref3, _results;
      _ref3 = w('title alt debugData debugEarthAPI debugTicks heading');
      _results = [];
      for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
        id = _ref3[_j];
        _results.push(el(id));
      }
      return _results;
    })(), titleStatus = _ref3[0], altStatus = _ref3[1], debugDataStatus = _ref3[2], debugEarthAPIStatus = _ref3[3], debugTicksStatus = _ref3[4], headingStatus = _ref3[5];
    window.cam = cam = {};
    ge = seenCam = flown = animTimeout = fm = lastMove = null;
    animTicks = camMoves = inMsgs = 0;
    lastFlap = flapAmount = counterlastFlap = 0;
    if (params.flapCounter) $("#userFlaps").html("Flaps: 0");
    pi = Math.PI;
    twoPi = pi * 2;
    piOver180 = pi / 180;
    compassPts = w('N NE E SE S SW W NW N');
    speed = params.speed;
    latFactor = 0.00001;
    lonRatio = 1 / Math.cos(params.startLat * piOver180);
    lonFactor = latFactor * lonRatio;
    resetCam = function(lat, lon, heading) {
      cam.lat = lat != null ? lat : params.startLat;
      cam.lon = lon != null ? lon : params.startLon;
      cam.heading = heading != null ? heading : params.startHeading;
      cam.alt = params.startAlt;
      cam.roll = 0.0000001;
      cam.tilt = params.cruiseTilt;
      lastMove = new Date();
      flapsCount = 0;
      $("#flapNum").html(flapsCount);
      flown = false;
      clearInterval(globalTimer);
      if (params.timer) {
        clearInterval(globalTimer);
        CountUpTimer(0, 0, 0, "timer");
      }
      if (params.flapCounter) return $("#userFlaps").html("Flaps: 0");
    };
    moveCam = function() {
      var c, unmoved, view;
      camMoves += 1;
      if (params.debugData) debugEarthAPIStatus.innerHTML = camMoves;
      unmoved = objsEq(cam, seenCam);
      if (unmoved) return false;
      lastMove = new Date();
      view = ge.getView();
      c = view.copyAsCamera(ge.ALTITUDE_ABSOLUTE);
      c.setLatitude(cam.lat);
      c.setLongitude(cam.lon);
      c.setAltitude(cam.alt);
      c.setHeading(cam.heading);
      c.setTilt(cam.tilt);
      c.setRoll(cam.roll);
      view.setAbstractView(c);
      seenCam = objClone(cam);
      if (params.debugData) {
        debugEarthAPIStatus.innerHTML += ' ' + JSON.stringify(cam, function(k, v) {
          return truncNum(v);
        });
      }
      return true;
    };
    addLayers = function() {
      var l, layers, _j, _len2, _results;
      layers = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      _results = [];
      for (_j = 0, _len2 = layers.length; _j < _len2; _j++) {
        l = layers[_j];
        _results.push(ge.getLayerRoot().enableLayerById(l, true));
      }
      return _results;
    };
    if (params.teleport === 1) {
      sprecListening = false;
      console.log("Beam me up (speech teleporter) loaded");
      sprStartSound = make({
        tag: 'audio',
        src: 'http://www.stdimension.org/MediaLib/effects/technology/federation/commbadge.wav',
        preload: 'auto'
      });
      sprBeamSound = make({
        tag: 'audio',
        src: 'http://www.stdimension.org/MediaLib/effects/technology/federation/beam1a.wav',
        preload: 'auto'
      });
      areYouThereScotty = function(recognition) {
        var baseURL, conf, result, transcript, _ref4, _ref5;
        console.log('Speech recognition results: ', recognition);
        result = (_ref4 = recognition.results) != null ? (_ref5 = _ref4[0]) != null ? _ref5[0] : void 0 : void 0;
        if (!result) return;
        conf = result.confidence;
        if (!(result.confidence > 0.33)) return;
        transcript = result.transcript;
        if (transcript === 'u c l') transcript = 'ucl';
        if (transcript === 'home') transcript = '90 tottenham court road';
        console.log('Scotty heard: ', transcript);
        baseURL = 'https://maps.googleapis.com/maps/api/geocode/json';
        return load({
          url: "" + baseURL + "?sensor=false&components=country:GB&address=" + (encodeURIComponent(transcript)) + params.geocodeSuffix,
          type: 'json'
        }, beamMeUp);
      };
      beamMeUp = function(geocoding) {
        var lat, lng, loc, _ref4, _ref5, _ref6;
        console.log('Geocoding results: ', geocoding);
        if (geocoding.status !== 'OK') return;
        loc = (_ref4 = geocoding.results) != null ? (_ref5 = _ref4[0]) != null ? (_ref6 = _ref5.geometry) != null ? _ref6.location : void 0 : void 0 : void 0;
        if (!loc) return;
        sprBeamSound.play();
        lat = loc.lat, lng = loc.lng;
        lat += params.beamLatOffset;
        console.log('Beaming you to: ', lat, lng);
        resetCam(lat, lng, 0);
        return fm.reset();
      };
      window.sprec = sprec = new webkitSpeechRecognition();
      sprec.lang = 'en-gb';
      sprec.onstart = function(e) {
        sprec.stop();
        return sprec.onstart = null;
      };
      sprec.start();
      sprec.onresult = areYouThereScotty;
      sprec.onerror = sprec.onnomatch = function(e) {
        return console.log(e);
      };
    }
    updateCam = function(data) {
      var alt, altDelta, flapDiff, heading, headingDelta, headingRad, latDelta, lonDelta, roll;
      if (data.reset === 1 && !sprecListening) {
        if (params.teleport === 1) {
          sprecListening = true;
          sprStartSound.play();
          sprec.start();
          console.log('sprec started');
        }
      }
      if (data.reset !== 1 && sprecListening) {
        if (params.teleport === 1) {
          sprecListening = false;
          sprec.stop();
          console.log('sprec stopped');
        }
      }
      if (flown && data.reset === 1) {
        resetCam();
        fm.reset();
      }
      if (data.reset === 2) window.location.reload();
      if (data.roll == null) return;
      if (params.flapCounter) {
        if (data.flap !== 0.0) {
          if (counterlastFlap === 0) flapsCount++;
          $("#userFlaps").html("Flaps: " + flapsCount);
        }
        counterlastFlap = data.flap;
      }
      flown = true;
      altDelta = 0;
      if (data.dive > 0) {
        altDelta = -data.dive * params.diveSpeed * speed;
        speed += data.dive * params.diveAccel;
        if (speed > params.maxSpeed) speed = params.maxSpeed;
      } else {
        speed -= params.diveDecel;
        if (speed < params.speed) speed = params.speed;
      }
      flapDiff = data.flap - lastFlap;
      if (flapDiff > 0) flapAmount += params.flapSize * flapDiff;
      if (flapAmount > 0) altDelta += flapAmount;
      flapAmount *= params.flapDecay;
      lastFlap = data.flap;
      roll = data.roll;
      if (roll > params.maxRoll) roll = params.maxRoll;
      if (roll < -params.maxRoll) roll = -params.maxRoll;
      headingDelta = -roll * params.turnSpeed;
      heading = wrapDegs360(cam.heading + headingDelta);
      headingRad = heading * piOver180;
      latDelta = Math.cos(headingRad) * speed * latFactor;
      lonDelta = Math.sin(headingRad) * speed * lonFactor;
      alt = cam.alt + altDelta;
      if (alt < params.minAlt) alt = params.minAlt;
      if (alt > params.maxAlt) alt = params.maxAlt;
      cam.lat += latDelta;
      cam.lon += lonDelta;
      cam.heading = heading;
      cam.alt = alt;
      cam.roll = roll;
      return cam.tilt = params.cruiseTilt - data.dive;
    };
    animTick = function() {
      var moved;
      if (params.debugData) debugTicksStatus.innerHTML = animTicks;
      headingStatus.innerHTML = compassPts[Math.round(wrapDegs360(cam.heading) / 45)];
      altStatus.innerHTML = "" + (Math.round(cam.alt)) + "m";
      moved = moveCam();
      if (animTicks % params.featureSkip === 0) {
        if (flown && new Date() - lastMove > params.resetTimeout * 1000) {
          resetCam();
          fm.reset();
        } else {
          fm.update();
        }
      }
      if (animTimeout != null) clearTimeout(animTimeout);
      animTimeout = null;
      if (!moved) animTimeout = setTimeout(animTick, 200);
      return animTicks += 1;
    };
    leapMotion = function() {
      var controller;
      if (params.enableLeap) {
        console.log("Leap Called!");
        controller = new Leap.Controller(params.leapOptions);
        return controller.loop(function(frame) {
          var dive, flap, heightDelta, palmHeight, roll;
          if (frame.hands.length === 1) {
            if (frame.timestamp % params.timeStampDelta === 0) {
              roll = Math.atan2(frame.hands[0].palmNormal[0], -frame.hands[0].palmNormal[1]);
              palmHeight = frame.hands[0].palmPosition[1];
              heightDelta = Math.round(adjustMapping(palmHeight, 0, 300, 0, 2));
              dive = 0;
              flap = 0;
              if (heightDelta < 1) dive = 1;
              if (heightDelta > 1) flap = 1;
              return updateCam({
                "roll": roll * params.rollMultiplier,
                "flap": flap,
                "dive": dive
              });
            }
          }
        });
      }
    };
    adjustMapping = function(value, r0, r1, r2, r3) {
      var mag = Math.abs(value - r0), sgn = value < 0 ? -1 : 1;;      return sgn * mag * (r3 - r2) / (r1 - r0);
    };
    connect = function() {
      var ws;
      ws = new WebSocket(params.ws);
      titleStatus.style.color = '#ff0';
      ws.onopen = function() {
        titleStatus.style.color = '#fff';
        return ge.getNavigationControl().setVisibility(ge.VISIBILITY_HIDE);
      };
      ws.onclose = function() {
        titleStatus.style.color = '#f00';
        setTimeout(connect, params.reconnectWait * 1000);
        return ge.getNavigationControl().setVisibility(ge.VISIBILITY_AUTO);
      };
      return ws.onmessage = function(e) {
        var data;
        inMsgs += 1;
        data = JSON.parse(e.data);
        if (params.debugData) {
          debugDataStatus.innerHTML = "" + inMsgs + " " + (JSON.stringify(data, function(k, v) {
            return truncNum(v);
          }));
        }
        return updateCam(data);
      };
    };
    earthInitCallback = function(instance) {
      var ccs, dis, las, lds, lts, ovs, rss, tgs, trs, tss;
      window.ge = ge = instance;
      console.log("Google Earth plugin v" + (ge.getPluginVersion()) + ", API v" + (ge.getApiVersion()));
      addLayers(ge.LAYER_TERRAIN, ge.LAYER_TREES, ge.LAYER_BUILDINGS, ge.LAYER_BUILDINGS_LOW_RESOLUTION);
      ge.getOptions().setAtmosphereVisibility(params.atmosphere);
      ge.getSun().setVisibility(params.sun);
      ge.getTime().getControl().setVisibility(params.timeControl ? ge.VISIBILITY_SHOW : ge.VISIBILITY_HIDE);
      ge.getOptions().setFlyToSpeed(ge.SPEED_TELEPORT);
      resetCam();
      ge.getWindow().setVisibility(true);
      fm = new FeatureManager(ge, lonRatio, cam, params);
      if (__indexOf.call(features, 'air') >= 0) las = new LondonAirSet(fm);
      if (__indexOf.call(features, 'tube') >= 0) tss = new TubeStationSet(fm);
      if (__indexOf.call(features, 'rail') >= 0) rss = new RailStationSet(fm);
      if (__indexOf.call(features, 'traffic') >= 0) trs = new LondonTrafficSet(fm);
      if (__indexOf.call(features, 'tide') >= 0) tgs = new TideGaugeSet(fm);
      if (__indexOf.call(features, 'misc') >= 0) ccs = new MiscSet(fm);
      if (__indexOf.call(features, 'twitter') >= 0) lts = new LondonTweetSet(fm);
      if (__indexOf.call(features, 'olympics') >= 0 && new Date("2012-08-12") - new Date() > 0) {
        ovs = new OlympicSet(fm);
      }
      if (__indexOf.call(features, 'leeds') >= 0) lds = new LeedsCitySet(fm);
      if (__indexOf.call(features, 'distance') >= 0) {
        dis = new DistanceSensorSet(fm);
      }
      google.earth.addEventListener(ge, 'frameend', animTick);
      animTick();
      connect();
      return leapMotion();
    };
    return google.earth.createInstance('earth', earthInitCallback, function(errMsg) {
      return console.log("Google Earth error: " + errMsg);
    });
  });

  google.load('earth', '1', {
    'other_params': 'sensor=false'
  });

  make = function(opts) {
    var c, k, t, v, _i, _len, _ref;
    if (opts == null) opts = {};
    t = document.createElement((_ref = opts.tag) != null ? _ref : 'div');
    for (k in opts) {
      if (!__hasProp.call(opts, k)) continue;
      v = opts[k];
      switch (k) {
        case 'tag':
          continue;
        case 'parent':
          v.appendChild(t);
          break;
        case 'kids':
          for (_i = 0, _len = v.length; _i < _len; _i++) {
            c = v[_i];
            if (c != null) t.appendChild(c);
          }
          break;
        case 'prevSib':
          v.parentNode.insertBefore(t, v.nextSibling);
          break;
        case 'text':
          t.appendChild(text(v));
          break;
        case 'cls':
          t.className = v;
          break;
        default:
          t[k] = v;
      }
    }
    return t;
  };

  globalTimer = void 0;

  CountUpTimer = function(secStart, minStart, hrStart, id) {
    var hr, min, sec, selector, start;
    selector = document.getElementById(id);
    sec = secStart;
    min = minStart;
    hr = hrStart;
    start = function() {
      var hrDisp, minDisp, secDisp;
      secDisp = "";
      minDisp = "";
      hrDisp = "";
      if (sec < 10) {
        secDisp = "0" + sec;
      } else {
        secDisp = sec;
      }
      if (sec > 59) {
        min++;
        sec = 0;
      }
      if (min < 10) {
        minDisp = "0" + min;
      } else {
        minDisp = min;
      }
      if (min > 59) {
        hr++;
        min = 0;
      }
      if (hr < 10) {
        hrDisp = "0" + hr;
      } else {
        hrDisp = hr;
      }
      if (sec === 0) secDisp = "00";
      if (min === 0) minDisp = "00";
      if (hr === 0) hrDisp = "00";
      selector.innerHTML = hrDisp + ":" + minDisp + ":" + secDisp;
      return sec++;
    };
    return globalTimer = setInterval(start, 1000);
  };

  CountUpTimer(0, 0, 0, "timer");

}).call(this);
