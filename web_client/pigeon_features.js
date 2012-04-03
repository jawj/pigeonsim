(function() {
  var box, load, oneEightyOverPi,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  load = function(url, callback, opts) {
    var k, kvps, v, xhr;
    if (opts == null) opts = {};
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
      var f, id, lat1, lat2, latDiff, latSize, lon1, lon2, lonDiff, lonSize, lookAt, lookLat, lookLon, midLat, midLon, _i, _len, _ref, _ref2;
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

    function Feature(id, lat, lon, alt) {
      this.id = id;
      this.lat = lat;
      this.lon = lon;
      this.alt = alt != null ? alt : 120;
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
      st = new SkyText(this.lat, this.lon, this.alt);
      angleToCamRad = Math.atan2(this.lon - cam.lon, this.lat - cam.lat);
      angleToCamDeg = angleToCamRad * oneEightyOverPi;
      st.line(this.name, {
        bearing: angleToCamDeg
      });
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

    return TubeStation;

  })(Feature);

  this.TubeStationSet = (function(_super) {

    __extends(TubeStationSet, _super);

    function TubeStationSet(featureManager) {
      var code, csv, dummy, lat, lon, name, row, station, _i, _len, _ref, _ref2;
      TubeStationSet.__super__.constructor.call(this, featureManager);
      csv = "ACT,DP,-0.28025120353611,51.50274977300050,Acton Town\nALD,MH,-0.07561418447775,51.51427182308330,Aldgate\nALE,DH,-0.07228711997537,51.51523341379640,Aldgate East\nALP,P,-0.29948653867861,51.54069476629340,Alperton\nAME,M,-0.60747883910247,51.67414971062970,Amersham\nANG,N,-0.10578991366531,51.53249886890430,Angel\nARC,N,-0.13511351821034,51.56542675453370,Archway\nAGR,P,-0.13351630958178,51.61634026105670,Arnos Grove\nARL,P,-0.10576198817556,51.55849876877660,Arsenal\nBST,MBHJ,-0.15690035605778,51.52306124814270,Baker Street\nBAL,N,-0.15320755266647,51.44332897963520,Balham\nBNK,WNC,-0.08891580904526,51.51330237151930,Bank\nBAR,MH,-0.09771112321625,51.52014572532490,Barbican\nBAY,DH,-0.18803826222162,51.51223305874100,Bayswater\nBKG,DH,0.08086318284941,51.53945120851570,Barking\nBDE,C,0.08851101382178,51.58578596039050,Barkingside\nBCT,DP,-0.21360685736108,51.49015994270890,Barons Court\nBEC,D,0.12740032115528,51.54028853520470,Becontree\nBPK,N,-0.16423230633382,51.55042662771820,Belsize Park\nBER,J,-0.06365135091808,51.49794911958150,Bermondsey\nBNG,C,-0.05543111714588,51.52719523606950,Bethnal Green\nBLF,DH,-0.10360673121986,51.51149052224740,Blackfriars\nBHR,V,-0.04099634092037,51.58695119543890,Blackhorse Road\nBDS,CJ,-0.14933235458620,51.51380453538800,Bond Street\nBOR,N,-0.09370266475837,51.50119399892850,Borough\nBOS,P,-0.32476357379637,51.49569638218810,Boston Manor\nBGR,P,-0.12421896320854,51.60709055695270,Bounds Green\nBWR,DH,-0.02482374687453,51.52680025482600,Bow Road\nBTX,N,-0.21345583375537,51.57680047144380,Brent Cross\nBRX,V,-0.11463558157862,51.46258133363170,Brixton\nBBB,DH,-0.01166193705829,51.52476993755730,Bromley-by-Bow\nBHL,C,0.04674385624050,51.62651733040940,Buckhurst Hill\nBUR,N,-0.26419875814563,51.60268109970250,Burnt Oak\nCRD,P,-0.11831233313327,51.54842131840370,Caledonian Road\nCTN,N,-0.14272614873029,51.53940352263100,Camden Town\nCWR,J,-0.04970598679438,51.49788868199510,Canada Water\nCWF,J,-0.01943181625326,51.50355048564750,Canary Wharf\nCNT,J,0.00817103653259,51.51383712928950,Canning Town\nCST,DH,-0.09069485068098,51.51143372233730,Cannon Street\nCPK,J,-0.29465374087843,51.60775951521530,Canons Park\nCLF,M,-0.56053495644878,51.66802547392600,Chalfont & Latimer,Chalfont and Latimer\nCHF,N,-0.15372800945125,51.54408310242260,Chalk Farm\nCYL,C,-0.11167742738397,51.51812323061440,Chancery Lane\nCHX,BN,-0.12475468662437,51.50859320760310,Charing Cross\nCHG,C,0.07452661126372,51.61787192540510,Chigwell\nCHM,M,-0.6113,51.7052,Chesham\nCHP,D,-0.26774687391373,51.49430059174510,Chiswick Park\nCWD,M,-0.51836598976305,51.65421786077450,Chorleywood\nCPC,N,-0.13831145946425,51.46172793328390,Clapham Common\nCPN,N,-0.12953105372760,51.46484373202770,Clapham North\nCPS,N,-0.14798209863917,51.45259983471440,Clapham South\nCFS,P,-0.14961471515588,51.65168753457490,Cockfosters\nCOL,N,-0.25014258776025,51.59528651879920,Colindale\nCLW,N,-0.17770093662879,51.41807188512260,Colliers Wood\nCOV,P,-0.12415926060311,51.51290958614150,Covent Garden\nCRX,M,-0.44171099260910,51.64704633811630,Croxley\nDGE,D,0.16587486967702,51.54411673422360,Dagenham East\nDGH,D,0.14768419491322,51.54162741361610,Dagenham Heathway\nDEB,C,0.08383780987971,51.64543432204890,Debden\nDHL,J,-0.23879755850816,51.55190355905610,Dollis Hill\nEBY,DC,-0.30150009636919,51.51491303373910,Ealing Broadway\nECM,DP,-0.28826038105700,51.51012473853780,Ealing Common\nECT,DP,-0.19354585405873,51.49180390789890,Earl's Court\nEAC,C,-0.24751320355021,51.51658219905410,East Acton\nEFY,N,-0.16473830562322,51.58727171913200,East Finchley\nEHM,DH,0.05147554883547,51.53892603654750,East Ham\nEPY,D,-0.21100317422227,51.45880474635000,East Putney\nETE,MP,-0.39684462718699,51.57649304450160,Eastcote\nEDG,N,-0.27497600604529,51.61362307984940,Edgware\nERB,B,-0.17013507301192,51.52018389383200,Edgware Road (Bakerloo)\nERD,DH,-0.16766613073758,51.51992047436730,Edgware Road (H & C)\nELE,NB,-0.10072960388334,51.49577704727070,Elephant & Castle,Elephant and Castle\nEPK,D,0.19918045923924,51.54980125398680,Elm Park\nEMB,DBNH,-0.12236021581418,51.50724179674830,Embankment\nEPP,C,0.11386691558357,51.69362460756540,Epping\nEUS,NV,-0.13328971879932,51.52859626089940,Euston,Euston Station\nESQ,MH,-0.13583614069432,51.52556100601610,Euston Square\nFLP,C,0.09092922619115,51.59568093186100,Fairlop\nFAR,MH,-0.10506525423688,51.52044475493070,Farringdon\nFYC,N,-0.19244710707211,51.60097642078520,Finchley Central,Central Finchley\nFRD,MJ,-0.18049417591581,51.54706483433670,Finchley Road\nFPK,PV,-0.10651210028216,51.56440164848450,Finsbury Park\nFBY,D,-0.19495684460322,51.48052978429810,Fulham Broadway\nGHL,C,0.06611553398291,51.57648754803150,Gants Hill\nGRD,DPH,-0.18298952648290,51.49423978391640,Gloucester Road\nGGR,N,-0.19399326125223,51.57222139323280,Golders Green\nGST,N,-0.13466215209239,51.52042499604550,Goodge Street\nGRH,C,0.09214640724270,51.61334985780140,Grange Hill\nGPS,MH,-0.14395608644737,51.52372031462880,Great Portland Street\nGPK,PVJ,-0.14292742220787,51.50685010850230,Green Park\nGFD,C,-0.34644414656746,51.54230202675910,Greenford\nGUN,D,-0.27517503479566,51.49179310432600,Gunnersbury\nHAI,C,0.09311901404450,51.60372721797820,Hainault\nHMS,H,-0.22493007106495,51.49349777200650,Hammersmith\nHMD,DP,-0.22240173052421,51.49256907974890,Hammersmith (District and Picc)\nHMP,N,-0.17821976292476,51.55668847626440,Hampstead\nHLN,C,-0.29300752262070,51.53000640358800,Hanger Lane\nHSD,B,-0.25750275515493,51.53619291015470,Harlesden\nHAW,B,-0.33523116624164,51.59220882796480,Harrow & Wealdstone,Harrow and Wealdstone\nHOH,M,-0.33701590425683,51.57932886728110,Harrow on the Hill,Harrow-on-the-Hill\nHTX,P,-0.42340934945466,51.46661417346270,Hatton Cross\nHRF,P,-0.44605876697794,51.45855310409200,Heathrow Terminal 4\nHRV,P,-0.488,51.4723,Heathrow Terminal 5\nHRC,P,-0.45243913096168,51.47121921006040,Heathrow Terminals 123\nHND,N,-0.22649620780329,51.58329383007200,Hendon Central\nHBT,N,-0.19475102194752,51.65060117058850,High Barnet\nHST,DH,-0.19250313559081,51.50067342026320,High Street Kensington\nHBY,V,-0.10396423878498,51.54622949173780,Highbury & Islington\nHIG,N,-0.14663842256113,51.57759782961870,Highgate\nHDN,MP,-0.44992629566186,51.55371684457090,Hillingdon\nHOL,CP,-0.12000884924483,51.51743878307590,Holborn\nHPK,C,-0.20572867274977,51.50733404315060,Holland Park\nHRD,P,-0.11292563253915,51.55275053787860,Holloway Road\nHCH,D,0.21901898670793,51.55400525600630,Hornchurch\nHNC,P,-0.36692242031907,51.47108330036540,Hounslow Central\nHNE,P,-0.35669531824492,51.47317061583320,Hounslow East\nHNW,P,-0.38573186840753,51.47303479896570,Hounslow West\nHPC,P,-0.15274881198177,51.50276041121250,Hyde Park Corner\nICK,MP,-0.44202655568901,51.56198474255920,Ickenham\nKEN,N,-0.10548515252628,51.48811953061150,Kennington\nKGN,B,-0.22471696470316,51.53045766611690,Kensal Green\nOLY,D,-0.21038252311747,51.49780916738490,Kensington (Olympia)\nKTN,N,-0.14046419295327,51.55030376223780,Kentish Town\nKNT,B,-0.31716440585798,51.58178846260140,Kenton\nKEW,D,-0.28525232821469,51.47702993015280,Kew Gardens\nKIL,J,-0.20463334125466,51.54687950245680,Kilburn\nKPK,B,-0.19396594736853,51.53506908435700,Kilburn Park\nKXX,MNPHV,-0.12385794814245,51.53039723791750,Kings Cross St. Pancras,King's Cross\nKBY,J,-0.27879905743407,51.58475686619030,Kingsbury\nKNB,P,-0.16050709132883,51.50155143320110,Knightsbridge\nLAM,B,-0.11176027027770,51.49905814869850,Lambeth North\nLAN,C,-0.17542865925782,51.51182153458860,Lancaster Gate\nLBG,H,-0.21086191784859,51.51718844988170,Ladbroke Grove\nLSQ,PN,-0.12823553217276,51.51122102836720,Leicester Square\nLEY,C,-0.00561987978131,51.55643292705490,Leyton\nLYS,C,0.00821504748634,51.56818526367450,Leytonstone\nLST,MCH,-0.08296570945694,51.51735123075170,Liverpool Street\nLON,NJ,-0.08692240419194,51.50549935324970,London Bridge\nLTN,C,0.05531199715457,51.64151275908050,Loughton\nMDV,B,-0.18562590222991,51.52976001681030,Maida Vale\nMNR,P,-0.09571246670488,51.57075600528430,Manor House\nMAN,DH,-0.09418713531293,51.51202120095600,Mansion House\nMAR,C,-0.15843804662659,51.51354329318110,Marble Arch\nMYB,B,-0.16310448714212,51.52222334197040,Marylebone\nMLE,DHC,-0.03340417038111,51.52509187183440,Mile End\nMHE,N,-0.20989441994604,51.60825889523920,Mill Hill East\nMON,DH,-0.08894273274156,51.51334781918420,Monument\nMPK,M,-0.43266684860392,51.62973109047760,Moor Park\nMGT,MNH,-0.08900631501309,51.51836724988460,Moorgate\nMOR,N,-0.19479070083452,51.40233694076680,Morden\nMCR,N,-0.13884252998990,51.53420661060250,Mornington Crescent\nNEA,J,-0.24978287282243,51.55396571746170,Neasden\nNEP,C,0.09033731368127,51.57557249361060,Newbury Park\nNAC,C,-0.25973738573780,51.52336555636410,North Acton Junction\nNEL,P,-0.28900497976256,51.51755516035860,North Ealing\nNGW,J,0.00360741693833,51.50018182399260,North Greenwich\nNHR,M,-0.36222357325819,51.58479184672980,North Harrow\nNWM,B,-0.30415573538263,51.56249028557540,North Wembley\nNFD,P,-0.31415683266497,51.49927648219350,Northfields\nNHT,C,-0.36845983428266,51.54815043900270,Northolt\nNWP,M,-0.31820635687621,51.57859284148750,Northwick Park\nNWD,M,-0.42386079385157,51.61115922890370,Northwood\nNWH,M,-0.40929863067416,51.60049457650000,Northwood Hills\nNHG,DCH,-0.19653768540776,51.50906353364370,Notting Hill Gate\nNPDEPOT,V,-0.053819,51.599924,Northumberland Park Depot\nOAK,P,-0.13184172130094,51.64758364919410,Oakwood\nOLD,N,-0.08754973143646,51.52560132336980,Old Street\nOST,P,-0.35199440464561,51.48092880458870,Osterley\nOVL,N,-0.11289340879807,51.48210545233800,Oval\nOXC,CBV,-0.14176898366897,51.51512379903700,Oxford Circus\nPAD,HDB,-0.17539000601032,51.51531041579340,Paddington\nPRY,P,-0.28422801590485,51.52690137924540,Park Royal\nPGR,D,-0.20123465658312,51.47509533047470,Parsons Green\nPER,C,-0.32385203849235,51.53659408992660,Perivale\nPIC,BP,-0.13400636555842,51.51002699527070,Piccadilly Circus\nPIM,V,-0.13374866528779,51.48919376011050,Pimlico\nPIN,M,-0.38091980415035,51.59285763009080,Pinner\nPLW,DH,0.01780469869649,51.53121839248360,Plaistow\nPUT,D,-0.20897667848792,51.46790222227180,Putney Bridge\nQPK,B,-0.20470409023420,51.53410090344690,Queen's Park\nQBY,J,-0.28578568164321,51.59434714807250,Queensbury\nQWY,C,-0.18743446136457,51.51038005162460,Queensway\nRCP,D,-0.23625835394560,51.49413653149780,Ravenscourt Park\nRLN,MP,-0.37100556351776,51.57497670388130,Rayners Lane\nRED,C,0.04542311610758,51.57630179240060,Redbridge\nRPK,B,-0.14686263475286,51.52350550346830,Regents Park\nRMD,D,-0.30175421768689,51.46315964085970,Richmond\nRKY,M,-0.47371210701839,51.64027270698850,Rickmansworth\nROA,H,-0.18823004302831,51.51901712033320,Royal Oak\nROD,C,0.04386441546338,51.61711524120540,Roding Valley\nRUI,MP,-0.42145507401498,51.57144911322280,Ruislip\nRUG,C,-0.41103928492841,51.56058850307670,Ruislip Gardens\nRUM,MP,-0.41234579209326,51.57318767786700,Ruislip Manor\nRSQ,P,-0.12431005564797,51.52291284508320,Russell Square\nSVS,V,-0.07249188149500,51.58335418466470,Seven Sisters\nSBC,C,-0.22630545901777,51.50556086849070,Shepherd's Bush\nXSBM,H,-0.2264,51.5058,Shepherd's Bush Market\nSSQ,DH,-0.15648623169091,51.49228782409720,Sloane Square\nSNB,C,0.02149046243869,51.58082701976080,Snaresbrook\nSEL,P,-0.30701883924671,51.50136793634410,South Ealing\nSHR,P,-0.35221157087043,51.56467757054850,South Harrow\nSKN,DPH,-0.17392231088383,51.49399987276360,South Kensington\nSKT,B,-0.30858867502022,51.57017168687130,South Kenton\nSRP,C,-0.39865875717595,51.55651695797160,South Ruislip\nSWM,N,-0.19197909402312,51.41528036588430,South Wimbledon\nSWF,C,0.02731713374280,51.59172564827300,South Woodford\nSFS,D,-0.20653754405539,51.44493132701890,Southfields\nSGT,P,-0.12775839337105,51.63231971007180,Southgate\nSWK,J,-0.10509183600618,51.50384300693900,Southwark\nSJW,J,-0.17417235633673,51.53456451631530,St. John's Wood,St. John Wood\nSTP,C,-0.09757365447760,51.51480129673320,St. Paul's\nSJP,DH,-0.13418374411553,51.49934545614030,St. James's Park\nSTB,D,-0.24545379523797,51.49479623145680,Stamford Brook\nSTA,J,-0.30310817135864,51.61961833683860,Stanmore\nSTG,DH,-0.04645866635082,51.52191062962780,Stepney Green\nSTK,NV,-0.12290931166210,51.47216653861570,Stockwell\nSPK,B,-0.27540924757983,51.54392228583470,Stonebridge Park\nSFD,CJ,-0.00319532957031,51.54130926596680,Stratford\nSHL,P,-0.33621563204436,51.55699618923430,Sudbury Hill\nSTN,P,-0.31548269703372,51.55078245689710,Sudbury Town\nSWC,J,-0.17475925302873,51.54331532015430,Swiss Cottage\nTEM,DH,-0.11370308973837,51.51096998494440,Temple\nTHB,C,0.10312537666349,51.67171131730330,Theydon Bois\nTBE,N,-0.15970053993575,51.43575962880830,Tooting Bec\nTBY,N,-0.16797676330522,51.42743538966260,Tooting Broadway\nTCR,CN,-0.13087051814094,51.51620955251380,Tottenham Court Road\nTTH,V,-0.06028111636750,51.58804530152150,Tottenham Hale\nTOT,N,-0.17926121292398,51.63020770476230,Totteridge & Whetstone\nTHL,DH,-0.07635369517461,51.51006595388410,Tower Hill\nTPK,N,-0.13792488108064,51.55666681998890,Tufnell Park\nTGR,DP,-0.25453298298794,51.49511172529810,Turnham Green\nTPL,P,-0.10279227505582,51.59029677015470,Turnpike Lane\nUPM,D,0.25108711606680,51.55888907616990,Upminster\nUPB,D,0.23577122039992,51.55875050794730,Upminster Bridge\nUPY,D,0.10156562559142,51.53833531248820,Upney\nUPK,DH,0.03527318012916,51.53523330392110,Upton Park\nUXB,MP,-0.47813947213628,51.54649637046050,Uxbridge\nVUX,V,-0.12374895103059,51.48573337604020,Vauxhall\nVIC,DHV,-0.14384485434014,51.49634217473100,Victoria\nWAL,V,-0.01991863902501,51.58295470500250,Walthamstow Central\nWAN,C,0.02874591933525,51.57552133692100,Wanstead\nWST,VN,-0.13827231338321,51.52451151754790,Warren Street\nWAR,B,-0.18367827068891,51.52327252274610,Warwick Avenue\nWLO,WBNJ,-0.11406943580766,51.50350220717360,Waterloo\nWAT,M,-0.41728063194596,51.65742097190640,Watford\nWEM,B,-0.29685944537320,51.55232996597800,Wembley Central\nWPK,MJ,-0.27925100872651,51.56326048395510,Wembley Park,Wembley Park fast\nWAC,C,-0.28099328999188,51.51786058618780,West Acton\nWBP,H,-0.20088377146790,51.52092084952600,Westbourne Park\nWBT,D,-0.19554083437396,51.48725695000670,West Brompton\nWFY,N,-0.18846886972823,51.60948570977260,West Finchley\nWHM,DHJ,0.00503950709667,51.52818177294170,West Ham\nWHD,J,-0.19074985025643,51.54670197909490,West Hampstead\nWHR,J,-0.35292063098543,51.57977819370930,West Harrow\nWKN,D,-0.20647711470530,51.49049168573210,West Kensington\nWRP,C,-0.43788643675992,51.56952886292040,West Ruislip\nWMS,DHJ,-0.12481826520070,51.50108458344640,Westminster\nWCT,C,-0.22425431922798,51.51197811358700,White City\nWCTSIDE,C,-0.22425431922798,51.51197811358700,White City Sidings\nWCL,DH,-0.05998498296226,51.51945524689070,Whitechapel\nWLG,J,-0.22241015208080,51.54930888824790,Willesden Green\nWJN,B,-0.24428889451703,51.53219149710360,Willesden Junction\nWDN,D,-0.20638158690359,51.42138371953170,Wimbledon\nWMP,D,-0.19959527217312,51.43446418602540,Wimbledon Park\nWGN,P,-0.10962638054845,51.59747603130840,Wood Green\nWGNSIDE,P,-0.10962638054845,51.59747603130840,Wood Green Sidings\nWFD,C,0.03403714415408,51.60703336518100,Woodford,Woodford Junction\nWFDSIDE,C,0.03403714415408,51.60703336518100,Woodford Sidings\nWSP,N,-0.18542102750884,51.61781140738290,Woodside Park\nXWLN,H,-0.224166667,51.50979722,Wood Lane\nXPRD,M,-0.29525630015897,51.57203799181500,Preston Road,Preston Road fast\nXLRD,H,-0.21777930179215,51.51354359389710,Latimer Road\nXGRD,H,-0.22674832920358,51.50195219730120,Goldhawk Road\nPADc,H,-0.1774,51.5173,Paddington Circle\nPADs,H,-0.1774,51.5173,Paddington H & C\nXXX5,B,-0.207778,51.533611,North Sidings between Queen's park and\nXXX9,B,-0.207778,51.533611,Queen's Park North Sidings\nXXX6,B,-0.104722,51.498333,London Road Depot\nXXX8,V,-0.01991863902501,51.58295470500250,Walthamstow Sidings\nXKRI,B,-0.2208,51.5342,Kensal Rise";
      _ref = csv.split("\n");
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

}).call(this);
