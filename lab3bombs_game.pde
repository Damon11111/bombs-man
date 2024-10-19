import processing.serial.*;
import java.util.ArrayList;
import gifAnimation.*;

Serial myPort;        // 串口
String inString = ""; // 接收到的串口数据

// 玩家1的 GIF 动画
Gif player1UpGif;
Gif player1DownGif;
Gif player1LeftGif;
Gif player1RightGif;
Gif player1IdleGif;  // 可选：静止时的动画

// 玩家2的 GIF 动画
Gif player2UpGif;
Gif player2DownGif;
Gif player2LeftGif;
Gif player2RightGif;
Gif player2IdleGif;  // 可选：静止时的动画

// 炸弹的 GIF 动画
Gif bombGif;

// 星星的 GIF 动画
Gif starGif;

// 墙的图片
PImage wallImg;

// 飞鞋的 GIF 动画
Gif speedShoesGif;

// 游戏变量
float player1X = 100, player1Y = 100;
float player2X = 700, player2Y = 500;
float playerSize = 40; // 玩家大小
int tileSize = 40;     // 地图网格大小
boolean gameOver = false;     // 游戏结束标志
boolean gameStarted = false;  // 游戏开始标志
String winner = "";           // 胜利者记录

ArrayList<Bomb> bombs = new ArrayList<Bomb>();         // 炸弹列表
ArrayList<Block> blocks = new ArrayList<Block>();      // 方块列表
ArrayList<Star> stars = new ArrayList<Star>();         // 星星列表
ArrayList<SpeedShoes> speedShoesList = new ArrayList<SpeedShoes>(); // 飞鞋列表

// 玩家1属性
int player1BombPower = 1; // 初始炸弹威力
float player1Speed = 2;   // 玩家1移动速度
int player1BombsAvailable = 3; // 玩家1可用的炸弹数量

// 玩家2属性
int player2BombPower = 1; // 初始炸弹威力
float player2Speed = 2;   // 玩家2移动速度
int player2BombsAvailable = 3; // 玩家2可用的炸弹数量

// 移动标志变量
boolean p1Up, p1Down, p1Left, p1Right;
boolean p2Up, p2Down, p2Left, p2Right;

// 玩家移动方向
String player1Direction = "down"; // 初始方向
String player2Direction = "down";

// 死亡处理变量
boolean player1Dead = false;
boolean player2Dead = false;
int gameOverDelay = 180; // 玩家死亡后延迟3秒再结束游戏

void setup() {
  size(800, 600);
  
  // 初始化串口通信
  println(Serial.list()); // 打印可用的串口
  String portName = Serial.list()[0]; // 根据您的系统调整索引
  myPort = new Serial(this, portName, 115200);
  myPort.clear(); // 清除串口缓冲区

  // 加载玩家1的 GIF 动画
  player1UpGif = new Gif(this, "fengw.gif");
  player1DownGif = new Gif(this, "fengs.gif");
  player1LeftGif = new Gif(this, "fenga.gif");
  player1RightGif = new Gif(this, "fengd.gif");
  player1IdleGif = new Gif(this, "fengs.gif"); // 可选

  player1UpGif.play();
  player1DownGif.play();
  player1LeftGif.play();
  player1RightGif.play();
  player1IdleGif.play();

  // 加载玩家2的 GIF 动画
  player2UpGif = new Gif(this, "paow.gif");
  player2DownGif = new Gif(this, "paos.gif");
  player2LeftGif = new Gif(this, "paoa.gif");
  player2RightGif = new Gif(this, "paod.gif");
  player2IdleGif = new Gif(this, "paotu.gif"); // 可选

  player2UpGif.play();
  player2DownGif.play();
  player2LeftGif.play();
  player2RightGif.play();
  player2IdleGif.play();

  // 加载炸弹的 GIF 动画
  bombGif = new Gif(this, "bomb.gif");
  bombGif.play();

  // 加载星星的 GIF 动画
  starGif = new Gif(this, "star.gif");
  starGif.play();

  // 加载墙的图片
  wallImg = loadImage("wall.png");

  // 加载飞鞋的 GIF 动画
  speedShoesGif = new Gif(this, "speed_shoes.gif");
  speedShoesGif.play();

  // 初始化地图上的方块、星星和飞鞋
  initBlocks();
  initStars();
  initSpeedShoes();
}

