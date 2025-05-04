import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:warp_simulator/src/physics.dart';

// "sandbox" scenario
get scenario0 => Scenario(
  targetShipStartPoint: Offset(-2, 2),
);

// shows how sub-lightspeed just causes delays/time dilation
get scenario1 => Scenario(
  targetShipStartPoint: Offset(-8, 3),
  targetShipStartSpeed: 0.8,
  targetShipStartRotation: pi/2,
  animate: (controller, sleep) async {
    if (await sleep(16000)) return;

    controller.targetTurnRight();
    if (await sleep(1090)) return;
    controller.targetTurnNeutral();
  },
);

// more STL time dilation, but with turns and accelerating
get scenario2 => Scenario(
  targetShipStartPoint: Offset(-2, 1),
  targetShipStartSpeed: 0.2,
  animate: (controller, sleep) async {
    if (await sleep(4000)) return;

    controller.targetForward();
    if (await sleep(400)) return;
    controller.targetNeutral();
    
    if (await sleep(2000)) return;

    controller.targetTurnLeft();
    if (await sleep(1400)) return;
    controller.targetTurnNeutral();

    if (await sleep(7000)) return;

    controller.targetTurnLeft();
    if (await sleep(500)) return;
    controller.targetTurnNeutral();
  },
);

// shows "ghost splitting/joining" with lateral FTL movements
get scenario3 => Scenario(
  targetShipStartPoint: Offset(-16, 4),
  targetShipStartSpeed: 1.8,
  targetShipStartRotation: pi/2,
  animate: (controller, sleep) async {
    if (await sleep(14500)) return;

    controller.targetTurnRight();
    if (await sleep(1090)) return;
    controller.targetTurnNeutral();
  },
);

// shows what "chasing ghosts" looks like
// (similar to chasing rainbows)
get scenario4 => Scenario(
  targetShipStartPoint: Offset(-1.6, -5),
  targetShipStartSpeed: 1.5,
  animate: (controller, sleep) async {
    if (await sleep(11000)) return;

    controller.goForward();
    if (await sleep(1500)) return;
    controller.goNeutral();

    if (await sleep(5000)) return;

    controller.goForward();
    if (await sleep(1300)) return;
    controller.goNeutral();
  },
);

// shows why FTL can be dangerous; it's like a supersonic bullet!
get scenario5 => Scenario(
  targetShipStartPoint: Offset(8, 11),
  targetShipStartSpeed: 1.4,
  targetShipStartRotation: -pi/2,
  animate: (controller, sleep) async {
    if (await sleep(7700)) return;

    controller.targetTurnLeft();
    if (await sleep(655)) return;
    controller.targetTurnNeutral();
  },
);