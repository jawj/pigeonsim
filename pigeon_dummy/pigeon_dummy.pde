
import muthesius.net.*;
import org.webbitserver.*;

int wsPort = 8888;
boolean mousedown = false;
WebSocketP5 ws;

void setup() {
  ws = new WebSocketP5(this, wsPort);
}

void draw() {
  if (! mousedown) return;
  String data = "{\"roll\":" + (mouseX - width / 2) + ",\"dive\":0,\"flap\":0}";
  ws.broadcast(data);
}

void stop() {
  ws.stop();
  super.stop();
}

void websocketOnOpen(WebSocketConnection c) {
  println("Client connected");
}

void websocketOnClosed(WebSocketConnection c) {
  println("Client gone");
}

void mousePressed() {
  mousedown = true;
}

void mouseReleased() {
  mousedown = false;
}
