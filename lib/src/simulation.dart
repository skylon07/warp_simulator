import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warp_wake_simulator/src/physics.dart';
import 'package:warp_wake_simulator/src/scenarios.dart';

class WarpWakeSimulation extends StatefulWidget {
  const WarpWakeSimulation({super.key});

  @override
  State createState() => _WarpWakeSimulationState();
}

class _WarpWakeSimulationState extends State<WarpWakeSimulation> with TickerProviderStateMixin {
  final starGenerator = StarPositionGenerator();

  late final TimeController timeController = TimeController(vsync: this)
    ..addListener(() {
      if (controlsController.isPressed(PhysicalKeyboardKey.arrowUp))    { physicsController.goForward(); }
      if (controlsController.isPressed(PhysicalKeyboardKey.arrowDown))  { physicsController.goBackward(); }
      if (controlsController.isPressed(PhysicalKeyboardKey.arrowLeft))  { physicsController.turnLeft(); }
      if (controlsController.isPressed(PhysicalKeyboardKey.arrowRight)) { physicsController.turnRight(); }
      if (controlsController.isPressed(PhysicalKeyboardKey.keyW))       { physicsController.targetForward(); }
      if (controlsController.isPressed(PhysicalKeyboardKey.keyS))       { physicsController.targetBackward(); }
      if (controlsController.isPressed(PhysicalKeyboardKey.keyA))       { physicsController.targetTurnLeft(); }
      if (controlsController.isPressed(PhysicalKeyboardKey.keyD))       { physicsController.targetTurnRight(); }
      
      physicsController.update(timeController.timeDelta ?? Duration.zero);
    });

  late final controlsController = ControlsController()
    ..onPressed(PhysicalKeyboardKey.arrowUp,      () => physicsController.goForward())
    ..onPressed(PhysicalKeyboardKey.arrowDown,    () => physicsController.goBackward())
    ..onPressed(PhysicalKeyboardKey.arrowLeft,    () => physicsController.turnLeft())
    ..onPressed(PhysicalKeyboardKey.arrowRight,   () => physicsController.turnRight())
    ..onUnpressed(PhysicalKeyboardKey.arrowUp,    () => physicsController.goNeutral())
    ..onUnpressed(PhysicalKeyboardKey.arrowDown,  () => physicsController.goNeutral())
    ..onUnpressed(PhysicalKeyboardKey.arrowLeft,  () => physicsController.turnNeutral())
    ..onUnpressed(PhysicalKeyboardKey.arrowRight, () => physicsController.turnNeutral())
    ..onPressed(PhysicalKeyboardKey.keyW,         () => physicsController.targetForward())
    ..onPressed(PhysicalKeyboardKey.keyS,         () => physicsController.targetBackward())
    ..onPressed(PhysicalKeyboardKey.keyA,         () => physicsController.targetTurnLeft())
    ..onPressed(PhysicalKeyboardKey.keyD,         () => physicsController.targetTurnRight())
    ..onUnpressed(PhysicalKeyboardKey.keyW,       () => physicsController.targetNeutral())
    ..onUnpressed(PhysicalKeyboardKey.keyS,       () => physicsController.targetNeutral())
    ..onUnpressed(PhysicalKeyboardKey.keyA,       () => physicsController.targetTurnNeutral())
    ..onUnpressed(PhysicalKeyboardKey.keyD,       () => physicsController.targetTurnNeutral())
    ..onPressed(PhysicalKeyboardKey.digit0,       () => physicsController.loadScenario(scenario0))
    ..onPressed(PhysicalKeyboardKey.digit1,       () => physicsController.loadScenario(scenario1))
    ..onPressed(PhysicalKeyboardKey.digit2,       () => physicsController.loadScenario(scenario2))
    ..onPressed(PhysicalKeyboardKey.digit3,       () => physicsController.loadScenario(scenario3))
    ..onPressed(PhysicalKeyboardKey.digit4,       () => physicsController.loadScenario(scenario4))
    ..onPressed(PhysicalKeyboardKey.digit5,       () => physicsController.loadScenario(scenario5))
    // ..onPressed(PhysicalKeyboardKey.digit6,       () => physicsController.loadScenario(scenario6))
    // ..onPressed(PhysicalKeyboardKey.digit7,       () => physicsController.loadScenario(scenario7))
    // ..onPressed(PhysicalKeyboardKey.digit8,       () => physicsController.loadScenario(scenario8))
    // ..onPressed(PhysicalKeyboardKey.digit9,       () => physicsController.loadScenario(scenario9))
    ..onPressed(PhysicalKeyboardKey.keyC,         () => setState(() { showCamera = !showCamera; }))
    ..onPressed(PhysicalKeyboardKey.keyV,         () => setState(() { physicsController.clearWakes(); }))
    ..onPressed(PhysicalKeyboardKey.keyB,         () => setState(() { showWakes = !showWakes; }));
  final physicsController = PhysicsController();

