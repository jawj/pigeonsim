
import SimpleOpenNI.*;

import muthesius.net.*;
import org.webbitserver.*;

int   wsPort            = 8888;
float scaleFactor       = 1.0;
int   fps               = 30;
float leanThresholdDeg  = 1.5;
long  flightGracePeriod = 333; // ms

WebSocketP5   ws;
SimpleOpenNI  ni;
IntVector     users;

PVector rShoul, lShoul, rElbow, lElbow, rHand, lHand, rHip, lHip, head;

int  flyingUserId = -1;
int  flapStage = -1;
long lastFlightTime = 0;

void setup() {
  rShoul = new PVector(); lShoul = new PVector();
  rElbow = new PVector(); lElbow = new PVector();
  rHand  = new PVector(); lHand  = new PVector();
  rHip   = new PVector(); lHip   = new PVector();
  head   = new PVector();
  
  ni    = new SimpleOpenNI(this);
  users = new IntVector();
  
  ni.setMirror(true);
  if (! ni.enableDepth()) {
     println("Can't open the depth map: is the camera connected?");
     exit();
  }
  ni.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
  
  ws = new WebSocketP5(this, wsPort);

  frameRate(fps);
  size(round(ni.depthWidth() * scaleFactor), round(ni.depthHeight() * scaleFactor));
  
  strokeWeight(6);
  smooth();
}

void draw() {
  scale(scaleFactor);
  
  ni.update();
  image(ni.depthImage(), 0, 0);
  ni.getUsers(users);
  long len = users.size();
  
  // identify current OR front-and-centremost user
  int activeUserId = -1;
  
  if (flyingUserId > 0 && ni.isTrackingSkeleton(flyingUserId)) {  // flyingUserId is set in identifyGestures
    activeUserId = flyingUserId;
  } else {
    float frontUserXZ = 1.0 / 0.0;  // Infinity
    for (int i = 0; i < len; i ++) {
      int userId = users.get(i);
      if (ni.isTrackingSkeleton(userId)) {
        ni.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, head);
        float xz = abs(head.x * 5.0) + head.z;  // lower z is nearer the Kinect; x nearer 0 is nearer the centre of the scene
        if (xz < frontUserXZ) {
          activeUserId = userId;
          frontUserXZ = xz;
        }
      }
    }
  }
  
  // draw users and identify gestures
  for (int i = 0; i < len; i ++) {
    int userId = users.get(i);
    if (ni.isTrackingSkeleton(userId)) {
      if (userId == activeUserId) {
        stroke(255);  // will be overridden if any gesture is identified
        identifyGestures(userId);
      } else {
        stroke(128);
      }
      drawSkeleton(userId);
    }
  }

}
