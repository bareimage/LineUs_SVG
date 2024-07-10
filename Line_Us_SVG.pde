// Processing 4.3 Version
// v0.3
// Creative Commons
// Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/
// Original by Michael Zoellner, 2018
// Updated for Processing 4.3, 2024
// Current branch by Igor Molochevski, 2024
// With the help of Copilot, I rewrote the entire codebase using a functional programming paradigm
// Things to-do
// - Add Error checking if host not found
// - Redo segmentation to only segment non linear pathes

import geomerative.*;
import processing.net.*;
import java.net.*;
import javax.swing.JOptionPane;

RShape grp; // Shape object for SVG
boolean lines; // Flag to toggle line drawing mode
boolean rawpoints; // Flag to toggle raw points mode
boolean connected; // Flag to check Line-Us connection status
boolean hide = false; // Flag to toggle UI visibility
float resolution = 5; // Resolution for polygonizer

String lineus_address = "line-us.local"; // Default address for Line-Us device

LineUs myLineUs; // Line-Us device instance

// Constants defining the drawing area boundaries
final int LINE_MIN_X = 650;
final int LINE_MAX_X = 1775;
final int LINE_MIN_Y = -1000;
final int LINE_MAX_Y = 1000;

final int LW = 1775 - 650; // Drawing area width
final int LH = 2000; // Drawing area height

void settings() {
  size(LW / 2, LH / 2); // Set canvas size
  smooth(); // Enable anti-aliasing
  RG.init(this); // Initialize Geomerative library
  grp = RG.loadShape("venn_.svg"); // Load SVG file
}

void draw() {
  background(255); // Clear background to white
  if (lines) {
    drawLines(); // Draw lines if lines mode is enabled
  } else {
    grp.draw(); // Otherwise, draw the shape
  }
  if (!hide) {
    drawInterface(); // Draw user interface if not hidden
  }
}

void drawLines() {
  RG.setPolygonizer(RG.ADAPTATIVE); // Set adaptive polygonizer
  RPoint[][] points = grp.getPointsInPaths(); // Get points from paths in the shape
  if (points != null) {
    forEachPoint(points, (point) -> {
      drawPath(point); // Draw each path
      drawPoints(point); // Draw points along the path
    });
  }
}

// Iterate over each point array and apply the given action
void forEachPoint(RPoint[][] points, Consumer<RPoint[]> action) {
  for (RPoint[] point : points) {
    action.accept(point);
  }
}

// Draw a path by connecting vertices
void drawPath(RPoint[] points) {
  noFill(); // Disable shape fill
  stroke(100); // Set stroke color to gray
  beginShape(); // Begin a new shape
  for (RPoint point : points) {
    vertex(point.x, point.y); // Add each point as a vertex
  }
  endShape(CLOSE); // Close the shape
}

// Draw circles at each point for visualization
void drawPoints(RPoint[] points) {
  noFill(); // Disable fill for circles
  stroke(0); // Set stroke color to black
  for (RPoint point : points) {
    circle(point.x, point.y, 5); // Draw a circle at each point
  }
}

// Draw the user interface text
void drawInterface() {
  fill(0, 150); // Set fill color with transparency
  text("Line-Us SVG Plotter", 20, 20); // Title text
  text("---------------------", 20, 40); // Separator line
  text("address:\t" + lineus_address + " (a)", 20, 60); // Display address
  text("open SVG:\to", 20, 80); // Option to open SVG
  text("zoom:\t+/-", 20, 100); // Zoom controls
  text("move:\tarrow keys <>", 20, 120); // Move controls
  text("rotate:\tr", 20, 140); // Rotate control
  text("lines:\tl", 20, 160); // Line toggle control
  if (connected) {
    fill(50, 255, 50); // Change color if connected
  }
  text("connect Line-Us:\tc", 20, 200); // Connect command
  fill(0, 150); // Reset fill color
  text("plot:\tp", 20, 220); // Plot command
  text("hide this:\th", 20, 240); // Hide UI command
}

