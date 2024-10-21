import processing.serial.*;
import java.util.ArrayList;
import gifAnimation.*;
import ddf.minim.*;  // Import Minim audio library

Serial myPort;        // Serial port
String inString = ""; // Received serial data

// Audio management
Minim minim;
AudioPlayer startMusic;
AudioPlayer bgMusic;
AudioPlayer winMusic;
AudioPlayer itemSound;
AudioPlayer bombSound;

// Background image
PImage backgroundImage;

// Player 1 GIF animations
Gif player1UpGif;
Gif player1DownGif;
Gif player1LeftGif;
Gif player1RightGif;
Gif player1IdleGif;  // Optional: idle animation

// Player 2 GIF animations
Gif player2UpGif;
Gif player2DownGif;
Gif player2LeftGif;
Gif player2RightGif;
Gif player2IdleGif;  // Optional: idle animation

// Bomb GIF animation
Gif bombGif;

// Star GIF animation
Gif starGif;

// Wall images
PImage[] wallImages = new PImage[5];

// Speed shoes GIF animation
Gif speedShoesGif;

// Game variables
float player1X = 100, player1Y = 100;
float player2X = 700, player2Y = 500;
float playerSize = 35; // Player size
int tileSize = 40;     // Map grid size
boolean gameOver = false;     // Game over flag
boolean gameStarted = false;  // Game start flag
String winner = "";           // Record of the winner

ArrayList<Bomb> bombs = new ArrayList<Bomb>();         // List of bombs
ArrayList<Block> blocks = new ArrayList<Block>();      // List of blocks
ArrayList<Star> stars = new ArrayList<Star>();         // List of stars
ArrayList<SpeedShoes> speedShoesList = new ArrayList<SpeedShoes>(); // List of speed shoes

// Player 1 attributes
int player1BombPower = 1; // Initial bomb power
float player1Speed = 2;   // Player 1 movement speed
int player1BombsAvailable = 3; // Number of bombs available to Player 1

// Player 2 attributes
int player2BombPower = 1; // Initial bomb power
float player2Speed = 2;   // Player 2 movement speed
int player2BombsAvailable = 3; // Number of bombs available to Player 2

// Movement flag variables
boolean p1Up, p1Down, p1Left, p1Right;
boolean p2Up, p2Down, p2Left, p2Right;

// Player movement direction
String player1Direction = "down"; // Initial direction
String player2Direction = "down";

// Death handling variables
boolean player1Dead = false;
boolean player2Dead = false;
int gameOverDelay = 180; // Delay of 3 seconds after player death before ending the game

void setup() {
  size(800, 600);
  
  // Initialize background image
  backgroundImage = loadImage("bg.png");
  
  // Initialize serial communication
  println(Serial.list()); // Print available serial ports
  String portName = Serial.list()[0]; // Adjust the index based on your system
  myPort = new Serial(this, portName, 115200);
  myPort.clear(); // Clear serial buffer

  // Initialize audio
  minim = new Minim(this);
  startMusic = minim.loadFile("start.wav");
  bgMusic = minim.loadFile("bg.wav");
  winMusic = minim.loadFile("win.wav");
  itemSound = minim.loadFile("item.wav");
  bombSound = minim.loadFile("bomb.wav");

  // Play start music
  startMusic.play();

  // Load Player 1 GIF animations
  player1UpGif = new Gif(this, "fengw.gif");
  player1DownGif = new Gif(this, "fengs.gif");
  player1LeftGif = new Gif(this, "fenga.gif");
  player1RightGif = new Gif(this, "fengd.gif");
  player1IdleGif = new Gif(this, "fengs.gif"); // Optional

  player1UpGif.play();
  player1DownGif.play();
  player1LeftGif.play();
  player1RightGif.play();
  player1IdleGif.play();

  // Load Player 2 GIF animations
  player2UpGif = new Gif(this, "paow.gif");
  player2DownGif = new Gif(this, "paos.gif");
  player2LeftGif = new Gif(this, "paoa.gif");
  player2RightGif = new Gif(this, "paod.gif");
  player2IdleGif = new Gif(this, "paotu.gif"); // Optional

  player2UpGif.play();
  player2DownGif.play();
  player2LeftGif.play();
  player2RightGif.play();
  player2IdleGif.play();

  // Load bomb GIF animation
  bombGif = new Gif(this, "bomb.gif");
  bombGif.play();

  // Load star GIF animation
  starGif = new Gif(this, "star.gif");
  starGif.play();

  // Load wall images
  for (int i = 0; i < 5; i++) {
    wallImages[i] = loadImage("wall" + (i+1) + ".png");
  }

  // Load speed shoes GIF animation
  speedShoesGif = new Gif(this, "speed_shoes.gif");
  speedShoesGif.play();

  // Initialize blocks, stars, and speed shoes on the map
  initBlocks();
  initStars();
  initSpeedShoes();
}

