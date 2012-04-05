
import muthesius.net.*;
import org.webbitserver.*;

int wsPort = 8888;
boolean mousedown = false;
int mouseXOffset;
WebSocketP5 ws;

void setup() {
  ws = new WebSocketP5(this, wsPort);
}

void draw() {
  if (! mousedown) return;
  String data = "{\"roll\":" + ((mouseXOffset - mouseX) / 2) + ",\"dive\":0,\"flap\":0}";
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
  mouseXOffset = mouseX;
}

void mouseReleased() {
  mousedown = false;
}
