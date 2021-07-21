import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:darkness_dungeon/decoration/door.dart';
import 'package:darkness_dungeon/decoration/key.dart';
import 'package:darkness_dungeon/decoration/potion_life.dart';
import 'package:darkness_dungeon/decoration/spikes.dart';
import 'package:darkness_dungeon/decoration/torch.dart';
import 'package:darkness_dungeon/enemies/boss.dart';
import 'package:darkness_dungeon/enemies/goblin.dart';
import 'package:darkness_dungeon/enemies/imp.dart';
import 'package:darkness_dungeon/enemies/mini_boss.dart';
import 'package:darkness_dungeon/interface/knight_interface.dart';
import 'package:darkness_dungeon/main.dart';
import 'package:darkness_dungeon/npc/kid.dart';
import 'package:darkness_dungeon/npc/wizard_npc.dart';
import 'package:darkness_dungeon/player/knight.dart';
import 'package:darkness_dungeon/player/remote_player.dart';
import 'package:darkness_dungeon/socket/socker_manager.dart';
import 'package:darkness_dungeon/util/dialogs.dart';
import 'package:darkness_dungeon/util/sounds.dart';
import 'package:flutter/material.dart';

class GameMap extends StatefulWidget {
  const GameMap({Key key}) : super(key: key);

  @override
  _GameMapState createState() => _GameMapState();
}

class _GameMapState extends State<GameMap> with WidgetsBindingObserver implements GameListener {
  GameController _controller;

  String nick;
  String statusServer = "CONNECTING";
  bool loading = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _controller = GameController()..setListener(this);
    Sounds.playBackgroundSound();

    SocketManager().listenConnection((_) {
      setState(() {
        statusServer = 'CONNECTED';
      });
    });

    SocketManager().listenError((_) {
      setState(() {
        statusServer = 'ERROR: $_';
      });
    });

    SocketManager().listen('message', _listen);

    super.initState();

    goGame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        Sounds.resumeBackgroundSound();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        Sounds.pauseBackgroundSound();
        break;
      case AppLifecycleState.detached:
        Sounds.stopBackgroundSound();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Sounds.stopBackgroundSound();
    SocketManager().close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size sizeScreen = MediaQuery.of(context).size;
    tileSize = max(sizeScreen.height, sizeScreen.width) / 15;

    print(tileSize);

    return Material(
      color: Colors.transparent,
      child: BonfireTiledWidget(
        constructionMode: true,
        showCollisionArea: true,
        gameController: _controller,
        joystick: Joystick(
          keyboardEnable: true,
          directional: JoystickDirectional(
            spriteBackgroundDirectional: Sprite.load('joystick_background.png'),
            spriteKnobDirectional: Sprite.load('joystick_knob.png'),
            size: 100,
            isFixed: false,
          ),
          actions: [
            JoystickAction(
              actionId: 0,
              sprite: Sprite.load('joystick_atack.png'),
              spritePressed: Sprite.load('joystick_atack_selected.png'),
              size: 80,
              margin: EdgeInsets.only(bottom: 50, right: 50),
            ),
            JoystickAction(
              actionId: 1,
              sprite: Sprite.load('joystick_atack_range.png'),
              spritePressed: Sprite.load('joystick_atack_range_selected.png'),
              size: 50,
              margin: EdgeInsets.only(bottom: 50, right: 160),
            )
          ],
        ),
        player: GamePlayer(
          id: 1,
          nick: 'Player One',
          initPosition: Vector2(4 * tileSize, 4 * tileSize),
        ),
        map: TiledWorldMap(
          'tiled/map_01/map.json',
          forceTileSize: Size(tileSize, tileSize),
          objectsBuilder: {
            // 'door': (p) => Door(p.position, p.size),
            // 'torch': (p) => Torch(p.position),
            // 'potion': (p) => PotionLife(p.position, 30),
            // 'wizard': (p) => WizardNPC(p.position),
            // 'spikes': (p) => Spikes(p.position),
            // 'key': (p) => DoorKey(p.position),
            // 'kid': (p) => Kid(p.position),
            // 'boss': (p) => Boss(p.position),
            // 'goblin': (p) => Goblin(p.position),
            // 'imp': (p) => Imp(p.position),
            // 'mini_boss': (p) => MiniBoss(p.position),
            // 'torch_empty': (p) => Torch(p.position, empty: true),
          },
        ),
        interface: KnightInterface(),
        // lightingColorGame: Colors.black.withOpacity(0.6),
        background: BackgroundColorGame(Colors.grey[900]),
        progress: Center(
          child: Text(
            "Loading...",
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Normal',
              fontSize: 20.0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void changeCountLiveEnemies(int count) {}

  @override
  void updateGame() {
    if (_controller.player != null && _controller.player.isDead) {}
  }

  void goGame() {
    if (SocketManager().connected) {
      setState(() {
        loading = true;
      });
      _joinGame();
    } else {
      print('Server não conectado.');
    }
  }

  void _joinGame() {
    SocketManager().send('message', {
      'action': 'CREATE',
      'data': {'nick': nick, 'skin': 0}
    });
  }

  void _listen(data) {
    if (data is Map && data['action'] == 'PLAYER_JOIN') {
      setState(() {
        loading = false;
      });
      if (data['data']['nick'] == nick) {
        SocketManager().cleanListeners();

        print(data['data']['playersON']);
        print(data['data']['id']);

        var _pos = Vector2(
          double.parse(data['data']['position']['x'].toString()),
          double.parse(data['data']['position']['y'].toString()),
        );

        print(_pos);
      }
    }
  }

  void _setupSocketControl() {
    SocketManager().listen('message', (data) {
      if (data['action'] == 'PLAYER_JOIN' && data['data']['id'] != 0) {
        _addRemotePlayer(data['data']);
      }
    });
  }

  void _addRemotePlayer(Map data) {
    Vector2 personPosition = Vector2(
      double.parse(data['position']['x'].toString()) * tileSize,
      double.parse(data['position']['y'].toString()) * tileSize,
    );

    var enemy = RemotePlayer(
      data['id'],
      data['nick'],
      personPosition,
      // _getSprite(data['skin'] ?? 0),
      SocketManager(),
    );
    if (data['life'] != null) {
      enemy.life = double.parse(data['life'].toString()) ?? 0.0;
    }
    _controller.addGameComponent(enemy);

    // _controller.addGameComponent(
    //   AnimatedObjectOnce(
    //     animation: SpriteSheetHero.smokeExplosion,
    //     position: Rect.fromLTRB(
    //       personPosition.x,
    //       personPosition.y,
    //       32,
    //       32,
    //     ).toVector2Rect(),
    //   ),
    // );
  }
}
