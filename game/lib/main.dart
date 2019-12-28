import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import 'package:flame_splash_screen/flame_splash_screen.dart';
import 'package:gravitational_waves/screens/options_screen.dart';

import './game/assets/tileset.dart';
import './game/assets/char.dart';
import './game/game.dart';

import './screens/game_screen.dart';
import 'game/audio.dart';
import 'game/preferences.dart';

void main() async {
  Flame.initializeWidget();

  await Preferences.init();
  await Audio.init();
  if (debugDefaultTargetPlatformOverride != TargetPlatform.fuchsia) {
    await Flame.util.setLandscape();
  }
  Size size = await Flame.util.initialDimensions();
  await Future.wait([Tileset.init(), Char.init()]);

  MyGame game = MyGame(size);

  GameScreen mainMenu = GameScreen(game: game);
  OptionsScreen options = OptionsScreen(game: game);

  runApp(
    MaterialApp(
      routes: {
        '/': (BuildContext ctx) => FlameSplashScreen(
              theme: FlameSplashTheme.dark,
              showBefore: (BuildContext context) {
                return Image.asset("assets/images/fireslime-banner.png",
                    width: 400);
              },
              onFinish: (BuildContext context) {
                game.prepare();
                Navigator.pushNamed(context, '/game');
              },
            ),
        '/options': (BuildContext ctx) => Scaffold(body: options),
        '/game': (BuildContext ctx) => Scaffold(
              body: WillPopScope(
                onWillPop: () async {
                  game.pause();
                  return false;
                },
                child: mainMenu,
              ),
            ),
      },
    ),
  );
}
