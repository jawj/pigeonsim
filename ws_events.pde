
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

