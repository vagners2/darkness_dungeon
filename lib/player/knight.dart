import 'dart:async' as async;

import 'package:bonfire/bonfire.dart';
import 'package:darkness_dungeon/main.dart';
import 'package:darkness_dungeon/socket/socker_manager.dart';
import 'package:darkness_dungeon/util/functions.dart';
import 'package:darkness_dungeon/util/game_sprite_sheet.dart';
import 'package:darkness_dungeon/util/player_sprite_sheet.dart';
import 'package:darkness_dungeon/util/sounds.dart';
import 'package:flutter/material.dart';
import 'package:darkness_dungeon/util/extensions.dart';

class GamePlayer extends SimplePlayer with Lighting, ObjectCollision {
  final Vector2 initPosition;
  final int id;
  final String nick;
  double attack = 5;
  double stamina = 9999;
  double initSpeed = tileSize / 0.25;
  async.Timer _timerStamina;
  bool containKey = false;
  bool showObserveEnemy = false;

  TextPaint _textConfig;
  JoystickMoveDirectional currentDirection;
  String directionEvent = 'IDLE';

  GamePlayer({
    this.id,
    this.nick,
    this.initPosition,
  }) : super(
          animation: PlayerSpriteSheet.playerAnimations(),
          width: tileSize,
          height: tileSize,
          position: initPosition,
          life: 200,
          speed: tileSize / 0.25,
        ) {
    setupCollision(
      CollisionConfig(
        collisions: [
          CollisionArea.rectangle(
            size: Size(valueByTileSize(8), valueByTileSize(8)),
            align: Vector2(
              valueByTileSize(4),
              valueByTileSize(8),
            ),
          ),
        ],
      ),
    );

    setupLighting(
      LightingConfig(
        radius: width * 1.5,
        blurBorder: width,
        color: Colors.deepOrangeAccent.withOpacity(0.2),
      ),
    );

    _textConfig = TextPaint(
      config: TextPaintConfig(
        fontSize: tileSize / 4,
        color: Colors.white,
      ),
    );
  }

  @override
  void joystickChangeDirectional(JoystickDirectionalEvent event) {
    this.speed = initSpeed * event.intensity;

    if (event.directional != currentDirection && position != null) {
      currentDirection = event.directional;
      switch (currentDirection) {
        case JoystickMoveDirectional.MOVE_UP:
          directionEvent = 'UP';
          break;
        case JoystickMoveDirectional.MOVE_UP_LEFT:
          directionEvent = 'UP_LEFT';
          break;
        case JoystickMoveDirectional.MOVE_UP_RIGHT:
          directionEvent = 'UP_RIGHT';
          break;
        case JoystickMoveDirectional.MOVE_RIGHT:
          directionEvent = 'RIGHT';
          break;
        case JoystickMoveDirectional.MOVE_DOWN:
          directionEvent = 'DOWN';
          break;
        case JoystickMoveDirectional.MOVE_DOWN_RIGHT:
          directionEvent = 'DOWN_RIGHT';
          break;
        case JoystickMoveDirectional.MOVE_DOWN_LEFT:
          directionEvent = 'DOWN_LEFT';
          break;
        case JoystickMoveDirectional.MOVE_LEFT:
          directionEvent = 'LEFT';
          break;
        case JoystickMoveDirectional.IDLE:
          directionEvent = 'IDLE';
          break;
      }
      SocketManager().send(
        'message',
        {
          'action': 'MOVE',
          'time': DateTime.now().toIso8601String(),
          'data': {
            'player_id': 0,
            'direction': directionEvent,
            'position': {'x': (position.left / tileSize), 'y': (position.top / tileSize)},
          }
        },
      );
    }
    super.joystickChangeDirectional(event);
  }

  @override
  void joystickAction(JoystickActionEvent event) {
    print(event.id);

    //keyboard A
    if ((event.id == 0 || event.id == 32) && event.event == ActionEvent.DOWN) {
      actionAttack();
    }

    //keyboard C
    if ((event.id == 1 || event.id == 99) && event.event == ActionEvent.DOWN) {
      actionAttackRange();
    }
    super.joystickAction(event);
  }

  @override
  void die() {
    remove();
    gameRef.addGameComponent(
      GameDecoration.withSprite(
        Sprite.load('player/crypt.png'),
        position: Vector2(
          this.position.center.dx,
          this.position.center.dy,
        ),
        height: 30,
        width: 30,
      ),
    );
    super.die();
  }

