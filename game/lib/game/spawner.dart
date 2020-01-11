import 'util.dart';

class Spawner {
  double chance;

  Spawner(this.chance);

  bool tossCoin(double dt) {
    return R.nextDouble() * dt <= chance;
  }

  void maybeSpawn(double dt, Function() action) {
    if (tossCoin(dt)) action();
  }
}
