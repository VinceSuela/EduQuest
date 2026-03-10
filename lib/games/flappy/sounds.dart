import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';

class Sounds extends Component {
  late AudioPool _point;
  late AudioPool _swoosh;
  late AudioPool _wing;
  late AudioPool _hit;

  @override
  Future<void> onLoad() async {
    _point = await FlameAudio.createPool(
      'point.ogg',
      minPlayers: 3,
      maxPlayers: 4,
    );

    _swoosh = await FlameAudio.createPool(
      'swoosh.ogg',
      minPlayers: 3,
      maxPlayers: 4,
    );

    _wing = await FlameAudio.createPool(
      'wing.ogg',
      minPlayers: 3,
      maxPlayers: 4,
    );

    _hit = await FlameAudio.createPool('hit.ogg', minPlayers: 3, maxPlayers: 4);
    await super.onLoad();
  }

  void point() {
    _point.start();
  }

  void swoosh() {
    _swoosh.start();
  }

  void wing() {
    _wing.start();
  }

  void hit() {
    _hit.start();
  }
}
