
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

oneEightyOverPi = 180 / Math.PI
box = null

class this.FeatureManager
  constructor: (@ge, @lonRatio) ->
    @featureTree = new RTree()
    @visibleFeatures = {}
    @updateMoment = 0
    
  addFeature: (f) ->
    @featureTree.insert(f.rect(), f)
    
  removeFeature: (f) ->
    @hideFeature(f)
    @featureTree.remove(f.rect(), f)
  
  showFeature: (f, cam) ->
    return no if @visibleFeatures[f.id]?
    @visibleFeatures[f.id] = f
    f.show(@ge, cam)
    return yes
  
  hideFeature: (f) ->
    return no unless @visibleFeatures[f.id]?
    delete @visibleFeatures[f.id]
    f.hide(@ge)
    return yes
  
  featuresInBBox: (lat1, lon1, lat2, lon2) ->  # ones must be SW of (i.e. lower than) twos
    @featureTree.search({x: lon1, y: lat1, w: lon2 - lon1, h: lat2 - lat1})
    
  update: (cam) ->
    lookAt = @ge.getView().copyAsLookAt(ge.ALTITUDE_ABSOLUTE)
    lookLat = lookAt.getLatitude()
    lookLon = lookAt.getLongitude()
    midLat = (cam.lat + lookLat) / 2
    midLon = (cam.lon + lookLon) / 2
    
    latDiff = Math.abs(cam.lat - midLat)
    lonDiff = Math.abs(cam.lon - midLon)
    
    if latDiff > lonDiff * @lonRatio
      latSize = latDiff
      lonSize = latDiff * @lonRatio
    else
      lonSize = lonDiff
      latSize = lonDiff / @lonRatio

    lat1 = midLat - latSize
    lat2 = midLat + latSize
    lon1 = midLon - lonSize
    lon2 = midLon + lonSize
    
    ###
    ge.getFeatures().removeChild(box) if box
    kml = "<?xml version='1.0' encoding='UTF-8'?><kml xmlns='http://www.opengis.net/kml/2.2'><Document><Placemark><name>lookAt</name><Point><coordinates>#{lookLon},#{lookLat},0</coordinates></Point></Placemark><Placemark><name>camera</name><Point><coordinates>#{cam.lon},#{cam.lat},0</coordinates></Point></Placemark><Placemark><name>middle</name><Point><coordinates>#{midLon},#{midLat},0</coordinates></Point></Placemark><Placemark><LineString><altitudeMode>absolute</altitudeMode><coordinates>#{lon1},#{lat1},100 #{lon1},#{lat2},100 #{lon2},#{lat2},100 #{lon2},#{lat1},50 #{lon1},#{lat1},100</coordinates></LineString></Placemark></Document></kml>"
    box = ge.parseKml(kml)
    ge.getFeatures().appendChild(box)
    #console.log(kml)
    ###
    
    for f in @featuresInBBox(lat1, lon1, lat2, lon2)
      @showFeature(f, cam)
      f.updateMoment = @updateMoment
    
    for own id, f of @visibleFeatures
      @hideFeature(f) if f.updateMoment < @updateMoment
    
    @updateMoment += 1

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
  constructor: (@id, @lat, @lon, @alt = 120) ->
  
  rect: -> {x: @lon, y: @lat, w: 0, h: 0}
    
  show: (ge, cam) ->
    st = new SkyText(@lat, @lon, @alt)
    
    angleToCamRad = Math.atan2(@lon - cam.lon, @lat - cam.lat)
    angleToCamDeg = angleToCamRad * oneEightyOverPi

    st.line(@name, {bearing: angleToCamDeg})
    @geNode = ge.parseKml(st.kml())
    ge.getFeatures().appendChild(@geNode)
    
  hide: (ge) ->
    if @geNode
      ge.getFeatures().removeChild(@geNode)
      delete @geNode


class this.TubeStation extends Feature

