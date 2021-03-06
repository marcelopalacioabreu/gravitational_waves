import 'package:flame/flame.dart';
import 'package:flame_splash_screen/flame_splash_screen.dart';
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride, kIsWeb;
import 'package:flutter/material.dart';

import './game/assets/char.dart';
import './game/assets/tileset.dart';
import './game/game.dart';
import './screens/credits_screen.dart';
import './screens/game_screen.dart';
import './screens/join_scoreboard_screen.dart';
import './screens/options_screen.dart';
import './screens/scoreboard_screen.dart';
import './screens/skins_screen.dart';
import 'game/assets/poofs.dart';
import 'game/audio.dart';
import 'game/game_data.dart';
import 'game/preferences.dart';
import 'widgets/assets/ui_tileset.dart';

void main() async {
  Flame.initializeWidget();

  await Future.wait([
    Preferences.init(),
    GameData.init(),
  ]);

  await Audio.init();
  if (!kIsWeb) {
    if (debugDefaultTargetPlatformOverride != TargetPlatform.fuchsia) {
      await Flame.util.setLandscape();
    }
    await Flame.util.fullScreen();
  }
  Size size = await Flame.util.initialDimensions();
  await Future.wait([Tileset.init(), Char.init(), Poofs.init()]);

  await UITileset.load();

  Audio.menuMusic();

  MyGame game = MyGame(size);

  GameScreen mainMenu = GameScreen(game: game);
  OptionsScreen options = OptionsScreen(game: game);
  ScoreboardScreen scoreboard = ScoreboardScreen(game: game);
  JoinScoreboardScreen joinScoreboard = JoinScoreboardScreen(game: game);
  SkinsScreen skins = SkinsScreen(game: game);
  CreditsScreen credits = CreditsScreen(game: game);

  runApp(
    MaterialApp(
      routes: {
        '/': (BuildContext ctx) => FlameSplashScreen(
              theme: FlameSplashTheme.dark,
              showBefore: (BuildContext context) {
                return Image.asset(
                  'assets/images/fireslime-banner.png',
                  width: 400,
                );
              },
              onFinish: (BuildContext context) {
                game.prepare();
                Navigator.pushNamed(context, '/game');
              },
            ),
        '/options': (BuildContext ctx) => Scaffold(body: options),
        '/skins': (BuildContext ctx) => Scaffold(body: skins),
        '/scoreboard': (BuildContext ctx) => Scaffold(body: scoreboard),
        '/join-scoreboard': (BuildContext ctx) =>
            Scaffold(body: joinScoreboard),
        '/credits': (BuildContext ctx) => Scaffold(body: credits),
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