  void actionAttack() {
    if (stamina < 15) {
      return;
    }

    SocketManager().send('message', {
      'action': 'ATTACK',
      'time': DateTime.now().toIso8601String(),
      'data': {
        'player_id': 0,
        'direction': this.lastDirection.getName(),
        'position': {'x': (position.left / tileSize), 'y': (position.top / tileSize)},
      }
    });

    Sounds.attackPlayerMelee();
    decrementStamina(15);
    this.simpleAttackMelee(
      damage: attack,
      animationBottom: PlayerSpriteSheet.attackEffectBottom(),
      animationLeft: PlayerSpriteSheet.attackEffectLeft(),
      animationRight: PlayerSpriteSheet.attackEffectRight(),
      animationTop: PlayerSpriteSheet.attackEffectTop(),
      height: tileSize,
      width: tileSize,
    );
  }

  void actionAttackRange() {
    if (stamina < 10) {
      return;
    }

    Sounds.attackRange();

    decrementStamina(10);
    this.simpleAttackRange(
      animationRight: GameSpriteSheet.fireBallAttackRight(),
      animationLeft: GameSpriteSheet.fireBallAttackLeft(),
      animationTop: GameSpriteSheet.fireBallAttackTop(),
      animationBottom: GameSpriteSheet.fireBallAttackBottom(),
      animationDestroy: GameSpriteSheet.fireBallExplosion(),
      width: tileSize * 0.65,
      height: tileSize * 0.65,
      damage: 10,
      speed: initSpeed * (tileSize / 32),
      destroy: () {
        Sounds.explosion();
      },
      collision: CollisionConfig(
        collisions: [
          CollisionArea.rectangle(size: Size(tileSize / 2, tileSize / 2)),
        ],
      ),
      lightingConfig: LightingConfig(
        radius: tileSize * 0.9,
        blurBorder: tileSize / 2,
        color: Colors.deepOrangeAccent.withOpacity(0.4),
      ),
    );
  }

  @override
  void update(double dt) {
    if (isDead) return;
    _verifyStamina();
    this.seeEnemy(
      radiusVision: tileSize * 6,
      notObserved: () {
        showObserveEnemy = false;
      },
      observed: (enemies) {
        if (showObserveEnemy) return;
        showObserveEnemy = true;
        _showEmote();
      },
    );
    super.update(dt);
  }

  @override
  void render(Canvas c) {
    _textConfig.render(
      c,
      nick,
      Vector2(
        position.left + ((width - (nick.length * (width / 13))) / 2),
        position.top - (tileSize / 3),
      ),
    );
    super.render(c);
  }

  void _verifyStamina() {
    if (_timerStamina == null) {
      _timerStamina = async.Timer(Duration(milliseconds: 150), () {
        _timerStamina = null;
      });
    } else {
      return;
    }

    stamina += 2;
    if (stamina > 100) {
      stamina = 100;
    }
  }

  void decrementStamina(int i) {
    // stamina -= i;
    // if (stamina < 0) {
    //   stamina = 0;
    // }
  }

  @override
  void receiveDamage(double damage, dynamic id) {
    if (isDead) return;

    SocketManager().send('message', {
      'action': 'RECEIVED_DAMAGE',
      'time': DateTime.now().toIso8601String(),
      'data': {
        'player_id': 0,
        'damage': damage,
        'player_id_attack': id,
      }
    });

    this.showDamage(
      damage,
      config: TextPaintConfig(
        fontSize: valueByTileSize(5),
        color: Colors.orange,
        fontFamily: 'Normal',
      ),
    );
    super.receiveDamage(damage, id);
  }

  void _showEmote({String emote = 'emote/emote_exclamacao.png'}) {
    gameRef.add(
      AnimatedFollowerObject(
        animation: SpriteAnimation.load(
          emote,
          SpriteAnimationData.sequenced(
            amount: 8,
            stepTime: 0.1,
            textureSize: Vector2(32, 32),
          ),
        ),
        target: this,
        positionFromTarget: Rect.fromLTWH(
          18,
          -6,
          tileSize / 2,
          tileSize / 2,
        ).toVector2Rect(),
      ),
    );
  }
}
