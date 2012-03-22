
import SimpleOpenNI.*;

import muthesius.net.*;
import org.webbitserver.*;

int   wsPort      = 8888;
float scaleFactor = 1.0 / 3.0;
int   fps         = 30;

WebSocketP5   ws;
SimpleOpenNI  ni;
IntVector     users;

PVector rShoul, lShoul, rElbow, lElbow, rHand, lHand, rHip, lHip, head;

int flapStage = -1;

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
  
  // identify front-and-centremost user
  int frontUserId = -1;
  float frontUserXZ = 1.0 / 0.0;  // Infinity
  for (int i = 0; i < len; i ++) {
    int userId = users.get(i);
    if (ni.isTrackingSkeleton(userId)) {
      ni.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, head);
      float xz = abs(head.x * 4.0) + head.z;  // lower z is nearer the Kinect; x nearer 0 is nearer the centre of the scene
      if (xz < frontUserXZ) {
        frontUserId = userId;
        frontUserXZ = xz;
      }
    }
  }
  
  // identify and draw
  for (int i = 0; i < len; i ++) {
    int userId = users.get(i);
    if (ni.isTrackingSkeleton(userId)) {
      if (userId == frontUserId) {
        stroke(255);  // will be overridden if any gesture is identified
        identifyGestures(userId);
      } else {
        stroke(128);
      }
      drawSkeleton(userId);
    }
  }

}
