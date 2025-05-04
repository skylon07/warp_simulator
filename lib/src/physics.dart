import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:warp_wake_simulator/src/scenarios.dart';

extension type RelativePoint._(Offset pos) {}
extension type AbsolutePoint._(Offset pos) {}
extension type RelativeRotation._(double ang) {}
extension type AbsoluteRotation._(double ang) {}
typedef Event = (AbsolutePoint, AbsoluteRotation, double);

extension OffsetPhysics on Offset {
  Offset rotate(num angle) {
    angle *= -1; // positive angles should mean CW, not CCW
    var rotatedX = dx * cos(angle) - dy * sin(angle);
    var rotatedY = dx * sin(angle) + dy * cos(angle);
    return Offset(rotatedX, rotatedY);
  }

  String toCoordinateString() => "${dx.toStringAsPrecision(3)}, ${dy.toStringAsPrecision(3)}";
}

extension FloatingPointDuration on Duration {
  double get inContinuousSeconds => inMicroseconds / Duration.microsecondsPerSecond;
}

extension DoublePrettyPrinting on double {
  String toStringOfLength(int size) {
    var string = toString();
    var substrEnd = size < string.length ? size : string.length;
    return string.substring(0, substrEnd).padRight(size, "0");
  }
}

class PhysicsState {
  var mainShipPoint = AbsolutePoint._(const Offset(0, 0));
  var mainShipVelocity = const Offset(0, 0);
  double mainShipAcceleration = 0;
  var mainShipRotation = AbsoluteRotation._(0);
  double mainShipRotationRate = 0;
  double mainShipRotationAcc = 0;

  var targetShipPoint = AbsolutePoint._(const Offset(0, 0));
  var targetShipVelocity = const Offset(0, 0);
  double targetShipAcceleration = 0;
  var targetShipRotation = AbsoluteRotation._(0);
  double targetShipRotationRate = 0;
  double targetShipRotationAcc = 0;
}

typedef CancelableSleepFunction = Future<bool> Function(int);
class Scenario {
  final Offset mainShipStartPoint;
  final double mainShipStartRotation;
  final double mainShipStartSpeed;

  final Offset targetShipStartPoint;
  final double targetShipStartRotation;
  final double targetShipStartSpeed;

  final void Function(PhysicsController, CancelableSleepFunction)? animate;
  var _animateCanceled = false;

  Scenario({
    this.mainShipStartPoint = const Offset(0, 0),
    this.mainShipStartRotation = 0,
    this.mainShipStartSpeed = 0,
    this.targetShipStartPoint = const Offset(0, 0),
    this.targetShipStartRotation = 0,
    this.targetShipStartSpeed = 0,
    this.animate,
  });

  void cancel() => _animateCanceled = true;

  PhysicsState _createState(PhysicsController controller) {
    var state = PhysicsState()
      ..mainShipPoint = AbsolutePoint._(mainShipStartPoint)
      ..mainShipRotation = AbsoluteRotation._(mainShipStartRotation)
      ..mainShipVelocity = Offset(0, mainShipStartSpeed)
      ..targetShipPoint = AbsolutePoint._(targetShipStartPoint)
      ..targetShipRotation = AbsoluteRotation._(targetShipStartRotation)
      ..targetShipVelocity = Offset(0, targetShipStartSpeed);
    Future.delayed(Duration.zero).then((_) => animate?.call(controller, _sleepCancelable));
    return state;
  }

  Future<bool> _sleepCancelable(int milliseconds) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
    return _animateCanceled;
  }
}

/// A hacked-together physics engine for the warp drive simulator.
/// 
/// This controller treats all distances in light-seconds.
/// Positions are given in cartesian coordinates, where positive `x` values
/// mean "right" and positive `y` values mean "up".
/// Angles are unit-less (so, radians?). An angle of zero is oriented upward
/// (where applicable), and positive angles indicate clockwise turning.
class PhysicsController {
  static const double wakeLifespan = 45;
  static const double ghostLifespan = 0.25;
  static const double _accelerationAmount = 1;
  static const double _rotationAmount = 0.0005;
  static const double _maxRotationRate = 0.024;

  late PhysicsState _state;
  Scenario? _lastScenario;

  PhysicsController() {
    loadScenario(scenario0);
  }
  
  AbsolutePoint get mainShipPoint => _state.mainShipPoint;
  Offset get mainShipVelocity => _state.mainShipVelocity;
  AbsoluteRotation get mainShipRotation => _state.mainShipRotation;
  AbsolutePoint get targetShipPoint => _state.targetShipPoint;
  Offset get targetShipVelocity => _state.targetShipVelocity;
  AbsoluteRotation get targetShipRotation => _state.targetShipRotation;