void draw() {
  background(51, 252, 255);
  
  if (!gameStarted) {
    drawStartButton();
  } else if (gameOver) {
    gameOverDelay--;
    if (gameOverDelay <= 0) {
      // 显示胜利者和重置按钮
      drawRestartButton();
      fill(0);
      textSize(32);
      textAlign(CENTER);
      text(winner + " Wins!", width / 2, height / 2);
    } else {
      // 在游戏结束前绘制死亡动画
      drawDeathAnimation();
    }
  } else {
    updatePlayerPositions(); // 更新玩家位置
    checkStarCollisions();   // 检查与星星的碰撞
    checkSpeedShoesCollisions(); // 检查与飞鞋的碰撞
    drawGame();
  }

  // 检查串口输入
  while (myPort.available() > 0) {
    inString = myPort.readStringUntil('\n');
    if (inString != null) {
      inString = trim(inString);
      handleInput(inString);
    }
  }
}

// 处理来自 Arduino 的串口输入
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
    // 放置炸弹
    placeBomb(1); // 玩家1放置炸弹
  }
}

// 初始化方块
void initBlocks() {
  blocks.clear();
  int numberOfBlocks = 50; // 根据需要设置墙壁数量
  for (int i = 0; i < numberOfBlocks; i++) {
    float x, y;
    int attempts = 0;
    do {
      x = floor(random(width / tileSize)) * tileSize;
      y = floor(random(height / tileSize)) * tileSize;
      attempts++;
      if (attempts > 1000) break; // 防止死循环
    } while (!isOutsidePlayerArea(x, y, player1X, player1Y, 3) ||
             !isOutsidePlayerArea(x, y, player2X, player2Y, 3));
    blocks.add(new Block(x, y, tileSize, tileSize, true));
  }
}

// 初始化星星
void initStars() {
  stars.clear();
  int numberOfStars = 5; // 根据需要设置星星数量
  for (int i = 0; i < numberOfStars; i++) {
    float x, y;
    int attempts = 0;
    do {
      x = floor(random(width / tileSize)) * tileSize;
      y = floor(random(height / tileSize)) * tileSize;
      attempts++;
      if (attempts > 1000) break; // 防止死循环
    } while (!isOutsidePlayerArea(x, y, player1X, player1Y, 3) ||
             !isOutsidePlayerArea(x, y, player2X, player2Y, 3));
    stars.add(new Star(x, y));
  }
}

// 初始化飞鞋
void initSpeedShoes() {
  speedShoesList.clear();
  int numberOfShoes = 3; // 根据需要设置飞鞋数量
  for (int i = 0; i < numberOfShoes; i++) {
    float x, y;
    int attempts = 0;
    do {
      x = floor(random(width / tileSize)) * tileSize;
      y = floor(random(height / tileSize)) * tileSize;
      attempts++;
      if (attempts > 1000) break; // 防止死循环
    } while (!isOutsidePlayerArea(x, y, player1X, player1Y, 3) ||
             !isOutsidePlayerArea(x, y, player2X, player2Y, 3));
    speedShoesList.add(new SpeedShoes(x, y));
  }
}

// 判断位置是否在玩家范围之外
boolean isOutsidePlayerArea(float x, float y, float playerX, float playerY, int range) {
  int playerTileX = (int)(playerX / tileSize);
  int playerTileY = (int)(playerY / tileSize);
  int tileX = (int)(x / tileSize);
  int tileY = (int)(y / tileSize);
  int dx = abs(tileX - playerTileX);
  int dy = abs(tileY - playerTileY);
  return dx >= range || dy >= range;
}

// 更新玩家位置
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

// 检查玩家是否与方块碰撞
boolean isCollidingWithBlocks(float px, float py) {
  for (Block block : blocks) {
    if (!block.destroyed && block.collides(px, py, playerSize)) {
      return true;
    }
  }
  return false;
}

// 检查与星星的碰撞
void checkStarCollisions() {
  // 玩家1
  for (int i = stars.size() - 1; i >= 0; i--) {
    Star s = stars.get(i);
    if (s.isCollected(player1X, player1Y, playerSize)) {
      stars.remove(i);
      player1BombPower = min(player1BombPower + 1, 5); // 增加玩家1的炸弹威力，最大为5
    }
  }
  // 玩家2
  for (int i = stars.size() - 1; i >= 0; i--) {
    Star s = stars.get(i);
    if (s.isCollected(player2X, player2Y, playerSize)) {
      stars.remove(i);
      player2BombPower = min(player2BombPower + 1, 5); // 增加玩家2的炸弹威力，最大为5
    }
  }
}