// Plot the SVG onto the Line-Us drawing area
void plot() {
  println("plotting..."); // Print plotting status
  myLineUs = new LineUs(this, lineus_address); // Initialize Line-Us instance
  if (!rawpoints) {
    RG.setPolygonizerLength(resolution); // Set polygonizer resolution if not raw points
  }
  RPoint[][] points = grp.getPointsInPaths(); // Get points from paths in the shape
  delay(1000); // Delay for setup

  int x = 700;
  int y = 0;
  int last_x = 700;
  int last_y = 0;

  if (points != null) {
    for (RPoint[] pointArray : points) {
      for (RPoint point : pointArray) {
        x = int(map(point.x, 0, width, 650, 1775)); // Map x coordinate to drawing area
        y = int(map(point.y, 0, height, 1000, -1000)); // Map y coordinate to drawing area

        // Ensure point is within drawing area boundaries
        if (x >= LINE_MIN_X && x <= LINE_MAX_X && y >= LINE_MIN_Y && y <= LINE_MAX_Y) {
          myLineUs.g01(x, y, 0); // Send point to Line-Us device
          last_x = x; // Update last x position
          last_y = y; // Update last y position
          delay(100); // Delay between commands
        }
      }
      myLineUs.g01(last_x, last_y, 1000); // Move pen up
      delay(100); // Delay before next path
    }
  }
}

// Handle key press events for various functionalities
void keyPressed() {
  switch (key) {
    case 'o':
      selectInput("Select an SVG file:", "svgSelected"); // Open file dialog to select SVG
      break;
    case 'a':
      lineus_address = JOptionPane.showInputDialog("LineUs Address (lineus.local, 192.168.4.1, ...):"); // Prompt for Line-Us address
      break;
    case 'h':
      hide = !hide; // Toggle hiding the UI
      break;
    case 'p':
      lines = true; // Enable line drawing
      plot(); // Plot the SVG
      break;
    case 'r':
      grp.rotate(PI / 2.0, grp.getCenter()); // Rotate the SVG by 90 degrees
      break;
    case 'w':
      rawpoints = !rawpoints; // Toggle raw points mode
      break;
    case 'c':
      tryConnectLineUs(); // Attempt to connect to Line-Us
      break;
    case '-':
      grp.scale(0.95); // Scale down the SVG
      break;
    case '+':
      grp.scale(1.05); // Scale up the SVG
      break;
    case 'l':
      lines = !lines; // Toggle line drawing mode
      break;
  }
  handleArrowKeys(); // Handle arrow key presses for moving the SVG
  grp.draw(); // Redraw the SVG
}

// Attempt to connect to the Line-Us device
void tryConnectLineUs() {
  try {
    myLineUs = new LineUs(this, lineus_address); // Initialize Line-Us instance
    connected = true; // Set connection flag to true
  } catch (Exception e) {
    connected = false; // Set connection flag to false
    println("connection error"); // Print connection error message
  }
}

// Handle arrow key presses for moving the SVG
void handleArrowKeys() {
  int t = 2;
  if (keyCode == LEFT) {
    grp.translate(-t, 0); // Move SVG left
  } else if (keyCode == RIGHT) {
    grp.translate(t * 2, 0); // Move SVG right
  } else if (keyCode == UP) {
    grp.translate(0, -t); // Move SVG up
  } else if (keyCode == DOWN) {
    grp.translate(0, t); // Move SVG down
  }
}

// Callback function when an SVG file is selected
void svgSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel."); // Print cancellation message
  } else {
    println("User selected " + selection.getAbsolutePath()); // Print selected file path
    grp = RG.loadShape(selection.getAbsolutePath()); // Load selected SVG file
    println(grp.getWidth()); // Print width of the loaded shape
  }
}

// Functional interface for consuming arrays of RPoint
@FunctionalInterface
interface Consumer<T> {
  void accept(T t);
}

/*
           /\
          /  \
         /    \
        /______\
       |        |
       |  (o) (o)
       |    ||  
       |  \====/
       |    --
      /|       \
     / |       |
    /__|_______|
  /    |       |
 /     |       |
       |       |
      /         \
     /           \
    /             \

That's all folks!
*/

