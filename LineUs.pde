// Processing 4.3 Version
// An example class to show how to use the Line-us API

class LineUs {
  
  Client lineUs;
  boolean connected = false;
  String helloMessage;
  String address = "192.168.0.4";
  
  LineUs(PApplet papp, String address) {
    try {
      lineUs = new Client(papp, address, 1337);
      
      if (lineUs.available() > 0) {
        connected = true;
        helloMessage = readResponse();
      }
    }
    catch (Exception e) {
      println("Error connecting to Line-us: " + e.getMessage());
    }
  }
  
  String getHelloString() {
    return connected ? helloMessage : "Not connected";
  }
  
  // Close the connection to the Line-us
  void disconnect() {
    if (connected) {
      lineUs.stop();
      connected = false;
    }
  }
  
  // Send a G01 (interpolated move), and wait for the response before returning
  void g01(int x, int y, int z) {
    String cmd = String.format("G01 X%d Y%d Z%d", x, y, z);
    sendCommand(cmd);
    readResponse();
  }
  
  // Read from the socket one byte at a time until we get a null
  String readResponse() {
    StringBuilder line = new StringBuilder();
    int c;
    while (true) {
       c = lineUs.read();
       if (c != 0 && c != -1) {
         line.append((char) c);
       } else if (c == 0) {
         break;
       }
    }
    return line.toString();
  }
  
  // Send the command to Line-us
  void sendCommand(String command) {
    lineUs.write(command + "\0");
  }
}
