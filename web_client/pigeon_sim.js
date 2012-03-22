(function() {
  var __slice = Array.prototype.slice;

  google.load('earth', '1.x');

  $(function() {
    var addLayers, connect, data, earthInitCallback, flapAmount, flown, ge, goToStart, k, kvp, lastFlap, latFactor, lonFactor, moveCam, params, pi, piOver180, speed, speedFactor, tick, twoPi, v, wls, _i, _len, _ref, _ref2;
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
      diveThreshold: 1.5,
      diveSpeed: 0.1,
      diveAccel: 0.05,
      diveDecel: 0.025,
      flapSize: 2,
      flapDecay: 0.8,
      maxRoll: 80,
      turnSpeed: 0.075,
      credits: 0,
      ws: "ws://127.0.0.1:8888/p5websocket"
    };
    wls = window.location.search;
    _ref = wls.substring(1).split('&');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      kvp = _ref[_i];
      _ref2 = kvp.split('='), k = _ref2[0], v = _ref2[1];
      params[k] = k === 'ws' ? v : parseFloat(v);
    }
    if (params.credits) $('#creditOuter').show();
    ge = flown = null;
    pi = Math.PI;
    twoPi = pi * 2;
    piOver180 = pi / 180;
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
    goToStart = function() {
      flown = false;
      return moveCam({
        lat: params.startLat,
        lon: params.startLon,
        heading: params.startHeading,
        alt: params.startAlt,
        tilt: 90,
        roll: 0.0000001,
        speed: 4.5
      });
    };
    speed = params.speed;
    lastFlap = flapAmount = 0;
    tick = function() {
      var altDelta, dive, flapDiff, heading, headingDelta, headingRad, latDelta, lonDelta, roll, rollRad, tilt;
      if (data.reset && flown) goToStart();
      altDelta = tilt = 0;
      if (data.dive && data.dive > params.diveThreshold) {
        dive = data.dive - params.diveThreshold;
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
        heading = ge.getView().copyAsCamera(ge.ALTITUDE_ABSOLUTE).getHeading();
        headingDelta = -roll * params.turnSpeed;
        headingRad = heading * piOver180;
        latDelta = Math.cos(headingRad) * speed * latFactor;
        lonDelta = Math.sin(headingRad) * speed * lonFactor;
        return moveCam({
          altDelta: altDelta,
          tilt: tilt,
          latDelta: latDelta,
          lonDelta: lonDelta,
          headingDelta: headingDelta,
          roll: roll,
          speed: ge.SPEED_TELEPORT
        });
      }
    };
    data = {};
    connect = function() {
      var reconnectDelay, ws;
      reconnectDelay = 2;
      ws = new WebSocket(params.ws);
      ws.onopen = function() {
        return console.log('Connected');
      };
      ws.onclose = function() {
        console.log("Disconnected: retrying in " + reconnectDelay + "s");
        return setTimeout(connect, reconnectDelay * 1000);
      };
      return ws.onmessage = function(e) {
        return data = JSON.parse(e.data);
      };
    };
    connect();
    earthInitCallback = function(instance) {
      window.ge = ge = instance;
      console.log("Google Earth plugin v" + (ge.getPluginVersion()) + ", API v" + (ge.getApiVersion()));
      addLayers(ge.LAYER_TERRAIN, ge.LAYER_TREES, ge.LAYER_BUILDINGS, ge.LAYER_BUILDINGS_LOW_RESOLUTION);
      goToStart();
      ge.getOptions().setStatusBarVisibility(true);
      ge.getOptions().setAtmosphereVisibility(true);
      ge.getSun().setVisibility(true);
      ge.getTime().getControl().setVisibility(ge.VISIBILITY_HIDE);
      ge.getWindow().setVisibility(true);
      return google.earth.addEventListener(ge, 'frameend', tick);
    };
    return google.earth.createInstance('earth', earthInitCallback, function() {
      return alert("Google Earth error: " + errorCode);
    });
  });

}).call(this);