// 检查与飞鞋的碰撞
void checkSpeedShoesCollisions() {
  // 玩家1
  for (int i = speedShoesList.size() - 1; i >= 0; i--) {
    SpeedShoes s = speedShoesList.get(i);
    if (s.isCollected(player1X, player1Y, playerSize)) {
      speedShoesList.remove(i);
      player1Speed += 0.5; // 增加玩家1的移动速度
    }
  }
  // 玩家2
  for (int i = speedShoesList.size() - 1; i >= 0; i--) {
    SpeedShoes s = speedShoesList.get(i);
    if (s.isCollected(player2X, player2Y, playerSize)) {
      speedShoesList.remove(i);
      player2Speed += 0.5; // 增加玩家2的移动速度
    }
  }
}

// 绘制游戏场景
void drawGame() {
  // 绘制方块
  for (Block block : blocks) {
    if (!block.destroyed) {
      block.display();
    }
  }

  // 绘制星星
  for (Star star : stars) {
    star.display();
  }

  // 绘制飞鞋
  for (SpeedShoes shoes : speedShoesList) {
    shoes.display();
  }

  // 绘制炸弹
  for (int i = bombs.size() - 1; i >= 0; i--) {
    Bomb b = bombs.get(i);
    b.update();
    b.display();

    // 检查炸弹是否完成
    if (b.isFinished()) {
      bombs.remove(i);
      // 恢复玩家的炸弹数量
      if (b.owner == 1) {
        player1BombsAvailable = min(player1BombsAvailable + 1, 3);
      } else if (b.owner == 2) {
        player2BombsAvailable = min(player2BombsAvailable + 1, 3);
      }
    }
  }

  // 绘制玩家1
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

  // 绘制玩家2
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

  // 检查炸弹对玩家的影响
  for (Bomb b : bombs) {
    if (b.exploded) {
      if (b.isPlayerHit(player1X, player1Y) && !player1Dead) {
        winner = "Player 2"; // 玩家1被击中，玩家2胜利
        player1Dead = true;
        gameOver = true;
      }
      if (b.isPlayerHit(player2X, player2Y) && !player2Dead) {
        winner = "Player 1"; // 玩家2被击中，玩家1胜利
        player2Dead = true;
        gameOver = true;
      }
    }
  }

  // 限制玩家移动在屏幕内
  player1X = constrain(player1X, playerSize / 2, width - playerSize / 2);
  player1Y = constrain(player1Y, playerSize / 2, height - playerSize / 2);
  player2X = constrain(player2X, playerSize / 2, width - playerSize / 2);
  player2Y = constrain(player2Y, playerSize / 2, height - playerSize / 2);
}

// 绘制死亡动画
void drawDeathAnimation() {
  if (player1Dead) {
    tint(255, 100); // 设置透明度
    image(player1DownGif, player1X - playerSize / 2, player1Y - playerSize / 2, playerSize, playerSize);
    noTint(); // 重置透明度
  }
  if (player2Dead) {
    tint(255, 100);
    image(player2DownGif, player2X - playerSize / 2, player2Y - playerSize / 2, playerSize, playerSize);
    noTint();
  }
}

// 绘制开始按钮
void drawStartButton() {
  fill(0, 200, 0);
  rect(width / 2 - 50, height / 2 - 25, 100, 50);
  fill(255);
  textSize(20);
  textAlign(CENTER, CENTER);
  text("Start", width / 2, height / 2);
}

// 绘制重启按钮
void drawRestartButton() {
  fill(200, 0, 0);
  rect(width / 2 - 50, height / 2 + 50, 100, 50);
  fill(255);
  textSize(20);
  textAlign(CENTER, CENTER);
  text("Restart", width / 2, height / 2 + 75);
}

// 鼠标点击事件
void mousePressed() {
  if (!gameStarted) {
    // 点击开始按钮
    if (mouseX > width / 2 - 50 && mouseX < width / 2 + 50 && mouseY > height / 2 - 25 && mouseY < height / 2 + 25) {
      gameStarted = true;
      gameOver = false;
    }
  } else if (gameOver && gameOverDelay <= 0) {
    // 点击重启按钮
    if (mouseX > width / 2 - 50 && mouseX < width / 2 + 50 && mouseY > height / 2 + 50 && mouseY < height / 2 + 100) {
      resetGame();
    }
  }
}

