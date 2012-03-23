
void identifyGestures(int userId) {
  // already got head position within draw()
  float confRShoul = ni.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, rShoul);
  float confLShoul = ni.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER,  lShoul);
  float confRElbow = ni.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW,    rElbow);
  float confLElbow = ni.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_ELBOW,     lElbow);
  float confRHand  = ni.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HAND,     rHand);
  float confLHand  = ni.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND,      lHand);
  float confRHip   = ni.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HIP,      rHip);
  float confLHip   = ni.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HIP,       lHip);
  
  float confSum = confRShoul + confLShoul + confRElbow + confLElbow + confRHand + confLHand + confRHip + confLHip;
  
  float rShoulElbowRad =   atan2(  rShoul.y - rElbow.y,   rShoul.x - rElbow.x);
  float rElbowHandRad  =   atan2(  rElbow.y - rHand.y,    rElbow.x - rHand.x);
  float rShoulHandRad  =   atan2(  rShoul.y - rHand.y,    rShoul.x - rHand.x);
  float lShoulElbowRad = - atan2(- lShoul.y + lElbow.y, - lShoul.x + lElbow.x);
  float lElbowHandRad  = - atan2(- lElbow.y + lHand.y,  - lElbow.x + lHand.x);
  float lShoulHandRad  = - atan2(- lShoul.y + lHand.y,  - lShoul.x + lHand.x);
  
  float rShoulElbowDeg = wrapDegs360(degrees(rShoulElbowRad));
  float rElbowHandDeg  = wrapDegs360(degrees(rElbowHandRad));
  float rShoulHandDeg  = wrapDegs360(degrees(rShoulHandRad));
  float lShoulElbowDeg = wrapDegs360(degrees(lShoulElbowRad));
  float lElbowHandDeg  = wrapDegs360(degrees(lElbowHandRad));
  float lShoulHandDeg  = wrapDegs360(degrees(lShoulHandRad));
  
  float rDegDiff = rElbowHandDeg - rShoulElbowDeg;
  float lDegDiff = lElbowHandDeg - lShoulElbowDeg;
  float shoulHandDegSum = wrapDegs360(lShoulHandDeg + rShoulHandDeg);
  
  boolean rArmStraight = rDegDiff >= -40 & rDegDiff < 80;
  boolean lArmStraight = lDegDiff >= -40 & lDegDiff < 80;
  boolean armsStraight = rArmStraight && lArmStraight;

  if                        (shoulHandDegSum >= 310 || shoulHandDegSum <  80) flapStage =  0;
  else if (flapStage >= 0 && shoulHandDegSum >= 295 && shoulHandDegSum < 310) flapStage =  1;
  else if (flapStage >= 1 && shoulHandDegSum >= 280 && shoulHandDegSum < 295) flapStage =  2;
  else if (flapStage >= 2 && shoulHandDegSum >= 265 && shoulHandDegSum < 280) flapStage =  3;
  else if (flapStage >= 3 && shoulHandDegSum >= 250 && shoulHandDegSum < 265) flapStage =  4;
  else if (flapStage >= 4 && shoulHandDegSum >= 235 && shoulHandDegSum < 250) flapStage =  5;
  else if (flapStage >= 5 && shoulHandDegSum >= 210 && shoulHandDegSum < 235) flapStage =  6;
  if                        (shoulHandDegSum >=  80 && shoulHandDegSum < 210) {
    long now = System.currentTimeMillis();
    long timeSinceFlight = now - lastFlightTime;
    if (timeSinceFlight > flightGracePeriod) flapStage = -1;
  } else {
    lastFlightTime = System.currentTimeMillis();
  }
  
  float handsDistance = dist(lHand.x, lHand.y, lHand.z, rHand.x, rHand.y, rHand.z);
  boolean handsTogether = handsDistance < 100;
  float meanShoulY = (lShoul.y + rShoul.y) / 2.0;
  boolean handsOverHead = lHand.y > meanShoulY && rHand.y > meanShoulY;
  
  float sumHipZ   = (rHip.z + lHip.z);
  float sumShoulZ = (rShoul.z + lShoul.z);
  float leanFwdDeg = degrees(atan2(sumHipZ, sumShoulZ)) - 45.0 - leanThresholdDeg;
  if (leanFwdDeg < 0) leanFwdDeg = 0;
  
  flyingUserId = userId;  // if *not* flying, this gets altered below
  
  if (armsStraight && flapStage >= 0 && confSum > 4.0) {  // we're flying!
    stroke(255, leanFwdDeg > 0 ? 128 : 255, 0);  // yellow if straight, orange if diving
    
    float handsLeftRad = atan2(rHand.y - lHand.y, rHand.x - lHand.x);
    float handsLeftDeg = wrapDegs180(degrees(handsLeftRad));
    
    String data = "{\"roll\":" + handsLeftDeg + ",\"dive\":" + leanFwdDeg + ",\"flap\":" + flapStage + "}";
    ws.broadcast(data);

  } else if (handsTogether && handsOverHead && confSum > 4.0) {
    stroke(0, 255, 0);
    ws.broadcast("{\"reset\": 1}");

  } else {
    flyingUserId = -1;
    ws.broadcast("{}");
  }
}

float wrapDegs360(float degs) {
  while (degs < 0)    degs += 360;
  while (degs >= 360) degs -= 360;
  return degs;
}

float wrapDegs180(float degs) {
  while (degs < -180) degs += 360;
  while (degs >= 180) degs -= 360;
  return degs;
}