void draw() {
  // Draw background image
  image(backgroundImage, 0, 0, width, height);
  
  if (!gameStarted) {
    drawStartButton();
  } else if (gameOver) {
    gameOverDelay--;
    if (gameOverDelay <= 0) {
      // Display winner and reset button
      drawRestartButton();
      fill(0);
      textSize(32);
      textAlign(CENTER);
      text(winner + " Wins!", width / 2, height / 2);
    } else {
      // Draw death animation
      drawDeathAnimation();
    }
  } else {
    if (!bgMusic.isPlaying()) {
      bgMusic.loop();  // Start background music
    }
    updatePlayerPositions(); // Update player positions
    checkStarCollisions();   // Check collisions with stars
    checkSpeedShoesCollisions(); // Check collisions with speed shoes
    drawGame();
  }

  // Check serial input
  while (myPort.available() > 0) {
    inString = myPort.readStringUntil('\n');
    if (inString != null) {
      inString = trim(inString);
      handleInput(inString);
    }
  }
}

// Handle input from Arduino
void handleInput(String input) {
  if (input.equals("UP_PRESS")) {
    p1Up = true;
  } else if (input.equals("UP_RELEASE")) {
    p1Up = false;
  } else if (input.equals("DOWN_PRESS")) {
    p1Down = true;
  } else if (input.equals("DOWN_RELEASE")) {
    p1Down = false;
  } else if (input.equals("LEFT_PRESS")) {
    p1Left = true;
  } else if (input.equals("LEFT_RELEASE")) {
    p1Left = false;
  } else if (input.equals("RIGHT_PRESS")) {
    p1Right = true;
  } else if (input.equals("RIGHT_RELEASE")) {
    p1Right = false;
  } else if (input.equals("BOMB_PRESS")) {
    // Place bomb
    placeBomb(1); // Player 1 places a bomb
  }
}

// Initialize blocks
void initBlocks() {
  blocks.clear();
  int numberOfBlocks = 50; // Set the number of walls as needed
  for (int i = 0; i < numberOfBlocks; i++) {
    float x, y;
    int attempts = 0;
    do {
      x = floor(random(width / tileSize)) * tileSize;
      y = floor(random(height / tileSize)) * tileSize;
      attempts++;
      if (attempts > 1000) break; // Prevent infinite loop
    } while (!isOutsidePlayerArea(x, y, player1X, player1Y, 3) ||
             !isOutsidePlayerArea(x, y, player2X, player2Y, 3));
    // Assign a random wall image to each block
    PImage randomWallImage = wallImages[(int)random(wallImages.length)];
    blocks.add(new Block(x, y, tileSize, tileSize, true, randomWallImage));
  }
}

// Initialize stars
void initStars() {
  stars.clear();
  int numberOfStars = 5; // Set the number of stars as needed
  for (int i = 0; i < numberOfStars; i++) {
    float x, y;
    int attempts = 0;
    do {
      x = floor(random(width / tileSize)) * tileSize;
      y = floor(random(height / tileSize)) * tileSize;
      attempts++;
      if (attempts > 1000) break; // Prevent infinite loop
    } while (!isOutsidePlayerArea(x, y, player1X, player1Y, 3) ||
             !isOutsidePlayerArea(x, y, player2X, player2Y, 3));
    stars.add(new Star(x, y));
  }
}

