import 'dart:ui';

import 'package:bonfire/bonfire.dart';
import 'package:darkness_dungeon/main.dart';
import 'package:darkness_dungeon/socket/server_remote_player_control.dart';
import 'package:darkness_dungeon/socket/socker_manager.dart';
import 'package:darkness_dungeon/util/player_sprite_sheet.dart';
import 'package:flutter/material.dart';
import 'package:darkness_dungeon/util/extensions.dart';

class RemotePlayer extends SimpleEnemy with ServerRemotePlayerControl, ObjectCollision {
  final int id;
  final String nick;
  TextPaint _textConfig;

  RemotePlayer(this.id, this.nick, Vector2 initPosition, SocketManager socketManager)
      : super(
          animation: PlayerSpriteSheet.playerAnimations(),
          position: initPosition,
          width: tileSize * 1.5,
          height: tileSize * 1.5,
          life: 100,
          speed: tileSize * 3,
        ) {
    setupCollision(
      CollisionConfig(
        collisions: [
          CollisionArea.rectangle(
            size: Size((tileSize * 0.5), (tileSize * 0.5)),
            align: Vector2((tileSize * 0.9) / 2, tileSize),
          ),
        ],
      ),
    );
    _textConfig = TextPaint(
      config: TextPaintConfig(
        fontSize: tileSize / 4,
        color: Colors.white,
      ),
    );
    setupServerPlayerControl(socketManager, id);
  }

  @override
  void render(Canvas canvas) {
    if (this.isVisibleInCamera()) {
      _renderNickName(canvas);
      this.drawDefaultLifeBar(
        canvas,
        // height: 4,
        // borderWidth: 2,
        // borderRadius: BorderRadius.circular(2),
      );
    }
    super.render(canvas);
  }

  @override
  void die() {
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
    remove();
    super.die();
  }

  void _renderNickName(Canvas canvas) {
    _textConfig.render(
      canvas,
      nick,
      Vector2(
        position.left + ((width - (nick.length * (width / 13))) / 2),
        position.top - 20,
      ),
    );
  }

  @override
  void serverAttack(String direction) {
    this.simpleAttackMelee(
      damage: 15,
      attackEffectBottomAnim: PlayerSpriteSheet.attackEffectBottom(),
      attackEffectLeftAnim: PlayerSpriteSheet.attackEffectLeft(),
      attackEffectRightAnim: PlayerSpriteSheet.attackEffectRight(),
      attackEffectTopAnim: PlayerSpriteSheet.attackEffectTop(),
      height: tileSize,
      width: tileSize,
      direction: direction.getDirectionEnum(),
    );

    // var anim = SpriteSheetHero.attackAxe;
    // this.simpleAttackRange(
    //   id: id,
    //   animationRight: anim,
    //   animationLeft: anim,
    //   animationUp: anim,
    //   animationDown: anim,
    //   interval: 0,
    //   direction: direction.getDirectionEnum(),
    //   animationDestroy: SpriteSheetHero.smokeExplosion,
    //   width: tileSize * 0.9,
    //   height: tileSize * 0.9,
    //   speed: speed * 1.5,
    //   damage: 15,
    //   collision: CollisionConfig(
    //     collisions: [CollisionArea.rectangle(size: Size(tileSize * 0.9, tileSize * 0.9))],
    //   ),
    // );
  }

  @override
  void receiveDamage(double damage, from) {}
}
