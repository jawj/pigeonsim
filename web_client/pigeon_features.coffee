
load = (url, callback, opts = {}) ->
  opts.method ?= 'GET'
  if opts.search?
    kvps = ("#{escape(k)}=#{escape(v)}" for own k, v of opts.search)
    url += '?' + kvps.join('&')
  xhr = new XMLHttpRequest()
  xhr.onreadystatechange = ->
    if xhr.readyState is 4
      obj = if opts.json? then JSON.parse(xhr.responseText)
      else if opts.xml? then xhr.responseXML
      else xhr.responseText
      callback(obj)
  xhr.open(opts.method, url, yes)
  xhr.send(opts.data)

box = null

class this.FeatureManager
  constructor: (@ge, @lonRatio) ->
    @featureTree = new RTree()
    @visibleFeatures = {}
    @maxVisible = 20
    @featureFifo = []
    
  addFeature: (f) ->
    @featureTree.insert(f.rect(), f)
    
  removeFeature: (f) ->
    @hideFeature(f)
    @featureTree.remove(f.rect(), f)
  
  showFeature: (f, cam) ->
    return no if @visibleFeatures[f.id]?
    @visibleFeatures[f.id] = f
    @featureFifo.unshift(f)
    f.show(@ge, cam)
    @hideFeature(@featureFifo.pop()) if @featureFifo.length > @maxVisible
    return yes
  
  hideFeature: (f) ->
    return no unless @visibleFeatures[f.id]?
    delete @visibleFeatures[f.id]
    f.hide(@ge)
    return yes
  
  featuresInBBox: (lat1, lon1, lat2, lon2) ->
    x = lon1 #Math.min(lon1, lon2)
    y = lat1 #Math.min(lat1, lat2)
    w = lon2 - lon1 #Math.abs(lon1 - lon2)
    h = lat2 - lat1 #Math.abs(lat1 - lat2)
    @featureTree.search({x, y, w, h})
    
  update: (cam) ->
    lookAt = @ge.getView().copyAsLookAt(ge.ALTITUDE_ABSOLUTE)
    lookLat = lookAt.getLatitude()
    lookLon = lookAt.getLongitude()
    camLat = cam.lat
    camLon = cam.lon
    midLat = (camLat + lookLat) / 2
    midLon = (camLon + lookLon) / 2
    
    latDiff = Math.abs(camLat - midLat)
    lonDiff = Math.abs(camLon - midLon)
    latSize = Math.max(latDiff / @lonRatio, lonDiff)
    lonSize = latSize * @lonRatio
    # console.log(latDiff, lonDiff, latSize, lonSize)
    lat1 = midLat - latSize
    lat2 = midLat + latSize
    lon1 = midLon - lonSize
    lon2 = midLon + lonSize
    
    ###
    ge.getFeatures().removeChild(box) if box
    kml = "<?xml version='1.0' encoding='UTF-8'?><kml xmlns='http://www.opengis.net/kml/2.2'><Document><Placemark><name>lookAt</name><Point><coordinates>#{lookLon},#{lookLat},0</coordinates></Point></Placemark><Placemark><name>camera</name><Point><coordinates>#{camLon},#{camLat},0</coordinates></Point></Placemark><Placemark><name>middle</name><Point><coordinates>#{midLon},#{midLat},0</coordinates></Point></Placemark><Placemark><LineString><altitudeMode>absolute</altitudeMode><coordinates>#{lon1},#{lat1},100 #{lon1},#{lat2},100 #{lon2},#{lat2},100 #{lon2},#{lat1},50 #{lon1},#{lat1},100</coordinates></LineString></Placemark></Document></kml>"
    box = ge.parseKml(kml)
    ge.getFeatures().appendChild(box)
    console.log(kml)
    ###
    
    @showFeature(f, cam) for f in @featuresInBBox(lat1, lon1, lat2, lon2)