// Initialize speed shoes
void initSpeedShoes() {
  speedShoesList.clear();
  int numberOfShoes = 3; // Set the number of speed shoes as needed
  for (int i = 0; i < numberOfShoes; i++) {
    float x, y;
    int attempts = 0;
    do {
      x = floor(random(width / tileSize)) * tileSize;
      y = floor(random(height / tileSize)) * tileSize;
      attempts++;
      if (attempts > 1000) break; // Prevent infinite loop
    } while (!isOutsidePlayerArea(x, y, player1X, player1Y, 3) ||
             !isOutsidePlayerArea(x, y, player2X, player2Y, 3));
    speedShoesList.add(new SpeedShoes(x, y));
  }
}

// Determine if the position is outside the player's area
boolean isOutsidePlayerArea(float x, float y, float playerX, float playerY, int range) {
  int playerTileX = (int)(playerX / tileSize);
  int playerTileY = (int)(playerY / tileSize);
  int tileX = (int)(x / tileSize);
  int tileY = (int)(y / tileSize);
  int dx = abs(tileX - playerTileX);
  int dy = abs(tileY - playerTileY);
  return dx >= range || dy >= range;
}

// Update player positions
void updatePlayerPositions() {
  if (!player1Dead) {
    float newPlayer1X = player1X;
    float newPlayer1Y = player1Y;
  
    if (p1Up) {
      newPlayer1Y -= player1Speed;
      player1Direction = "up";
    }
    if (p1Down) {
      newPlayer1Y += player1Speed;
      player1Direction = "down";
    }
    if (p1Left) {
      newPlayer1X -= player1Speed;
      player1Direction = "left";
    }
    if (p1Right) {
      newPlayer1X += player1Speed;
      player1Direction = "right";
    }
  
    if (!isCollidingWithBlocks(newPlayer1X, newPlayer1Y)) {
      player1X = newPlayer1X;
      player1Y = newPlayer1Y;
    }
  }
  
  if (!player2Dead) {
    float newPlayer2X = player2X;
    float newPlayer2Y = player2Y;
  
    if (p2Up) {
      newPlayer2Y -= player2Speed;
      player2Direction = "up";
    }
    if (p2Down) {
      newPlayer2Y += player2Speed;
      player2Direction = "down";
    }
    if (p2Left) {
      newPlayer2X -= player2Speed;
      player2Direction = "left";
    }
    if (p2Right) {
      newPlayer2X += player2Speed;
      player2Direction = "right";
    }
  
    if (!isCollidingWithBlocks(newPlayer2X, newPlayer2Y)) {
      player2X = newPlayer2X;
      player2Y = newPlayer2Y;
    }
  }
}

// Check if player is colliding with blocks
boolean isCollidingWithBlocks(float px, float py) {
  for (Block block : blocks) {
    if (!block.destroyed && block.collides(px, py, playerSize)) {
      return true;
    }
  }
  return false;
}

// Check collisions with stars
void checkStarCollisions() {
  // Player 1
  for (int i = stars.size() - 1; i >= 0; i--) {
    Star s = stars.get(i);
    if (s.isCollected(player1X, player1Y, playerSize)) {
      stars.remove(i);
      player1BombPower = min(player1BombPower + 1, 5); // Increase Player 1's bomb power, max 5
      itemSound.rewind();
      itemSound.play(); // Play item sound effect
    }
  }
  // Player 2
  for (int i = stars.size() - 1; i >= 0; i--) {
    Star s = stars.get(i);
    if (s.isCollected(player2X, player2Y, playerSize)) {
      stars.remove(i);
      player2BombPower = min(player2BombPower + 1, 5); // Increase Player 2's bomb power, max 5
      itemSound.rewind();
      itemSound.play(); // Play item sound effect
    }
  }
}

// Check collisions with speed shoes
void checkSpeedShoesCollisions() {
  // Player 1
  for (int i = speedShoesList.size() - 1; i >= 0; i--) {
    SpeedShoes s = speedShoesList.get(i);
    if (s.isCollected(player1X, player1Y, playerSize)) {
      speedShoesList.remove(i);
      player1Speed += 0.5; // Increase Player 1's movement speed
      itemSound.rewind();
      itemSound.play(); // Play item sound effect
    }
  }
  // Player 2
  for (int i = speedShoesList.size() - 1; i >= 0; i--) {
    SpeedShoes s = speedShoesList.get(i);
    if (s.isCollected(player2X, player2Y, playerSize)) {
      speedShoesList.remove(i);
      player2Speed += 0.5; // Increase Player 2's movement speed
      itemSound.rewind();
      itemSound.play(); // Play item sound effect
    }
  }
}