// 重置游戏
void resetGame() {
  gameStarted = true;
  gameOver = false;
  winner = "";
  bombs.clear();
  stars.clear();
  speedShoesList.clear();
  initStars();   // 重新初始化星星
  initBlocks();  // 重新初始化方块
  initSpeedShoes(); // 重新初始化飞鞋
  player1X = 100;
  player1Y = 100;
  player2X = 700;
  player2Y = 500;
  player1BombPower = 1; // 重置玩家1的炸弹威力
  player2BombPower = 1; // 重置玩家2的炸弹威力
  player1Speed = 2;     // 重置玩家1的速度
  player2Speed = 2;     // 重置玩家2的速度
  player1BombsAvailable = 3; // 重置玩家1的炸弹数量
  player2BombsAvailable = 3; // 重置玩家2的炸弹数量
  player1Dead = false;
  player2Dead = false;
  gameOverDelay = 180; // 重置游戏结束延迟
  player1Direction = "down"; // 重置玩家方向
  player2Direction = "down";
}

// 键盘按下事件
void keyPressed() {
  // 玩家1控制（用于没有 Arduino 时的测试）
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
    placeBomb(1); // 玩家1放置炸弹
  }

  // 玩家2控制（方向键 + Enter）
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
    placeBomb(2); // 玩家2放置炸弹
  }
}

// 键盘释放事件
void keyReleased() {
  // 玩家1（用于没有 Arduino 时的测试）
  if (key == 'w') p1Up = false;
  if (key == 's') p1Down = false;
  if (key == 'a') p1Left = false;
  if (key == 'd') p1Right = false;

  // 玩家2
  if (keyCode == UP) p2Up = false;
  if (keyCode == DOWN) p2Down = false;
  if (keyCode == LEFT) p2Left = false;
  if (keyCode == RIGHT) p2Right = false;
}

// 放置炸弹函数
void placeBomb(int player) {
  if (player == 1 && player1BombsAvailable > 0) {
    bombs.add(new Bomb(player1X, player1Y, player1BombPower, 1)); // 玩家1放置炸弹
    player1BombsAvailable--;
  } else if (player == 2 && player2BombsAvailable > 0) {
    bombs.add(new Bomb(player2X, player2Y, player2BombPower, 2)); // 玩家2放置炸弹
    player2BombsAvailable--;
  }
}

// 炸弹类
class Bomb {
  float x, y;
  int timer = 180; // 3秒倒计时（60帧/秒）
  boolean exploded = false;
  ArrayList<Explosion> explosions = new ArrayList<Explosion>();
  int power; // 炸弹威力
  int owner; // 炸弹的所属玩家，1 或 2

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
      }
    } else {
      // 更新爆炸的持续时间
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
    explosions.add(new Explosion(x, y)); // 中心爆炸
    for (int dir = 0; dir < 4; dir++) {
      int dx = 0, dy = 0;
      if (dir == 0) dy = -1; // 上
      if (dir == 1) dy = 1;  // 下
      if (dir == 2) dx = -1; // 左
      if (dir == 3) dx = 1;  // 右
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

  // 检查所有爆炸是否结束
  boolean isFinished() {
    return exploded && explosions.isEmpty();
  }
}

// 爆炸类
class Explosion {
  float x, y;
  int duration = 30; // 爆炸持续时间

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

// 方块类
class Block {
  float x, y;
  float width, height;
  boolean destructible; // 是否可被破坏
  boolean destroyed = false; // 是否已被破坏

  Block(float x, float y, float width, float height, boolean destructible) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.destructible = destructible;
  }

  void display() {
    image(wallImg, x, y, width, height); // 绘制墙的图片
  }

  boolean collides(float px, float py, float size) {
    return (px + size / 2 > x && px - size / 2 < x + width &&
            py + size / 2 > y && py - size / 2 < y + height);
  }

  boolean contains(float x, float y) {
    return x >= this.x && x < this.x + width && y >= this.y && y < this.y + height;
  }
}

// 星星类
class Star {
  float x, y;
  float size = 30; // 星星大小

  Star(float x, float y) {
    this.x = x + tileSize / 2;
    this.y = y + tileSize / 2;
  }

  void display() {
    image(starGif, x - size / 2, y - size / 2, size, size);
  }

  // 检查玩家是否收集到星星
  boolean isCollected(float px, float py, float playerSize) {
    float distance = dist(px, py, x, y);
    return distance < (size / 2 + playerSize / 2);
  }
}

// 飞鞋类
class SpeedShoes {
  float x, y;
  float size = 30; // 飞鞋大小

  SpeedShoes(float x, float y) {
    this.x = x + tileSize / 2;
    this.y = y + tileSize / 2;
  }

  void display() {
    image(speedShoesGif, x - size / 2, y - size / 2, size, size);
  }

  // 检查玩家是否收集到飞鞋
  boolean isCollected(float px, float py, float playerSize) {
    float distance = dist(px, py, x, y);
    return distance < (size / 2 + playerSize / 2);
  }
}