class this.RailStationSet extends FeatureSet
  constructor: (featureManager) ->
    super(featureManager)
    csv = """ARB,Arbroath,56.559562,-2.588937
      ARD,Ardgay,57.881434,-4.36209
      AUI,Ardlui,56.301956,-4.721641
      ADS,Ardrossan Harbour,55.639868,-4.821088
      ASB,Ardrossan South Beach,55.641412,-4.801189
      ADN,Ardrossan Town,55.639703,-4.812653
      ADK,Ardwick,53.471358,-2.213882
      AGS,Argyle Street,55.857316,-4.250665
      ARG,Arisaig,56.912524,-5.839058
      ARL,Arlesey,52.026039,-0.266294
      AWT,Armathwaite,54.809114,-2.77168
      ARN,Arnside,54.202111,-2.827769
      ARR,Arram,53.88459,-0.426874
      ART,Arrochar & Tarbet,56.203961,-4.722753
      ARU,Arundel,50.848204,-0.546151
      ACT,Ascot,51.406242,-0.675816
      AUW,Ascott-under-Wychwood,51.867347,-1.564038
      ASH,Ash,51.249593,-0.712787
      AHV,Ash Vale,51.272244,-0.721631
      ABY,Ashburys,53.471652,-2.194435
      ASC,Ashchurch for Tewkesbury,51.999172,-2.109044
      ASF,Ashfield,55.888915,-4.2492
      AFS,Ashford (Surrey),51.436505,-0.46805
      AFK,Ashford International,51.143704,0.876228
      ABW,Abbey Wood (London),51.491061,0.121422
      ABE,Aber,51.574966,-3.229839
      ABR,Abercynon North,51.645316,-3.326816
      ACY,Abercynon,51.644711,-3.327001
      ABA,Aberdare,51.71506,-3.443095
      ABD,Aberdeen,57.143687,-2.098692
      AUR,Aberdour,56.054585,-3.300559
      AVY,Aberdovey,52.543971,-4.057076
      ABH,Abererch,52.898598,-4.374184
      AGV,Abergavenny,51.816693,-3.009653
      AGL,Abergele & Pensarn,53.294589,-3.582625
      AYW,Aberystwyth,52.414059,-4.081905
      ACR,Accrington,53.753208,-2.370004
      AAT,Achanalt,57.609576,-4.913846
      ACN,Achnasheen,57.579268,-5.072328
      ACH,Achnashellach,57.482052,-5.33305
      ACK,Acklington,55.3071,-1.651848
      ACL,Acle,52.634706,1.543939
      ACG,Acocks Green,52.449336,-1.818969
      ACB,Acton Bridge,53.265984,-2.602668
      ACC,Acton Central,51.508716,-0.262948
      AML,Acton Main Line,51.51718,-0.266733
      ADD,Adderley Park,52.483099,-1.85594
      ADW,Addiewell,55.843404,-3.606521
      ASN,Addlestone,51.373043,-0.484438
      ADM,Adisham,51.241204,1.199118
      ADC,Adlington (Cheshire),53.31957,-2.133562
      ADL,Adlington (Lancs),53.612944,-2.603064
      AWK,Adwick,53.57302,-1.181478
      AIG,Aigburth,53.36458,-2.927155
      ANS,Ainsdale,53.602047,-3.042649
      AIN,Aintree,53.473924,-2.956279
      AIR,Airbles,55.782828,-3.994185
      ADR,Airdrie,55.863973,-3.982901
      AYP,Albany Park,51.435451,0.125763
      ALB,Albrighton,52.637956,-2.268896
      ALD,Alderley Edge,53.303795,-2.236797
      AMT,Aldermaston,51.402015,-1.138755
      AHT,Aldershot,51.246415,-0.759842
      AGT,Aldrington,50.836376,-0.183794
      AAP,Alexandra Palace,51.597925,-0.12021
      AXP,Alexandra Parade,55.863672,-4.211414
      ALX,Alexandria,55.985075,-4.577467
      ALF,Alfreton,53.100449,-1.369694
      ALW,Allens West,54.524633,-1.361129
      ASS,Alness,57.694377,-4.249715
      ALM,Alnmouth,55.392419,-1.636893
      ALR,Alresford (Essex),51.85401,0.997467
      ASG,Alsager,53.09275,-2.298608
      ALN,Althorne,51.647875,0.752513
      ALP,Althorpe,53.585289,-0.732588
      ABC,Altnabreac,58.388133,-3.706287
      AON,Alton,51.151964,-0.966898
      ALT,Altrincham,53.387659,-2.347083
      ALV,Alvechurch,52.346084,-1.967653
      AMB,Ambergate,53.060533,-1.480695
      AMY,Amberley,50.896671,-0.54197
      AMR,Amersham,51.674208,-0.607574
      AMF,Ammanford,51.79598,-3.996754
      ANC,Ancaster,52.987933,-0.53561
      AND,Anderston,55.859873,-4.271922
      ADV,Andover,51.211541,-1.492221
      ANZ,Anerley,51.412151,-0.06586
      AGR,Angel Road,51.612405,-0.048766
      ANG,Angmering,50.816565,-0.48937
      ANN,Annan,54.983839,-3.262583
      ANL,Anniesland,55.889502,-4.321631
      AFV,Ansdell & Fairhaven,53.741476,-2.993031
      APP,Appleby,54.580353,-2.486697
      APD,Appledore (Kent),51.033234,0.816376
      APF,Appleford,51.639643,-1.242123
      APB,Appley Bridge,53.579047,-2.71888
      APS,Apsley,51.732527,-0.462913
      ASY,Ashley,53.356009,-2.34101
      AHD,Ashtead,51.317879,-0.308122
      AHN,Ashton-under-Lyne,53.491288,-2.094312
      AHS,Ashurst (Kent),51.128658,0.152679
      ANF,Ashurst New Forest,50.889841,-1.526623
      AWM,Ashwell & Morden,52.03078,-0.109761
      ASK,Askam,54.189044,-3.204514
      ALK,Aslockton,52.951393,-0.898544
      ASP,Aspatria,54.759322,-3.331731
      APG,Aspley Guise,52.021246,-0.632312
      AST,Aston,52.504244,-1.871929
      ATH,Atherstone,52.578987,-1.552802
      ATN,Atherton,53.529159,-2.478971
      ATT,Attadale,57.395014,-5.455569
      ATB,Attenborough,52.906365,-1.23126
      ATL,Attleborough,52.514568,1.022371
      AUK,Auchinleck,55.470274,-4.295335
      AUD,Audley End,52.00445,0.207186
      AUG,Aughton Park,53.554487,-2.895073
      AVM,Aviemore,57.188496,-3.828866
      AVF,Avoncliff,51.339646,-2.281323
      AVN,Avonmouth,51.500359,-2.69947
      AXM,Axminster,50.779259,-3.00473
      AYS,Aylesbury,51.813896,-0.815073
      AYL,Aylesford,51.301315,0.4662
      AYH,Aylesham,51.227257,1.209482
      AYR,Ayr,55.458142,-4.625855
      BAC,Bache,53.209334,-2.892356
      BAJ,Baglan,51.615543,-3.811153
      BAG,Bagshot,51.364366,-0.688644
      BLD,Baildon,53.850237,-1.753639
      BIO,Baillieston,55.844706,-4.114496
      BAB,Balcombe,51.055516,-0.136906
      BDK,Baldock,51.992879,-0.187537
      BAL,Balham,51.443224,-0.152399
      BHC,Balloch,56.002926,-4.583468
      BSI,Balmossie,56.474554,-2.838959
      BMB,Bamber Bridge,53.726791,-2.66077
      BAM,Bamford,53.339015,-1.68908
      BNV,Banavie,56.84329,-5.095412
      BAN,Banbury,52.060317,-1.328117
      BNG,Bangor (Gwynedd),53.222298,-4.135887
      BAH,Bank Hall,53.437508,-2.987511
      BAD,Banstead,51.329346,-0.213134
      BSS,Barassie,55.561056,-4.651118
      ZBB,Barbican,51.519682,-0.097415
      BLL,Bardon Mill,54.974498,-2.346513
      BAR,Bare Lane,54.07455,-2.835328
      BGI,Bargeddie,55.851724,-4.071742
      BGD,Bargoed,51.692311,-3.229689
      BKG,Barking,51.539494,0.08093
      BRT,Barlaston,52.942887,-2.16811
      BMG,Barming,51.284892,0.478988
      BRM,Barmouth,52.722905,-4.056604
      BNH,Barnehurst,51.464958,0.159673
      BNS,Barnes,51.467085,-0.242141
      BNI,Barnes Bridge,51.472007,-0.252607
      BTB,Barnetby,53.574242,-0.409717
      BAA,Barnham,50.830896,-0.639658
      BNL,Barnhill,55.877835,-4.223411
      BNY,Barnsley,53.554623,-1.477087
      BNP,Barnstaple,51.073965,-4.06314
      BTG,Barnt Green,52.361101,-1.992458
      BRR,Barrhead,55.803747,-4.397268
      BRL,Barrhill,55.09701,-4.781761
      BAV,Barrow Haven,53.69715,-0.391457
      BWS,Barrow upon Soar,52.749353,-1.144836
      BIF,Barrow-in-Furness,54.119007,-3.226117
      BRY,Barry,51.39678,-3.284995
      BYD,Barry Docks,51.402439,-3.260714
      BYI,Barry Island,51.392411,-3.273373
      BYL,Barry Links,56.493138,-2.745447
      BAU,Barton-on-Humber,53.688844,-0.443263
      BSO,Basildon,51.568107,0.456819
      BSK,Basingstoke,51.268355,-1.087245
      BBL,Bat & Ball,51.289758,0.194255
      BTH,Bath Spa,51.377681,-2.357016
      BHG,Bathgate,55.899112,-3.64097
      BTL,Batley,53.709955,-1.622956
      BTT,Battersby,54.457691,-1.092985
      BAK,Battersea Park,51.476959,-0.147509
      BAT,Battle,50.91291,0.494732
      BLB,Battlesbridge,51.624828,0.565313
      BAY,Bayford,51.757719,-0.095583
      BCF,Beaconsfield,51.611292,-0.643803
      BER,Bearley,52.244423,-1.750247
      BRN,Bearsden,55.91715,-4.332887
      BSD,Bearsted,51.275819,0.57761
      BSL,Beasdale,56.899532,-5.763783
      BEU,Beaulieu Road,50.855038,-1.50474
      BEB,Bebington,53.357669,-3.003634
      BCC,Beccles,52.458545,1.569521
      BEC,Beckenham Hill,51.42458,-0.015925
      BKJ,Beckenham Junction,51.411033,-0.025786
      BKJ,Beckenham Junction,51.411171,-0.025996
      BDM,Bedford,52.136198,-0.479421
      BSJ,Bedford St Johns,52.129489,-0.467479
      BDH,Bedhampton,50.853945,-0.995813
      BMT,Bedminster,51.440085,-2.594152
      BEH,Bedworth,52.479312,-1.467384
      BDW,Bedwyn,51.379636,-1.598773
      BEE,Beeston,52.920773,-1.207654
      BKS,Bekesbourne,51.26136,1.136737
      BLV,Belle Vue,53.462389,-2.180505
      BLG,Bellgrove,55.857128,-4.225423
      BGM,Bellingham,51.432911,-0.019305
      BLH,Bellshill,55.816553,-4.02518
      BLM,Belmont,51.343812,-0.19883
      BLP,Belper,53.024585,-1.482618
      BEG,Beltring,51.204705,0.403524
      BVD,Belvedere,51.492117,0.152314
      BEM,Bempton,54.128307,-0.180443
      BEY,Ben Rhydding,53.925727,-1.797433
      BEF,Benfleet,51.543947,0.561741
      BEN,Bentham,54.115796,-2.510911
      BTY,Bentley (Hants),51.181229,-0.86811
      BYK,Bentley (S Yorks),53.543689,-1.15156
      BAS,Bere Alston,50.48558,-4.200384
      BFE,Bere Ferrers,50.451263,-4.181463
      BKM,Berkhamsted,51.763139,-0.56199
      BKW,Berkswell,52.395895,-1.642831
      BYA,Berney Arms,52.58981,1.630399
      BBW,Berry Brow,53.621054,-1.793433
      BRS,Berrylands,51.399043,-0.280691
      BRK,Berwick (Sussex),50.840371,0.166045
      BWK,Berwick-upon-Tweed,55.774827,-2.011143
      BES,Bescar Lane,53.623552,-2.914678
      BSC,Bescot Stadium,52.563107,-1.9911
      BTO,Betchworth,51.248186,-0.266949
      BET,Bethnal Green,51.523917,-0.059541
      BYC,Betws-y-Coed,53.092081,-3.800866
      BEV,Beverley,53.842303,-0.423899
      BEX,Bexhill,50.841036,0.477047
      BXY,Bexley,51.440218,0.147929
      BXH,Bexleyheath,51.463499,0.133762
      BCS,Bicester North,51.903489,-1.150364
      BIT,Bicester Town,51.893492,-1.148053
      BKL,Bickley,51.400103,0.045266
      BID,Bidston,53.409152,-3.078559
      BIW,Biggleswade,52.084689,-0.261163
      BBK,Bilbrook,52.623732,-2.186083
      BIC,Billericay,51.628885,0.418658
      BIL,Billingham,54.605617,-1.279734
      BIG,Billingshurst,51.015197,-0.450277
      BIN,Bingham,52.954574,-0.952051
      BIY,Bingley,53.848627,-1.837325
      BCG,Birchgrove,51.521556,-3.201862
      BCH,Birchington-on-Sea,51.377497,1.301436
      BWD,Birchwood,53.411957,-2.528007
      BIK,Birkbeck,51.403889,-0.055712
      BDL,Birkdale,53.634064,-3.014447
      BKC,Birkenhead Central,53.388329,-3.02082
      BKN,Birkenhead North,53.40445,-3.057532
      BKP,Birkenhead Park,53.397421,-3.0391
      BHI,Birmingham International,52.45082,-1.72585
      BMO,Birmingham Moor Street,52.479092,-1.892468
      BHM,Birmingham New Street,52.477794,-1.89836
      BSW,Birmingham Snow Hill,52.483368,-1.899083
      BIA,Bishop Auckland,54.657472,-1.677568
      BBG,Bishopbriggs,55.903872,-4.224901
      BIS,Bishops Stortford,51.866697,0.16492
      BIP,Bishopstone,50.780136,0.082785
      BPT,Bishopton,55.902153,-4.501567
      BTE,Bitterne,50.91821,-1.37699
      BBN,Blackburn,53.74653,-2.47912
      BKH,Blackheath,51.465795,0.008898
      BHO,Blackhorse Road,51.586606,-0.04121
      BPN,Blackpool North,53.821927,-3.049271
      BPB,Blackpool Pleasure Beach,53.787965,-3.053873
      BPS,Blackpool South,53.798714,-3.048935
      BLK,Blackrod,53.591536,-2.569523
      BAW,Blackwater,51.331808,-0.777005
      BFF,Blaenau Ffestiniog,52.994563,-3.938601
      BLA,Blair Atholl,56.765533,-3.850225
      BAI,Blairhill,55.866598,-4.042168
      BKT,Blake Street,52.604899,-1.844907
      BKD,Blakedown,52.406189,-2.176345
      BLT,Blantyre,55.797554,-4.086412
      BLO,Blaydon,54.965794,-1.712593
      BSB,Bleasby,53.041687,-0.942482
      BLY,Bletchley,51.995342,-0.736299
      BLX,Bloxwich,52.618215,-2.011472
      BWN,Bloxwich North,52.625451,-2.017678
      BLN,Blundellsands & Crosby,53.487698,-3.039857
      BYB,Blythe Bridge,52.968159,-2.06696
      BOD,Bodmin Parkway,50.44585,-4.662967
      BOR,Bodorgan,53.204318,-4.41801
      BOG,Bognor Regis,50.786547,-0.676157
      BGS,Bogston,55.937034,-4.711381
      BON,Bolton,53.574158,-2.425823
      BTD,Bolton-on-Dearne,53.519013,-1.312226
      BKA,Bookham,51.288735,-0.383998
      BOC,Bootle (Cumbria),54.291309,-3.393862
      BNW,Bootle New Strand,53.453403,-2.994746
      BOT,Bootle Oriel Road,53.446635,-2.995733
      BBS,Bordesley,52.471886,-1.877764
      BRG,Borough Green & Wrotham,51.293216,0.306272
      BRH,Borth,52.491041,-4.050186
      BOH,Bosham,50.842737,-0.847413
      BSN,Boston,52.978112,-0.030995
      BOE,Botley,50.916801,-1.258792
      BTF,Bottesford,52.945006,-0.796018
      BNE,Bourne End,51.577119,-0.710454
      BMH,Bournemouth,50.727529,-1.863927
      BRV,Bournville,52.426976,-1.926418
      BWB,Bow Brickhill,52.004309,-0.696056
      BOP,Bowes Park,51.607013,-0.120557
      BWG,Bowling,55.931071,-4.493826
      BXW,Boxhill & Westhumble,51.254008,-0.328467
      BCE,Bracknell,51.413091,-0.751687
      BDQ,Bradford Forster Square,53.796938,-1.752965
      BDI,Bradford Interchange,53.791088,-1.749599
      BOA,Bradford-on-Avon,51.344909,-2.252324
      BDN,Brading,50.678358,-1.138712
      BTR,Braintree,51.875399,0.556715
      BML,Bramhall,53.360628,-2.163592
      BMY,Bramley (Hants),51.330076,-1.060973
      BLE,Bramley (West Yorks),53.805363,-1.637211
      BMP,Brampton (Cumbria),54.932642,-2.703815
      BRP,Brampton (Suffolk),52.395456,1.54384
      BCN,Branchton,55.940588,-4.803528
      BND,Brandon,52.454024,0.624756
      BSM,Branksome,50.72758,-1.919181
      BYS,Braystones,54.439546,-3.543373
      BDY,Bredbury,53.423168,-2.110486
      BRC,Breich,55.827308,-3.668119
      BFD,Brentford,51.487546,-0.309629
      BRE,Brentwood,51.613606,0.299613
      BWO,Bricket Wood,51.705431,-0.359092
      BEA,Bridge of Allan,56.156627,-3.957221
      BRO,Bridge of Orchy,56.515852,-4.762978
      BGN,Bridgend,51.506973,-3.575292
      BDG,Bridgeton,55.848938,-4.226073
      BWT,Bridgwater,51.12785,-2.990413
      BDT,Bridlington,54.08415,-0.198734
      BRF,Brierfield,53.824549,-2.23695
      BGG,Brigg,53.549164,-0.486128
      BTN,Brighton,50.828997,-0.141252
      BMD,Brimsdown,51.655584,-0.030791
      BNT,Brinnington,53.432131,-2.135118
      BPW,Bristol Parkway,51.513798,-2.542164
      BRI,Bristol Temple Meads,51.449141,-2.581317
      BHD,Brithdir,51.710304,-3.22873
      RBS,British Steel Redcar,54.6099,-1.112676
      BNF,Briton Ferry,51.637899,-3.819268
      BRX,Brixton,51.463298,-0.114158
      BGE,Broad Green,53.406518,-2.893484
      BDB,Broadbottom,53.440988,-2.016519
      BSR,Broadstairs,51.36068,1.433586
      BCU,Brockenhurst,50.81683,-1.573523
      BHS,Brockholes,53.596986,-1.769692
      BCY,Brockley,51.464647,-0.037511
      BNR,Brockley Whins,54.95955,-1.461367
      BOM,Bromborough,53.321861,-2.986895
      BMR,Bromborough Rake,53.329921,-2.989469
      BMC,Bromley Cross,53.614055,-2.410897
      BMN,Bromley North,51.408326,0.017019
      BMS,Bromley South,51.399974,0.01737
      BMV,Bromsgrove,52.322702,-2.048366
      BSY,Brondesbury,51.545166,-0.202284
      BSP,Brondesbury Park,51.540699,-0.210103
      BPK,Brookmans Park,51.721064,-0.204526
      BKO,Brookwood,51.303754,-0.635731
      BME,Broome,52.422784,-2.885206
      BMF,Broomfleet,53.740154,-0.673353
      BRA,Brora,58.012933,-3.852286
      BUH,Brough,53.727248,-0.579448
      BYF,Broughty Ferry,56.467149,-2.873156
      BXB,Broxbourne,51.746914,-0.01106
      BCV,Bruce Grove,51.593959,-0.069842
      BDA,Brundall,52.619507,1.439322
      BGA,Brundall Gardens,52.623467,1.41844
      BRW,Brunswick,53.383256,-2.976077
      BRU,Bruton,51.111631,-2.447073
      BYN,Bryn,53.49988,-2.647214
      BUC,Buckenham,52.597762,1.470349
      BCK,Buckley,53.16305,-3.055926
      BUK,Bucknell,52.357561,-2.948511
      BGL,Bugle,50.399938,-4.791836
      BHR,Builth Road,52.16933,-3.427041
      BLW,Bulwell,52.999713,-1.196227
      BUE,Bures,51.971172,0.769177
      BUG,Burgess Hill,50.95361,-0.127743
      BUY,Burley Park,53.812045,-1.577771
      BUW,Burley-in-Wharfedale,53.908164,-1.753376
      BNA,Burnage,53.421181,-2.215677
      BUD,Burneside (Cumbria),54.355305,-2.766223
      BNM,Burnham (Berks),51.523506,-0.646356
      BUU,Burnham-on-Crouch,51.633662,0.814058
      BUB,Burnley Barracks,53.79125,-2.258013
      BNC,Burnley Central,53.793525,-2.244972
      BYM,Burnley Manchester Road,53.784978,-2.248868
      BUI,Burnside (Strathclyde),55.817072,-4.20398
      BTS,Burntisland,56.057074,-3.233198
      BCB,Burscough Bridge,53.605211,-2.841739
      BCJ,Burscough Junction,53.598032,-2.840085
      BUO,Bursledon,50.88438,-1.305267
      BUJ,Burton Joyce,52.984088,-1.040711
      BUT,Burton-on-Trent,52.805832,-1.642455
      BSE,Bury St Edmunds,52.253778,0.713335
      BUS,Busby,55.780334,-4.262187
      BHK,Bush Hill Park,51.641519,-0.069195
      BSH,Bushey,51.645585,-0.384726
      BUL,Butlers Lane,52.592484,-1.838013
      BPC,Penychain,52.902898,-4.33873
      BXD,Buxted,50.990008,0.131466
      BUX,Buxton,53.260736,-1.912862
      BFN,Byfleet & New Haw,51.349793,-0.48137
      BYE,Bynea,51.672036,-4.098902
      CAD,Cadoxton,51.412278,-3.248906
      CGW,Caergwrle,53.107878,-3.032913
      CPH,Caerphilly,51.571577,-3.218492
      CWS,Caersws,52.516137,-3.432503
      CDT,Caldicot,51.584789,-2.760578
      CIR,Caledonian Road & Barnsbury,51.543041,-0.116703
      CSK,Calstock,50.497565,-4.208697
      CDU,Cam & Dursley,51.717621,-2.359081
      CAM,Camberley,51.336325,-0.744254
      CBN,Camborne,50.210425,-5.29746
      CBG,Cambridge,52.194572,0.137581
      CBH,Cambridge Heath (London),51.531972,-0.057252
      CBL,Cambuslang,55.819601,-4.172995
      CMD,Camden Road,51.541791,-0.138675
      CMO,Camelon,56.006085,-3.817598
      CNL,Canley,52.399255,-1.547565
      CAO,Cannock,52.686176,-2.022141
      CNN,Canonbury,51.548733,-0.092164
      CBE,Canterbury East,51.27427,1.075999
      CBW,Canterbury West,51.284272,1.075333
      CNY,Cantley,52.578772,1.513436
      CPU,Capenhurst,53.260188,-2.942284
      CBB,Carbis Bay,50.197153,-5.464024
      CDD,Cardenden,56.141247,-3.261642
      CDB,Cardiff Bay,51.467107,-3.166412
      CDF,Cardiff Central,51.476024,-3.17931
      CDQ,Cardiff Queen Street,51.48196,-3.170189
      CDO,Cardonald,55.852562,-4.340677
      CDR,Cardross,55.960371,-4.653055
      CRF,Carfin,55.807334,-3.956243
      CAK,Cark,54.177568,-2.972828
      CAR,Carlisle,54.890652,-2.933819
      CTO,Carlton,52.964976,-1.07925
      CLU,Carluke,55.731261,-3.848914
      CMN,Carmarthen,51.85336,-4.305984
      CML,Carmyle,55.834331,-4.158167
      CNF,Carnforth,54.129687,-2.771231
      CAN,Carnoustie,56.500552,-2.706607
      CAY,Carntyne,55.855045,-4.178649
      CPK,Carpenders Park,51.628353,-0.385917
      CAG,Carrbridge,57.279485,-3.828202
      CSH,Carshalton,51.368452,-0.166343
      CSB,Carshalton Beeches,51.357408,-0.169772
      CRS,Carstairs,55.691044,-3.668465
      CDY,Cartsdyke,55.942205,-4.731571
      CBP,Castle Bar Park,51.52293,-0.331526
      CLC,Castle Cary,51.099807,-2.522796
      CFD,Castleford,53.724093,-1.354656
      CAS,Castleton (Manchester),53.591861,-2.178232
      CSM,Castleton Moor,54.46729,-0.946661
      CAT,Caterham,51.282138,-0.07828
      CTF,Catford,51.444405,-0.026291
      CFB,Catford Bridge,51.444739,-0.024765
      CYS,Cathays,51.488898,-3.178692
      CCT,Cathcart,55.817663,-4.260522
      CTL,Cattal,53.997495,-1.319778
      CAU,Causeland,50.405676,-4.466483
      CYB,Cefn-y-Bedd,53.098814,-3.031053
      CTH,Chadwell Heath,51.568038,0.128985
      CFH,Chafford Hundred,51.485556,0.287475
      CFO,Chalfont and Latimer,51.668111,-0.560504
      CHW,Chalkwell,51.538721,0.670621
      CEF,Chapel-en-le-Frith,53.312245,-1.918761
      CLN,Chapeltown,53.462353,-1.466275
      CPN,Chapelton (Devon),51.016529,-4.024745
      CWC,Chappel & Wakes Colne,51.925916,0.758531
      CHG,Charing (Kent),51.208097,0.790362
      CHC,Charing Cross (Glasgow),55.864675,-4.269805
      CBY,Charlbury,51.872434,-1.489678
      CTN,Charlton,51.486812,0.031283
      CRT,Chartham,51.257268,1.018069
      CSR,Chassen Road,53.446174,-2.368232
      CTM,Chatham,51.380376,0.52118
      CHT,Chathill,55.536731,-1.706391
      CHU,Cheadle Hulme,53.375944,-2.188302
      CHE,Cheam,51.355476,-0.214142
      CED,Cheddington,51.857925,-0.662126
      CEL,Chelford,53.270867,-2.279605
      CHM,Chelmsford,51.736377,0.468598
      CLD,Chelsfield,51.356255,0.109097
      CNM,Cheltenham Spa,51.897403,-2.099613
      CPW,Chepstow,51.640179,-2.671911
      CYT,Cherry Tree,53.732884,-2.518376
      CHY,Chertsey,51.387161,-0.509654
      CHN,Cheshunt,51.702878,-0.023933
      CSN,Chessington North,51.364038,-0.300676
      CSS,Chessington South,51.356547,-0.308134
      CTR,Chester,53.196709,-2.879595
      CRD,Chester Road,52.535659,-1.832472
      CLS,Chester-le-Street,54.854601,-1.578028
      CHD,Chesterfield,53.238237,-1.420114
      CSW,Chestfield & Swalecliffe,51.360331,1.067729
      CNO,Chetnole,50.866482,-2.574037
      CCH,Chichester,50.832042,-0.78173
      CIL,Chilham,51.244612,0.975926
      CHL,Chilworth,51.215208,-0.524802
      CHI,Chingford,51.633086,0.009923
      CLY,Chinley,53.340304,-1.94439
      CPM,Chippenham,51.462485,-2.115389
      CHP,Chipstead,51.309317,-0.169404
      CRK,Chirk,52.9331,-3.065642
      CIT,Chislehurst,51.405555,0.057443
      CHK,Chiswick,51.481135,-0.267812
      CHO,Cholsey,51.570203,-1.158003
      CRL,Chorley,53.652551,-2.626777
      CLW,Chorleywood,51.654251,-0.518298
      CHR,Christchurch,50.738202,-1.784539
      CHH,Christs Hospital,51.05068,-0.36353
      CTW,Church & Oswaldtwistle,53.750355,-2.390906
      CHF,Church Fenton,53.826347,-1.227446
      CTT,Church Stretton,52.537435,-2.803694
      CIM,Cilmeri,52.150537,-3.456549
      CTK,City Thameslink,51.513936,-0.103564
      CLT,Clacton-on-Sea,51.794012,1.154124
      CLA,Clandon,51.264001,-0.502744
      CPY,Clapham (N Yorks),54.105398,-2.409844
      CLP,Clapham High Street,51.46548,-0.132496
      CLJ,Clapham Junction,51.464187,-0.170268
      CLJ,Clapham Junction,51.464187,-0.170254
      CLJ,Clapham Junction,51.464187,-0.17024
      CLJ,Clapham Junction,51.464186,-0.170225
      CPT,Clapton,51.561644,-0.056998
      CLR,Clarbeston Road,51.851676,-4.883578
      CKS,Clarkston,55.789343,-4.27563
      CLV,Claverdon,52.277103,-1.696549
      CLG,Claygate,51.361211,-0.348224
      CLE,Cleethorpes,53.56193,-0.029227
      CEA,Cleland,55.804643,-3.910234
      CLI,Clifton (Manchester),53.522505,-2.314745
      CFN,Clifton Down,51.464542,-2.611743
      CLH,Clitheroe,53.873478,-2.394337
      CLK,Clock House,51.408584,-0.040631
      CUW,Clunderwen,51.84055,-4.73187
      CYK,Clydebank,55.900684,-4.404399
      CBC,Coatbridge Central,55.863165,-4.0324
      CBS,Coatbridge Sunnyside,55.866918,-4.028281
      COA,Coatdyke,55.864335,-4.004974
      CSD,Cobham & Stoke d'Abernon,51.318097,-0.389323
      CSL,Codsall,52.627302,-2.201758
      CGN,Cogan,51.445991,-3.189099
      COL,Colchester,51.900723,0.892629
      CET,Colchester Town,51.886465,0.904792
      CLM,Collingham,53.144105,-0.750391
      CLL,Collington,50.839283,0.457891
      CNE,Colne,53.854846,-2.181177
      CWL,Colwall,52.079877,-2.356946
      CWB,Colwyn Bay,53.296374,-3.72542
      CME,Combe (Oxon),51.83234,-1.392884
      COM,Commondale,54.481823,-0.974996
      CNG,Congleton,53.15787,-2.192579
      CNS,Conisbrough,53.489327,-1.234333
      CON,Connel Ferry,56.452337,-5.38542
      CEY,Cononley,53.917268,-2.011233
      CNP,Conway Park,53.393374,-3.02267
      CNW,Conwy,53.280116,-3.830528
      COB,Cooden Beach,50.833366,0.426888
      COO,Cookham,51.557464,-0.72206
      CBR,Cooksbridge,50.90375,-0.009175
      COE,Coombe Junction Halt (Rail Station),50.445906,-4.481887
      COP,Copplestone,50.814456,-3.75159
      CRB,Corbridge,54.966311,-2.018565
      CKH,Corkerhill,55.837494,-4.334278
      CKL,Corkickle,54.541686,-3.582165
      CPA,Corpach,56.842809,-5.121943
      CRR,Corrour,56.760196,-4.69059
      COY,Coryton,51.520367,-3.231538
      CSY,Coseley,52.545096,-2.085772
      COS,Cosford,52.644967,-2.306184
      CSA,Cosham,50.841913,-1.067315
      CGM,Cottingham,53.781668,-0.40644
      COT,Cottingley,53.767831,-1.587712
      CDS,Coulsdon South,51.315835,-0.137861
      COV,Coventry,52.400828,-1.51345
      CWN,Cowden,51.155633,0.110059
      COW,Cowdenbeath,56.112084,-3.343184
      CRA,Cradley Heath,52.469667,-2.090482
      CGD,Craigendoran,55.994788,-4.711225
      CRM,Cramlington,55.087773,-1.59861
      CRV,Craven Arms,52.442014,-2.837043
      CRW,Crawley,51.112208,-0.186646
      CRY,Crayford,51.448278,0.178963
      CDI,Crediton,50.783292,-3.646794
      CES,Cressing,51.852344,0.577989
      CSG,Cressington,53.358764,-2.912003
      CWD,Creswell (Derbys),53.264038,-1.21587
      CRE,Crewe,53.08964,-2.432969
      CKN,Crewkerne,50.873526,-2.778497
      CWH,Crews Hill,51.684487,-0.106861
      CNR,Crianlarich,56.390464,-4.618419
      CCC,Criccieth,52.918425,-4.237519
      CRI,Cricklewood,51.558454,-0.212652
      CFF,Croftfoot,55.818251,-4.228311
      CFT,Crofton Park,51.455187,-0.036477
      CMR,Cromer,52.930112,1.292843
      CMF,Cromford,53.112947,-1.548786
      CKT,Crookston,55.842192,-4.365931
      CRG,Cross Gates,53.804928,-1.451585
      CFL,Crossflatts,53.858479,-1.844889
      COI,Crosshill,55.833279,-4.256797
      CMY,Crossmyloof,55.83394,-4.284303
      CSO,Croston,53.667574,-2.777748
      CRH,Crouch Hill,51.571303,-0.117123
      COH,Crowborough,51.046377,0.188041
      CWU,Crowhurst,50.888574,0.501366
      CWE,Crowle,53.589753,-0.817362
      CRN,Crowthorne,51.366726,-0.819256
      CRO,Croy,55.955671,-4.035967
      CYP,Crystal Palace,51.418107,-0.072584
      CUD,Cuddington,53.239933,-2.599305
      CUF,Cuffley,51.708723,-0.109758
      CUM,Culham,51.653795,-1.236495
      CUA,Culrain,57.919495,-4.404272
      CUB,Cumbernauld,55.942019,-3.980326
      CUP,Cupar,56.316977,-3.008758
      CUH,Curriehill,55.900559,-3.31875
      CUX,Cuxton,51.373925,0.461737
      CMH,Cwmbach,51.701931,-3.413735
      CWM,Cwmbran,51.656587,-3.01621
      CYN,Cynghordy,52.051506,-3.748223
      DDK,Dagenham Dock,51.526089,0.146131
      DSY,Daisy Hill,53.539468,-2.515861
      DAG,Dalgety Bay,56.042088,-3.367719
      DAL,Dalmally,56.401176,-4.983532
      DAK,Dalmarnock,55.842079,-4.217695
      DAM,Dalmeny,55.986312,-3.381617
      DMR,Dalmuir,55.911922,-4.426666
      DLR,Dalreoch,55.947407,-4.577845
      DLY,Dalry,55.706215,-4.711059
      DLS,Dalston (Cumbria),54.846181,-2.988856
      DLK,Dalston Kingsland,51.548148,-0.075674
      DLT,Dalton,54.154244,-3.179001
      DLW,Dalwhinnie,56.935154,-4.246191
      DNY,Danby,54.466433,-0.910733
      DCT,Danescourt,51.500505,-3.233926
      DZY,Danzey,52.324377,-1.821237
      DAR,Darlington,54.520458,-1.547333
      DAN,Darnall,53.3846,-1.412566
      DSM,Darsham,52.273018,1.523501
      DFD,Dartford,51.44737,0.219276
      DRT,Darton,53.588383,-1.53166
      DWN,Darwen,53.69805,-2.464937
      DAT,Datchet,51.483077,-0.579405
      DVN,Davenport,53.390916,-2.152956
      DWL,Dawlish,50.580806,-3.464638
      DWW,Dawlish Warren,50.598696,-3.443575
      DEA,Deal,51.223051,1.398876
      DEN,Dean,51.042228,-1.634786
      DNN,Dean Lane (closed),53.504125,-2.184648
      DGT,Deansgate,53.474199,-2.251049
      DGY,Deganwy,53.294762,-3.83339
      DHN,Deighton,53.668496,-1.751898
      DLM,Delamere,53.228788,-2.666559
      DBD,Denby Dale,53.572646,-1.663213
      DNM,Denham,51.578838,-0.497416
      DGC,Denham Golf Club,51.580598,-0.517766
      DMK,Denmark Hill,51.468202,-0.089335
      DNT,Dent,54.282418,-2.363602
      DTN,Denton,53.456881,-2.131658
      DEP,Deptford,51.478847,-0.026244
      DBY,Derby,52.916177,-1.463073
      DBR,Derby Road (Ipswich),52.050568,1.182674
      DKR,Derker (closed),53.550155,-2.101686
      DPT,Devonport,50.378518,-4.170739
      DEW,Dewsbury,53.692145,-1.63311
      DID,Didcot Parkway,51.610955,-1.242875
      DIG,Digby & Sowton,50.713976,-3.473574
      DMH,Dilton Marsh,51.247993,-2.207405
      DMG,Dinas (Rhondda),51.617835,-3.437552
      DNS,Dinas Powys,51.431663,-3.218361
      DGL,Dingle Road,51.440052,-3.180599
      DIN,Dingwall,57.594217,-4.422197
      DND,Dinsdale,54.514739,-1.467075
      DTG,Dinting,53.449345,-1.970296
      DSL,Disley,53.358197,-2.042481
      DIS,Diss,52.373676,1.123725
      DOC,Dockyard (Plymouth),50.382153,-4.175927
      DOD,Dodworth,53.544158,-1.530939
      DOL,Dolau,52.29536,-3.263623
      DLH,Doleham,50.918746,0.610725
      DLG,Dolgarrog,53.186363,-3.82264
      DWD,Dolwyddelan,53.052027,-3.885137
      DON,Doncaster,53.521497,-1.140238
      DCH,Dorchester South,50.709281,-2.43724
      DCW,Dorchester West,50.710942,-2.442539
      DOR,Dore,53.327471,-1.515449
      DKG,Dorking,51.240926,-0.324228
      DPD,Dorking Deepdene,51.2388,-0.32462
      DKT,Dorking West,51.236222,-0.339956
      DMS,Dormans,51.155787,-0.004281
      DDG,Dorridge,52.372082,-1.752892
      DVH,Dove Holes,53.299818,-1.890426
      DVP,Dover Priory,51.125705,1.305325
      DVC,Dovercourt,51.93875,1.280641
      DVY,Dovey Junction,52.564372,-3.923911
      DOW,Downham Market,52.604126,0.3657
      DRG,Drayton Green,51.516616,-0.330172
      DYP,Drayton Park,51.552771,-0.105483
      DRM,Drem,56.005117,-2.786053
      DRF,Driffield,54.001547,-0.434676
      DRI,Drigg,54.376967,-3.443414
      DTW,Droitwich Spa,52.268216,-2.158356
      DRO,Dronfield,53.301385,-1.468778
      DMC,Drumchapel,55.904805,-4.362864
      DFR,Drumfrochar,55.94124,-4.774746
      DRU,Drumgelloch,55.865828,-3.954069
      DMY,Drumry,55.904585,-4.385457
      DUD,Duddeston,52.488376,-1.871386
      DDP,Dudley Port,52.524665,-2.049474
      DFI,Duffield,52.987744,-1.486036
      DRN,Duirinish,57.319951,-5.691305
      DST,Duke Street,55.85843,-4.213034
      DUL,Dullingham,52.201664,0.366692
      DBC,Dumbarton Central,55.946647,-4.566903
      DBE,Dumbarton East,55.942239,-4.554119
      DUM,Dumbreck,55.845026,-4.300927
      DMF,Dumfries,55.07256,-3.6043
      DMP,Dumpton Park,51.345705,1.425845
      DUN,Dunbar,55.998287,-2.513351
      DBL,Dunblane,56.185881,-3.965478
      DBG,Mottisfont & Dunbridge,51.033791,-1.546704
      DCG,Duncraig,57.336977,-5.63712
      DEE,Dundee,56.456475,-2.971208
      DFE,Dunfermline Town,56.068184,-3.452524
      DKD,Dunkeld & Birnam,56.557045,-3.578396
      DNL,Dunlop,55.711875,-4.532372
      DOT,Dunston,54.950061,-1.642056
      DNG,Dunton Green,51.296487,0.170965
      DHM,Durham,54.779398,-1.581762
      DUR,Durrington-on-Sea,50.817518,-0.411444
      DYC,Dyce,57.205633,-2.192328
      DYF,Dyffryn Ardudwy,52.788866,-4.10465
      EAG,Eaglescliffe,54.529442,-1.349449
      EAL,Ealing Broadway,51.514841,-0.301729
      ERL,Earlestown,53.451151,-2.637662
      EAR,Earley,51.441099,-0.917969
      EAD,Earlsfield,51.442335,-0.18769
      ELD,Earlswood (Surrey),51.227325,-0.170797
      EWD,Earlswood (West Midlands),52.366594,-1.861161
      EBL,East Boldon,54.946421,-1.420327
      ECR,East Croydon,51.375452,-0.092754
      EDY,East Didsbury,53.409323,-2.221995
      EDW,East Dulwich,51.461493,-0.080546
      EFL,East Farleigh,51.255235,0.484759
      EGF,East Garforth,53.791992,-1.37054
      EGR,East Grinstead,51.126268,-0.017873
      EKL,East Kilbride,55.765998,-4.180214
      EML,East Malling,51.285807,0.43931
      ETL,East Tilbury,51.484831,0.412958
      EWR,East Worthing,50.821636,-0.354868
      EBN,Eastbourne,50.769371,0.281276
      EBK,Eastbrook,51.437634,-3.206147
      EST,Easterhouse,55.859751,-4.107164
      ERA,Eastham Rake,53.307553,-2.981132
      ESL,Eastleigh,50.96924,-1.350074
      EGN,Eastrington,53.75518,-0.787635
      ECC,Eccles,53.485374,-2.334513
      ECS,Eccles Road,52.470903,0.969942
      ECL,Eccleston Park,53.430801,-2.780041
      EDL,Edale,53.364805,-1.816325
      EDN,Eden Park,51.390089,-0.026329
      EBR,Edenbridge,51.208432,0.060673
      EBT,Edenbridge Town,51.200079,0.067199
      EDG,Edge Hill,53.402631,-2.946483
      EDB,Edinburgh,55.952387,-3.188229
      EDR,Edmonton Green,51.624929,-0.061087
      EFF,Effingham Junction,51.291492,-0.419942
      EGG,Eggesford,50.887727,-3.874767
      EGH,Egham,51.429645,-0.546493
      EGT,Egton,54.437678,-0.761937
      EPH,Elephant & Castle,51.494028,-0.0987
      ELG,Elgin,57.642893,-3.311242
      ELP,Ellesmere Port,53.282205,-2.896422
      ELE,Elmers End,51.398298,-0.049408
      ESD,Elmstead Woods,51.417116,0.0443
      ESW,Elmswell,52.238056,0.912622
      ELR,Elsecar,53.498676,-1.427425
      ESM,Elsenham,51.920552,0.228097
      ELS,Elstree & Borehamwood,51.652888,-0.279775
      ELW,Eltham,51.455642,0.052499
      ELO,Elton & Orston,52.951885,-0.855366
      ELY,Ely,52.391244,0.266851
      EMP,Emerson Park,51.568642,0.22014
      EMS,Emsworth,50.851381,-0.938774
      ENC,Enfield Chase,51.653255,-0.09067
      ENL,Enfield Lock,51.670923,-0.028506
      ENF,Enfield Town,51.652027,-0.079301
      ENT,Entwistle,53.655991,-2.414543
      EPS,Epsom,51.33439,-0.268753
      EPD,Epsom Downs,51.323685,-0.23893
      ERD,Erdington,52.528297,-1.839502
      ERI,Eridge,51.088961,0.201459
      ERH,Erith,51.481669,0.175081
      ESH,Esher,51.379888,-0.353315
      EXR,Essex Road,51.540706,-0.09625
      ETC,Etchingham,51.010541,0.442385
      EBA,Euxton Balshaw Lane,53.660494,-2.672021
      EVE,Evesham,52.098407,-1.947305
      EWE,Ewell East,51.345297,-0.241505
      EWW,Ewell West,51.350042,-0.256962
      EXC,Exeter Central,50.726472,-3.533291
      EXD,Exeter St Davids,50.729263,-3.543301
      EXT,Exeter St Thomas,50.717135,-3.538851
      EXG,Exhibition Centre (Glasgw),55.861544,-4.283574
      EXM,Exmouth,50.621621,-3.414985
      EXN,Exton,50.668291,-3.44411
      EYN,Eynsford,51.362717,0.20442
      FLS,Failsworth (closed),53.510403,-2.163309
      FRB,Fairbourne,52.696056,-4.049422
      FRF,Fairfield,53.471308,-2.145774
      FRL,Fairlie,55.751937,-4.853246
      FRW,Fairwater,51.493906,-3.233849
      FCN,Falconwood,51.459153,0.079331
      FKG,Falkirk Grahamston,56.002608,-3.785039
      FKK,Falkirk High,55.991809,-3.792236
      FOC,Falls of Cruachan,56.393869,-5.112456
      FMR,Falmer,50.862122,-0.087358
      FAL,Falmouth Docks,50.150693,-5.056074
      FMT,Falmouth Town,50.148364,-5.065264
      NFA,North Fambridge,51.648587,0.681687
      FRM,Fareham,50.853023,-1.192024
      FNB,Farnborough (Main),51.296603,-0.755708
      FNN,Farnborough North,51.302043,-0.743009
      FNC,Farncombe,51.197148,-0.604528
      FNH,Farnham,51.211901,-0.79241
      FNR,Farningham Road,51.401393,0.235539
      FNW,Farnworth,53.550018,-2.387848
      ZFD,Farringdon (London),51.520167,-0.105179
      FLD,Fauldhouse,55.822469,-3.71931
      FAV,Faversham,51.311715,0.891076
      FGT,Faygate,51.095884,-0.262991
      FAZ,Fazakerley,53.469099,-2.936722
      FRN,Fearn,57.778126,-3.993937
      FEA,Featherstone,53.679083,-1.358447
      FLX,Felixstowe,51.967085,1.350465
      FEL,Feltham,51.447897,-0.409817
      FNT,Feniton,50.786666,-3.285431
      FEN,Fenny Stratford,51.999897,-0.717656
      FER,Fernhill,51.686498,-3.395894
      FRY,Ferriby,53.717172,-0.507835
      FYS,Ferryside,51.768374,-4.369483
      FFA,Ffairfach,51.872481,-3.992879
      FIL,Filey,54.209876,-0.293865
      FIT,Filton Abbey Wood,51.504936,-2.562432
      FNY,Finchley Road & Frognal,51.550266,-0.183115
      FPK,Finsbury Park,51.564303,-0.106259
      FIN,Finstock,51.852788,-1.469327
      FSB,Fishbourne,50.83904,-0.815065
      FSG,Fishersgate,50.834226,-0.219395
      FGH,Fishguard Harbour,52.011557,-4.98567
      FSK,Fiskerton,53.060293,-0.912183
      FZW,Fitzwilliam,53.632516,-1.374275
      FWY,Five Ways,52.471108,-1.912949
      FLE,Fleet,51.290632,-0.830789
      FLM,Flimby,54.689689,-3.521051
      FLN,Flint,53.249539,-3.132993
      FLT,Flitwick,52.003651,-0.495233
      FLI,Flixton,53.443822,-2.384245
      FLF,Flowery Field,53.461869,-2.081053
      FKC,Folkestone Central,51.082889,1.169515
      FKW,Folkestone West,51.084588,1.153935
      FOD,Ford,50.829565,-0.578595
      FOG,Forest Gate,51.549432,0.02438
      FOH,Forest Hill,51.439278,-0.053131
      FBY,Formby,53.553492,-3.070905
      FOR,Forres,57.60978,-3.625948
      FRS,Forsinard,58.356883,-3.896887
      FTM,Fort Matilda,55.959023,-4.795247
      FTW,Fort William,56.820426,-5.106129
      FOK,Four Oaks,52.579794,-1.828025
      FOX,Foxfield,54.258765,-3.216065
      FXN,Foxton,52.11913,0.056551
      FRT,Frant,51.104025,0.294571
      FTN,Fratton,50.796326,-1.073969
      FRE,Freshfield,53.566068,-3.071827
      FFD,Freshford,51.342024,-2.301006
      FML,Frimley,51.31186,-0.746974
      FRI,Frinton-on-Sea,51.837693,1.243201
      FZH,Frizinghall,53.820383,-1.769005
      FRD,Frodsham,53.295876,-2.723117
      FRO,Frome,51.227263,-2.309993
      FLW,Fulwell,51.433933,-0.349446
      FNV,Furness Vale,53.348766,-1.988844
      FZP,Furze Platt,51.533021,-0.728454
      GNB,Gainsborough Central,53.399604,-0.769696
      GBL,Gainsborough Lea Road,53.386109,-0.768581
      GCH,Garelochhead,56.079855,-4.825698
      GRF,Garforth,53.796593,-1.382313
      GGV,Gargrave,53.978429,-2.105175
      GAR,Garrowhill,55.855233,-4.129448
      GRS,Garscadden,55.887688,-4.364989
      GSD,Garsdale,54.321351,-2.325896
      GSN,Garston (Herts),51.686726,-0.381641
      GSW,Garswood,53.488534,-2.672134
      GMG,Garth (Bridgend),51.596457,-3.641465
      GTH,Garth (Powys),52.133244,-3.529915
      GVE,Garve,57.613022,-4.688391
      GST,Gathurst,53.559417,-2.694393
      GTY,Gatley,53.392919,-2.231234
      GTW,Gatwick Airport,51.156485,-0.161014
      GGJ,Georgemas Junction,58.513608,-3.452128
      GER,Gerrards Cross,51.589024,-0.555255
      GDP,Gidea Park,51.581904,0.205991
      GFN,Giffnock,55.804018,-4.293561
      GIG,Giggleswick,54.061674,-2.303995
      GBD,Gilberdyke,53.747982,-0.732249
      GFF,Gilfach Fargoed,51.684251,-3.226577
      GIL,Gillingham (Dorset),51.034026,-2.272619
      GLM,Gillingham (Kent),51.38672,0.550534
      GSC,Gilshochill,55.89729,-4.281996
      GIP,Gipsy Hill,51.424451,-0.08381
      GIR,Girvan,55.246316,-4.848359
      GLS,Glaisdale,54.43944,-0.793956
      GCW,Glan Conwy,53.267436,-3.797732
      GLC,Glasgow Central,55.85975,-4.257629
      GCL,Glasgow Central Low Level,55.860524,-4.258041
      GQL,Glasgow Queen Street Low Level,55.86234,-4.250636
      GLQ,Glasgow Queen Street,55.862182,-4.251442
      GLZ,Glazebrook,53.428416,-2.460485
      GLE,Gleneagles,56.27484,-3.731162
      GLF,Glenfinnan,56.872382,-5.449605
      GLG,Glengarnock,55.738882,-4.674482
      GLT,Glenrothes with Thornton,56.162348,-3.143017
      GLO,Glossop,53.444484,-1.949071
      GCR,Gloucester,51.86542,-2.238643
      GLY,Glynde,50.859165,0.070105
      GOB,Gobowen,52.893538,-3.035982
      GOD,Godalming,51.186581,-0.618842
      GDL,Godley,53.451718,-2.054772
      GDN,Godstone,51.218153,-0.050058
      GOE,Goldthorpe,53.533402,-1.313501
      GOF,Golf Street,56.497782,-2.719549
      GOL,Golspie,57.971447,-3.987218
      GOM,Gomshall,51.219469,-0.442041
      GMY,Goodmayes,51.565578,0.110834
      GOO,Goole,53.704933,-0.874217
      GTR,Goostrey,53.222567,-2.326469
      GDH,Gordon Hill,51.663336,-0.094584
      GOR,Goring & Streatley,51.521493,-1.133029
      GBS,Goring-by-Sea,50.817711,-0.433058
      GTO,Gorton,53.469088,-2.166208
      GPO,Gospel Oak,51.555336,-0.150744
      GRK,Gourock,55.962311,-4.816637
      GWN,Gowerton,51.648729,-4.035954
      GOX,Goxhill,53.676722,-0.337126
      GPK,Grange Park,51.642608,-0.097332
      GOS,Grange-over-Sands,54.195281,-2.902737
      GTN,Grangetown (Cardiff),51.467032,-3.18907
      GRA,Grantham,52.906492,-0.642445
      GRT,Grateley,51.170052,-1.620762
      GVH,Gravelly Hill,52.515009,-1.852593
      GRV,Gravesend,51.441347,0.366673
      GRY,Grays,51.476246,0.32186
      GTA,Great Ayton,54.48932,-1.116368
      GRB,Great Bentley,51.85177,1.065185
      GRC,Great Chesterford,52.05982,0.193549
      GCT,Great Coates,53.575776,-0.130235
      GMV,Great Malvern,52.109207,-2.318266
      GMN,Great Missenden,51.703522,-0.709119
      GYM,Great Yarmouth,52.612184,1.72091
      GNL,Green Lane,53.38327,-3.016415
      GNR,Green Road,54.244532,-3.245572
      GBK,Greenbank,53.251574,-2.533071
      GRL,Greenfaulds,55.935226,-3.993091
      GNF,Greenfield,53.538874,-2.013841
      GFD,Greenford,51.542331,-0.345815
      GNH,Greenhithe for Bluewater,51.450757,0.278869
      GKC,Greenock Central,55.945332,-4.752614
      GKW,Greenock West,55.947328,-4.767813
      GNW,Greenwich,51.478134,-0.013314
      GEA,Gretna Green,55.00191,-3.064598
      GMD,Grimsby Docks,53.574344,-0.075622
      GMB,Grimsby Town,53.564125,-0.086958
      GRN,Grindleford,53.305577,-1.626295
      GMT,Grosmont,54.436126,-0.724981
      GRP,Grove Park,51.430861,0.021752
      GUI,Guide Bridge,53.474642,-2.11371
      GLD,Guildford,51.236964,-0.580404
      GSY,Guiseley,53.875947,-1.715083
      GUN,Gunnersbury,51.491677,-0.275264
      GSL,Gunnislake,50.516518,-4.219457
      GNT,Gunton,52.866373,1.349137
      GWE,Gwersyllt,53.072589,-3.017889
      GYP,Gypsy Lane,54.532902,-1.179405
      HAB,Habrough,53.605536,-0.267977
      HCB,Hackbridge,51.377869,-0.153882
      HKC,Hackney Central,51.547104,-0.056031
      HAC,Hackney Downs,51.548757,-0.060792
      HKW,Hackney Wick,51.54341,-0.024892
      HDM,Haddenham & Thame Parkway,51.770859,-0.942115
      HAD,Haddiscoe,52.528811,1.623031
      HDF,Hadfield,53.46076,-1.965318
      HDW,Hadley Wood,51.668498,-0.176147
      HGF,Hag Fold,53.533867,-2.494821
      HAG,Hagley,52.422412,-2.147
      HMY,Hairmyres,55.761959,-4.219997
      HAL,Hale,53.378732,-2.347356
      HAS,Halesworth,52.346837,1.505698
      HED,Halewood,53.364494,-2.830134
      HFX,Halifax,53.720974,-1.853577
      HLG,Hall Green,52.436922,-1.845645
      HID,Hall i' th' Wood,53.597437,-2.413108
      HLR,Hall Road,53.497501,-3.049625
      HAI,Halling,51.352476,0.444961
      HWH,Haltwhistle,54.967854,-2.463572
      HMT,Ham Street,51.068376,0.85454
      HME,Hamble,50.871363,-1.329152
      HNC,Hamilton Central,55.773189,-4.038874
      BKQ,Birkenhead Hamilton Square,53.394709,-3.013679
      HNW,Hamilton West,55.778955,-4.054164
      HMM,Hammerton,53.996114,-1.283038
      HMD,Hampden Park (Sussex),50.796399,0.279384
      HDH,Hampstead Heath,51.555211,-0.16568
      HMP,Hampton (London),51.415933,-0.372097
      HMC,Hampton Court,51.402553,-0.342726
      HMW,Hampton Wick,51.414523,-0.312468
      HIA,Hampton-in-Arden,52.429046,-1.699923
      HSD,Hamstead (Birmingham),52.531082,-1.928973
      HAM,Hamworthy,50.72518,-2.019351
      HND,Hanborough,51.825163,-1.373508
      HTH,Handforth,53.346419,-2.213256
      HAN,Hanwell,51.511834,-0.338561
      HPN,Hapton,53.781762,-2.316685
      HRL,Harlech,52.861343,-4.109197
      HDN,Harlesden,51.536289,-0.257644
      HRD,Harling Road,52.453708,0.909167
      HLN,Harlington (Beds),51.96207,-0.495665
      HWM,Harlow Mill,51.79037,0.132334
      HWN,Harlow Town,51.781074,0.095159
      HRO,Harold Wood,51.592766,0.233154
      HPD,Harpenden,51.814882,-0.351955
      HRM,Harrietsham,51.244831,0.67243
      HGY,Harringay,51.577359,-0.10511
      HRY,Harringay Green Lanes,51.577183,-0.098118
      HRR,Harrington,54.613353,-3.565742
      HGT,Harrogate,53.99319,-1.537613
      HRW,Harrow & Wealdstone,51.592169,-0.334549
      HRW,Harrow & Wealdstone,51.592178,-0.334548
      HOH,Harrow-on-the-Hill,51.579254,-0.33697
      HTF,Hartford,53.241772,-2.553628
      HBY,Hartlebury,52.334463,-2.220674
      HPL,Hartlepool,54.686764,-1.207331
      HTW,Hartwood,55.811476,-3.839312
      HPQ,Harwich International,51.947301,1.255155
      HWC,Harwich Town,51.944157,1.286712
      HSL,Haslemere,51.088842,-0.719351
      HSK,Hassocks,50.924609,-0.145926
      HGS,Hastings,50.857591,0.576484
      HTE,Hatch End,51.609418,-0.368579
      HFS,Hatfield & Stainforth,53.588919,-1.024057
      HAT,Hatfield (Herts),51.763884,-0.215565
      HAP,Hatfield Peverel,51.77987,0.59215
      HSG,Hathersage,53.325787,-1.651192
      HTY,Hattersley,53.445297,-2.04031
      HTN,Hatton (Warks),52.295291,-1.672964
      HAV,Havant,50.854416,-0.981596
      HVN,Havenhouse,53.114494,0.27317
      HVF,Haverfordwest,51.802643,-4.960236
      HWD,Hawarden,53.185373,-3.032081
      HWB,Hawarden Bridge,53.218088,-3.032717
      HKH,Hawkhead,55.842184,-4.398836
      HDB,Haydon Bridge,54.974865,-2.247906
      HYR,Haydons Road,51.425446,-0.18879
      HAY,Hayes & Harlington,51.503095,-0.420663
      HYS,Hayes (Kent),51.376332,0.010584
      HYL,Hayle,50.186237,-5.419516
      HYM,Haymarket,55.945802,-3.21845
      HHE,Haywards Heath,51.005257,-0.105281
      HAZ,Hazel Grove,53.377558,-2.122018
      HCN,Headcorn,51.165711,0.627512
      HDY,Headingley,53.817988,-1.594191
      HDL,Headstone Lane,51.60265,-0.357197
      HDG,Heald Green,53.369431,-2.236666
      HLI,Healing,53.581821,-0.160634
      HHL,Heath High Level,51.516563,-3.181712
      HLL,Heath Low Level,51.515661,-3.181977
      HAF,Heathrow Airport Terminal 4,51.458266,-0.445443
      LHR,Heathrow Airport Terminals 1-3,51.471405,-0.454313
      HTC,Heaton Chapel,53.425575,-2.17904
      HBD,Hebden Bridge,53.737601,-2.00906
      HEC,Heckington,52.977339,-0.293937
      HDE,Hedge End,50.932309,-1.294492
      HNF,Hednesford,52.709731,-2.002322
      HEI,Heighington,54.59697,-1.582084
      HLC,Helensburgh Central,56.0042,-4.732738
      HLU,Helensburgh Upper,56.012355,-4.729785
      HLD,Hellifield,54.010874,-2.227848
      HMS,Helmsdale,58.117423,-3.658693
      HSB,Helsby,53.275173,-2.770755
      HML,Hemel Hempstead,51.742338,-0.490752
      HEN,Hendon,51.580069,-0.238648
      HNG,Hengoed,51.64741,-3.224137
      HNL,Henley-in-Arden,52.291052,-1.784424
      HOT,Henley-on-Thames,51.534181,-0.900193
      HEL,Hensall,53.698563,-1.114522
      HFD,Hereford,52.061169,-2.708212
      HNB,Herne Bay,51.364596,1.117756
      HNH,Herne Hill,51.453304,-0.102263
      HER,Hersham,51.376978,-0.389788
      HFE,Hertford East,51.799039,-0.072913
      HFN,Hertford North,51.798861,-0.09176
      HES,Hessle,53.717594,-0.442201
      HSW,Heswall,53.329731,-3.073702
      HEV,Hever,51.181407,0.095096
      HEW,Heworth,54.951574,-1.555779
      HEX,Hexham,54.974183,-2.095274
      HYD,Heyford,51.919197,-1.299252
      HHB,Heysham Port,54.033154,-2.913111
      HIB,High Brooms,51.149401,0.277359
      HST,High Street (Glasgow),55.859558,-4.240104
      HWY,High Wycombe,51.629588,-0.74539
      HGM,Higham,51.426557,0.466307
      HIP,Highams Park,51.60835,-0.000196
      HIG,Highbridge & Burnham-on-Sea,51.21815,-2.972163
      HII,Highbury & Islington,51.546088,-0.103741
      HHY,Highbury & Islington,51.546178,-0.103737
      HTO,Hightown,53.525121,-3.057065
      HLB,Hildenborough,51.214482,0.227617
      HLF,Hillfoot,55.920085,-4.320259
      HLE,Hillington East,55.854721,-4.354709
      HLW,Hillington West,55.856015,-4.371565
      HIL,Hillside,53.62212,-3.024714
      HLS,Hilsea,50.828264,-1.058783
      HYW,Hinchley Wood,51.374995,-0.340501
      HNK,Hinckley,52.535014,-1.371913
      HIN,Hindley,53.542251,-2.575501
      HNA,Hinton Admiral,50.752628,-1.71412
      HIT,Hitchin,51.953288,-0.263456
      HGR,Hither Green,51.452024,-0.000918
      HOC,Hockley,51.60356,0.659029
      HBN,Hollingbourne,51.265177,0.627879
      HOD,Hollinwood (closed),53.520141,-2.14668
      HCH,Holmes Chapel,53.198946,-2.351138
      HLM,Holmwood,51.180997,-0.321077
      HOL,Holton Heath,50.711396,-2.077839
      HHD,Holyhead,53.3077,-4.631008
      HLY,Holytown,55.812893,-3.973918
      HMN,Homerton,51.547012,-0.042332
      HYB,Honeybourne,52.101433,-1.834974
      HON,Honiton,50.79657,-3.186728
      HOY,Honley,53.608242,-1.780966
      HPA,Honor Oak Park,51.449987,-0.04548
      HOK,Hook,51.279996,-0.961619
      HOO,Hooton,53.297213,-2.977009
      HPE,Hope (Flintshire),53.117372,-3.036876
      HOP,Hope (Derbyshire),53.345942,-1.728535
      HPT,Hopton Heath,52.391384,-2.91191
      HOR,Horley,51.16877,-0.161026
      HBP,Hornbeam Park,53.979883,-1.526828
      HRN,Hornsey,51.586462,-0.111949
      HRS,Horsforth,53.84772,-1.630233
      HRH,Horsham,51.066059,-0.319243
      HSY,Horsley,51.279343,-0.435386
      HIR,Horton-in-Ribblesdale,54.149396,-2.302036
      HSC,Hoscar,53.597382,-2.803808
      HGN,Hough Green,53.372406,-2.775066
      HOU,Hounslow,51.461944,-0.362256
      HOV,Hove,50.835209,-0.17066
      HXM,Hoveton & Wroxham,52.715596,1.408019
      HWW,How Wood (Herts),51.717745,-0.344647
      HOW,Howden,53.764552,-0.8607
      HYK,Hoylake,53.390226,-3.178829
      HBB,Hubberts Bridge,52.975637,-0.110064
      HKN,Hucknall,53.038301,-1.195808
      HUD,Huddersfield,53.648516,-1.784692
      HUL,Hull,53.74417,-0.345686
      HUP,Humphrey Park,53.452243,-2.327537
      HCT,Huncoat,53.772154,-2.345895
      HGD,Hungerford,51.414907,-1.512272
      HUB,Hunmanby,54.174306,-0.314787
      HUN,Huntingdon,52.328662,-0.192047
      HNT,Huntly,57.444472,-2.775741
      HNX,Hunts Cross,53.360725,-2.855861
      HUR,Hurst Green,51.244427,0.003966
      HUT,Hutton Cranswick,53.955687,-0.433345
      HUY,Huyton,53.409698,-2.842988
      HYC,Hyde Central,53.451898,-2.085249
      HYT,Hyde North,53.464814,-2.085457
      HKM,Hykeham,53.195361,-0.598163
      HYN,Hyndland,55.879747,-4.314653
      HYH,Hythe (Essex),51.885649,0.927557
      IBM,IBM (Greenock),55.92944,-4.82722
      IFI,Ifield,51.115617,-0.214744
      IFD,Ilford,51.559117,0.069706
      ILK,Ilkley,53.924777,-1.822031
      INC,Ince (Manchester),53.538926,-2.611519
      INE,Ince & Elton,53.276758,-2.816225
      INT,Ingatestone,51.667045,0.384273
      INS,Insch,57.337483,-2.617115
      IGD,Invergordon,57.689001,-4.17484
      ING,Invergowrie,56.456463,-3.0574
      INK,Inverkeithing,56.034671,-3.396185
      INP,Inverkip,55.906098,-4.872566
      INV,Inverness,57.479852,-4.223359
      INH,Invershin,57.924851,-4.399479
      INR,Inverurie,57.286251,-2.373564
      IPS,Ipswich,52.050605,1.144456
      IRL,Irlam,53.434324,-2.433229
      IRV,Irvine,55.610871,-4.675125
      ISL,Isleworth,51.474761,-0.336885
      ISP,Islip,51.825758,-1.238163
      IVR,Iver,51.508503,-0.506706
      IVY,Ivybridge,50.393395,-3.904228
      LVJ,Liverpool James Street,53.404779,-2.991957
      JEQ,Jewellery Quarter,52.489448,-1.913207
      JOH,Johnston (Pembrokeshire),51.756758,-4.996363
      JHN,Johnstone,55.834703,-4.503621
      JOR,Jordanhill,55.88223,-4.325994
      KSL,Kearsley,53.544154,-2.375118
      KSN,Kearsney,51.14938,1.272093
      KEI,Keighley,53.867976,-1.901652
      KEH,Keith,57.550882,-2.954069
      KEL,Kelvedon,51.84071,0.702413
      KEM,Kemble,51.676269,-2.023084
      KMH,Kempston Hardwick,52.092228,-0.503892
      KMP,Kempton Park,51.420982,-0.40973
      KMS,Kemsing,51.297184,0.247456
      KML,Kemsley,51.36244,0.735388
      KEN,Kendal,54.332104,-2.739649
      KLY,Kenley,51.324774,-0.100899
      KNE,Kennett,52.277279,0.490492
      KNS,Kennishead,55.813043,-4.325057
      KNL,Kensal Green,51.53054,-0.225063
      KNR,Kensal Rise,51.534554,-0.219933
      KPA,Kensington Olympia,51.497898,-0.21034
      KTH,Kent House,51.412213,-0.045221
      KTN,Kentish Town,51.550496,-0.140339
      KTW,Kentish Town West,51.546548,-0.14663
      KNT,Kenton,51.581802,-0.316958
      KBK,Kents Bank,54.172911,-2.925229
      KET,Kettering,52.393568,-0.731547
      KWB,Kew Bridge,51.489512,-0.287085
      KWG,Kew Gardens,51.477072,-0.285031
      KEY,Keyham,50.389864,-4.179628
      KYN,Keynsham,51.417973,-2.495629
      KDB,Kidbrooke,51.46212,0.027523
      KID,Kidderminster,52.384495,-2.238466
      KDG,Kidsgrove,53.08658,-2.244816
      KWL,Kidwelly,51.734348,-4.31701
      KBN,Kilburn High Road,51.537278,-0.192213
      KLD,Kildale,54.477272,-1.06786
      KIL,Kildonan,58.170794,-3.869111
      KGT,Kilgetty,51.732115,-4.715186
      KMK,Kilmarnock,55.612115,-4.498664
      KLM,Kilmaurs,55.637205,-4.53047
      KPT,Kilpatrick,55.924694,-4.453397
      KWN,Kilwinning,55.655947,-4.709998
      KBC,Kinbrace,58.258297,-3.941213
      KGM,Kingham,51.902256,-1.628773
      KGH,Kinghorn,56.069331,-3.174155
      KGL,Kings Langley,51.70636,-0.4384
      KLN,Kings Lynn,52.753844,0.403116
      KNN,Kings Norton,52.414304,-1.932319
      KGN,Kings Nympton,50.936065,-3.905431
      KGP,Kings Park,55.819883,-4.247241
      KGS,Kings Sutton,52.02136,-1.280914
      KGE,Kingsknowe,55.918807,-3.264965
      KNG,Kingston,51.412749,-0.301144
      KND,Kingswood,51.29486,-0.211432
      KIN,Kingussie,57.077766,-4.052189
      KIT,Kintbury,51.402519,-1.445973
      KBX,Kirby Cross,51.841408,1.215024
      KKS,Kirk Sandall,53.563436,-1.074921
      KIR,Kirkby,53.486205,-2.902828
      KKB,Kirkby in Ashfield,53.100116,-1.253054
      KSW,Kirkby Stephen,54.455134,-2.368604
      KBF,Kirkby-in-Furness,54.232342,-3.188899
      KDY,Kirkcaldy,56.112051,-3.16703
      KRK,Kirkconnel,55.388305,-3.998491
      KKD,Kirkdale,53.440914,-2.981116
      KKM,Kirkham & Wesham,53.786929,-2.882937
      KKH,Kirkhill,55.814104,-4.168698
      KKN,Kirknewton,55.888685,-3.432508
      KWD,Kirkwood,55.854183,-4.048387
      KTL,Kirton Lindsey,53.48486,-0.593916
      KIV,Kiveton Bridge,53.340976,-1.26718
      KVP,Kiveton Park,53.336777,-1.239498
      KNA,Knaresborough,54.008768,-1.470502
      KBW,Knebworth,51.86686,-0.187265
      KNI,Knighton,52.345084,-3.042195
      KCK,Knockholt,51.345788,0.130874
      KNO,Knottingley,53.706554,-1.259181
      KNU,Knucklas,52.359873,-3.096878
      KNF,Knutsford,53.301984,-2.372091
      KYL,Kyle of Lochalsh,57.279747,-5.7138
      LDY,Ladybank,56.273772,-3.122276
      LAD,Ladywell,51.456243,-0.019015
      LAI,Laindon,51.567525,0.42432
      LRG,Lairg,58.001811,-4.399891
      LKE,Lake (Isle of Wight),50.646463,-1.166338
      LAK,Lakenheath,52.447417,0.535222
      LAM,Lamphey,51.667195,-4.873291
      LNK,Lanark,55.673072,-3.772858
      LAN,Lancaster,54.048556,-2.807908
      LAC,Lancing,50.827074,-0.323083
      LAW,Landywood,52.657139,-2.020648
      LGB,Langbank,55.924512,-4.585257
      LHO,Langho,53.804982,-2.4479
      LNY,Langley (Berks),51.508062,-0.541737
      LGG,Langley Green,52.493885,-2.004958
      LGM,Langley Mill,53.018078,-1.331242
      LGS,Langside,55.821127,-4.277326
      LGW,Langwathby,54.694363,-2.663689
      LAG,Langwith - Whaley Thorns,53.232535,-1.209704
      LAP,Lapford,50.856993,-3.81066
      LPW,Lapworth,52.341275,-1.725468
      LBT,Larbert,56.022698,-3.830573
      LAR,Largs,55.792737,-4.867177
      LWH,Lawrence Hill,51.458008,-2.564431
      LAY,Layton (Lancs),53.835638,-3.030222
      LZB,Lazonby & Kirkoswald,54.750224,-2.7022
      LEH,Lea Hall,52.480656,-1.786005
      LEA,Leagrave,51.905166,-0.458477
      LHM,Lealholm,54.460604,-0.825731
      LMS,Leamington Spa,52.284504,-1.536199
      LSW,Leasowe,53.408062,-3.099592
      LHD,Leatherhead,51.298749,-0.333053
      LED,Ledbury,52.044947,-2.42498
      LEE,Lee,51.449753,0.013519
      LDS,Leeds,53.795641,-1.54803
      LEI,Leicester,52.631442,-1.125267
      LIH,Leigh (Kent),51.193897,0.210522
      LES,Leigh-on-Sea,51.541275,0.64044
      LBZ,Leighton Buzzard,51.916314,-0.676982
      LEL,Lelant,50.184113,-5.436598
      LTS,Lelant Saltings,50.179292,-5.441436
      LEN,Lenham,51.234484,0.70779
      LNZ,Lenzie,55.921312,-4.153878
      LEO,Leominster,52.225151,-2.730478
      LET,Letchworth,51.979971,-0.229237
      LEU,Leuchars,56.375093,-2.893716
      LVM,Levenshulme,53.444178,-2.192668
      LWS,Lewes,50.870625,0.011359
      LEW,Lewisham,51.46569,-0.013999
      LEY,Leyland,53.698869,-2.687141
      LEM,Leyton Midland Road,51.569726,-0.008023
      LER,Leytonstone High Road,51.563555,0.008444
      LIC,Lichfield City,52.680386,-1.825412
      LTV,Lichfield Trent Valley,52.686909,-1.800222
      LIF,Lichfield Trent Valley High Level,52.686909,-1.800237
      LID,Lidlington,52.041545,-0.558906
      LHS,Limehouse,51.512536,-0.039776
      LCN,Lincoln Central,53.226107,-0.539922
      LFD,Lingfield,51.176448,-0.007138
      LGD,Lingwood,52.622126,1.489968
      LIN,Linlithgow,55.976446,-3.595847
      LIP,Liphook,51.071309,-0.80021
      LSK,Liskeard,50.446842,-4.467497
      LIS,Liss,51.043564,-0.89285
      LVT,Lisvane & Thornhill,51.544579,-3.185612
      LTK,Little Kimble,51.752236,-0.808429
      LTT,Little Sutton,53.285529,-2.943292
      LTL,Littleborough,53.64301,-2.09465
      LIT,Littlehampton,50.810098,-0.545972
      LVN,Littlehaven,51.079746,-0.307954
      LTP,Littleport,52.462396,0.316582
      LVC,Liverpool Central Loop Line,53.404615,-2.979153
      LVC,Liverpool Central,53.404615,-2.979168
      LVL,Liverpool Lime Street Low Level,53.408222,-2.977747
      LIV,Liverpool Lime Street,53.407324,-2.977726
      LSN,Livingston North,55.901378,-3.544346
      LVG,Livingston South,55.871687,-3.501565
      LLA,Llanaber,52.741517,-4.077183
      LBR,Llanbedr,52.820865,-4.110204
      LLT,Llanbister Road,52.336436,-3.213422
      LNB,Llanbradach,51.603256,-3.233058
      LLN,Llandaf,51.508525,-3.228912
      LDN,Llandanwg,52.836176,-4.123863
      LLC,Llandecwyn,52.920699,-4.057042
      LLL,Llandeilo,51.885351,-3.986909
      LLV,Llandovery,51.995319,-3.802843
      LLO,Llandrindod,52.242368,-3.379145
      LLD,Llandudno,53.320931,-3.827004
      LLJ,Llandudno Junction,53.283958,-3.809106
      LLI,Llandybie,51.821041,-4.003667
      LLE,Llanelli,51.673871,-4.161326
      LLF,Llanfairfechan,53.257303,-3.983207
      LPG,Llanfairpwll,53.220961,-4.209221
      LLG,Llangadog,51.94022,-3.893163
      LLM,Llangammarch,52.114306,-3.554826
      LLH,Llangennech,51.69114,-4.07895
      LGO,Llangynllo,52.349636,-3.16137
      LLS,Llanishen,51.532746,-3.181988
      LWR,Llanrwst,53.144191,-3.803046
      LAS,Llansamlet,51.661506,-3.884702
      LNR,Llanwrda,51.962594,-3.871689
      LNW,Llanwrtyd,52.104719,-3.632174
      LLW,Llwyngwril,52.666796,-4.087687
      LLY,Llwynypia,51.634004,-3.453524
      LHA,Loch Awe,56.402002,-5.041954
      LHE,Loch Eil Outward Bound,56.855249,-5.191563
      LCL,Lochailort,56.880942,-5.663377
      LCS,Locheilside,56.855388,-5.290022
      LCG,Lochgelly,56.135322,-3.312939
      LCC,Lochluichart,57.621738,-4.809044
      LHW,Lochwinnoch,55.78715,-4.616057
      LOC,Lockerbie,55.123056,-3.353531
      LCK,Lockwood,53.634747,-1.800792
      BFR,London Blackfriars,51.51181,-0.103306
      LBG,London Bridge,51.505019,-0.086066
      LBG,London Bridge,51.505109,-0.086062
      CST,London Cannon Street,51.511382,-0.090267
      CHX,London Charing Cross,51.508027,-0.124777
      EUS,London Euston,51.528136,-0.133898
      FST,London Fenchurch Street,51.511646,-0.078871
      LOF,London Fields,51.541152,-0.057726
      KGX,London Kings Cross,51.530884,-0.1229
      LST,London Liverpool Street,51.517991,-0.0814
      MYB,London Marylebone,51.522524,-0.162886
      PAD,London Paddington,51.516446,-0.176823
      LRB,London Road (Brighton),50.836655,-0.136474
      LRD,London Road (Guildford),51.240644,-0.565048
      STP,London St Pancras International,51.532391,-0.127164
      VIC,London Victoria,51.495257,-0.144534
      VIC,London Victoria,51.495257,-0.14452
      WAT,London Waterloo,51.503298,-0.113083
      WAE,London Waterloo East,51.504076,-0.108873
      LBK,Long Buckby,52.294731,-1.086452
      LGE,Long Eaton,52.885005,-1.287515
      LPR,Long Preston,54.016849,-2.255595
      LGK,Longbeck,54.58923,-1.030488
      LOB,Longbridge,52.396431,-1.981283
      LNG,Longcross,51.385171,-0.594551
      LGF,Longfield,51.396153,0.300393
      LND,Longniddry,55.976478,-2.888347
      LPT,Longport,53.041897,-2.216448
      LGN,Longton,52.989672,-2.137009
      LOO,Looe,50.35921,-4.456199
      LOT,Lostock,53.572942,-2.494265
      LTG,Lostock Gralam,53.267679,-2.465201
      LOH,Lostock Hall,53.723857,-2.687094
      LOS,Lostwithiel,50.407491,-4.665461
      LBO,Loughborough (Leics),52.778973,-1.195922
      LGJ,Loughborough Junction,51.466297,-0.102156
      LOW,Lowdham,53.006925,-0.997581
      LSY,Lower Sydenham,51.424828,-0.033319
      LWT,Lowestoft,52.474462,1.749733
      LUD,Ludlow,52.370891,-2.715254
      LUT,Luton,51.882311,-0.414015
      LTN,Luton Airport Parkway,51.872444,-0.395856
      LUX,Luxulyan,50.390289,-4.74751
      LYD,Lydney,51.714631,-2.53116
      LYE,Lye (West Midlands),52.459935,-2.115923
      LYP,Lymington Pier,50.758289,-1.529438
      LYT,Lymington Town,50.760901,-1.537153
      LYC,Lympstone Commando,50.662224,-3.440853
      LYM,Lympstone Village,50.64828,-3.43102
      LTM,Lytham,53.739294,-2.964037
      MAC,Macclesfield,53.259358,-2.121379
      MCN,Machynlleth,52.59515,-3.854536
      MST,Maesteg,51.609939,-3.654661
      MEW,Maesteg (Ewenny Road),51.605343,-3.649006
      MAG,Maghull,53.506484,-2.930852
      MDN,Maiden Newton,50.779995,-2.569429
      MAI,Maidenhead,51.51867,-0.722642
      MDB,Maidstone Barracks,51.277167,0.51399
      MDE,Maidstone East,51.277828,0.521325
      MDW,Maidstone West,51.270464,0.515804
      MAL,Malden Manor,51.384727,-0.26125
      MLG,Mallaig,57.005966,-5.829579
      MLT,Malton,54.132092,-0.797233
      MVL,Malvern Link,52.125387,-2.319843
      MIA,Manchester Airport,53.365056,-2.272978
      MCO,Manchester Oxford Road,53.474046,-2.241993
      MAN,Manchester Piccadilly,53.477376,-2.230908
      MCV,Manchester Victoria,53.487482,-2.242597
      MNE,Manea,52.497855,0.177714
      MNG,Manningtree,51.949062,1.04527
      MNP,Manor Park,51.552476,0.046368
      MNR,Manor Road,53.394794,-3.171436
      MRB,Manorbier,51.660166,-4.791863
      MAS,Manors,54.97277,-1.604754
      MFT,Mansfield,53.142559,-1.197153
      MSW,Mansfield Woodhouse,53.163624,-1.201666
      MCH,March,52.55991,0.091216
      MRN,Marden,51.175173,0.493199
      MAR,Margate,51.385433,1.37203
      MHR,Market Harborough,52.480407,-0.908861
      MKR,Market Rasen,53.384477,-0.337104
      MNC,Markinch,56.201006,-3.130789
      MKT,Marks Tey,51.880949,0.783355
      MLW,Marlow,51.570995,-0.766412
      MPL,Marple,53.400707,-2.057262
      MSN,Marsden,53.603199,-1.930749
      MSK,Marske,54.587429,-1.018925
      MGN,Marston Green,52.467202,-1.7556
      MTM,Martin Mill,51.170684,1.348248
      MAO,Martins Heron,51.407594,-0.724662
      MTO,Marton,54.544354,-1.198499
      MYH,Maryhill,55.897152,-4.301934
      MYL,Maryland,51.546081,0.005843
      MRY,Maryport,54.711587,-3.494705
      MAT,Matlock,53.138155,-1.558986
      MTB,Matlock Bath,53.12197,-1.557657
      MAU,Mauldeth Road,53.433076,-2.20925
      MAX,Maxwell Park,55.837723,-4.288677
      MAY,Maybole,55.354739,-4.685266
      MZH,Maze Hill,51.482623,0.00294
      MHS,Meadowhall,53.417483,-1.412852
      MEL,Meldreth,52.090726,0.00897
      MKM,Melksham,51.379819,-2.144492
      MES,Melton (Suffolk),52.104453,1.338267
      MMO,Melton Mowbray,52.760687,-0.885575
      MEN,Menheniot,50.426214,-4.409257
      MNN,Menston,53.892352,-1.735513
      MEO,Meols,53.399455,-3.154267
      MEC,Meols Cop,53.646286,-2.975802
      MEP,Meopham,51.386421,0.356981
      MHM,Merstham,51.264151,-0.1502
      MER,Merthyr Tydfil,51.744588,-3.377289
      MEV,Merthyr Vale,51.686649,-3.336588
      MGM,Metheringham,53.138901,-0.391449
      MCE,Metrocentre,54.958754,-1.665638
      MEX,Mexborough,53.49101,-1.288562
      MIC,Micheldever,51.182388,-1.260662
      MIK,Micklefield,53.788852,-1.326797
      MBR,Middlesbrough,54.579117,-1.234732
      MDL,Middlewood,53.359974,-2.083353
      MDG,Midgham,51.395973,-1.177692
      MLF,Milford (Surrey),51.163313,-0.636928
      MFH,Milford Haven,51.714985,-5.041005
      MLH,Mill Hill (Lancs),53.735472,-2.501733
      MIL,Mill Hill Broadway,51.613094,-0.249216
      MLB,Millbrook (Beds),52.053846,-0.532681
      MBK,Millbrook (Hants),50.911486,-1.433834
      MIN,Milliken Park,55.825106,-4.533341
      MLM,Millom,54.21083,-3.271084
      MIH,Mills Hill (Manchester),53.551325,-2.171511
      MLN,Milngavie,55.940853,-4.315095
      MLR,Milnrow (closed),53.608121,-2.111499
      MKC,Milton Keynes Central,52.034297,-0.774125
      MFF,Minffordd,52.926145,-4.084972
      MFD,Minffordd Ffestiniog Railway Station,52.925889,-4.084216
      MSR,Minster,51.329179,1.317244
      MIR,Mirfield,53.671414,-1.692548
      MIS,Mistley,51.943642,1.08143
      MIJ,Mitcham Junction,51.392947,-0.157731
      MOB,Mobberley,53.329964,-2.333295
      MON,Monifieth,56.480101,-2.818251
      MRS,Monks Risborough,51.735766,-0.829311
      MTP,Montpelier,51.468346,-2.588687
      MTS,Montrose,56.712786,-2.472081
      MRF,Moorfields,53.408578,-2.989173
      MRF,Moorfields,53.408578,-2.989188
      MOG,Moorgate,51.518491,-0.088917
      MOG,Moorgate,51.518491,-0.088903
      MSD,Moorside,53.516289,-2.351798
      MRP,Moorthorpe,53.595012,-1.304949
      MRR,Morar,56.969696,-5.821899
      MRD,Morchard Road,50.831888,-3.776385
      MDS,Morden South,51.396114,-0.199436
      MCM,Morecambe,54.070329,-2.869306
      MTN,Moreton (Dorset),50.701111,-2.31288
      MRT,Moreton (Merseyside),53.407223,-3.1135
      MIM,Moreton-in-Marsh,51.99229,-1.700369
      MFA,Morfa Mawddach,52.707142,-4.032178
      MLY,Morley,53.749938,-1.59098
      MPT,Morpeth,55.162514,-1.682929
      MOR,Mortimer,51.372078,-1.03549
      MTL,Mortlake,51.468085,-0.267083
      MSS,Moses Gate,53.555996,-2.401186
      MOS,Moss Side,53.764445,-2.943526
      MSL,Mossley (Manchester),53.514994,-2.04128
      MSH,Mossley Hill,53.379053,-2.915443
      MPK,Mosspark,55.840832,-4.347799
      MSO,Moston,53.523434,-2.171021
      MTH,Motherwell,55.791669,-3.994317
      MOT,Motspur Park,51.395194,-0.239507
      MTG,Mottingham,51.440217,0.05008
      MLD,Mouldsworth,53.231819,-2.732223
      MCB,Moulsecoomb,50.846714,-0.118814
      MFL,Mount Florida,55.826802,-4.26201
      MTV,Mount Vernon,55.839831,-4.136591
      MTA,Mountain Ash,51.681334,-3.376353
      MOO,Muir of Ord,57.517829,-4.460231
      MUI,Muirend,55.810407,-4.273827
      MUB,Musselburgh,55.933585,-3.073205
      MYT,Mytholmroyd,53.729016,-1.981427
      NFN,Nafferton,54.011702,-0.386985
      NLS,Nailsea & Backwell,51.419404,-2.750638
      NRN,Nairn,57.580229,-3.872
      NAN,Nantwich,53.063226,-2.519253
      NAR,Narberth,51.799378,-4.727204
      NBR,Narborough,52.57131,-1.203337
      NVR,Navigation Road,53.395391,-2.343417
      NTH,Neath,51.662364,-3.807234
      NMT,Needham Market,52.152604,1.055291
      NEI,Neilston,55.783032,-4.426937
      NEL,Nelson,53.835019,-2.213761
      NES,Neston,53.292425,-3.063764
      NET,Netherfield,52.961429,-1.079846
      NRT,Nethertown,54.456956,-3.566397
      NTL,Netley,50.874852,-1.341752
      NBA,New Barnet,51.648576,-0.172971
      NBC,New Beckenham,51.416767,-0.035247
      NBN,New Brighton,53.437416,-3.047963
      NCE,New Clee,53.574465,-0.059154
      NWX,New Cross,51.476342,-0.032401
      NXG,New Cross Gate,51.475127,-0.040373
      NCK,New Cumnock,55.402741,-4.184329
      NEH,New Eltham,51.438058,0.07056
      NHY,New Hey (closed),53.601097,-2.095387
      NHL,New Holland,53.701941,-0.360219
      NHE,New Hythe,51.313001,0.454959
      NLN,New Lane,53.611318,-2.867556
      NEM,New Malden,51.404072,-0.255916
      NMC,New Mills Central,53.364856,-2.00567
      NMN,New Mills Newtown,53.359643,-2.008524
      NWM,New Milton,50.755742,-1.657806
      NPD,New Pudsey,53.804498,-1.680797
      NSG,New Southgate,51.614115,-0.143012
      NCT,Newark Castle,53.080022,-0.813157
      NNG,Newark North Gate,53.081905,-0.800116
      NBY,Newbury,51.397647,-1.322842
      NRC,Newbury Racecourse,51.398458,-1.30778
      NCL,Newcastle,54.968407,-1.617292
      NVH,Newhaven Harbour,50.789784,0.055021
      NVN,Newhaven Town,50.794849,0.054973
      NGT,Newington,51.35334,0.6686
      NMK,Newmarket,52.237958,0.406236
      NWE,Newport (Essex),51.979877,0.215167
      NWP,Newport (S Wales),51.58975,-2.998636
      NQY,Newquay,50.415084,-5.075699
      NSD,Newstead,53.071711,-1.222351
      NTN,Newton (S Lanarks),55.818772,-4.133041
      NTA,Newton Abbot,50.529571,-3.599182
      NAY,Newton Aycliffe,54.613711,-1.589655
      NWN,Newton for Hyde,53.456395,-2.067142
      NTC,Newton St Cyres,50.778917,-3.589404
      NLW,Newton-le-Willows,53.453075,-2.613597
      NOA,Newton-on-Ayr,55.474053,-4.625805
      NWR,Newtonmore,57.05913,-4.119104
      NWT,Newtown (Powys),52.512327,-3.311395
      NNP,Ninian Park,51.476438,-3.20141
      NIT,Nitshill,55.811929,-4.359944
      NBT,Norbiton,51.412356,-0.284003
      NRB,Norbury,51.411444,-0.1219
      NSB,Normans Bay,50.826097,0.389491
      NOR,Normanton,53.700535,-1.423404
      NBW,North Berwick,56.05703,-2.730747
      NCM,North Camp,51.275792,-0.731181
      NDL,North Dulwich,51.454509,-0.087892
      NLR,North Llanrwst,53.143836,-3.802732
      NQU,North Queensferry,56.012494,-3.394582
      NRD,North Road,54.536209,-1.553959
      NSH,North Sheen,51.465153,-0.287853
      NWA,North Walsham,52.816912,1.384475
      NWB,North Wembley,51.562596,-0.303961
      NTR,Northallerton,54.333082,-1.441282
      NMP,Northampton,52.237514,-0.906639
      NFD,Northfield,52.408205,-1.965844
      NFL,Northfleet,51.445844,0.324363
      NLT,Northolt Park,51.557539,-0.359444
      NUM,Northumberland Park,51.601969,-0.053907
      NWI,Northwich,53.261465,-2.496916
      NTB,Norton Bridge,52.866713,-2.190542
      NRW,Norwich,52.627176,1.306844
      NWD,Norwood Junction,51.397017,-0.075196
      NOT,Nottingham,52.947093,-1.146379
      NUN,Nuneaton,52.526386,-1.463866
      NHD,Nunhead,51.466827,-0.052247
      NNT,Nunthorpe,54.527892,-1.169462
      NUT,Nutbourne,50.846059,-0.882928
      NUF,Nutfield,51.226865,-0.133734
      OKN,Oakengates,52.693411,-2.450193
      OKM,Oakham,52.672232,-0.734161
      OKL,Oakleigh Park,51.637679,-0.166184
      OBN,Oban,56.412471,-5.473909
      OCK,Ockendon,51.521991,0.290497
      OLY,Ockley,51.151506,-0.335988
      OHL,Old Hill,52.470947,-2.056185
      ORN,Old Roan,53.486909,-2.95107
      OLD,Old Street,51.525832,-0.088509
      OLF,Oldfield Park,51.379226,-2.380507
      OLM,Oldham Mumps (closed),53.541077,-2.102117
      OLW,Oldham Werneth (closed),53.538713,-2.129271
      OLT,Olton,52.438524,-1.804303
      ORE,Ore,50.866943,0.591597
      OMS,Ormskirk,53.568968,-2.881789
      ORP,Orpington,51.373295,0.089117
      ORR,Orrell,53.530326,-2.708837
      OPK,Orrell Park,53.461912,-2.963315
      OTF,Otford,51.313155,0.196806
      OUN,Oulton Broad North,52.477785,1.715736
      OUS,Oulton Broad South,52.469752,1.707989
      OUT,Outwood,53.715302,-1.510403
      OVE,Overpool,53.284146,-2.924812
      OVR,Overton,51.254052,-1.259999
      OXN,Oxenholme Lake District,54.305247,-2.722261
      OXF,Oxford,51.7535,-1.270135
      OXS,Oxshott,51.336393,-0.362396
      OXT,Oxted,51.257905,-0.004807
      OXT,Oxted,51.257904,-0.004793
      PDW,Paddock Wood,51.182263,0.389178
      PDG,Padgate,53.405804,-2.556811
      PGN,Paignton,50.434702,-3.564892
      PCN,Paisley Canal,55.840077,-4.423783
      PYG,Paisley Gilmour Street,55.847343,-4.424491
      PYJ,Paisley St James,55.852111,-4.442427
      PAL,Palmers Green,51.618315,-0.110411
      PAN,Pangbourne,51.485401,-1.09045
      PNL,Pannal,53.958338,-1.533473
      PTF,Pantyffynnon,51.778883,-3.997449
      PAR,Par,50.355312,-4.704716
      PBL,Parbold,53.590949,-2.7706
      PKT,Park Street,51.725462,-0.340253
      PKS,Parkstone (Dorset),50.723102,-1.94894
      PSN,Parson Street,51.433316,-2.607745
      PTK,Partick,55.869881,-4.308791
      PRN,Parton,54.569909,-3.58202
      PWY,Patchway,51.52593,-2.562691
      PAT,Patricroft,53.484792,-2.358243
      PTT,Patterton,55.790388,-4.334873
      PEA,Peartree,52.897012,-1.47321
      PMR,Peckham Rye,51.470033,-0.069389
      PMR,Peckham Rye,51.470033,-0.069374
      PEG,Pegswood,55.178132,-1.644179
      PEM,Pemberton,53.530421,-2.670354
      PBY,Pembrey & Burry Port,51.683533,-4.247865
      PMB,Pembroke,51.672955,-4.906058
      PMD,Pembroke Dock,51.693923,-4.938082
      PNY,Pen-y-Bont,52.273952,-3.321936
      PNA,Penally,51.658926,-4.722087
      PEN,Penarth,51.435887,-3.17445
      PCD,Pencoed,51.524608,-3.500492
      PGM,Pengam,51.670456,-3.230109
      PNE,Penge East,51.419332,-0.054194
      PNW,Penge West,51.417553,-0.060814
      PHG,Penhelig,52.545701,-4.035034
      PNS,Penistone,53.525516,-1.622556
      PKG,Penkridge,52.723514,-2.119289
      PMW,Penmaenmawr,53.270481,-3.923515
      PNM,Penmere,50.149783,-5.082995
      PER,Penrhiwceiber,51.669925,-3.359956
      PRH,Penrhyndeudraeth,52.92884,-4.06457
      PNR,Penrith North Lakes,54.661817,-2.758032
      PYN,Penryn,50.170268,-5.110926
      PES,Pensarn (Gwynedd),52.83072,-4.112166
      PHR,Penshurst,51.197334,0.173499
      PTB,Pentre-Bach,51.725017,-3.362332
      PNF,Penyffordd,53.143103,-3.054838
      PNZ,Penzance,50.121676,-5.532452
      PRW,Perranwell,50.216484,-5.11183
      PRY,Perry Barr,52.516499,-1.901955
      PSH,Pershore,52.130296,-2.071529
      PTH,Perth,56.392084,-3.439696
      PBO,Peterborough,52.574992,-0.249823
      PTR,Petersfield,51.006719,-0.94112
      PET,Petts Wood,51.388618,0.074507
      PEV,Pevensey & Westham,50.815792,0.324836
      PEB,Pevensey Bay,50.817454,0.342936
      PEW,Pewsey,51.342188,-1.770665
      PIL,Pilning,51.556624,-2.627116
      PIN,Pinhoe,50.737773,-3.469347
      PIT,Pitlochry,56.702488,-3.735568
      PSE,Pitsea,51.560361,0.506321
      PLS,Pleasington,53.730973,-2.544121
      PLK,Plockton,57.33354,-5.665988
      PLC,Pluckley,51.15647,0.747426
      PLM,Plumley,53.274689,-2.41966
      PMP,Plumpton,50.928657,-0.060154
      PLU,Plumstead,51.489794,0.084284
      PLY,Plymouth,50.377811,-4.143349
      POK,Pokesdown,50.731075,-1.825094
      PLG,Polegate,50.821239,0.245169
      PSW,Polesworth,52.625936,-1.60994
      PWE,Pollokshaws East,55.824714,-4.287434
      PWW,Pollokshaws West,55.823821,-4.301591
      PLE,Pollokshields East,55.841061,-4.268588
      PLW,Pollokshields West,55.837693,-4.275739
      PMT,Polmont,55.984731,-3.714965
      POL,Polsloe Bridge,50.731268,-3.501961
      PON,Ponders End,51.642256,-0.035054
      PYP,Pont-y-Pant,53.065146,-3.862725
      PTD,Pontarddulais,51.717625,-4.045565
      PFR,Pontefract Baghill,53.691898,-1.303355
      PFM,Pontefract Monkhill,53.699001,-1.303692
      POT,Pontefract Tanshelf,53.694145,-1.318917
      PLT,Pontlottyn,51.746634,-3.278966
      PYC,Pontyclun,51.523767,-3.39293
      PPL,Pontypool & New Inn,51.697965,-3.014243
      PPD,Pontypridd,51.59937,-3.341386
      POO,Poole,50.719417,-1.983311
      POP,Poppleton,53.975914,-1.148605
      PTG,Port Glasgow,55.933507,-4.689806
      PSL,Port Sunlight,53.349266,-2.998029
      PTA,Port Talbot Parkway,51.59172,-3.781331
      PTC,Portchester,50.848738,-1.124226
      POR,Porth,51.612538,-3.407199
      PTM,Porthmadog,52.930931,-4.134453
      PMG,Porthmadog Harbour Ffestiniog Railway Station,52.924054,-4.126825
      PLN,Portlethen,57.061359,-2.126619
      PLD,Portslade,50.835674,-0.205309
      PMS,Portsmouth & Southsea,50.798483,-1.090898
      PMA,Portsmouth Arms,50.956995,-3.950601
      PMH,Portsmouth Harbour,50.79695,-1.107827
      PPK,Possilpark & Parkhouse,55.890237,-4.258024
      PBR,Potters Bar,51.69707,-0.192582
      PFY,Poulton-le-Fylde,53.848439,-2.990619
      PYT,Poynton,53.3504,-2.13441
      PRS,Prees,52.89965,-2.68974
      PSC,Prescot,53.423573,-2.79917
      PRT,Prestatyn,53.336513,-3.407133
      PRB,Prestbury,53.293398,-2.145481
      PRE,Preston,53.756874,-2.708125
      PRP,Preston Park,50.845937,-0.15514
      PST,Prestonpans,55.953093,-2.974772
      PRA,Prestwick Intl Airport,55.509035,-4.61415
      PTW,Prestwick,55.501697,-4.615136
      PTL,Priesthill & Darnley,55.812166,-4.34288
      PRR,Princes Risborough,51.717863,-0.843858
      PRL,Prittlewell,51.55069,0.710706
      PRU,Prudhoe,54.965834,-1.864876
      PUL,Pulborough,50.95735,-0.516534
      PFL,Purfleet,51.481012,0.236796
      PUR,Purley,51.337576,-0.114009
      PUO,Purley Oaks,51.347043,-0.09883
      PUT,Putney,51.461301,-0.216451
      PWL,Pwllheli,52.88785,-4.416706
      PYL,Pyle,51.525736,-3.698069
      QYD,Quakers Yard,51.660728,-3.322813
      QBR,Queenborough,51.415638,0.749696
      QPK,Queens Park (Glasgow),55.835692,-4.267317
      QPW,Queens Park (London),51.533966,-0.20496
      QRP,Queens Road Peckham,51.473565,-0.057288
      QRB,Queenstown Road (Battersea),51.474967,-0.146653
      QUI,Quintrell Downs,50.403965,-5.029798
      RDF,Radcliffe (Notts),52.948906,-1.036578
      RDT,Radlett,51.685191,-0.31722
      RAD,Radley,51.686209,-1.240464
      RDR,Radyr,51.516506,-3.248007
      RNF,Rainford,53.51712,-2.789469
      RNM,Rainham (London),51.516723,0.190663
      RAI,Rainham (Kent),51.366304,0.611366
      RNH,Rainhill,53.417136,-2.7664
      RAM,Ramsgate,51.34103,1.406065
      RGW,Ramsgreave & Wilpshire,53.780056,-2.478744
      RAN,Rannoch,56.686029,-4.576859
      RAU,Rauceby,52.985225,-0.4566
      RAV,Ravenglass,54.355623,-3.408966
      RVB,Ravensbourne,51.414186,-0.00753
      RVN,Ravensthorpe,53.675538,-1.655582
      RWC,Rawcliffe,53.689059,-0.960867
      RLG,Rayleigh,51.589297,0.60001
      RAY,Raynes Park,51.409171,-0.230127
      RDG,Reading,51.458786,-0.971842
      RDG,Reading,51.458786,-0.971828
      RDW,Reading West,51.455457,-0.990268
      REC,Rectory Road,51.558502,-0.068241
      RDB,Redbridge,50.91993,-1.470151
      RCC,Redcar Central,54.616237,-1.070883
      RCE,Redcar East,54.609263,-1.052307
      RDN,Reddish North,53.449426,-2.156253
      RDS,Reddish South,53.43594,-2.158763
      RDC,Redditch,52.306339,-1.945241
      RDH,Redhill,51.240198,-0.165874
      RDA,Redland,51.468383,-2.599125
      RED,Redruth,50.233241,-5.225963
      REE,Reedham (Norfolk),52.564527,1.559675
      RHM,Reedham (Surrey),51.331117,-0.12339
      REI,Reigate,51.241955,-0.2038
      RTN,Renton,55.970423,-4.586108
      RET,Retford,53.315173,-0.947883
      REL,Retford Low Level,53.314085,-0.944773
      RHI,Rhiwbina,51.52118,-3.213975
      RHO,Rhosneigr,53.234854,-4.506648
      RHL,Rhyl,53.318438,-3.489107
      RHY,Rhymney,51.75884,-3.289309
      RHD,Ribblehead,54.205855,-2.360859
      RIL,Rice Lane,53.457786,-2.962318
      RMD,Richmond (London),51.463059,-0.301536
      RMD,Richmond NLL,51.463146,-0.301389
      RIC,Rickmansworth,51.640249,-0.473261
      RDD,Riddlesdown,51.332484,-0.09936
      RID,Ridgmont,52.026412,-0.594535
      RDM,Riding Mill,54.949056,-1.970784
      RIS,Rishton,53.763558,-2.420154
      RBR,Robertsbridge,50.984928,0.468812
      ROB,Roby,53.410055,-2.855933
      RCD,Rochdale,53.610321,-2.153522
      ROC,Roche,50.41826,-4.830223
      RTR,Rochester,51.385547,0.51031
      RFD,Rochford,51.581732,0.702332
      RFY,Rock Ferry,53.372665,-3.010826
      ROG,Rogart,57.988695,-4.158188
      ROL,Rolleston,53.065743,-0.898764
      RMB,Roman Bridge,53.04443,-3.921653
      RMF,Romford,51.57483,0.183264
      RML,Romiley,53.414026,-2.089325
      ROM,Romsey,50.99252,-1.493134
      ROO,Roose,54.115172,-3.194565
      RSG,Rose Grove,53.786702,-2.282269
      RSH,Rose Hill Marple,53.396238,-2.07652
      ROS,Rosyth,56.045511,-3.427303
      RMC,Rotherham Central,53.43227,-1.360436
      RNR,Roughton Road,52.918047,1.299813
      RLN,Rowlands Castle,50.892162,-0.957455
      ROW,Rowley Regis,52.477339,-2.030869
      RYB,Roy Bridge,56.888346,-4.837231
      RYN,Roydon,51.775491,0.036279
      RYS,Royston,52.053089,-0.026892
      RUA,Ruabon,52.987148,-3.043138
      RUF,Rufford,53.635023,-2.806943
      RUG,Rugby,52.37911,-1.250471
      RGT,Rugeley Town,52.754393,-1.936834
      RGL,Rugeley Trent Valley,52.77003,-1.92955
      RUN,Runcorn,53.338709,-2.739252
      RUE,Runcorn East,53.326938,-2.665087
      RKT,Ruskington,53.041484,-0.380757
      RUS,Ruswarp,54.470204,-0.627788
      RUT,Rutherglen,55.830587,-4.21209
      RYD,Ryde Esplanade,50.732857,-1.159761
      RYP,Ryde Pier Head,50.739172,-1.160116
      RYR,Ryde St Johns Road,50.724353,-1.156555
      RRB,Ryder Brow,53.456594,-2.173086
      RYE,Rye,50.952365,0.730726
      RYH,Rye House,51.769417,0.005656
      SFD,Salford Central,53.483098,-2.254838
      SLD,Salford Crescent,53.486602,-2.275748
      SAF,Salfords (Surrey),51.201744,-0.162462
      SAH,Salhouse,52.675599,1.391438
      SAL,Salisbury,51.070541,-1.806377
      SAE,Saltaire,53.838506,-1.790483
      STS,Saltash,50.407341,-4.209143
      SLB,Saltburn,54.583463,-0.974148
      SLT,Saltcoats,55.633879,-4.784268
      SAM,Saltmarshe,53.722353,-0.810009
      SLW,Salwick,53.781715,-2.81977
      SNA,Sandal & Agbrigg,53.663094,-1.481421
      SDB,Sandbach,53.150183,-2.393505
      SNR,Sanderstead,51.348281,-0.093652
      SDL,Sandhills,53.429952,-2.99149
      SND,Sandhurst,51.346473,-0.803897
      SDG,Sandling,51.090371,1.066075
      SAN,Sandown,50.656858,-1.162377
      SDP,Sandplace,50.386738,-4.464516
      SAD,Sandwell & Dudley,52.508673,-2.01159
      SDW,Sandwich,51.269909,1.342597
      SDY,Sandy,52.124744,-0.281167
      SNK,Sankey for Penketh,53.392476,-2.650469
      SQH,Sanquhar,55.370169,-3.92451
      SRR,Sarn,51.538716,-3.589928
      SDF,Saundersfoot,51.722099,-4.716613
      SDR,Saunderton,51.675905,-0.825447
      SAW,Sawbridgeworth,51.814353,0.160438
      SXY,Saxilby,53.267224,-0.664039
      SAX,Saxmundham,52.214913,1.490197
      SCA,Scarborough,54.279808,-0.40572
      SCT,Scotscalder,58.482976,-3.552057
      SCH,Scotstounhill,55.885134,-4.352872
      SCU,Scunthorpe,53.586195,-0.650984
      SML,Sea Mills,51.47999,-2.649953
      SEB,Seaburn,54.929542,-1.386707
      SEF,Seaford,50.772837,0.100161
      SFL,Seaforth & Litherland,53.466283,-3.005622
      SEA,Seaham,54.836651,-1.340941
      SEM,Seamer,54.240768,-0.417045
      SSC,Seascale,54.395644,-3.484887
      SEC,Seaton Carew,54.658321,-1.200444
      SRG,Seer Green,51.60967,-0.607414
      SBY,Selby,53.783385,-1.063565
      SRS,Selhurst,51.391926,-0.088274
      SEL,Sellafield,54.416593,-3.510456
      SEG,Selling,51.277356,0.9409
      SLY,Selly Oak,52.441995,-1.935808
      SET,Settle,54.066925,-2.280717
      SVK,Seven Kings,51.564026,0.097127
      SVS,Seven Sisters,51.582268,-0.075245
      SEV,Sevenoaks,51.276862,0.181696
      SVB,Severn Beach,51.560024,-2.664481
      STJ,Severn Tunnel Junction,51.584675,-2.777897
      SFR,Shalford (Surrey),51.214318,-0.566782
      SHN,Shanklin,50.633897,-1.179824
      SHA,Shaw & Crompton (closed),53.576825,-2.089577
      SHW,Shawford,51.021813,-1.32818
      SHL,Shawlands,55.829206,-4.292329
      SSS,Sheerness-on-Sea,51.441063,0.758563
      SHF,Sheffield,53.378236,-1.46211
      SED,Shelford (Cambs),52.148838,0.14001
      SNF,Shenfield,51.630878,0.329879
      SEN,Shenstone,52.63906,-1.844787
      SPH,Shepherds Well,51.188403,1.229941
      SPY,Shepley,53.588755,-1.70493
      SHP,Shepperton,51.396802,-0.446766
      STH,Shepreth,52.114171,0.031348
      SHE,Sherborne,50.944014,-2.513073
      SIE,Sherburn-in-Elmet,53.797168,-1.232689
      SHM,Sheringham,52.941454,1.210338
      SLS,Shettleston,55.853531,-4.16003
      SDM,Shieldmuir,55.777486,-3.95698
      SFN,Shifnal,52.666084,-2.371837
      SHD,Shildon,54.626804,-1.637539
      SHI,Shiplake,51.511219,-0.882503
      SHY,Shipley,53.833065,-1.773493
      SPP,Shippea Hill,52.430229,0.413368
      SIP,Shipton,51.86566,-1.592679
      SHB,Shirebrook,53.20426,-1.202439
      SHH,Shirehampton,51.484347,-2.679278
      SRO,Shireoaks,53.32484,-1.168215
      SRL,Shirley,52.403434,-1.845173
      SRY,Shoeburyness,51.530975,0.795375
      SHO,Sholing,50.896742,-1.364905
      SEH,Shoreham (Kent),51.332216,0.188917
      SSE,Shoreham-by-Sea (Sussex),50.834419,-0.271693
      SRT,Shortlands,51.405798,0.00181
      SHT,Shotton,53.212555,-3.038424
      SHS,Shotts,55.818643,-3.798309
      SHR,Shrewsbury,52.711941,-2.749759
      SID,Sidcup,51.433868,0.103821
      SIL,Sileby,52.731612,-1.109982
      SIC,Silecroft,54.226224,-3.33537
      SLK,Silkstone Common,53.534933,-1.56348
      SLV,Silver Street,51.614689,-0.067215
      SVR,Silverdale,54.169918,-2.803841
      SIN,Singer,55.907664,-4.405471
      SIT,Sittingbourne,51.341977,0.734715
      SKG,Skegness,53.143079,0.333893
      SKE,Skewen,51.661393,-3.846524
      SKI,Skipton,53.958699,-2.025876
      SGR,Slade Green,51.467785,0.190518
      SWT,Slaithwaite,53.623843,-1.881579
      SLA,Slateford,55.926682,-3.243455
      SLR,Sleaford,52.995494,-0.410341
      SLH,Sleights,54.461066,-0.662497
      SLO,Slough,51.51188,-0.591493
      SMA,Small Heath,52.463774,-1.859387
      SAB,Smallbrook Junction,50.711089,-1.154188
      SGB,Smethwick Galton Bridge High Level,52.501795,-1.98049
      SGB,Smethwick Galton Bridge,52.501795,-1.980505
      SMR,Smethwick Rolfe Street,52.496399,-1.970638
      SMI,Smitham,51.32203,-0.134453
      SMB,Smithy Bridge,53.633268,-2.113501
      SNI,Snaith,53.693132,-1.028463
      SDA,Snodland,51.330229,0.44827
      SWO,Snowdown,51.215303,1.213735
      SOR,Sole Street,51.383143,0.378126
      SOL,Solihull,52.414404,-1.788384
      SYT,Somerleyton,52.510255,1.652285
      SAT,South Acton,51.499694,-0.270134
      SBK,South Bank,54.583841,-1.176681
      SBM,South Bermondsey,51.488135,-0.054652
      SCY,South Croydon,51.362963,-0.093431
      SES,South Elmsall,53.594624,-1.284861
      SGN,South Greenford,51.533749,-0.336682
      SGL,South Gyle,55.936347,-3.299475
      SOH,South Hampstead,51.541433,-0.178852
      SOK,South Kenton,51.570214,-0.30844
      SMO,South Merton,51.402991,-0.205133
      SOM,South Milford,53.782343,-1.250533
      SRU,South Ruislip,51.55692,-0.399238
      STO,South Tottenham,51.580373,-0.072077
      SWS,South Wigston,52.582241,-1.134068
      STL,Southall,51.505956,-0.378589
      SOA,Southampton Airport Parkway,50.950805,-1.363086
      SOU,Southampton Central,50.907438,-1.413587
      SOB,Southbourne,50.848266,-0.908091
      SBU,Southbury,51.648706,-0.05241
      SEE,Southease,50.831348,0.030674
      SOC,Southend Central,51.537067,0.711756
      SOE,Southend East,51.538975,0.731844
      SOV,Southend Victoria,51.541515,0.71153
      SMN,Southminster,51.660629,0.835221
      SOP,Southport,53.646533,-3.002432
      SWK,Southwick,50.832508,-0.235934
      SOW,Sowerby Bridge,53.70786,-1.907023
      SPA,Spalding,52.788826,-0.156873
      SBR,Spean Bridge,56.889996,-4.921595
      SPI,Spital,53.339952,-2.993906
      SPO,Spondon,52.912236,-1.41109
      SPN,Spooner Row,52.535018,1.086499
      SRI,Spring Road,52.443429,-1.837384
      SPR,Springburn,55.881705,-4.228109
      SPF,Springfield,56.294961,-3.05245
      SQU,Squires Gate,53.777345,-3.050299
      SAC,St Albans,51.750477,-0.327515
      SAA,St Albans Abbey,51.744737,-0.342546
      SAR,St Andrews Road,51.512768,-2.696317
      SAS,St Annes-on-the-Sea,53.753045,-3.029096
      SAU,St Austell,50.339502,-4.789401
      SBS,St Bees,54.492582,-3.591382
      SBF,St Budeaux Ferry Road,50.401377,-4.186842
      SBV,St Budeaux Victoria Road,50.401995,-4.187433
      SCR,St Columb Road,50.399054,-4.940821
      SDN,St Denys,50.922179,-1.38775
      SER,St Erth,50.17048,-5.444304
      SGM,St Germans,50.394259,-4.308436
      SNH,St Helens Central,53.453137,-2.730304
      SHJ,St Helens Junction,53.43374,-2.700259
      SIH,St Helier (London),51.389898,-0.198746
      SIV,St Ives (Cornwall),50.208647,-5.476772
      SJS,St James Street (London),51.580981,-0.032892
      SJP,St James Park (Devon),50.731143,-3.522008
      SAJ,St Johns (London),51.469389,-0.022693
      SKN,St Keyne Wishing Well Halt (Rail Station),50.423026,-4.463555
      SLQ,St Leonards Warrior Square,50.855864,0.560546
      SMT,St Margarets (Herts),51.787845,0.001297
      SMG,St Margarets (London),51.455234,-0.320178
      SMY,St Mary Cray,51.394748,0.10641
      STM,St Michaels,53.375614,-2.952798
      SNO,St Neots,52.231579,-0.247392
      STA,Stafford,52.803904,-2.122032
      SNS,Staines,51.432454,-0.503145
      SLL,Stallingborough,53.587116,-0.183671
      SYB,Stalybridge,53.484594,-2.06274
      SMD,Stamford,52.647404,-0.480489
      SMH,Stamford Hill,51.574468,-0.076656
      SFO,Stanford-le-Hope,51.514363,0.423067
      SNT,Stanlow & Thornton,53.278293,-2.84115
      SSD,Stansted Airport,51.888597,0.260843
      SST,Stansted Mountfitchet,51.901445,0.199808
      SPU,Staplehurst,51.171464,0.550469
      SRD,Stapleton Road,51.467504,-2.566218
      SBE,Starbeck,53.999013,-1.501135
      SCS,Starcross,50.627784,-3.447718
      SVL,Staveley,54.375446,-2.819402
      SCF,Stechford,52.484834,-1.811019
      SON,Steeton & Silsden,53.900044,-1.944723
      SPS,Stepps,55.889906,-4.140782
      SVG,Stevenage,51.901693,-0.207086
      STV,Stevenston,55.634275,-4.750768
      SWR,Stewartby,52.069089,-0.52067
      STT,Stewarton,55.682149,-4.51804
      STG,Stirling,56.119808,-3.935613
      SPT,Stockport,53.405553,-2.163012
      SKS,Stocksfield,54.947054,-1.916769
      SSM,Stocksmoor,53.594101,-1.723249
      STK,Stockton,54.569633,-1.318556
      SKM,Stoke Mandeville,51.787801,-0.784063
      SKW,Stoke Newington,51.565233,-0.072861
      SOT,Stoke-on-Trent,53.007996,-2.180986
      SNE,Stone,52.908341,-2.155039
      SCG,Stone Crossing,51.451328,0.263799
      SBP,Stonebridge Park,51.544111,-0.275805
      SOG,Stonegate,51.019963,0.363896
      STN,Stonehaven,56.966807,-2.225304
      SHU,Stonehouse,51.745891,-2.279496
      SNL,Stoneleigh,51.363398,-0.248641
      SBJ,Stourbridge Junction,52.447599,-2.133841
      SBT,Stourbridge Town,52.455591,-2.141812
      SMK,Stowmarket,52.189728,1.000037
      STR,Stranraer,54.909612,-5.024713
      SRA,Stratford (London),51.541895,-0.003369
      SAV,Stratford-upon-Avon,52.194261,-1.716279
      STC,Strathcarron,57.422711,-5.428605
      STW,Strawberry Hill,51.438961,-0.339337
      STE,Streatham,51.425806,-0.131524
      SRC,Streatham Common,51.418728,-0.135984
      SRH,Streatham Hill,51.438191,-0.127134
      SHC,Streethouse,53.67617,-1.400121
      SRN,Strines,53.375053,-2.033915
      STF,Stromeferry,57.352274,-5.551151
      SOO,Strood,51.396546,0.500216
      STD,Stroud (Glos),51.74458,-2.219378
      STU,Sturry,51.301072,1.122285
      SYA,Styal,53.348344,-2.240455
      SUD,Sudbury & Harrow Road,51.554398,-0.315445
      SUY,Sudbury (Suffolk),52.036289,0.735476
      SDH,Sudbury Hill Harrow,51.558465,-0.335781
      SUG,Sugar Loaf,52.082278,-3.68696
      SUM,Summerston,55.89906,-4.291681
      SUU,Sunbury,51.418312,-0.417761
      SUN,Sunderland,54.905346,-1.382318
      SUP,Sundridge Park,51.413779,0.021472
      SNG,Sunningdale,51.391939,-0.633023
      SNY,Sunnymeads,51.469896,-0.558994
      SUR,Surbiton,51.392457,-0.303936
      SUO,Sutton (London),51.35953,-0.19119
      SUT,Sutton Coldfield,52.564956,-1.824837
      SUC,Sutton Common,51.374888,-0.196318
      SPK,Sutton Parkway,53.1142,-1.245639
      SWL,Swale,51.389237,0.747164
      SAY,Swanley,51.393385,0.169251
      SWM,Swanscombe,51.449068,0.309572
      SWA,Swansea,51.625149,-3.941564
      SNW,Swanwick,50.875658,-1.26584
      SWY,Sway,50.784692,-1.609988
      SWG,Swaythling,50.941138,-1.376399
      SWD,Swinderby,53.169575,-0.702677
      SWI,Swindon,51.565472,-1.7855
      SWE,Swineshead,52.969825,-0.18716
      SNN,Swinton (Manchester),53.514848,-2.337459
      SWN,Swinton (South Yorks),53.486257,-1.305823
      SYD,Sydenham,51.427246,-0.054218
      SYH,Sydenham Hill,51.432712,-0.080314
      SYL,Syon Lane,51.481783,-0.32482
      SYS,Syston,52.694228,-1.082392
      TAC,Tackley,51.881323,-1.297212
      TAD,Tadworth,51.291634,-0.235939
      TAF,Taffs Well,51.540804,-3.262947
      TAI,Tain,57.814403,-4.05205
      TLC,Tal-y-Cafn,53.228378,-3.818267
      TAL,Talsarnau,52.904322,-4.068162
      TLB,Talybont,52.772645,-4.096603
      TAB,Tame Bridge Parkway,52.552946,-1.976206
      TAH,Tamworth High Level,52.637132,-1.687273
      TAM,Tamworth,52.637132,-1.687258
      TYB,Tan-y-Bwlch Ffestiniog Railway Station,52.954385,-4.011522
      TAP,Taplow,51.523563,-0.681352
      TAT,Tattenham Corner,51.30918,-0.242584
      TAU,Taunton,51.023296,-3.10275
      TAY,Taynuilt,56.430793,-5.23959
      TED,Teddington,51.424479,-0.332684
      TEA,Tees-side Airport,54.518142,-1.425322
      TGM,Teignmouth,50.548048,-3.494676
      TFC,Telford Central,52.681121,-2.44097
      TMC,Templecombe,51.001495,-2.417722
      TEN,Tenby,51.672952,-4.706727
      TEY,Teynham,51.333393,0.807456
      THD,Thames Ditton,51.389002,-0.33899
      THA,Thatcham,51.393842,-1.24317
      THH,Thatto Heath,53.436597,-2.759373
      THW,The Hawthorns,52.505387,-1.964003
      TLK,The Lakes,52.359473,-1.845765
      THE,Theale,51.433451,-1.074953
      TEO,Theobalds Grove,51.692458,-0.034805
      TTF,Thetford,52.419143,0.745098
      THI,Thirsk,54.228223,-1.372596
      TBY,Thornaby,54.559281,-1.301425
      TNN,Thorne North,53.616081,-0.972336
      TNS,Thorne South,53.603794,-0.95465
      THO,Thornford,50.911957,-2.579716
      THB,Thornliebank,55.810869,-4.31168
      TNA,Thornton Abbey,53.653969,-0.323495
      TTH,Thornton Heath,51.398775,-0.10028
      THT,Thorntonhall,55.768673,-4.251149
      TPB,Thorpe Bay,51.537573,0.761758
      TPC,Thorpe Culvert,53.122801,0.199477
      TLS,Thorpe-le-Soken,51.847647,1.161432
      TBD,Three Bridges,51.116918,-0.161157
      TOK,Three Oaks,50.900887,0.613395
      THU,Thurgarton,53.02922,-0.962023
      THC,Thurnscoe,53.54506,-1.308786
      THS,Thurso,58.590162,-3.527556
      TRS,Thurston,52.250018,0.808683
      TIL,Tilbury Town,51.462358,0.354069
      THL,Tile Hill,52.395118,-1.596839
      TLH,Tilehurst,51.471509,-1.029795
      TIP,Tipton,52.530455,-2.065696
      TIR,Tir-phil,51.720908,-3.246391
      TIS,Tisbury,51.060845,-2.078996
      TVP,Tiverton Parkway,50.917169,-3.359657
      TOD,Todmorden,53.713831,-2.09966
      TOL,Tolworth,51.376857,-0.279438
      TPN,Ton Pentre,51.647802,-3.486198
      TON,Tonbridge,51.191407,0.271001
      TDU,Tondu,51.547362,-3.595565
      TNF,Tonfanau,52.613557,-4.123706
      TNP,Tonypandy,51.619764,-3.44888
      TOO,Tooting,51.419846,-0.161252
      TOP,Topsham,50.686203,-3.464436
      TQY,Torquay,50.461118,-3.54329
      TRR,Torre,50.473173,-3.546431
      TOT,Totnes,50.435849,-3.688712
      TOM,Tottenham Hale,51.58831,-0.059904
      TTN,Totton,50.918005,-1.482123
      TWN,Town Green,53.542821,-2.904485
      TRA,Trafford Park,53.454832,-2.310631
      TRF,Trefforest,51.591462,-3.32513
      TRE,Trefforest Estate,51.568291,-3.290259
      TRH,Trehafod,51.610151,-3.380985
      TRB,Treherbert,51.672245,-3.536314
      TRY,Treorchy,51.657535,-3.505745
      TRM,Trimley,51.976541,1.319566
      TRI,Tring,51.800747,-0.622415
      TRD,Troed-y-Rhiw,51.712428,-3.346756
      TRN,Troon,55.542809,-4.655279
      TRO,Trowbridge,51.319826,-2.214331
      TRU,Truro,50.263828,-5.064859
      TUL,Tulloch,56.884261,-4.701311
      TUH,Tulse Hill,51.43986,-0.105051
      TBW,Tunbridge Wells,51.13023,0.262837
      TUR,Turkey Street,51.672629,-0.04719
      TUT,Tutbury & Hatton,52.864376,-1.68208
      TWI,Twickenham,51.450029,-0.330372
      TWY,Twyford,51.475534,-0.863274
      TYC,Ty Croes,53.222574,-4.474739
      TGS,Ty Glas,51.521538,-3.196543
      TYG,Tygwyn,52.893799,-4.078662
      TYL,Tyndrum Lower,56.433329,-4.714805
      TYS,Tyseley,52.45413,-1.83911
      TYW,Tywyn,52.585591,-4.093568
      UCK,Uckfield,50.968669,0.096476
      UDD,Uddingston,55.823522,-4.086685
      ULC,Ulceby,53.619059,-0.302048
      ULL,Ulleskelf,53.853628,-1.213977
      ULV,Ulverston,54.191592,-3.097915
      UMB,Umberleigh,50.996741,-3.982909
      UNI,University,52.451255,-1.936678
      UHA,Uphall,55.919036,-3.502116
      UPL,Upholland,53.528394,-2.741405
      UPM,Upminster,51.559018,0.250907
      UPM,Upminster,51.559108,0.250912
      UPH,Upper Halliford,51.413065,-0.430885
      UHL,Upper Holloway,51.563632,-0.129487
      UTY,Upper Tyndrum,56.43465,-4.703706
      UWL,Upper Warlingham,51.308509,-0.077924
      UPT,Upton,53.386503,-3.084151
      UPW,Upwey,50.64826,-2.466135
      URM,Urmston,53.448285,-2.353796
      UTT,Uttoxeter,52.897076,-1.857251
      VAL,Valley,53.2813,-4.563375
      VXH,Vauxhall,51.486189,-0.122864
      VIR,Virginia Water,51.401954,-0.562207
      WDO,Waddon,51.367396,-0.117311
      WAD,Wadhurst,51.073456,0.313201
      WFL,Wainfleet,53.105152,0.234731
      WKK,Wakefield Kirkgate,53.678673,-1.488572
      WKF,Wakefield Westgate,53.681664,-1.505115
      WKD,Walkden,53.51979,-2.396319
      WLG,Wallasey Grove Road,53.428019,-3.069705
      WLV,Wallasey Village,53.4229,-3.069125
      WLT,Wallington,51.360384,-0.150808
      WAF,Wallyford,55.940279,-3.014955
      WAM,Walmer,51.203329,1.382905
      WSL,Walsall,52.584412,-1.984749
      WDN,Walsden,53.696273,-2.104465
      WLC,Waltham Cross,51.685062,-0.026532
      WHC,Walthamstow Central,51.582919,-0.019788
      WMW,Walthamstow Queens Road,51.581503,-0.023819
      WAO,Walton (Merseyside),53.45623,-2.965746
      WON,Walton-on-the-Naze,51.846179,1.267699
      WAL,Walton-on-Thames,51.372928,-0.414614
      WAN,Wanborough,51.244519,-0.667569
      WSW,Wandsworth Common,51.446183,-0.163361
      WWR,Wandsworth Road,51.470216,-0.138494
      WNT,Wandsworth Town,51.461047,-0.188101
      WNP,Wanstead Park,51.551693,0.02624
      WBL,Warblington,50.853434,-0.967141
      WAR,Ware,51.807965,-0.028753
      WRM,Wareham,50.692876,-2.115241
      WGV,Wargrave,51.498159,-0.876498
      WMN,Warminster,51.20677,-2.176728
      WNH,Warnham,51.092896,-0.329437
      WBQ,Warrington Bank Quay,53.386023,-2.602363
      WAC,Warrington Central,53.391879,-2.592416
      WRW,Warwick,52.286553,-1.581842
      WTO,Water Orton,52.518599,-1.743083
      WBC,Waterbeach,52.262442,0.197412
      WTR,Wateringbury,51.249732,0.422495
      WLO,Waterloo (Merseyside),53.474968,-3.025534
      WFH,Watford High Street,51.652658,-0.391688
      WFJ,Watford Junction,51.663911,-0.395902
      WFN,Watford North,51.675708,-0.389902
      WTG,Watlington,52.673191,0.383334
      WAS,Watton-at-Stone,51.856358,-0.119695
      WNG,Waun-gron Park,51.488195,-3.229661
      WED,Wedgwood,52.951063,-2.170821
      WEE,Weeley,51.853109,1.115513
      WET,Weeton,53.923191,-1.581221
      WMG,Welham Green,51.736355,-0.210669
      WLI,Welling,51.464797,0.101717
      WEL,Wellingborough,52.303795,-0.676634
      WLN,Wellington (Shropshire),52.701319,-2.517163
      WLP,Welshpool,52.657507,-3.139869
      WGC,Welwyn Garden City,51.801053,-0.204046
      WLW,Welwyn North,51.823503,-0.192067
      WEM,Wem,52.856328,-2.718755
      WMB,Wembley Central,51.552325,-0.296409
      WCX,Wembley Stadium,51.554416,-0.285585
      WMS,Wemyss Bay,55.876138,-4.889059
      WND,Wendover,51.761762,-0.747348
      WNN,Wennington,54.123538,-2.586897
      WSA,West Allerton,53.369139,-2.906964
      WBY,West Byfleet,51.339222,-0.505465
      WCL,West Calder,55.853798,-3.567012
      WCY,West Croydon,51.378426,-0.10256
      WDT,West Drayton,51.510055,-0.472214
      WDU,West Dulwich,51.440716,-0.091346
      WEA,West Ealing,51.513505,-0.320111
      WHD,West Hampstead,51.547468,-0.191159
      WHP,West Hampstead Thameslink,51.548476,-0.191812
      WHR,West Horndon,51.567946,0.340672
      WKB,West Kilbride,55.69615,-4.851723
      WKI,West Kirby,53.373188,-3.183771
      WMA,West Malling,51.292018,0.418682
      WNW,West Norwood,51.431746,-0.103804
      WRU,West Ruislip,51.569759,-0.437747
      WRN,West Runton,52.935553,1.245476
      WLD,West St Leonards,50.853148,0.539965
      WSU,West Sutton,51.365851,-0.205148
      WWI,West Wickham,51.381299,-0.014405
      WWO,West Worthing,50.818344,-0.39296
      WSB,Westbury (Wilts),51.26698,-2.199178
      WCF,Westcliff-on-Sea,51.537336,0.691495
      WCB,Westcombe Park,51.484202,0.018421
      WHA,Westenhanger,51.09488,1.037719
      WTA,Wester Hailes,55.914311,-3.284338
      WFI,Westerfield,52.080995,1.165936
      WES,Westerton,55.9048,-4.334865
      WGA,Westgate-on-Sea,51.38145,1.338389
      WHG,Westhoughton,53.555685,-2.523727
      WNM,Weston Milton,51.348466,-2.942392
      WSM,Weston-super-Mare,51.344315,-2.971668
      WRL,Wetheral,54.883846,-2.831717
      WYB,Weybridge,51.361768,-0.457704
      WYB,Weybridge,51.361768,-0.457719
      WEY,Weymouth,50.615302,-2.454219
      WBR,Whaley Bridge,53.330249,-1.984644
      WHE,Whalley,53.824254,-2.412255
      WTS,Whatstandwell,53.083107,-1.50431
      WFF,Whifflet,55.853686,-4.018644
      WHM,Whimple,50.768016,-3.354335
      WNL,Whinhill,55.938364,-4.746675
      WHN,Whiston,53.413883,-2.796431
      WTB,Whitby,54.484623,-0.615419
      WHT,Whitchurch (Cardiff),51.520645,-3.222176
      WCH,Whitchurch (Hants),51.237407,-1.338163
      WTC,Whitchurch (Shrops),52.968074,-2.671474
      WHL,White Hart Lane,51.605037,-0.070888
      WNY,White Notley,51.838919,0.595891
      WCR,Whitecraigs,55.790316,-4.310143
      WTH,Whitehaven,54.553037,-3.586934
      WTL,Whitland,51.818039,-4.614418
      WBD,Whitley Bridge,53.699148,-1.158284
      WTE,Whitlocks End,52.391844,-1.851531
      WHI,Whitstable,51.357585,1.033325
      WLE,Whittlesea,52.549956,-0.118217
      WLF,Whittlesford Parkway,52.103598,0.165646
      WTN,Whitton,51.449605,-0.35766
      WWL,Whitwell (Derbys),53.28038,-1.199373
      WHY,Whyteleafe,51.309955,-0.081121
      WHS,Whyteleafe South,51.303551,-0.076668
      WCK,Wick,58.441553,-3.096864
      WIC,Wickford,51.615025,0.519213
      WCM,Wickham Market,52.151116,1.398711
      WDD,Widdrington,55.241398,-1.616251
      WID,Widnes,53.378511,-2.733537
      WMR,Widney Manor,52.395948,-1.774363
      WGN,Wigan North Western,53.543675,-2.633273
      WGW,Wigan Wallgate,53.544835,-2.633185
      WGT,Wigton,54.829347,-3.164352
      WMI,Wildmill,51.52087,-3.579649
      WIJ,Willesden Junction,51.532497,-0.244524
      WIJ,Willesden Junction Low Level,51.532028,-0.243244
      WLM,Williamwood,55.794107,-4.290107
      WIL,Willington,52.853661,-1.563356
      WMC,Wilmcote,52.222489,-1.755918
      WML,Wilmslow,53.326862,-2.226326
      WNE,Wilnecote (Staffs),52.610861,-1.679485
      WIM,Wimbledon,51.421273,-0.206358
      WIM,Wimbledon,51.421273,-0.206344
      WBO,Wimbledon Chase,51.409556,-0.214007
      WSE,Winchelsea,50.93376,0.702292
      WIN,Winchester,51.067203,-1.319688
      WNF,Winchfield,51.284948,-0.906961
      WIH,Winchmore Hill,51.633943,-0.100874
      WDM,Windermere,54.37961,-2.903394
      WNC,Windsor & Eton Central,51.483268,-0.610363
      WNR,Windsor & Eton Riverside,51.48565,-0.606517
      WNS,Winnersh,51.430282,-0.87684
      WTI,Winnersh Triangle,51.436741,-0.891313
      WSF,Winsford,53.190525,-2.494597
      WSH,Wishaw,55.772038,-3.926414
      WTM,Witham (Essex),51.805975,0.639157
      WTY,Witley,51.133156,-0.645762
      WTT,Witton (West Midlands),52.512393,-1.88443
      WVF,Wivelsfield,50.963778,-0.120812
      WIV,Wivenhoe,51.85654,0.956167
      WOB,Woburn Sands,52.01816,-0.654062
      WOK,Woking,51.318466,-0.55694
      WKM,Wokingham,51.411217,-0.842525
      WOH,Woldingham,51.290155,-0.051843
      WVH,Wolverhampton,52.587858,-2.119508
      WOL,Wolverton,52.065887,-0.804246
      WOM,Wombwell,53.517588,-1.416311
      WDE,Wood End,52.344368,-1.844497
      WST,Wood Street,51.58658,-0.002378
      WDB,Woodbridge,52.09046,1.317801
      WGR,Woodgrange Park,51.549263,0.04445
      WDL,Woodhall,55.931198,-4.655382
      SOF,South Woodham Ferrers,51.649462,0.606533
      WDH,Woodhouse,53.363761,-1.357553
      WDS,Woodlesford,53.756802,-1.442883
      WLY,Woodley,53.429268,-2.09327
      WME,Woodmansterne,51.319016,-0.154236
      WSR,Woodsmoor,53.386489,-2.142085
      WOO,Wool,50.681626,-2.221456
      WLS,Woolston,50.898912,-1.377048
      WWA,Woolwich Arsenal,51.489908,0.069221
      WWD,Woolwich Dockyard,51.491126,0.054669
      WWW,Wootton Wawen,52.265879,-1.784546
      WOF,Worcester Foregate Street,52.19493,-2.221737
      WCP,Worcester Park,51.38125,-0.245143
      WOS,Worcester Shrub Hill,52.194737,-2.209403
      WKG,Workington,54.645102,-3.558501
      WRK,Worksop,53.311658,-1.122543
      WOR,Worle,51.358032,-2.909626
      WPL,Worplesdon,51.289013,-0.582558
      WRT,Worstead,52.777461,1.404089
      WRH,Worthing,50.818489,-0.376146
      WRB,Wrabness,51.939521,1.171528
      WRY,Wraysbury,51.457707,-0.541903
      WRE,Wrenbury,53.019715,-2.596249
      WRS,Wressle,53.772779,-0.924206
      WXC,Wrexham Central,53.046203,-2.999053
      WRX,Wrexham General,53.050246,-3.002443
      WYE,Wye,51.185011,0.929334
      WYM,Wylam,54.974978,-1.814074
      WYL,Wylde Green,52.545727,-1.831401
      WMD,Wymondham,52.565434,1.118048
      WYT,Wythall,52.380175,-1.866261
      YAL,Yalding,51.22648,0.412192
      YRD,Yardley Wood,52.421515,-1.854374
      YRM,Yarm,54.493909,-1.351557
      YAE,Yate,51.5406,-2.43252
      YAT,Yatton,51.39101,-2.827783
      YEO,Yeoford,50.776914,-3.727137
      YVJ,Yeovil Junction,50.924739,-2.612457
      YVP,Yeovil Pen Mill,50.944518,-2.613428
      YET,Yetminster,50.895755,-2.573756
      YNW,Ynyswen,51.664973,-3.521608
      YOK,Yoker,55.892737,-4.387401
      YRK,York,53.957982,-1.093191
      YRT,Yorton,52.808971,-2.736458
      YSM,Ystrad Mynach,51.640936,-3.241305
      YSR,Ystrad Rhondda,51.643641,-3.466695
      NEW,Newcraighall,55.93485,-3.092769
      WAV,Wavertree Technology Park,53.405207,-2.922909
      LEG,Lea Green,53.42711,-2.723838
      BEL,Beauly,57.478264,-4.469863
      BTP,Braintree Freeport,51.869424,0.568463
      BGH,Brighouse,53.698211,-1.779441
      BSU,Brunstane,55.942505,-3.10099
      BSH,Bushey,51.645754,-0.385298
      CFR,Chandlers Ford,50.982996,-1.384385
      DFL,Dunfermline Queen Margaret,56.080568,-3.421465
      DNO,Dunrobin Castle,57.985516,-3.948924
      HOZ,Howwood (Renfrewshire),55.810558,-4.56304
      OKE,Okehampton,50.732371,-3.996237
      SHT,Shotton High Level,53.21355,-3.037699
      STZ,St Peters,54.911447,-1.383816
      WRP,Warwick Parkway,52.286116,-1.612046
      WFJ,Watford Junction,51.663533,-0.396494
      WBP,West Brompton,0,0
      WEH,West Ham,51.528489,0.005459
      WMB,Wembley Central,51.552325,-0.296395
      HWI,Horwich Parkway,53.578121,-2.539666
      STQ,Southampton Town Quay,50.895142,-1.405822
      SHV,Southsea Hoverport,50.785316,-1.099977
      EDP,Edinburgh Park,55.927544,-3.307663
      LWM,Llantwit Major,51.409745,-3.48163
      RIA,Rhoose,51.387064,-3.349395
      GRH,Gartcosh,55.885655,-4.079483
      GLH,Glasshoughton,53.709059,-1.342008
      KVD,Kelvindale,55.893589,-4.3098
      MUF,Manchester United FC,53.462209,-2.290653
      LRH,Larkhall,55.738591,-3.9755
      MEY,Merryton,55.748702,-3.978242
      CTE,Chatelherault,55.765214,-4.004665
      HWF,Heathrow Airport Terminal 4 (Rail-Air),51.459329,-0.446947
      LPY,Liverpool South Parkway,53.357759,-2.889143
      APN,Newcastle Airport Metro,55.035435,-1.711941
      BIB,Bishop's Lydeard,51.0545,-3.194309
      CEH,Coleshill Parkway,52.516541,-1.708169
      LAU,Laurencekirk,56.836334,-2.465932
      LLR,Llanharan,51.537586,-3.440791
      SPL,London St Pancras International LL,51.532168,-0.127317
      ZFD,Farringdon (London),51.5203,-0.105029
      VXH,Vauxhall,51.486189,-0.12285
      HWV,Heathrow Airport Terminal 5,51.470052,-0.49057
      EBV,Ebbw Vale Parkway,51.757146,-3.196112
      LTH,Llanhilleth,51.700302,-3.135195
      NBE,Newbridge,51.665815,-3.142894
      RCA,Risca & Pontymister,51.605848,-3.092217
      ROR,Rogerstone,51.595617,-3.066618
      CKY,Crosskeys,51.620903,-3.126179
      HTR,Heathrow Airport Central Bus Stn (Rail-Air),51.471094,-0.453286
      MTC,Mitcham Eastfields,51.407736,-0.15462
      ALO,Alloa,56.117782,-3.790048
      HWX,Heathrow Airport Terminal 5 (Rail-Air),51.47125,-0.489349
      SPB,Shepherds Bush,51.505284,-0.21763
      AVP,Aylesbury Vale Parkway,51.831164,-0.86016
      LPY,Liverpool South Parkway,53.357759,-2.889128
      EMD,East Midlands Parkway,52.863363,-1.263108
      COR,Corby,52.489213,-0.687206
      EBD,Ebbsfleet International,51.442971,0.32095
      STP,London St Pancras International,51.532514,-0.126438
      SMC,Sampford Courtenay,50.770091,-3.948912
      IMW,Imperial Wharf,51.474948,-0.182798
      SFA,Stratford International,51.544828,-0.00875
      ZCW,Canada Water,51.497989,-0.049693
      DLJ,Dalston Junction,51.546115,-0.075111
      HGG,Haggerston,51.538705,-0.07564
      HOX,Hoxton,51.531512,-0.075655
      SDE,Shadwell,51.511284,-0.056908
      SDC,Shoreditch High Street,51.523375,-0.07522
      SQE,Surrey Quays,51.493196,-0.047492
      WPE,Wapping,51.504388,-0.055904
      ZWL,Whitechapel,51.519469,-0.05973
      ROE,Rotherhithe,51.500816,-0.052022
      SNP,Stanhope,54.743074,-2.003923
      FRR,Frosterley,54.727001,-1.96442
      WLH,Wolsingham,54.726439,-1.883791
      BIA,Bishop Auckland,54.657472,-1.677552
      NWX,New Cross ELL,51.476343,-0.032415
      NXG,New Cross Gate ELL,51.475127,-0.040387
      SIA,Southend Airport,51.568669,0.705238
      ARM,Armadale (W Lothian),55.885704,-3.695404
      BKR,Blackridge,55.881156,-3.765196
      CAC,Caldercruix,55.887937,-3.887701"""
    for row in csv.split("\n")
      [code, name, lon, lat] = row.split(',')
      station = new TubeStation("rail-#{code}", parseFloat(lat), parseFloat(lon))
      station.name = "\uF001 #{name}"
      @addFeature(station)

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