// Draw the game scene
void drawGame() {
  // Draw blocks
  for (Block block : blocks) {
    if (!block.destroyed) {
      block.display();
    }
  }

  // Draw stars
  for (Star star : stars) {
    star.display();
  }

  // Draw speed shoes
  for (SpeedShoes shoes : speedShoesList) {
    shoes.display();
  }

  // Draw bombs
  for (int i = bombs.size() - 1; i >= 0; i--) {
    Bomb b = bombs.get(i);
    b.update();
    b.display();

    // Check if bomb is finished
    if (b.isFinished()) {
      bombs.remove(i);
      // Restore player's bomb count
      if (b.owner == 1) {
        player1BombsAvailable = min(player1BombsAvailable + 1, 3);
      } else if (b.owner == 2) {
        player2BombsAvailable = min(player2BombsAvailable + 1, 3);
      }
    }
  }

  // Draw Player 1
  if (!player1Dead) {
    Gif currentGif;
    switch (player1Direction) {
      case "up":
        currentGif = player1UpGif;
        break;
      case "down":
        currentGif = player1DownGif;
        break;
      case "left":
        currentGif = player1LeftGif;
        break;
      case "right":
        currentGif = player1RightGif;
        break;
      default:
        currentGif = player1IdleGif;
        break;
    }
    image(currentGif, player1X - playerSize / 2, player1Y - playerSize / 2, playerSize, playerSize);
  }

  // Draw Player 2
  if (!player2Dead) {
    Gif currentGif;
    switch (player2Direction) {
      case "up":
        currentGif = player2UpGif;
        break;
      case "down":
        currentGif = player2DownGif;
        break;
      case "left":
        currentGif = player2LeftGif;
        break;
      case "right":
        currentGif = player2RightGif;
        break;
      default:
        currentGif = player2IdleGif;
        break;
    }
    image(currentGif, player2X - playerSize / 2, player2Y - playerSize / 2, playerSize, playerSize);
  }

  // Check bomb effects on players
  for (Bomb b : bombs) {
    if (b.exploded) {
      if (b.isPlayerHit(player1X, player1Y) && !player1Dead) {
        winner = "Player 2"; // Player 1 is hit, Player 2 wins
        player1Dead = true;
        gameOver = true;
        handleWin();
      }
      if (b.isPlayerHit(player2X, player2Y) && !player2Dead) {
        winner = "Player 1"; // Player 2 is hit, Player 1 wins
        player2Dead = true;
        gameOver = true;
        handleWin();
      }
    }
  }

  // Constrain player movement within the screen
  player1X = constrain(player1X, playerSize / 2, width - playerSize / 2);
  player1Y = constrain(player1Y, playerSize / 2, height - playerSize / 2);
  player2X = constrain(player2X, playerSize / 2, width - playerSize / 2);
  player2Y = constrain(player2Y, playerSize / 2, height - playerSize / 2);
}

// Handle victory music
void handleWin() {
  bgMusic.pause(); // Pause background music
  winMusic.rewind();
  winMusic.play(); // Play victory music
}

// Draw death animation
void drawDeathAnimation() {
  if (player1Dead) {
    tint(255, 100); // Set transparency
    image(player1DownGif, player1X - playerSize / 2, player1Y - playerSize / 2, playerSize, playerSize);
    noTint(); // Reset transparency
  }
  if (player2Dead) {
    tint(255, 100);
    image(player2DownGif, player2X - playerSize / 2, player2Y - playerSize / 2, playerSize, playerSize);
    noTint();
  }
}

// Draw start button
void drawStartButton() {
  fill(0, 200, 0);
  rect(width / 2 - 50, height / 2 - 25, 100, 50);
  fill(255);
  textSize(20);
  textAlign(CENTER, CENTER);
  text("Start", width / 2, height / 2);
}

// Draw restart button
void drawRestartButton() {
  fill(200, 0, 0);
  rect(width / 2 - 50, height / 2 + 50, 100, 50);
  fill(255);
  textSize(20);
  textAlign(CENTER, CENTER);
  text("Restart", width / 2, height / 2 + 75);
}

