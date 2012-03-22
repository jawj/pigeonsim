(function() {
  var __slice = Array.prototype.slice;

  google.load('earth', '1.x');

  window.onload = function() {
    var addLayers, altStatus, compassPts, connect, data, debugDataStatus, earthInitCallback, el, flapAmount, flown, ge, goToStart, headingStatus, k, kvp, lastFlap, latFactor, lonFactor, moveCam, params, pi, piOver180, speed, speedFactor, tick, titleStatus, twoPi, v, wls, wrapDegs180, wrapDegs360, _i, _len, _ref, _ref2;
    if (!window.WebSocket) {
      alert('This app needs browser WebSocket support');
      return;
    }
    params = {
      startLat: 51.520113,
      startLon: -0.130956,
      startHeading: 55,
      startAlt: 80,
      speed: 4,
      maxSpeed: 10,
      diveSpeed: 0.1,
      diveAccel: 0.05,
      diveDecel: 0.025,
      flapSize: 2,
      flapDecay: 0.8,
      maxRoll: 80,
      turnSpeed: 0.075,
      credits: 0,
      status: 1,
      ws: 'ws://127.0.0.1:8888/p5websocket',
      reconnectWait: 2,
      debugData: 0
    };
    wls = window.location.search;
    _ref = wls.substring(1).split('&');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      kvp = _ref[_i];
      _ref2 = kvp.split('='), k = _ref2[0], v = _ref2[1];
      params[k] = k === 'ws' ? v : parseFloat(v);
    }
    el = function(id) {
      return document.getElementById(id);
    };
    if (params.credits) el('creditOuter').style.display = 'block';
    if (params.status) el('statusOuter').style.display = 'block';
    titleStatus = el('title');
    altStatus = el('alt');
    debugDataStatus = el('debugData');
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
    moveCam = function(o) {
      var c;
      if (o == null) o = {};
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
    lastFlap = flapAmount = 0;
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
    tick = function() {
      var alt, altDelta, dive, flapDiff, heading, headingDelta, headingRad, latDelta, lonDelta, oldAlt, oldHeading, roll, rollRad, tilt, view;
      view = ge.getView().copyAsCamera(ge.ALTITUDE_ABSOLUTE);
      oldHeading = view.getHeading();
      oldAlt = view.getAltitude();
      headingStatus.innerHTML = compassPts[Math.round(wrapDegs360(oldHeading) / 45)];
      altStatus.innerHTML = "" + (Math.round(oldAlt)) + "m";
      if (data.reset && flown) goToStart(4.5);
      altDelta = tilt = 0;
      if (data.dive) {
        dive = data.dive;
        altDelta = -dive * params.diveSpeed * speed;
        tilt = 90 - dive;
        speed += dive * params.diveAccel;
        if (speed > params.maxSpeed) speed = params.maxSpeed;
      } else {
        speed -= params.diveAccel;
        if (speed < params.speed) speed = params.speed;
      }
      if (data.flap) {
        flapDiff = data.flap - lastFlap;
        if (flapDiff > 0) flapAmount += params.flapSize * flapDiff;
        lastFlap = data.flap;
      }
      if (flapAmount > 0) altDelta += flapAmount;
      flapAmount *= params.flapDecay;
      if (data.roll) {
        flown = true;
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
      }
    };
    data = {};
    connect = function() {
      var ws;
      ws = new WebSocket(params.ws);
      ws.onopen = function() {
        return titleStatus.style.color = '#fff';
      };
      ws.onclose = function() {
        titleStatus.style.color = '#f00';
        return setTimeout(connect, params.reconnectWait * 1000);
      };
      return ws.onmessage = function(e) {
        if (params.debugData) {
          debugDataStatus.innerHTML = "" + (new Date().getTime()) + ": " + e.data;
        }
        return data = JSON.parse(e.data);
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
      ge.getTime().getControl().setVisibility(ge.VISIBILITY_HIDE);
      ge.getWindow().setVisibility(true);
      return google.earth.addEventListener(ge, 'frameend', tick);
    };
    return google.earth.createInstance('earth', earthInitCallback, function() {
      return alert("Google Earth error: " + errorCode);
    });
  };

}).call(this);
