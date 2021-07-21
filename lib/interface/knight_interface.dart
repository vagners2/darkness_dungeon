import 'dart:ui';

import 'package:bonfire/bonfire.dart';
import 'package:darkness_dungeon/interface/bar_life_component.dart';
import 'package:darkness_dungeon/player/knight.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

class KnightInterface extends GameInterface {
  Sprite key;
  KnightInterface();

  @override
  Future<void> onLoad() async {
    key = await Sprite.load('itens/key_silver.png');
    add(BarLifeComponent());
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    try {
      _drawKey(canvas);
    } catch (e) {}
    super.render(canvas);
  }

  void _drawKey(Canvas c) {
    if (gameRef.player != null && (gameRef.player as GamePlayer).containKey) {
      key.renderFromVector2Rect(
          c, Rect.fromLTWH(150, 20, 35, 30).toVector2Rect());
    }
  }
}
