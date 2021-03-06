import 'dart:convert';
import 'package:flame/animation.dart';
import 'package:flame/sprite.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/services.dart' show rootBundle;

part 'spritesheet.g.dart';

const double _SRC_SIZE = 16.0;

@JsonSerializable()
class AnimationElement {
  int x, y, w, h, length, millis;

  AnimationElement();

  factory AnimationElement.fromJson(Map<String, dynamic> json) =>
      _$AnimationElementFromJson(json);
  Map<String, dynamic> toJson() => _$AnimationElementToJson(this);

  Sprite sprite(String fileName) {
    double x = this.x * _SRC_SIZE;
    double y = this.y * _SRC_SIZE;
    double w = this.w * _SRC_SIZE;
    double h = this.h * _SRC_SIZE;
    return Sprite('$fileName.png', x: x, y: y, width: w, height: h);
  }

  Animation animation(String fileName) {
    double x = this.x * _SRC_SIZE;
    double y = this.y * _SRC_SIZE;
    double w = this.w * _SRC_SIZE;
    double h = this.h * _SRC_SIZE;
    return Animation.sequenced(
      '$fileName.png',
      length,
      textureX: x,
      textureY: y,
      textureWidth: w,
      textureHeight: h,
      stepTime: millis / 1000,
    );
  }
}

@JsonSerializable()
class AnimationsJson {
  Map<String, AnimationElement> animations;

  AnimationsJson();

  factory AnimationsJson.fromJson(Map<String, dynamic> json) =>
      _$AnimationsJsonFromJson(json);
  Map<String, dynamic> toJson() => _$AnimationsJsonToJson(this);
}

class Spritesheet {
  String fileName;
  AnimationsJson animations;

  Spritesheet._(this.fileName, this.animations);

  static Future<Spritesheet> parse(fileName) async {
    String content =
        await rootBundle.loadString('assets/images/$fileName.json');
    AnimationsJson animations = AnimationsJson.fromJson(json.decode(content));
    return Spritesheet._(fileName, animations);
  }

  Sprite sprite(String name) {
    return animations.animations[name].sprite(fileName);
  }

  Sprite blockGn(String name, int dx, int dy) {
    AnimationElement animation = animations.animations[name];
    double x = (animation.x + dx) * _SRC_SIZE;
    double y = (animation.y + dy) * _SRC_SIZE;
    return Sprite('$fileName.png',
        x: x, y: y, width: _SRC_SIZE, height: _SRC_SIZE);
  }

  List<Sprite> generate(String name) {
    List<Sprite> list = [];
    int i = 1;
    while (true) {
      String key = '$name-$i';
      if (!animations.animations.containsKey(key)) {
        break;
      }
      list.add(sprite(key));
      i++;
    }
    return list;
  }
}
