import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';

/// Adds a horizontal list of variable number of jumping dots
///
/// The animation is a smooth up/down continuous animation of each dot.
/// This animation can be used where a text is being expected from an async call
/// The below class is a private [AnimatedWidget] class which is called in the
/// [StatefulWidget].
class _JumpingDot extends AnimatedWidget {
  final Color color;
  final double dotSize;

  _JumpingDot({Key key, Animation<double> animation, this.color, this.dotSize})
      : super(key: key, listenable: animation);

  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    return Container(
      margin: EdgeInsets.only(bottom: animation.value),
      child: Container(
        width: dotSize - 8,
        height: dotSize - 8,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class JumpingDots extends StatefulWidget {
  final int numberOfDots;
  final double dotSize;
  final double dotSpacing;
  final Color color;
  final int milliseconds;

  /// Starting and ending values for animations.
  final double beginTweenValue = 0.0;
  final double endTweenValue = 8.0;

  JumpingDots({
    this.numberOfDots = 3,
    this.color = Colors.black,
    this.dotSize = 5,
    this.dotSpacing = 0.0,
    this.milliseconds = 250,
  });

  _JumpingDotsState createState() =>
      _JumpingDotsState(
        numberOfDots: this.numberOfDots,
        color: this.color,
        dotSize: this.dotSize,
        dotSpacing: this.dotSpacing,
        milliseconds: this.milliseconds,
      );
}

class _JumpingDotsState extends State<JumpingDots> with TickerProviderStateMixin {
  int numberOfDots;
  int milliseconds;
  double dotSpacing;
  double dotSize;
  Color color;

  List<AnimationController> controllers = <AnimationController>[];
  List<Animation<double>> animations = <Animation<double>>[];
  List<Widget> _widgets = <Widget>[];

  _JumpingDotsState({
    this.numberOfDots,
    this.dotSize,
    this.color,
    this.dotSpacing,
    this.milliseconds,
  });

  initState() {
    super.initState();
    for (int i = 0; i < numberOfDots; i++) {
      _addAnimationControllers();
      _buildAnimations(i);
      _addListOfDots(i);
    }

    controllers[0].forward();
  }

  void _addAnimationControllers() {
    controllers.add(AnimationController(
        duration: Duration(milliseconds: milliseconds), vsync: this));
  }

  void _addListOfDots(int index) {
    _widgets.add(
      Padding(
        padding: EdgeInsets.only(right: dotSpacing),
        child: _JumpingDot(
          animation: animations[index],
          dotSize: dotSize,
          color: color,
        ),
      ),
    );
  }

  void _buildAnimations(int index) {
    animations.add(
      Tween(begin: widget.beginTweenValue, end: widget.endTweenValue)
          .animate(controllers[index])
        ..addStatusListener(
              (AnimationStatus status) {
            if (status == AnimationStatus.completed)
              controllers[index].reverse();
            if (index == numberOfDots - 1 &&
                status == AnimationStatus.dismissed) {
              controllers[0].forward();
            }
            if (animations[index].value > widget.endTweenValue / 2 &&
                index < numberOfDots - 1) {
              controllers[index + 1].forward();
            }
          },
        ),
    );
  }

  Widget build(BuildContext context) {
    return Container(
      height: dotSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _widgets,
      ),
    );
  }

  dispose() {
    for (int i = 0; i < numberOfDots; i++) controllers[i].dispose();
    super.dispose();
  }
}