  double distanceBetweenShips() => relative(_state.targetShipPoint).pos.distance;

  RelativePoint relative(AbsolutePoint point) { 
    var translatedPoint = point.pos - _state.mainShipPoint.pos;
    var rotatedPoint = translatedPoint.rotate(-_state.mainShipRotation.ang);
    return RelativePoint._(rotatedPoint);
  }

  AbsolutePoint absolute(RelativePoint point) {
    var rotatedPoint = point.pos.rotate(_state.mainShipRotation.ang);
    var translatedPoint = rotatedPoint + _state.mainShipPoint.pos;
    return AbsolutePoint._(translatedPoint);
  }

  RelativeRotation relativeRotation(AbsoluteRotation rotation) {
    var relativeRotation = RelativeRotation._(rotation.ang - _state.mainShipRotation.ang);
    return relativeRotation;
  }

  AbsoluteRotation absoluteRotation(RelativeRotation rotation) {
    var absoluteRotation = AbsoluteRotation._(rotation.ang + _state.mainShipRotation.ang);
    return absoluteRotation;
  }

  static const _cameraOffset = Offset(0, 4);
  RelativePoint get cameraRelative => RelativePoint._(_cameraOffset);
  AbsolutePoint get cameraAbsolute => absolute(cameraRelative);

  Offset cameraPerspective(RelativePoint point) {
    return point.pos - _cameraOffset;
  }

  void goForward        () => _state.mainShipAcceleration   =  _accelerationAmount;
  void goBackward       () => _state.mainShipAcceleration   = -_accelerationAmount;
  void goNeutral        () => _state.mainShipAcceleration   =  0;
  void turnRight        () => _state.mainShipRotationAcc   =  _rotationAmount;
  void turnLeft         () => _state.mainShipRotationAcc   = -_rotationAmount;
  void turnNeutral      () => _state.mainShipRotationAcc   =  0;
  void targetForward    () => _state.targetShipAcceleration =  _accelerationAmount;
  void targetBackward   () => _state.targetShipAcceleration = -_accelerationAmount;
  void targetNeutral    () => _state.targetShipAcceleration =  0;
  void targetTurnRight  () => _state.targetShipRotationAcc =  _rotationAmount;
  void targetTurnLeft   () => _state.targetShipRotationAcc = -_rotationAmount;
  void targetTurnNeutral() => _state.targetShipRotationAcc   =  0;

  void loadScenario(Scenario scenario) {
    _lastScenario?.cancel();
    _lastScenario = scenario;

    _totalTime = 0;
    _state = scenario._createState(this);
    clearWakes();
  }

  void update(Duration timeDelta) {
    var timeDeltaSeconds = timeDelta.inContinuousSeconds;
    _totalTime += timeDeltaSeconds;

    // TODO: any way to share this code at all...?
    _state.mainShipVelocity += Offset(0, _state.mainShipAcceleration * timeDeltaSeconds);
    _state.mainShipPoint = AbsolutePoint._(_state.mainShipPoint.pos + _state.mainShipVelocity.rotate(_state.mainShipRotation.ang) * timeDeltaSeconds);

    if (_state.mainShipRotationAcc != 0) {
      _state.mainShipRotationRate += _state.mainShipRotationAcc;
      if (_state.mainShipRotationRate >  _maxRotationRate) _state.mainShipRotationRate =  _maxRotationRate;
      if (_state.mainShipRotationRate < -_maxRotationRate) _state.mainShipRotationRate = -_maxRotationRate;
    } else if (_state.mainShipRotationRate > _rotationAmount) {
      _state.mainShipRotationRate -= _rotationAmount;
    } else if (_state.mainShipRotationRate < -_rotationAmount) {
      _state.mainShipRotationRate += _rotationAmount;
    } else if (_state.mainShipRotationRate != 0) {
      _state.mainShipRotationRate = 0;
    }
    _state.mainShipRotation = AbsoluteRotation._(_state.mainShipRotation.ang + _state.mainShipRotationRate);

    _state.targetShipVelocity += Offset(0, _state.targetShipAcceleration * timeDeltaSeconds);
    _state.targetShipPoint = AbsolutePoint._(_state.targetShipPoint.pos + _state.targetShipVelocity.rotate(_state.targetShipRotation.ang) * timeDeltaSeconds);

    if (_state.targetShipRotationAcc != 0) {
      _state.targetShipRotationRate += _state.targetShipRotationAcc;
      if (_state.targetShipRotationRate >  _maxRotationRate) _state.targetShipRotationRate =  _maxRotationRate;
      if (_state.targetShipRotationRate < -_maxRotationRate) _state.targetShipRotationRate = -_maxRotationRate;
    } else if (_state.targetShipRotationRate > _rotationAmount) {
      _state.targetShipRotationRate -= _rotationAmount;
    } else if (_state.targetShipRotationRate < -_rotationAmount) {
      _state.targetShipRotationRate += _rotationAmount;
    } else if (_state.targetShipRotationRate != 0) {
      _state.targetShipRotationRate = 0;
    }
    _state.targetShipRotation = AbsoluteRotation._(_state.targetShipRotation.ang + _state.targetShipRotationRate);

    if (_updatesLeftBeforeWakeAdd <= 0) {
      _wakes.add((_state.targetShipPoint, _state.targetShipRotation, _totalTime));
      _updatesLeftBeforeWakeAdd += _updatesPerWake;
    }
    _updatesLeftBeforeWakeAdd--;
    _cleanUpExpiredEvents();
    _checkForWakesObserved();
  }