// Mouse click event
void mousePressed() {
  if (!gameStarted) {
    // Click start button
    if (mouseX > width / 2 - 50 && mouseX < width / 2 + 50 && mouseY > height / 2 - 25 && mouseY < height / 2 + 25) {
      gameStarted = true;
      gameOver = false;
      startMusic.rewind();
      startMusic.play(); // Play start music
    }
  } else if (gameOver && gameOverDelay <= 0) {
    // Click restart button
    if (mouseX > width / 2 - 50 && mouseX < width / 2 + 50 && mouseY > height / 2 + 50 && mouseY < height / 2 + 100) {
      resetGame();
    }
  }
}

// Reset the game
void resetGame() {
  gameStarted = true;
  gameOver = false;
  winner = "";
  bombs.clear();
  stars.clear();
  speedShoesList.clear();
  initStars();   // Re-initialize stars
  initBlocks();  // Re-initialize blocks
  initSpeedShoes(); // Re-initialize speed shoes
  player1X = 100;
  player1Y = 100;
  player2X = 700;
  player2Y = 500;
  player1BombPower = 1; // Reset Player 1's bomb power
  player2BombPower = 1; // Reset Player 2's bomb power
  player1Speed = 2;     // Reset Player 1's speed
  player2Speed = 2;     // Reset Player 2's speed
  player1BombsAvailable = 3; // Reset Player 1's bomb count
  player2BombsAvailable = 3; // Reset Player 2's bomb count
  player1Dead = false;
  player2Dead = false;
  gameOverDelay = 180; // Reset game over delay
  player1Direction = "down"; // Reset player directions
  player2Direction = "down";
  bgMusic.rewind();
  bgMusic.loop(); // Replay background music
  winMusic.pause(); // Stop victory music
}

// Key press event
void keyPressed() {
  // Player 1 controls (for testing without Arduino)
  if (key == 'w') {
    p1Up = true;
    player1Direction = "up";
  }
  if (key == 's') {
    p1Down = true;
    player1Direction = "down";
  }
  if (key == 'a') {
    p1Left = true;
    player1Direction = "left";
  }
  if (key == 'd') {
    p1Right = true;
    player1Direction = "right";
  }
  if (key == 'f') {
    placeBomb(1); // Player 1 places a bomb
  }

  // Player 2 controls (arrow keys + Enter)
  if (keyCode == UP) {
    p2Up = true;
    player2Direction = "up";
  }
  if (keyCode == DOWN) {
    p2Down = true;
    player2Direction = "down";
  }
  if (keyCode == LEFT) {
    p2Left = true;
    player2Direction = "left";
  }
  if (keyCode == RIGHT) {
    p2Right = true;
    player2Direction = "right";
  }
  if (keyCode == ENTER) {
    placeBomb(2); // Player 2 places a bomb
  }
}

// Key release event
void keyReleased() {
  // Player 1 (for testing without Arduino)
  if (key == 'w') p1Up = false;
  if (key == 's') p1Down = false;
  if (key == 'a') p1Left = false;
  if (key == 'd') p1Right = false;

  // Player 2
  if (keyCode == UP) p2Up = false;
  if (keyCode == DOWN) p2Down = false;
  if (keyCode == LEFT) p2Left = false;
  if (keyCode == RIGHT) p2Right = false;
}

// Function to place a bomb
void placeBomb(int player) {
  if (player == 1 && player1BombsAvailable > 0) {
    bombs.add(new Bomb(player1X, player1Y, player1BombPower, 1)); // Player 1 places a bomb
    player1BombsAvailable--;
  } else if (player == 2 && player2BombsAvailable > 0) {
    bombs.add(new Bomb(player2X, player2Y, player2BombPower, 2)); // Player 2 places a bomb
    player2BombsAvailable--;
  }
}

// Bomb class
class Bomb {
  float x, y;
  int timer = 180; // 3-second countdown (60 frames per second)
  boolean exploded = false;
  ArrayList<Explosion> explosions = new ArrayList<Explosion>();
  int power; // Bomb power
  int owner; // Bomb owner, 1 or 2

  Bomb(float x, float y, int power, int owner) {
    this.x = floor(x / tileSize) * tileSize + tileSize / 2;
    this.y = floor(y / tileSize) * tileSize + tileSize / 2;
    this.power = power;
    this.owner = owner;
  }

