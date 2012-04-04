
void onNewUser(int userId) {
  println("onNewUser - userId: " + userId);
  println("  start pose detection");
  ni.requestCalibrationSkeleton(userId, true);
}

void onLostUser(int userId) {
  println("onLostUser - userId: " + userId);
}

void onStartCalibration(int userId) {
  println("onStartCalibration - userId: " + userId);
}

void onEndCalibration(int userId, boolean successful) {
  println("onEndCalibration - userId: " + userId + ", successful: " + successful);
  if (successful) { 
    println("  User calibrated");
    ni.startTrackingSkeleton(userId); 
  } else { 
    println("  Failed to calibrate user, retrying");
    ni.requestCalibrationSkeleton(userId, true);
  }
}

