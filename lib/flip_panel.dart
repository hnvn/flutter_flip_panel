library flip_panel;

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

typedef Widget DigitBuilder(BuildContext, int);

@immutable
class FlipClock extends StatelessWidget {
  DigitBuilder _digitBuilder;
  Widget _separator;
  final DateTime startTime;
  final EdgeInsets spacing;

  /// Set countdown to true to have a countdown timer.
  final bool countdown;
  final bool _showHours;

  /// Called when the countdown clock hits zero.
  VoidCallback onDone;

  FlipClock({
    Key key,
    @required DigitBuilder digitBuilder,
    @required Widget separator,
    @required this.startTime,
    this.countdown = false,
    this.spacing = const EdgeInsets.symmetric(horizontal: 2.0),
  })  : _showHours = true,
        _digitBuilder = digitBuilder,
        _separator = separator;

  FlipClock.simple({
    Key key,
    @required this.startTime,
    @required Color digitColor,
    @required Color backgroundColor,
    @required double digitSize,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(0.0)),
    this.spacing = const EdgeInsets.symmetric(horizontal: 2.0),
  })  : countdown = false,
        _showHours = true {
    _digitBuilder = (context, digit) => Container(
          alignment: Alignment.center,
          width: 44.0,
          height: 60.0,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: Text(
            '$digit',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: digitSize,
                color: digitColor),
          ),
        );
    _separator = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      width: 24.0,
      height: 60.0,
      alignment: Alignment.center,
      child: Text(
        ':',
        style: TextStyle(
          fontSize: digitSize,
          color: digitColor,
        ),
      ),
    );
  }

  FlipClock.countdown({
    Key key,
    @required Duration duration,
    @required Color digitColor,
    @required Color backgroundColor,
    @required double digitSize,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(0.0)),
    this.spacing = const EdgeInsets.symmetric(horizontal: 2.0),
    this.onDone,
  })  : countdown = true,
        startTime = DateTime(2018, 1, 0, 0, 0, duration.inSeconds),
        _showHours = duration.inHours > 0 {
    _digitBuilder = (context, digit) => Container(
          alignment: Alignment.center,
          width: 44.0,
          height: 60.0,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: Text(
            '$digit',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: digitSize,
                color: digitColor),
          ),
        );
    _separator = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      width: 24.0,
      height: 60.0,
      alignment: Alignment.center,
      child: Text(
        ':',
        style: TextStyle(
          fontSize: digitSize,
          color: digitColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var time = startTime;

    final timeStream =
        Stream<DateTime>.periodic(Duration(milliseconds: 1000), (_) {
      var oldTime = time;
      time = time.add(Duration(seconds: countdown ? -1 : 1));
      if (oldTime.day != time.day) {
        time = oldTime;
        if (onDone != null) onDone();
      } 
      return time;
    }).asBroadcastStream();

    var digitList = <Widget>[];
    // TODO(efortuna): Instead, allow the user to specify the format of time instead.
    // Add hours if appropriate.
    if (_showHours) {
      digitList.addAll([_buildSegment(timeStream, (DateTime time) => time.hour ~/ 10,
            (DateTime time) => time.hour % 10, startTime),

        Padding(
          padding: spacing,
          child: _separator,
        )]);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: digitList..addAll([
        // Minutes
        _buildSegment(timeStream, (DateTime time) => time.minute ~/ 10,
            (DateTime time) => time.minute % 10, startTime),

        Padding(
          padding: spacing,
          child: _separator,
        ),

        // Seconds
        _buildSegment(timeStream, (DateTime time) => time.second ~/ 10,
            (DateTime time) => time.second % 10, startTime)
      ]),
    );
  }

  _buildSegment(Stream<DateTime> timeStream, Function tensDigit,
      Function onesDigit, DateTime startTime) {
    return Row(children: [
      Padding(
        padding: spacing,
        child: FlipPanel<int>.stream(
          itemStream: timeStream.map<int>(tensDigit),
          itemBuilder: _digitBuilder,
          duration: const Duration(milliseconds: 450),
          initValue: tensDigit(startTime),
        ),
      ),
      Padding(
        padding: spacing,
        child: FlipPanel<int>.stream(
          itemStream: timeStream.map<int>(onesDigit),
          itemBuilder: _digitBuilder,
          duration: const Duration(milliseconds: 450),
          initValue: onesDigit(startTime),
        ),
      ),
    ]);
  }
}