  void update() {
    if (!exploded) {
      timer--;
      if (timer <= 0) {
        exploded = true;
        createExplosions();
        bombSound.rewind();
        bombSound.play(); // Play bomb explosion sound
      }
    } else {
      // Update explosion duration
      for (int i = explosions.size() - 1; i >= 0; i--) {
        Explosion exp = explosions.get(i);
        exp.update();
        if (exp.isDone()) {
          explosions.remove(i);
        }
      }
    }
  }

  void display() {
    if (!exploded) {
      image(bombGif, x - tileSize / 2, y - tileSize / 2, tileSize, tileSize);
    } else {
      for (Explosion exp : explosions) {
        exp.display();
      }
    }
  }

  void createExplosions() {
    explosions.add(new Explosion(x, y)); // Center explosion
    for (int dir = 0; dir < 4; dir++) {
      int dx = 0, dy = 0;
      if (dir == 0) dy = -1; // Up
      if (dir == 1) dy = 1;  // Down
      if (dir == 2) dx = -1; // Left
      if (dir == 3) dx = 1;  // Right
      for (int i = 1; i <= power; i++) {
        float nx = x + dx * i * tileSize;
        float ny = y + dy * i * tileSize;
        if (isBlocked(nx, ny)) break;
        explosions.add(new Explosion(nx, ny));
      }
    }
  }

  boolean isBlocked(float x, float y) {
    for (Block block : blocks) {
      if (!block.destroyed && block.contains(x, y)) {
        if (block.destructible) block.destroyed = true;
        return true;
      }
    }
    return false;
  }

  boolean isPlayerHit(float px, float py) {
    for (Explosion exp : explosions) {
      if (exp.contains(px, py)) {
        return true;
      }
    }
    return false;
  }

  // Check if all explosions are finished
  boolean isFinished() {
    return exploded && explosions.isEmpty();
  }
}

// Explosion class
class Explosion {
  float x, y;
  int duration = 30; // Explosion duration

  Explosion(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void update() {
    duration--;
  }

  boolean isDone() {
    return duration <= 0;
  }

  void display() {
    fill(255, 150, 0, 200);
    rectMode(CENTER);
    rect(x, y, tileSize, tileSize);
    rectMode(CORNER);
  }

  boolean contains(float px, float py) {
    float halfTile = tileSize / 2;
    return px > x - halfTile && px < x + halfTile &&
           py > y - halfTile && py < y + halfTile;
  }
}

// Block class
class Block {
  float x, y;
  float width, height;
  boolean destructible; // Whether the block can be destroyed
  boolean destroyed = false; // Whether the block has been destroyed
  PImage img; // Image of the block

  Block(float x, float y, float width, float height, boolean destructible, PImage img) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.destructible = destructible;
    this.img = img;
  }

  void display() {
    image(img, x, y, width, height); // Draw the block image
  }

  boolean collides(float px, float py, float size) {
    return (px + size / 2 > x && px - size / 2 < x + width &&
            py + size / 2 > y && py - size / 2 < y + height);
  }

  boolean contains(float x, float y) {
    return x >= this.x && x < this.x + width && y >= this.y && y < this.y + height;
  }
}

// Star class
class Star {
  float x, y;
  float size = 30; // Star size

  Star(float x, float y) {
    this.x = x + tileSize / 2;
    this.y = y + tileSize / 2;
  }

  void display() {
    image(starGif, x - size / 2, y - size / 2, size, size);
  }

  // Check if player has collected the star
  boolean isCollected(float px, float py, float playerSize) {
    float distance = dist(px, py, x, y);
    return distance < (size / 2 + playerSize / 2);
  }
}

// SpeedShoes class
class SpeedShoes {
  float x, y;
  float size = 30; // Speed shoes size

  SpeedShoes(float x, float y) {
    this.x = x + tileSize / 2;
    this.y = y + tileSize / 2;
  }

  void display() {
    image(speedShoesGif, x - size / 2, y - size / 2, size, size);
  }

  // Check if player has collected the speed shoes
  boolean isCollected(float px, float py, float playerSize) {
    float distance = dist(px, py, x, y);
    return distance < (size / 2 + playerSize / 2);
  }
}
