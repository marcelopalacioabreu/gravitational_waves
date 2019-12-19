import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/anchor.dart';
import 'package:flame/game.dart';
import 'package:flame/position.dart';
import 'package:flutter/gestures.dart';

import 'rotation_manager.dart';
import 'components/background.dart';
import 'components/planet.dart';
import 'components/player.dart';
import 'components/stars.dart';
import 'components/wall.dart';
import 'pages/game_over_page.dart';
import 'pages/page.dart';
import 'palette.dart';
import 'spawner.dart';
import 'util.dart';

class MyGame extends BaseGame {

  static Spawner planetSpawner = Spawner(0.0001);

  RotationManager rotationManager;
  double lastGeneratedX;
  Player player;
  double gravity;

  Size rawSize, scaledSize;
  Position resizeOffset = Position.empty();
  double scale = 2.0;

  bool sleeping;

  Page currentPage;

  MyGame(Size size) {
    resize(size);
  }

  void prepare() {
    sleeping = true;
    currentPage = null;

    gravity = GRAVITY_ACC;
    lastGeneratedX = -CHUNCK_SIZE / 2.0 * BLOCK_SIZE;

    components.clear();
    _addBg(Background.plains(lastGeneratedX));

    add(player = Player());
    add(Wall());
    add(Stars(size));
    fixCamera();
    rotationManager = RotationManager();
  }

  void start() {
    sleeping = false;
    generateNextChunck();
  }

  void restart() {
    prepare();
    start();
  }

  void generateNextChunck() {
    while (lastGeneratedX < player.x + size.width) {
      _addBg(Background(lastGeneratedX));
    }
  }

  void _addBg(Background bg) {
    add(bg);
    lastGeneratedX = bg.endX;
  }

  void recalculateScaleFactor(Size rawSize) {
    int blocksWidth = 32;
    int blocksHeight = 18;

    double width = blocksWidth * BLOCK_SIZE;
    double height = blocksHeight * BLOCK_SIZE;

    double scaleX = rawSize.width / width;
    double scaleY = rawSize.height / height;

    this.scale = math.min(scaleX, scaleY);

    this.rawSize = rawSize;
    this.size = Size(width, height);
    this.scaledSize = Size(scale * width, scale * height);
    this.resizeOffset = Position((rawSize.width - scaledSize.width) / 2, (rawSize.height - scaledSize.height) / 2);
  }

  int get score => player.x ~/ 100;

  @override
  void resize(Size rawSize) {
    recalculateScaleFactor(rawSize);
    super.resize(size);
  }

  @override
  void update(double t) {
    if (currentPage != null) {
      return;
    }

    super.update(t);
    fixCamera();

    if (!sleeping) {
      maybeGeneratePlanet(t);
      generateNextChunck();
      rotationManager?.tick(t);
    }
  }

  void maybeGeneratePlanet(double dt) {
    planetSpawner.maybeSpawn(dt, () => addLater(Planet(size)));
  }

  void fixCamera() {
    camera.x = player.x - size.width / 3;
  }

  @override
  void render(Canvas c) {
    c.save();
    c.translate(resizeOffset.x, resizeOffset.y);
    c.scale(scale, scale);

    c.drawRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height), Palette.background.paint);
    renderGame(c);

    c.restore();
    c.drawRect(Rect.fromLTWH(0.0, 0.0, rawSize.width, resizeOffset.y), Palette.black.paint);
    c.drawRect(Rect.fromLTWH(0.0, resizeOffset.y + scaledSize.height, rawSize.width, resizeOffset.y), Palette.black.paint);
    c.drawRect(Rect.fromLTWH(0.0, 0.0, resizeOffset.x, rawSize.height), Palette.black.paint);
    c.drawRect(Rect.fromLTWH(resizeOffset.x + scaledSize.width, 0.0, resizeOffset.x, rawSize.height), Palette.black.paint);
  }

  void renderGame(Canvas canvas) {
    if (currentPage?.fullScreen != true) {
      renderComponents(canvas);
      renderLives(canvas);
      renderScore(canvas);
    }
    currentPage?.render(canvas);
  }

  void renderComponents(Canvas canvas) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(rotationManager.angle);
      canvas.translate(-size.width / 2, -size.height / 2);
      super.render(canvas);
      canvas.restore();
  }

  void renderLives(Canvas canvas) {
    final p = Position(size.width - 10, size.height - 10);
    final text = '${player.livesLeft} hearts';
    Fonts.livesCounter.render(canvas, text, p, anchor: Anchor.bottomRight);
  }

  void renderScore(Canvas canvas) {
    final p = Position(10, size.height - 10);
    final text = '$score m';
    Fonts.scoreCounter.render(canvas, text, p, anchor: Anchor.bottomLeft);
  }

  Position fixScaleFor(Position rawP) {
    return rawP.clone().minus(resizeOffset).div(scale);
  }

  @override
  void onTapUp(TapUpDetails details) {
    if (currentPage != null) {
      currentPage.tap(fixScaleFor(Position.fromOffset(details.globalPosition)));
      return;
    }
    if (sleeping) {
      return;
    }
    super.onTapUp(details);
    gravity *= -1;
  }

  void pause() {}

  void gameOver() {
    currentPage = GameOverPage(this);
  }
}