  var showCamera = false;
  var showWakes = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ControlsListener(
        controller: controlsController,
        child: AnimatedBuilder(
          animation: timeController,
          builder: (context, _) => buildVisuals(context)
        ),
      ),
    );
  }

  Widget buildVisuals(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var screenSize = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        // scene (wakes, stars, ships)
        CustomPaint(
          size: screenSize,
          willChange: true,
          painter: ObjectScenePainter(
            controller: physicsController,
            starGenerator: starGenerator,
            showWakes: showWakes,
            showCamera: showCamera,
          ),
        ),

        // position/velocity info
        Align(
          alignment: const Alignment(0, 0.4),
          child: Text("${physicsController.distanceBetweenShips().toStringAsPrecision(3)} ls", style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
        ),
        Align(
          alignment: const Alignment(0, 0.44),
          child: Text("${physicsController.mainShipVelocity.dy.toStringAsPrecision(2)} c", style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
        ),
        Align(
          alignment: const Alignment(0, 0.48),
          child: Text("${physicsController.targetShipVelocity.dy.toStringAsPrecision(2)} c", style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
        ),
        
        // controls
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              "Move: ↑ ← ↓ →\nTgt Move: W A S D\nCamera: C\nClear Wakes: V\nShow Wakes: B\nScenarios: 0-9",
              style: textTheme.bodyMedium?.copyWith(color: Colors.white),
              textAlign: TextAlign.end,
            ),
          ),
        ),
      ],
    );
  }
}

class ObjectScenePainter extends CustomPainter {
  final PhysicsController controller;
  final StarPositionGenerator starGenerator;
  final bool showWakes;
  final bool showCamera;

  ObjectScenePainter({
    required this.controller,
    required this.starGenerator,
    required this.showWakes,
    required this.showCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showWakes) {
      var unseenWakes = controller.calculateUnseenWakes().toList();
      var skipWakes = 0;
      var numWakesToSkip = unseenWakes.length ~/ 1200;
      for (var wake in unseenWakes) {
        if (skipWakes > 0) {
          skipWakes--;
          continue;
        }
        var (point, _, age) = wake;
        _paintWake(canvas, size, point, _colorFromWakeAge(age, numWakesToSkip), age);
        skipWakes = numWakesToSkip;
      }
    }

    for (var starPos in _generateStars()) {
      _paintStar(canvas, size, starPos);
    }

    _paintShip(
      canvas, size,
      controller.mainShipPoint,
      controller.mainShipRotation,
      Colors.green,
    );
    _paintShip(
      canvas, size,
      controller.targetShipPoint,
      controller.targetShipRotation,
      Colors.red,
    );
    for (var (ghostPoint, ghostRotation, ghostAge) in controller.calculateGhosts()) {
      _paintShip(
          canvas, size,
          ghostPoint,
          ghostRotation,
          _colorFromGhostAge(ghostAge),
        );
    }

    // camera
    if (showCamera) {
      _paintCamera(canvas, size, controller.cameraAbsolute);
    }
  }

  void _paintWake(Canvas canvas, Size size, AbsolutePoint point, Color color, double age) {
    double strokeWidth = _scaleInPainter(0.01);
    var radius = _scaleInPainter(age - strokeWidth/2);
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(_pointInPerspective(point, size), radius, paint);
  }

  Color _colorFromWakeAge(double age, int numWakesToSkip) {
    const colorSpeed = 360/PhysicsController.wakeLifespan;
    var alpha = 0.3 * pow(numWakesToSkip + 1, 0.65);
    if (alpha > 1) alpha = 1;
    return HSVColor.fromAHSV(alpha, (colorSpeed * age) % 360, 1, 1).toColor();
  }

  void _paintStar(Canvas canvas, Size size, AbsolutePoint point) {
    var paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(_pointInPerspective(point, size), 3/2, paint);
  }