/// Signature for a function that creates a widget for a given index, e.g., in a
/// list.
typedef Widget IndexedItemBuilder(BuildContext, int);

/// Signature for a function that creates a widget for a value emitted from a [Stream]
typedef Widget StreamItemBuilder<T>(BuildContext, T);

/// A widget for flip panel with built-in animation
/// Content of the panel is built from [IndexedItemBuilder] or [StreamItemBuilder]
///
/// Note: the content size should be equal

enum FlipDirection { up, down }

class FlipPanel<T> extends StatefulWidget {
  final IndexedItemBuilder indexedItemBuilder;
  final StreamItemBuilder<T> streamItemBuilder;
  final Stream<T> itemStream;
  final int itemsCount;
  final Duration period;
  final Duration duration;
  final int loop;
  final int startIndex;
  final T initValue;
  final double spacing;
  final FlipDirection direction;

  FlipPanel({
    Key key,
    this.indexedItemBuilder,
    this.streamItemBuilder,
    this.itemStream,
    this.itemsCount,
    this.period,
    this.duration,
    this.loop,
    this.startIndex,
    this.initValue,
    this.spacing,
    this.direction,
  }) : super(key: key);

  /// Create a flip panel from iterable source
  /// [itemBuilder] is called periodically in each time of [period]
  /// The animation is looped in [loop] times before finished.
  /// Setting [loop] to -1 makes flip animation run forever.
  /// The [period] should be two times greater than [duration] of flip animation,
  /// if not the animation becomes jerky/stuttery.
  FlipPanel.builder({
    Key key,
    @required IndexedItemBuilder itemBuilder,
    @required this.itemsCount,
    @required this.period,
    this.duration = const Duration(milliseconds: 500),
    this.loop = 1,
    this.startIndex = 0,
    this.spacing = 0.5,
    this.direction = FlipDirection.up,
  })  : assert(itemBuilder != null),
        assert(itemsCount != null),
        assert(startIndex < itemsCount),
        assert(period == null ||
            period.inMilliseconds >= 2 * duration.inMilliseconds),
        indexedItemBuilder = itemBuilder,
        streamItemBuilder = null,
        itemStream = null,
        initValue = null,
        super(key: key);

  /// Create a flip panel from stream source
  /// [itemBuilder] is called whenever a new value is emitted from [itemStream]
  FlipPanel.stream({
    Key key,
    @required this.itemStream,
    @required StreamItemBuilder<T> itemBuilder,
    this.initValue,
    this.duration = const Duration(milliseconds: 500),
    this.spacing = 0.5,
    this.direction = FlipDirection.up,
  })  : assert(itemStream != null),
        indexedItemBuilder = null,
        streamItemBuilder = itemBuilder,
        itemsCount = 0,
        period = null,
        loop = 0,
        startIndex = 0,
        super(key: key);

  @override
  _FlipPanelState<T> createState() => _FlipPanelState<T>();
}