  double _totalTime = 0;

  final _wakes = <Event>{};
  final _wakeGhosts = <Event, Event>{};
  final _wakesInRange = <Event>{};
  
  num _updatesLeftBeforeWakeAdd = 0;
  static const _updatesPerWake = 1.2;

  void _checkForWakesObserved() {
    for (var wake in _wakes) {
      var (wakePoint, wakeRotation, wakeEmissionTime) = wake;

      var mainShipPos = _state.mainShipPoint.pos;
      var posDiff = wakePoint.pos - mainShipPos;
      var distanceToWake = sqrt(
        posDiff.dx * posDiff.dx +
        posDiff.dy * posDiff.dy
      );
      
      // assumes age = distance, because distance units are light-seconds
      var wakeAge = _totalTime - wakeEmissionTime;
      var wakeRadius = wakeAge;

      var wakeInRange = distanceToWake <= wakeRadius;
      var wakeWasInRange = _wakesInRange.contains(wake);
      if (wakeInRange != wakeWasInRange) {
        if (wakeInRange) {
          // you can only see wakes when crossing into them
          Event ghostEvent = (wakePoint, wakeRotation, _totalTime);
          _wakeGhosts[wake] = ghostEvent;
          _wakesInRange.add(wake);
        } else {
          _wakesInRange.remove(wake);
        }
      }
    }
  }

  void _cleanUpExpiredEvents() {
    var wakesToRemove = <Event>[];
    for (var wake in _wakes) {
      var (_, _, wakeEmissionTime) = wake;

      var wakeAge = _totalTime - wakeEmissionTime;
      if (wakeAge > wakeLifespan) {
        wakesToRemove.add(wake);
      }
    }
    for (var wake in wakesToRemove) {
      _wakes.remove(wake);
      _wakesInRange.remove(wake);
      _wakeGhosts.remove(wake);
    }
  }

  /// Calculates wakes and returns each as a center point, orientation,
  /// and time since being emitted.
  Iterable<Event> calculateUnseenWakes() {
    return _wakes
      .where((wake) {
        var wakeHasBeenSeen = _wakeGhosts.containsKey(wake);
        return !wakeHasBeenSeen;
      })
      .map((wake) {
        var (centerPoint, rotation, emissionTime) = wake;
        return (centerPoint, rotation, _totalTime - emissionTime);
      });
  }

  /// Calculates known wake ghosts and returns each as a center point, orientation,
  /// and time since first observed.
  Iterable<Event> calculateGhosts() {
    return _wakeGhosts.values.map((ghost) {
      var (centerPoint, rotation, observanceTime) = ghost;
      return (centerPoint, rotation, _totalTime - observanceTime);
    });
  }

  void clearWakes() {
    _wakes.clear();
    _wakeGhosts.clear();
    _wakesInRange.clear();
  }
}

class StarPositionGenerator {
  static const starsPerChunk = 2;
  static const double chunkSize = 5;

  final int _seed;

  StarPositionGenerator([int? seed]) : _seed = seed ?? DateTime.now().millisecondsSinceEpoch;

  List<AbsolutePoint> starsForChunk(int x, int y) {
    var random = _randomForChunk(x, y);
    var positions = [
      for (var starIdx = 0; starIdx < starsPerChunk; ++starIdx)
        AbsolutePoint._(Offset(chunkSize*(random.nextDouble()-0.5 + x), chunkSize*(random.nextDouble()-0.5 + y)))
    ];
    return positions;
  }

  List<AbsolutePoint> starsAroundChunk(int x, int y, {int distance = 7}) {
    var positions = [
      for (int chunkX = x - distance; chunkX <= x + distance; chunkX++)
      for (int chunkY = y - distance; chunkY <= y + distance; chunkY++)
        ...starsForChunk(chunkX, chunkY),
    ];
    return positions;
  }

  Random _randomForChunk(int x, int y) => Random("$_seed:$x:$y".hashCode);
}
