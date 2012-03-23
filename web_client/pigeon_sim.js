(function() {
  var __hasProp = Object.prototype.hasOwnProperty,
    __slice = Array.prototype.slice;

  google.load('earth', '1.x');

  window.onload = function() {
    var addLayers, altStatus, animTick, animTicks, animTimeout, cam, camMoves, compassPts, connect, debugDataStatus, debugEarthAPIStatus, debugTicksStatus, earthInitCallback, el, flapAmount, flown, ge, headingStatus, id, inMsgs, k, kvp, lastFlap, latFactor, lonFactor, lonRatio, moveCam, objClone, objsEq, params, pi, piOver180, resetCam, seenCam, speed, titleStatus, truncNum, twoPi, updateCam, v, w, wrapDegs180, wrapDegs360, _i, _len, _ref, _ref2, _ref3;
    if (!window.WebSocket) {
      alert('This app needs browser WebSocket support');
      return;
    }
    el = function(id) {
      return document.getElementById(id);
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
    params = {
      startLat: 51.520113,
      startLon: -0.130956,
      startHeading: 55,
      startAlt: 80,
      minAlt: 5,
      speed: 3,
      maxSpeed: 6,
      diveSpeed: 0.15,
      diveAccel: 0.05,
      diveDecel: 0.05,
      flapSize: 2,
      flapDecay: 0.8,
      maxRoll: 80,
      turnSpeed: 0.075,
      credits: 0,
      status: 1,
      timeControl: 0,
      debugData: 0,
      reconnectWait: 2,
      ws: 'ws://127.0.0.1:8888/p5websocket'
    };
    _ref = window.location.search.substring(1).split('&');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      kvp = _ref[_i];
      _ref2 = kvp.split('='), k = _ref2[0], v = _ref2[1];
      params[k] = k === 'ws' ? v : parseFloat(v);
    }
    if (params.credits) el('creditOuter').style.display = 'block';
    if (params.status) el('statusOuter').style.display = 'block';
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
    ge = cam = seenCam = flown = animTimeout = null;
    animTicks = camMoves = inMsgs = 0;
    lastFlap = flapAmount = 0;
    pi = Math.PI;
    twoPi = pi * 2;
    piOver180 = pi / 180;
    compassPts = w('N NE E SE S SW W NW N');
    speed = params.speed;
    latFactor = 0.00001;
    lonRatio = 1 / Math.cos(params.startLat * piOver180);
    lonFactor = latFactor * lonRatio;
    resetCam = function() {
      cam = {
        lat: params.startLat,
        lon: params.startLon,
        heading: params.startHeading,
        alt: params.startAlt,
        roll: 0.0000001,
        tilt: 90
      };
      return flown = false;
    };
    moveCam = function() {
      var c, unmoved, view;
      camMoves += 1;
      if (params.debugData) debugEarthAPIStatus.innerHTML = camMoves;
      unmoved = objsEq(cam, seenCam);
      if (unmoved) return false;
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
    updateCam = function(data) {
      var alt, altDelta, flapDiff, heading, headingDelta, headingRad, latDelta, lonDelta, roll;
      if (data.reset && flown) resetCam();
      if (data.roll == null) return;
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
      heading = cam.heading + headingDelta;
      headingRad = heading * piOver180;
      latDelta = Math.cos(headingRad) * speed * latFactor;
      lonDelta = Math.sin(headingRad) * speed * lonFactor;
      alt = cam.alt + altDelta;
      if (alt < params.minAlt) alt = params.minAlt;
      cam.lat += latDelta;
      cam.lon += lonDelta;
      cam.heading = heading;
      cam.alt = alt;
      cam.roll = roll;
      return cam.tilt = 90 - data.dive;
    };
    animTick = function() {
      var moved;
      animTicks += 1;
      if (params.debugData) debugTicksStatus.innerHTML = animTicks;
      headingStatus.innerHTML = compassPts[Math.round(wrapDegs360(cam.heading) / 45)];
      altStatus.innerHTML = "" + (Math.round(cam.alt)) + "m";
      moved = moveCam();
      if (animTimeout != null) clearTimeout(animTimeout);
      animTimeout = null;
      if (!moved) return animTimeout = setTimeout(animTick, 200);
    };
    connect = function() {
      var ws;
      ws = new WebSocket(params.ws);
      titleStatus.style.color = '#ff0';
      ws.onopen = function() {
        return titleStatus.style.color = '#fff';
      };
      ws.onclose = function() {
        titleStatus.style.color = '#f00';
        return setTimeout(connect, params.reconnectWait * 1000);
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
      window.ge = ge = instance;
      console.log("Google Earth plugin v" + (ge.getPluginVersion()) + ", API v" + (ge.getApiVersion()));
      addLayers(ge.LAYER_TERRAIN, ge.LAYER_TREES, ge.LAYER_BUILDINGS, ge.LAYER_BUILDINGS_LOW_RESOLUTION);
      ge.getOptions().setAtmosphereVisibility(true);
      ge.getSun().setVisibility(true);
      ge.getTime().getControl().setVisibility(params.timeControl ? ge.VISIBILITY_SHOW : ge.VISIBILITY_HIDE);
      ge.getOptions().setFlyToSpeed(ge.SPEED_TELEPORT);
      resetCam();
      ge.getWindow().setVisibility(true);
      animTick();
      return google.earth.addEventListener(ge, 'frameend', animTick);
    };
    google.earth.createInstance('earth', earthInitCallback, function() {
      return console.log("Google Earth error: " + errorCode);
    });
    return connect();
  };

}).call(this);
