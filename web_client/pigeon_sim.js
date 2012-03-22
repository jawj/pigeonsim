(function() {
  var __slice = Array.prototype.slice;

  google.load('earth', '1.x');

  window.onload = function() {
    var addLayers, altStatus, apiSent, compassPts, connect, data, debugDataStatus, debugEarthAPIStatus, debugTicksStatus, earthInitCallback, el, fallbackTimeout, flapAmount, flown, ge, goToStart, headingStatus, k, kvp, lastFlap, latFactor, lonFactor, moveCam, params, pi, piOver180, speed, speedFactor, tick, tickNum, titleStatus, truncNum, twoPi, v, wls, wrapDegs180, wrapDegs360, _i, _len, _ref, _ref2;
    if (!window.WebSocket) {
      alert('This app needs browser WebSocket support');
      return;
    }
    el = function(id) {
      return document.getElementById(id);
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
      speed: 4,
      maxSpeed: 10,
      diveSpeed: 0.15,
      diveAccel: 0.05,
      diveDecel: 0.025,
      flapSize: 2,
      flapDecay: 0.8,
      maxRoll: 80,
      turnSpeed: 0.075,
      credits: 0,
      status: 1,
      geStatusBar: 0,
      geTimeCtrl: 0,
      debugData: 0,
      reconnectWait: 1,
      ws: 'ws://127.0.0.1:8888/p5websocket'
    };
    wls = window.location.search;
    _ref = wls.substring(1).split('&');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      kvp = _ref[_i];
      _ref2 = kvp.split('='), k = _ref2[0], v = _ref2[1];
      params[k] = k === 'ws' ? v : parseFloat(v);
    }
    if (params.credits) el('creditOuter').style.display = 'block';
    if (params.status) el('statusOuter').style.display = 'block';
    titleStatus = el('title');
    altStatus = el('alt');
    debugDataStatus = el('debugData');
    debugEarthAPIStatus = el('debugEarthAPI');
    debugTicksStatus = el('debugTicks');
    headingStatus = el('heading');
    ge = flown = null;
    pi = Math.PI;
    twoPi = pi * 2;
    piOver180 = pi / 180;
    compassPts = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N'];
    speedFactor = 0.00001;
    lonFactor = 1 / Math.cos(params.startLat * piOver180);
    latFactor = speedFactor;
    lonFactor = speedFactor * lonFactor;
    apiSent = 0;
    moveCam = function(o) {
      var c;
      if (o == null) o = {};
      apiSent += 1;
      if (params.debugData) {
        debugEarthAPIStatus.innerHTML = "" + apiSent + " " + (JSON.stringify(o, function(k, v) {
          return truncNum(v);
        }));
      }
      c = ge.getView().copyAsCamera(ge.ALTITUDE_ABSOLUTE);
      if (o.lat) c.setLatitude(o.lat);
      if (o.lon) c.setLongitude(o.lon);
      if (o.alt) c.setAltitude(o.alt);
      if (o.heading) c.setHeading(o.heading);
      if (o.tilt) c.setTilt(o.tilt);
      if (o.roll) c.setRoll(o.roll);
      if (o.latDelta) c.setLatitude(c.getLatitude() + o.latDelta);
      if (o.lonDelta) c.setLongitude(c.getLongitude() + o.lonDelta);
      if (o.altDelta) c.setAltitude(c.getAltitude() + o.altDelta);
      if (o.headingDelta) c.setHeading(c.getHeading() + o.headingDelta);
      if (o.tiltDelta) c.setTilt(c.getTilt() + o.tiltDelta);
      if (o.rollDelta) c.setRoll(c.getRoll() + o.rollDelta);
      if (o.speed) ge.getOptions().setFlyToSpeed(o.speed);
      return ge.getView().setAbstractView(c);
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
    goToStart = function(speed) {
      if (speed == null) speed = ge.SPEED_TELEPORT;
      flown = false;
      return moveCam({
        lat: params.startLat,
        lon: params.startLon,
        heading: params.startHeading,
        alt: params.startAlt,
        tilt: 90,
        roll: 0.0000001,
        speed: speed
      });
    };
    speed = params.speed;
    lastFlap = flapAmount = tickNum = 0;
    fallbackTimeout = null;
    tick = function() {
      var alt, altDelta, dive, flapDiff, heading, headingDelta, headingRad, latDelta, lonDelta, oldAlt, oldHeading, roll, rollRad, tilt, view;
      clearTimeout(fallbackTimeout);
      tickNum += 1;
      if (params.debugData) debugTicksStatus.innerHTML = tickNum;
      view = ge.getView().copyAsCamera(ge.ALTITUDE_ABSOLUTE);
      oldHeading = view.getHeading();
      oldAlt = view.getAltitude();
      headingStatus.innerHTML = compassPts[Math.round(wrapDegs360(oldHeading) / 45)];
      altStatus.innerHTML = "" + (Math.round(oldAlt)) + "m";
      if (data.reset && flown) goToStart(4.5);
      if (data.roll != null) {
        flown = true;
        dive = data.dive;
        altDelta = tilt = 0;
        if (dive > 0) {
          altDelta = -dive * params.diveSpeed * speed;
          tilt = 90 - dive;
          speed += dive * params.diveAccel;
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
        rollRad = roll * piOver180;
        headingDelta = -roll * params.turnSpeed;
        heading = oldHeading + headingDelta;
        headingRad = heading * piOver180;
        latDelta = Math.cos(headingRad) * speed * latFactor;
        lonDelta = Math.sin(headingRad) * speed * lonFactor;
        alt = oldAlt + altDelta;
        return moveCam({
          alt: alt,
          tilt: tilt,
          latDelta: latDelta,
          lonDelta: lonDelta,
          heading: heading,
          roll: roll,
          speed: ge.SPEED_TELEPORT
        });
      } else {
        return fallbackTimeout = setTimeout(tick, 200);
      }
    };
    data = {};
    connect = function() {
      var received, ws;
      received = 0;
      ws = new WebSocket(params.ws);
      ws.onopen = function() {
        return titleStatus.style.color = '#fff';
      };
      ws.onclose = function() {
        titleStatus.style.color = '#f00';
        return setTimeout(connect, params.reconnectWait * 1000);
      };
      return ws.onmessage = function(e) {
        received += 1;
        data = JSON.parse(e.data);
        if (params.debugData) {
          return debugDataStatus.innerHTML = "" + received + " " + (JSON.stringify(data, function(k, v) {
            return truncNum(v);
          }));
        }
      };
    };
    connect();
    earthInitCallback = function(instance) {
      window.ge = ge = instance;
      console.log("Google Earth plugin v" + (ge.getPluginVersion()) + ", API v" + (ge.getApiVersion()));
      addLayers(ge.LAYER_TERRAIN, ge.LAYER_TREES, ge.LAYER_BUILDINGS, ge.LAYER_BUILDINGS_LOW_RESOLUTION);
      goToStart();
      ge.getOptions().setAtmosphereVisibility(true);
      ge.getSun().setVisibility(true);
      ge.getOptions().setStatusBarVisibility(params.geStatusBar);
      ge.getTime().getControl().setVisibility(params.geTimeCtrl ? ge.VISIBILITY_SHOW : ge.VISIBILITY_HIDE);
      ge.getWindow().setVisibility(true);
      return google.earth.addEventListener(ge, 'frameend', tick);
    };
    return google.earth.createInstance('earth', earthInitCallback, function() {
      return console.log("Google Earth error: " + errorCode);
    });
  };

}).call(this);
