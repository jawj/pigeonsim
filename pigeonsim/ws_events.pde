
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
  String data = "{\"roll\":1,\"dive\":0,\"flap\":0}";
   ws.broadcast(data);
}
