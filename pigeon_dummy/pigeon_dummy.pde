
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
  float dive = keyPressed && keyCode == DOWN ? 1.0 : 0.0;
  float flap = keyPressed && keyCode == UP   ? 2.0 : 0.0;
  String data = "{\"roll\":" + ((mouseXOffset - mouseX) / 2) + ",\"dive\":" + dive + ",\"flap\":" + flap + "}";
  println("flap:" + flap);
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
void keyPressed() {
  if      (key == ' ') ws.broadcast("{\"reset\": 1}");
  else if (key == 'r') ws.broadcast("{\"reset\": 2}");
}

