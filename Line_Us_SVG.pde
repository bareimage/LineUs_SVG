// Processing 4.3 Version
// v0.2
// Creative Commons
// Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// https://creativecommons.org/licenses/by-sa/4.0/
// Original by Michael Zoellner, 2018
// Updated for Processing 4.3, 2024
// Current branch by Igor Molochevski, 2024
// Things to-do
// - Add Error checking if host not found
// - Redo segmentation to only segment non linear pathes

import geomerative.*;
import processing.net.*;
import java.net.*;
import javax.swing.JOptionPane;

RShape grp;
boolean lines;
boolean rawpoints;
boolean connected;
boolean hide = false;
float resolution = 5;

String lineus_address = "lineus.local"; //"192.168.4.1";

LineUs myLineUs;

// App Drawing Area
// x: 650 - 1775
// y: 1000 - -1000
// z: 0 - 1000
// 100 units = 5mm

final int LINE_MIN_X = 650;
final int LINE_MAX_X = 1775;
final int LINE_MIN_Y = -1000;
final int LINE_MAX_Y = 1000;

final int LW = 1775 - 650;
final int LH = 2000;

void settings() {
  size(LW/2, LH/2);
  smooth();
  RG.init(this);
  grp = RG.loadShape("venn_.svg");
}



void draw() {
  background(255);

  if (lines) {
    RG.setPolygonizer(RG.UNIFORMLENGTH);

    if (mousePressed) {
      resolution = map(mouseY, 0, height, 3, 200);
    }

    if (!rawpoints) {
      RG.setPolygonizerLength(resolution);
    }
    RPoint[][] points = grp.getPointsInPaths();

    // If there are any points
    if (points != null) {
      for (int j = 0; j < points.length; j++) {
        noFill();
        stroke(100);
        beginShape();
        for (int i = 0; i < points[j].length; i++) {
          vertex(points[j][i].x, points[j][i].y);
        }
        endShape(CLOSE);

        noFill();
        stroke(0);
        for (int i = 0; i < points[j].length; i++) {
          circle(points[j][i].x, points[j][i].y, 5);
        }
      }
    }
  } else {
    grp.draw();
  }

  // interface
  if (!hide) {
    fill(0, 150);
    text("Line-Us SVG Plotter", 20, 20);
    text("---------------------", 20, 40);
    text("address:\t" + lineus_address + " (a)", 20, 60);
    text("open SVG:\to", 20, 80);
    text("zoom:\t+/-", 20, 100);
    text("move:\tarrow keys <>", 20, 120);
    text("rotate:\tr", 20, 140);
    text("lines:\tl", 20, 160);
    text("resolution:\tpress mouse / move", 20, 180);
    if (connected) {
      fill(50, 255, 50);
    }
    text("connect Line-Us:\tc", 20, 200);
    fill(0, 150);
    text("plot:\tp", 20, 220);
    text("hide this:\th", 20, 240);
  }
}

void plot() {
  println("plotting...");

  myLineUs = new LineUs(this, lineus_address);

  if (!rawpoints) {
    RG.setPolygonizerLength(resolution);
  }
  RPoint[][] points = grp.getPointsInPaths();

  delay(1000);

  // x: 650 - 1775
  // y: 1000 - -1000
  // If there are any points
  int x = 700;
  int y = 0;
  int last_x = 700;
  int last_y = 0;

  if (points != null) {
    for (int j = 0; j < points.length; j++) {
      for (int i = 0; i < points[j].length; i++) {
        x = int(map(points[j][i].x, 0, width, 650, 1775));
        y = int(map(points[j][i].y, 0, height, 1000, -1000));

        // safety check. there could be svg elements outside the drawing area crashing the robot
        if (x >= LINE_MIN_X && x <= LINE_MAX_X && y >= LINE_MIN_Y && y <= LINE_MAX_Y) {
          myLineUs.g01(x, y, 0);
          last_x = x;
          last_y = y;
          delay(100);
        }
      }
      myLineUs.g01(last_x, last_y, 1000);
      delay(100);
    }
  }
}

void keyPressed() {
  int t = 2;

  switch (key) {
    case 'o':
      selectInput("Select an SVG file:", "svgSelected");
      break;
    case 'a':
      lineus_address = JOptionPane.showInputDialog("LineUs Address (lineus.local, 192.168.4.1, ...):");
      break;
    case 'h':
      hide = !hide;
      break;
    case 'p':
      lines = true;
      plot();
      break;
    case 'r':
      grp.rotate(PI/2.0, grp.getCenter());
      break;
    case 'w':
      rawpoints = !rawpoints;
      break;
    case 'c':
      try {
        myLineUs = new LineUs(this, lineus_address);
        connected = true;
      } catch (Exception e) {
        connected = false;
        println("connection error");
      }
      break;
    case '-':
      grp.scale(0.95);
      break;
    case '+':
      grp.scale(1.05);
      break;
    case 'l':
      lines = !lines;
      break;
  }

  if (keyCode == LEFT) {
    grp.translate(-t, 0);
  } else if (keyCode == RIGHT) {
    grp.translate(t*2, 0);
  } else if (keyCode == UP) {
    grp.translate(0, -t);
  } else if (keyCode == DOWN) {
    grp.translate(0, t);
  }

  grp.draw();
}

void svgSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    grp = RG.loadShape(selection.getAbsolutePath());
    println(grp.getWidth());
  }
}