class _FlipPanelState<T> extends State<FlipPanel>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation _animation;
  int _currentIndex;
  bool _isReversePhase;
  bool _isStreamMode;
  bool _running;
  final _perspective = 0.003;
  final _zeroAngle =
      0.0001; // There's something wrong in the perspective transform, I use a very small value instead of zero to temporarily get it around.
  int _loop;
  T _currentValue, _nextValue;
  Timer _timer;
  StreamSubscription<T> _subscription;

  Widget _child1, _child2;
  Widget _upperChild1, _upperChild2;
  Widget _lowerChild1, _lowerChild2;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _isStreamMode = widget.itemStream != null;
    _isReversePhase = false;
    _running = false;
    _loop = 0;

    _controller =
        new AnimationController(duration: widget.duration, vsync: this)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _isReversePhase = true;
              _controller.reverse();
            }
            if (status == AnimationStatus.dismissed) {
              _currentValue = _nextValue;
              _running = false;
            }
          })
          ..addListener(() {
            setState(() {
              _running = true;
            });
          });
    _animation =
        Tween(begin: _zeroAngle, end: math.pi / 2).animate(_controller);

    if (widget.period != null) {
      _timer = Timer.periodic(widget.period, (_) {
        if (widget.loop < 0 || _loop < widget.loop) {
          if (_currentIndex + 1 == widget.itemsCount - 2) {
            _loop++;
          }
          _currentIndex = (_currentIndex + 1) % widget.itemsCount;
          _child1 = null;
          _isReversePhase = false;
          _controller.forward();
        } else {
          _timer.cancel();
          _currentIndex = (_currentIndex + 1) % widget.itemsCount;
          setState(() {
            _running = false;
          });
        }
      });
    }

    if (_isStreamMode) {
      _currentValue = widget.initValue;
      _subscription = widget.itemStream.distinct().listen((value) {
        if (_currentValue == null) {
          _currentValue = value;
        } else if (value != _currentValue) {
          _nextValue = value;
          _child1 = null;
          _isReversePhase = false;
          _controller.forward();
        }
      });
    } else if (widget.loop < 0 || _loop < widget.loop) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_subscription != null) _subscription.cancel();
    if (_timer != null) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _buildChildWidgetsIfNeed(context);

    return _buildPanel();
  }

  void _buildChildWidgetsIfNeed(BuildContext context) {
    Widget makeUpperClip(Widget widget) {
      return ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 0.5,
          child: widget,
        ),
      );
    }

    Widget makeLowerClip(Widget widget) {
      return ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 0.5,
          child: widget,
        ),
      );
    }

    if (_running) {
      if (_child1 == null) {
        _child1 = _child2 != null
            ? _child2
            : _isStreamMode
                ? widget.streamItemBuilder(context, _currentValue)
                : widget.indexedItemBuilder(
                    context, _currentIndex % widget.itemsCount);
        _child2 = null;
        _upperChild1 =
            _upperChild2 != null ? _upperChild2 : makeUpperClip(_child1);
        _lowerChild1 =
            _lowerChild2 != null ? _lowerChild2 : makeLowerClip(_child1);
      }
      if (_child2 == null) {
        _child2 = _isStreamMode
            ? widget.streamItemBuilder(context, _nextValue)
            : widget.indexedItemBuilder(
                context, (_currentIndex + 1) % widget.itemsCount);
        _upperChild2 = makeUpperClip(_child2);
        _lowerChild2 = makeLowerClip(_child2);
      }
    } else {
      _child1 = _child2 != null
          ? _child2
          : _isStreamMode
              ? widget.streamItemBuilder(context, _currentValue)
              : widget.indexedItemBuilder(
                  context, _currentIndex % widget.itemsCount);
      _upperChild1 =
          _upperChild2 != null ? _upperChild2 : makeUpperClip(_child1);
      _lowerChild1 =
          _lowerChild2 != null ? _lowerChild2 : makeLowerClip(_child1);
    }
  }

  Widget _buildUpperFlipPanel() => widget.direction == FlipDirection.up
      ? Stack(
          children: [
            Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _upperChild1),
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, _perspective)
                ..rotateX(_isReversePhase ? _animation.value : math.pi / 2),
              child: _upperChild2,
            ),
          ],
        )
      : Stack(
          children: [
            Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _upperChild2),
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, _perspective)
                ..rotateX(_isReversePhase ? math.pi / 2 : _animation.value),
              child: _upperChild1,
            ),
          ],
        );

  Widget _buildLowerFlipPanel() => widget.direction == FlipDirection.up
      ? Stack(
          children: [
            Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _lowerChild2),
            Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, _perspective)
                ..rotateX(_isReversePhase ? math.pi / 2 : -_animation.value),
              child: _lowerChild1,
            )
          ],
        )
      : Stack(
          children: [
            Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _lowerChild1),
            Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, _perspective)
                ..rotateX(_isReversePhase ? -_animation.value : math.pi / 2),
              child: _lowerChild2,
            )
          ],
        );

  Widget _buildPanel() {
    return _running
        ? Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildUpperFlipPanel(),
              Padding(
                padding: EdgeInsets.only(top: widget.spacing),
              ),
              _buildLowerFlipPanel(),
            ],
          )
        : _isStreamMode && _currentValue == null
            ? Container()
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, _perspective)
                        ..rotateX(_zeroAngle),
                      child: _upperChild1),
                  Padding(
                    padding: EdgeInsets.only(top: widget.spacing),
                  ),
                  Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, _perspective)
                        ..rotateX(_zeroAngle),
                      child: _lowerChild1)
                ],
              );
  }
}