class this.FeatureSet
  constructor: (@featureManager) ->
    @features = {}
  
  addFeature: (f) ->
    @features[f.id] = f
    @featureManager.addFeature(f)
    
  removeFeature: () ->
    @featureManager.removeFeature(f)
    delete @features[f.id]
  
  clearFeatures: -> @removeFeature(f) for own f of @features

    
class this.Feature
  constructor: (@id, @lat, @lon, @alt = 100) ->
  
  rect: -> {x: @lon, y: @lat, w: 0, h: 0}
    
  show: (ge, cam) ->
    st = new SkyText(@lat, @lon, @alt)
    st.line(@name, {bearing: cam.heading})
    @geNode = ge.parseKml(st.kml())
    ge.getFeatures().appendChild(@geNode)
    
  hide: (ge) ->
    if @geNode
      ge.getFeatures().removeChild(@geNode)
      delete @geNode


class this.TubeStation extends Feature

class this.TubeStationSet extends FeatureSet
  constructor: (featureManager) ->
    super(featureManager)
    csv = """ACT,DP,-0.28025120353611,51.50274977300050,Acton Town
        ALD,MH,-0.07561418447775,51.51427182308330,Aldgate
        ALE,DH,-0.07228711997537,51.51523341379640,Aldgate East
        ALP,P,-0.29948653867861,51.54069476629340,Alperton
        AME,M,-0.60747883910247,51.67414971062970,Amersham
        ANG,N,-0.10578991366531,51.53249886890430,Angel
        ARC,N,-0.13511351821034,51.56542675453370,Archway
        AGR,P,-0.13351630958178,51.61634026105670,Arnos Grove
        ARL,P,-0.10576198817556,51.55849876877660,Arsenal
        BST,MBHJ,-0.15690035605778,51.52306124814270,Baker Street
        BAL,N,-0.15320755266647,51.44332897963520,Balham
        BNK,WNC,-0.08891580904526,51.51330237151930,Bank
        BAR,MH,-0.09771112321625,51.52014572532490,Barbican
        BAY,DH,-0.18803826222162,51.51223305874100,Bayswater
        BKG,DH,0.08086318284941,51.53945120851570,Barking
        BDE,C,0.08851101382178,51.58578596039050,Barkingside
        BCT,DP,-0.21360685736108,51.49015994270890,Barons Court
        BEC,D,0.12740032115528,51.54028853520470,Becontree
        BPK,N,-0.16423230633382,51.55042662771820,Belsize Park
        BER,J,-0.06365135091808,51.49794911958150,Bermondsey
        BNG,C,-0.05543111714588,51.52719523606950,Bethnal Green
        BLF,DH,-0.10360673121986,51.51149052224740,Blackfriars
        BHR,V,-0.04099634092037,51.58695119543890,Blackhorse Road
        BDS,CJ,-0.14933235458620,51.51380453538800,Bond Street
        BOR,N,-0.09370266475837,51.50119399892850,Borough
        BOS,P,-0.32476357379637,51.49569638218810,Boston Manor
        BGR,P,-0.12421896320854,51.60709055695270,Bounds Green
        BWR,DH,-0.02482374687453,51.52680025482600,Bow Road
        BTX,N,-0.21345583375537,51.57680047144380,Brent Cross
        BRX,V,-0.11463558157862,51.46258133363170,Brixton
        BBB,DH,-0.01166193705829,51.52476993755730,Bromley-by-Bow
        BHL,C,0.04674385624050,51.62651733040940,Buckhurst Hill
        BUR,N,-0.26419875814563,51.60268109970250,Burnt Oak
        CRD,P,-0.11831233313327,51.54842131840370,Caledonian Road
        CTN,N,-0.14272614873029,51.53940352263100,Camden Town
        CWR,J,-0.04970598679438,51.49788868199510,Canada Water
        CWF,J,-0.01943181625326,51.50355048564750,Canary Wharf
        CNT,J,0.00817103653259,51.51383712928950,Canning Town
        CST,DH,-0.09069485068098,51.51143372233730,Cannon Street
        CPK,J,-0.29465374087843,51.60775951521530,Canons Park
        CLF,M,-0.56053495644878,51.66802547392600,Chalfont & Latimer,Chalfont and Latimer
        CHF,N,-0.15372800945125,51.54408310242260,Chalk Farm
        CYL,C,-0.11167742738397,51.51812323061440,Chancery Lane
        CHX,BN,-0.12475468662437,51.50859320760310,Charing Cross
        CHG,C,0.07452661126372,51.61787192540510,Chigwell
        CHM,M,-0.6113,51.7052,Chesham
        CHP,D,-0.26774687391373,51.49430059174510,Chiswick Park
        CWD,M,-0.51836598976305,51.65421786077450,Chorleywood
        CPC,N,-0.13831145946425,51.46172793328390,Clapham Common
        CPN,N,-0.12953105372760,51.46484373202770,Clapham North
        CPS,N,-0.14798209863917,51.45259983471440,Clapham South
        CFS,P,-0.14961471515588,51.65168753457490,Cockfosters
        COL,N,-0.25014258776025,51.59528651879920,Colindale
        CLW,N,-0.17770093662879,51.41807188512260,Colliers Wood
        COV,P,-0.12415926060311,51.51290958614150,Covent Garden
        CRX,M,-0.44171099260910,51.64704633811630,Croxley
        DGE,D,0.16587486967702,51.54411673422360,Dagenham East
        DGH,D,0.14768419491322,51.54162741361610,Dagenham Heathway
        DEB,C,0.08383780987971,51.64543432204890,Debden
        DHL,J,-0.23879755850816,51.55190355905610,Dollis Hill
        EBY,DC,-0.30150009636919,51.51491303373910,Ealing Broadway
        ECM,DP,-0.28826038105700,51.51012473853780,Ealing Common
        ECT,DP,-0.19354585405873,51.49180390789890,Earl's Court
        EAC,C,-0.24751320355021,51.51658219905410,East Acton
        EFY,N,-0.16473830562322,51.58727171913200,East Finchley
        EHM,DH,0.05147554883547,51.53892603654750,East Ham
        EPY,D,-0.21100317422227,51.45880474635000,East Putney
        ETE,MP,-0.39684462718699,51.57649304450160,Eastcote
        EDG,N,-0.27497600604529,51.61362307984940,Edgware
        ERB,B,-0.17013507301192,51.52018389383200,Edgware Road (Bakerloo)
        ERD,DH,-0.16766613073758,51.51992047436730,Edgware Road (H & C)
        ELE,NB,-0.10072960388334,51.49577704727070,Elephant & Castle,Elephant and Castle
        EPK,D,0.19918045923924,51.54980125398680,Elm Park
        EMB,DBNH,-0.12236021581418,51.50724179674830,Embankment
        EPP,C,0.11386691558357,51.69362460756540,Epping
        EUS,NV,-0.13328971879932,51.52859626089940,Euston,Euston Station
        ESQ,MH,-0.13583614069432,51.52556100601610,Euston Square
        FLP,C,0.09092922619115,51.59568093186100,Fairlop
        FAR,MH,-0.10506525423688,51.52044475493070,Farringdon
        FYC,N,-0.19244710707211,51.60097642078520,Finchley Central,Central Finchley
        FRD,MJ,-0.18049417591581,51.54706483433670,Finchley Road
        FPK,PV,-0.10651210028216,51.56440164848450,Finsbury Park
        FBY,D,-0.19495684460322,51.48052978429810,Fulham Broadway
        GHL,C,0.06611553398291,51.57648754803150,Gants Hill
        GRD,DPH,-0.18298952648290,51.49423978391640,Gloucester Road
        GGR,N,-0.19399326125223,51.57222139323280,Golders Green
        GST,N,-0.13466215209239,51.52042499604550,Goodge Street
        GRH,C,0.09214640724270,51.61334985780140,Grange Hill
        GPS,MH,-0.14395608644737,51.52372031462880,Great Portland Street
        GPK,PVJ,-0.14292742220787,51.50685010850230,Green Park
        GFD,C,-0.34644414656746,51.54230202675910,Greenford
        GUN,D,-0.27517503479566,51.49179310432600,Gunnersbury
        HAI,C,0.09311901404450,51.60372721797820,Hainault
        HMS,H,-0.22493007106495,51.49349777200650,Hammersmith
        HMD,DP,-0.22240173052421,51.49256907974890,Hammersmith (District and Picc)
        HMP,N,-0.17821976292476,51.55668847626440,Hampstead
        HLN,C,-0.29300752262070,51.53000640358800,Hanger Lane
        HSD,B,-0.25750275515493,51.53619291015470,Harlesden
        HAW,B,-0.33523116624164,51.59220882796480,Harrow & Wealdstone,Harrow and Wealdstone
        HOH,M,-0.33701590425683,51.57932886728110,Harrow on the Hill,Harrow-on-the-Hill
        HTX,P,-0.42340934945466,51.46661417346270,Hatton Cross
        HRF,P,-0.44605876697794,51.45855310409200,Heathrow Terminal 4
        HRV,P,-0.488,51.4723,Heathrow Terminal 5
        HRC,P,-0.45243913096168,51.47121921006040,Heathrow Terminals 123
        HND,N,-0.22649620780329,51.58329383007200,Hendon Central
        HBT,N,-0.19475102194752,51.65060117058850,High Barnet
        HST,DH,-0.19250313559081,51.50067342026320,High Street Kensington
        HBY,V,-0.10396423878498,51.54622949173780,Highbury & Islington
        HIG,N,-0.14663842256113,51.57759782961870,Highgate
        HDN,MP,-0.44992629566186,51.55371684457090,Hillingdon
        HOL,CP,-0.12000884924483,51.51743878307590,Holborn
        HPK,C,-0.20572867274977,51.50733404315060,Holland Park
        HRD,P,-0.11292563253915,51.55275053787860,Holloway Road
        HCH,D,0.21901898670793,51.55400525600630,Hornchurch
        HNC,P,-0.36692242031907,51.47108330036540,Hounslow Central
        HNE,P,-0.35669531824492,51.47317061583320,Hounslow East
        HNW,P,-0.38573186840753,51.47303479896570,Hounslow West
        HPC,P,-0.15274881198177,51.50276041121250,Hyde Park Corner
        ICK,MP,-0.44202655568901,51.56198474255920,Ickenham
        KEN,N,-0.10548515252628,51.48811953061150,Kennington
        KGN,B,-0.22471696470316,51.53045766611690,Kensal Green
        OLY,D,-0.21038252311747,51.49780916738490,Kensington (Olympia)
        KTN,N,-0.14046419295327,51.55030376223780,Kentish Town
        KNT,B,-0.31716440585798,51.58178846260140,Kenton
        KEW,D,-0.28525232821469,51.47702993015280,Kew Gardens
        KIL,J,-0.20463334125466,51.54687950245680,Kilburn
        KPK,B,-0.19396594736853,51.53506908435700,Kilburn Park
        KXX,MNPHV,-0.12385794814245,51.53039723791750,Kings Cross St. Pancras,King's Cross
        KBY,J,-0.27879905743407,51.58475686619030,Kingsbury
        KNB,P,-0.16050709132883,51.50155143320110,Knightsbridge
        LAM,B,-0.11176027027770,51.49905814869850,Lambeth North
        LAN,C,-0.17542865925782,51.51182153458860,Lancaster Gate
        LBG,H,-0.21086191784859,51.51718844988170,Ladbroke Grove
        LSQ,PN,-0.12823553217276,51.51122102836720,Leicester Square
        LEY,C,-0.00561987978131,51.55643292705490,Leyton
        LYS,C,0.00821504748634,51.56818526367450,Leytonstone
        LST,MCH,-0.08296570945694,51.51735123075170,Liverpool Street
        LON,NJ,-0.08692240419194,51.50549935324970,London Bridge
        LTN,C,0.05531199715457,51.64151275908050,Loughton
        MDV,B,-0.18562590222991,51.52976001681030,Maida Vale
        MNR,P,-0.09571246670488,51.57075600528430,Manor House
        MAN,DH,-0.09418713531293,51.51202120095600,Mansion House
        MAR,C,-0.15843804662659,51.51354329318110,Marble Arch
        MYB,B,-0.16310448714212,51.52222334197040,Marylebone
        MLE,DHC,-0.03340417038111,51.52509187183440,Mile End
        MHE,N,-0.20989441994604,51.60825889523920,Mill Hill East
        MON,DH,-0.08894273274156,51.51334781918420,Monument
        MPK,M,-0.43266684860392,51.62973109047760,Moor Park
        MGT,MNH,-0.08900631501309,51.51836724988460,Moorgate
        MOR,N,-0.19479070083452,51.40233694076680,Morden
        MCR,N,-0.13884252998990,51.53420661060250,Mornington Crescent
        NEA,J,-0.24978287282243,51.55396571746170,Neasden
        NEP,C,0.09033731368127,51.57557249361060,Newbury Park
        NAC,C,-0.25973738573780,51.52336555636410,North Acton Junction
        NEL,P,-0.28900497976256,51.51755516035860,North Ealing
        NGW,J,0.00360741693833,51.50018182399260,North Greenwich
        NHR,M,-0.36222357325819,51.58479184672980,North Harrow
        NWM,B,-0.30415573538263,51.56249028557540,North Wembley
        NFD,P,-0.31415683266497,51.49927648219350,Northfields
        NHT,C,-0.36845983428266,51.54815043900270,Northolt
        NWP,M,-0.31820635687621,51.57859284148750,Northwick Park
        NWD,M,-0.42386079385157,51.61115922890370,Northwood
        NWH,M,-0.40929863067416,51.60049457650000,Northwood Hills
        NHG,DCH,-0.19653768540776,51.50906353364370,Notting Hill Gate
        NPDEPOT,V,-0.053819,51.599924,Northumberland Park Depot
        OAK,P,-0.13184172130094,51.64758364919410,Oakwood
        OLD,N,-0.08754973143646,51.52560132336980,Old Street
        OST,P,-0.35199440464561,51.48092880458870,Osterley
        OVL,N,-0.11289340879807,51.48210545233800,Oval
        OXC,CBV,-0.14176898366897,51.51512379903700,Oxford Circus
        PAD,HDB,-0.17539000601032,51.51531041579340,Paddington
        PRY,P,-0.28422801590485,51.52690137924540,Park Royal
        PGR,D,-0.20123465658312,51.47509533047470,Parsons Green
        PER,C,-0.32385203849235,51.53659408992660,Perivale
        PIC,BP,-0.13400636555842,51.51002699527070,Piccadilly Circus
        PIM,V,-0.13374866528779,51.48919376011050,Pimlico
        PIN,M,-0.38091980415035,51.59285763009080,Pinner
        PLW,DH,0.01780469869649,51.53121839248360,Plaistow
        PUT,D,-0.20897667848792,51.46790222227180,Putney Bridge
        QPK,B,-0.20470409023420,51.53410090344690,Queen's Park
        QBY,J,-0.28578568164321,51.59434714807250,Queensbury
        QWY,C,-0.18743446136457,51.51038005162460,Queensway
        RCP,D,-0.23625835394560,51.49413653149780,Ravenscourt Park
        RLN,MP,-0.37100556351776,51.57497670388130,Rayners Lane
        RED,C,0.04542311610758,51.57630179240060,Redbridge
        RPK,B,-0.14686263475286,51.52350550346830,Regents Park
        RMD,D,-0.30175421768689,51.46315964085970,Richmond
        RKY,M,-0.47371210701839,51.64027270698850,Rickmansworth
        ROA,H,-0.18823004302831,51.51901712033320,Royal Oak
        ROD,C,0.04386441546338,51.61711524120540,Roding Valley
        RUI,MP,-0.42145507401498,51.57144911322280,Ruislip
        RUG,C,-0.41103928492841,51.56058850307670,Ruislip Gardens
        RUM,MP,-0.41234579209326,51.57318767786700,Ruislip Manor
        RSQ,P,-0.12431005564797,51.52291284508320,Russell Square
        SVS,V,-0.07249188149500,51.58335418466470,Seven Sisters
        SBC,C,-0.22630545901777,51.50556086849070,Shepherd's Bush
        XSBM,H,-0.2264,51.5058,Shepherd's Bush Market
        SSQ,DH,-0.15648623169091,51.49228782409720,Sloane Square
        SNB,C,0.02149046243869,51.58082701976080,Snaresbrook
        SEL,P,-0.30701883924671,51.50136793634410,South Ealing
        SHR,P,-0.35221157087043,51.56467757054850,South Harrow
        SKN,DPH,-0.17392231088383,51.49399987276360,South Kensington
        SKT,B,-0.30858867502022,51.57017168687130,South Kenton
        SRP,C,-0.39865875717595,51.55651695797160,South Ruislip
        SWM,N,-0.19197909402312,51.41528036588430,South Wimbledon
        SWF,C,0.02731713374280,51.59172564827300,South Woodford
        SFS,D,-0.20653754405539,51.44493132701890,Southfields
        SGT,P,-0.12775839337105,51.63231971007180,Southgate
        SWK,J,-0.10509183600618,51.50384300693900,Southwark
        SJW,J,-0.17417235633673,51.53456451631530,St. John's Wood,St. John Wood
        STP,C,-0.09757365447760,51.51480129673320,St. Paul's
        SJP,DH,-0.13418374411553,51.49934545614030,St. James's Park
        STB,D,-0.24545379523797,51.49479623145680,Stamford Brook
        STA,J,-0.30310817135864,51.61961833683860,Stanmore
        STG,DH,-0.04645866635082,51.52191062962780,Stepney Green
        STK,NV,-0.12290931166210,51.47216653861570,Stockwell
        SPK,B,-0.27540924757983,51.54392228583470,Stonebridge Park
        SFD,CJ,-0.00319532957031,51.54130926596680,Stratford
        SHL,P,-0.33621563204436,51.55699618923430,Sudbury Hill
        STN,P,-0.31548269703372,51.55078245689710,Sudbury Town
        SWC,J,-0.17475925302873,51.54331532015430,Swiss Cottage
        TEM,DH,-0.11370308973837,51.51096998494440,Temple
        THB,C,0.10312537666349,51.67171131730330,Theydon Bois
        TBE,N,-0.15970053993575,51.43575962880830,Tooting Bec
        TBY,N,-0.16797676330522,51.42743538966260,Tooting Broadway
        TCR,CN,-0.13087051814094,51.51620955251380,Tottenham Court Road
        TTH,V,-0.06028111636750,51.58804530152150,Tottenham Hale
        TOT,N,-0.17926121292398,51.63020770476230,Totteridge & Whetstone
        THL,DH,-0.07635369517461,51.51006595388410,Tower Hill
        TPK,N,-0.13792488108064,51.55666681998890,Tufnell Park
        TGR,DP,-0.25453298298794,51.49511172529810,Turnham Green
        TPL,P,-0.10279227505582,51.59029677015470,Turnpike Lane
        UPM,D,0.25108711606680,51.55888907616990,Upminster
        UPB,D,0.23577122039992,51.55875050794730,Upminster Bridge
        UPY,D,0.10156562559142,51.53833531248820,Upney
        UPK,DH,0.03527318012916,51.53523330392110,Upton Park
        UXB,MP,-0.47813947213628,51.54649637046050,Uxbridge
        VUX,V,-0.12374895103059,51.48573337604020,Vauxhall
        VIC,DHV,-0.14384485434014,51.49634217473100,Victoria
        WAL,V,-0.01991863902501,51.58295470500250,Walthamstow Central
        WAN,C,0.02874591933525,51.57552133692100,Wanstead
        WST,VN,-0.13827231338321,51.52451151754790,Warren Street
        WAR,B,-0.18367827068891,51.52327252274610,Warwick Avenue
        WLO,WBNJ,-0.11406943580766,51.50350220717360,Waterloo
        WAT,M,-0.41728063194596,51.65742097190640,Watford
        WEM,B,-0.29685944537320,51.55232996597800,Wembley Central
        WPK,MJ,-0.27925100872651,51.56326048395510,Wembley Park,Wembley Park fast
        WAC,C,-0.28099328999188,51.51786058618780,West Acton
        WBP,H,-0.20088377146790,51.52092084952600,Westbourne Park
        WBT,D,-0.19554083437396,51.48725695000670,West Brompton
        WFY,N,-0.18846886972823,51.60948570977260,West Finchley
        WHM,DHJ,0.00503950709667,51.52818177294170,West Ham
        WHD,J,-0.19074985025643,51.54670197909490,West Hampstead
        WHR,J,-0.35292063098543,51.57977819370930,West Harrow
        WKN,D,-0.20647711470530,51.49049168573210,West Kensington
        WRP,C,-0.43788643675992,51.56952886292040,West Ruislip
        WMS,DHJ,-0.12481826520070,51.50108458344640,Westminster
        WCT,C,-0.22425431922798,51.51197811358700,White City
        WCTSIDE,C,-0.22425431922798,51.51197811358700,White City Sidings
        WCL,DH,-0.05998498296226,51.51945524689070,Whitechapel
        WLG,J,-0.22241015208080,51.54930888824790,Willesden Green
        WJN,B,-0.24428889451703,51.53219149710360,Willesden Junction
        WDN,D,-0.20638158690359,51.42138371953170,Wimbledon
        WMP,D,-0.19959527217312,51.43446418602540,Wimbledon Park
        WGN,P,-0.10962638054845,51.59747603130840,Wood Green
        WGNSIDE,P,-0.10962638054845,51.59747603130840,Wood Green Sidings
        WFD,C,0.03403714415408,51.60703336518100,Woodford,Woodford Junction
        WFDSIDE,C,0.03403714415408,51.60703336518100,Woodford Sidings
        WSP,N,-0.18542102750884,51.61781140738290,Woodside Park
        XWLN,H,-0.224166667,51.50979722,Wood Lane
        XPRD,M,-0.29525630015897,51.57203799181500,Preston Road,Preston Road fast
        XLRD,H,-0.21777930179215,51.51354359389710,Latimer Road
        XGRD,H,-0.22674832920358,51.50195219730120,Goldhawk Road
        PADc,H,-0.1774,51.5173,Paddington Circle
        PADs,H,-0.1774,51.5173,Paddington H & C
        XXX5,B,-0.207778,51.533611,North Sidings between Queen's park and
        XXX9,B,-0.207778,51.533611,Queen's Park North Sidings
        XXX6,B,-0.104722,51.498333,London Road Depot
        XXX8,V,-0.01991863902501,51.58295470500250,Walthamstow Sidings
        XKRI,B,-0.2208,51.5342,Kensal Rise"""
    for row in csv.split("\n")
      [code, dummy, lon, lat, name] = row.split(',')
      station = new TubeStation("tube-#{code}", parseFloat(lat), parseFloat(lon))
      station.name = "\uF000 #{name}"
      @addFeature(station)