  void _paintShip(Canvas canvas, Size size, AbsolutePoint point, AbsoluteRotation rotation, Color color) {
    var relativePos = _pointInPerspective(point, size);
    var relativeAng = _rotateInPerspective(rotation);
    Offset shipPieceInPerspective(Offset piecePos) => 
      _posInPainter(piecePos).rotate(relativeAng) + relativePos;
    
    // determines the size of the ship from the center to the tip of the nose
    double noseDistance = 0.7;
    var nosePos       = shipPieceInPerspective(Offset(0, noseDistance));
    var leftWingPos   = shipPieceInPerspective(Offset(-noseDistance/2, -noseDistance));
    var rightWingPos  = shipPieceInPerspective(Offset( noseDistance/2, -noseDistance));

    var paint = Paint()
      ..color = color
      ..strokeWidth = _scaleInPainter(0.2);
    canvas.drawLine(leftWingPos, nosePos, paint);
    canvas.drawLine(rightWingPos, nosePos, paint);
  }

  Color _colorFromGhostAge(double age) {
    var agePercent = 1 - (age / PhysicsController.ghostLifespan);
    if (agePercent < 0) agePercent = 0;

    int alpha = (180 * agePercent).toInt();
    return Colors.purpleAccent.withAlpha(alpha);
  }

  void _paintCamera(Canvas canvas, Size size, AbsolutePoint point) {
    var paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(_pointInPerspective(point, size), 5/2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  Offset _pointInPerspective(AbsolutePoint point, Size size) {
    var relativePoint = controller.relative(point);
    var posFromCamera = controller.cameraPerspective(relativePoint);
    var painterPoint =
      _posInPainter(posFromCamera) + 
      Offset(size.width/2, size.height/2);
    return painterPoint;
  }

  static const double pixelsPerLightSecond = 20;

  double _scaleInPainter(double distance) {
    return distance * pixelsPerLightSecond;
  }

  Offset _posInPainter(Offset pos) {
    // the painter thinks "positive y" means "down"
    return Offset(pos.dx, -pos.dy) * pixelsPerLightSecond;
  }

  double _rotateInPerspective(AbsoluteRotation rotation) {
    // reversed because the painter thinks "positive angles" means counter-clockwise
    // (physics controller says "positive angles" are clockwise)
    var painterAng = -controller.relativeRotation(rotation).ang;
    return painterAng;
  }

  List<AbsolutePoint> _generateStars() {
    var chunkPos = controller.mainShipPoint.pos;
    var chunkSize = StarPositionGenerator.chunkSize;
    return starGenerator.starsAroundChunk((chunkPos.dx + chunkSize/2) ~/ chunkSize, (chunkPos.dy + chunkSize/2) ~/ chunkSize);
  }
}


class TimeController extends AnimationController {
  Duration? get timeDelta => _timeDelta;

  Duration? _lastTime;
  Duration? _currentTime;
  Duration? _timeDelta;

  TimeController({required super.vsync}) : super(duration: const Duration(seconds: 1)) {
    addListener(() {
      _lastTime = _currentTime;
      _currentTime = lastElapsedDuration;
      _timeDelta = _calcTimeDelta();
    });

    repeat();
  }

  Duration? _calcTimeDelta() {
    if (lastElapsedDuration case var currentTime?) {
      return currentTime - (_lastTime ?? Duration.zero);
    } else {
      return null;
    }
  }
}


class ControlsListener extends StatefulWidget {
  final Widget child;
  final ControlsController controller;

  const ControlsListener({super.key, required this.controller, required this.child});

  @override
  _ControlsListenerState createState() => _ControlsListenerState();
}

class _ControlsListenerState extends State<ControlsListener> {
  final focusNode = FocusNode();
  late final controller = widget.controller;

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
  }

  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      controller._onKeyDown(event.physicalKey);
    } else if (event is KeyUpEvent) {
      controller._onKeyUp(event.physicalKey);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: handleKeyEvent,
      child: widget.child,
    );
  }
}

class ControlsController {
  final _keyPressedState = <PhysicalKeyboardKey, bool>{};
  final _onPressedCallbacks = <PhysicalKeyboardKey, void Function()>{};
  final _onUnpressedCallbacks = <PhysicalKeyboardKey, void Function()>{};

  bool isPressed(PhysicalKeyboardKey key) => _keyPressedState[key] ?? false;

  void onPressed(PhysicalKeyboardKey key, void Function() callback) {
    _onPressedCallbacks[key] = callback;
  }

  void onUnpressed(PhysicalKeyboardKey key, void Function() callback) {
    _onUnpressedCallbacks[key] = callback;
  }

  void _onKeyDown(PhysicalKeyboardKey key) {
    _keyPressedState[key] = true;
    _onPressedCallbacks[key]?.call();
  }

  void _onKeyUp(PhysicalKeyboardKey key) {
    _keyPressedState[key] = false;
    _onUnpressedCallbacks[key]?.call();
  }
}
