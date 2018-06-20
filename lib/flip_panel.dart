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

  FlipClock({
    Key key,
    @required DigitBuilder digitBuilder,
    @required Widget separator,
    @required this.startTime,
    this.spacing = const EdgeInsets.symmetric(horizontal: 2.0),
  })  : _digitBuilder = digitBuilder,
        _separator = separator;

  FlipClock.simple({
    Key key,
    @required this.startTime,
    @required Color digitColor,
    @required Color backgroundColor,
    @required double digitSize,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(0.0)),
    this.spacing = const EdgeInsets.symmetric(horizontal: 2.0),
  }) {
    _digitBuilder = (context, digit) => Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
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
    int seconds = startTime.second;
    int minutes = startTime.minute;
    int hours = startTime.hour;
    var time = startTime;

    final timeStream = Stream<DateTime>.periodic(Duration(milliseconds: 1000), (_) {
      time = time.add(const Duration(seconds: 1));
      return time;
    }).asBroadcastStream();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hours
        Padding(
          padding: spacing,
          child: FlipPanel<int>.stream(
            itemStream: timeStream.map((time) => time.hour ~/ 10),
            itemBuilder: _digitBuilder,
            duration: const Duration(milliseconds: 450),
            initValue: hours ~/ 10,
          ),
        ),
        Padding(
          padding: spacing,
          child: FlipPanel<int>.stream(
            itemStream: timeStream.map((time) => time.hour % 10),
            itemBuilder: _digitBuilder,
            duration: const Duration(milliseconds: 450),
            initValue: hours % 10,
          ),
        ),

        Padding(
          padding: spacing,
          child: _separator,
        ),

        // Minutes
        Padding(
          padding: spacing,
          child: FlipPanel<int>.stream(
            itemStream: timeStream.map((time) => time.minute ~/ 10),
            itemBuilder: _digitBuilder,
            duration: const Duration(milliseconds: 450),
            initValue: minutes ~/ 10,
          ),
        ),
        Padding(
          padding: spacing,
          child: FlipPanel<int>.stream(
            itemStream: timeStream.map((time) => time.minute % 10),
            itemBuilder: _digitBuilder,
            duration: const Duration(milliseconds: 450),
            initValue: minutes % 10,
          ),
        ),

        Padding(
          padding: spacing,
          child: _separator,
        ),

        // Seconds
        Padding(
          padding: spacing,
          child: FlipPanel<int>.stream(
            itemStream: timeStream.map((time) => time.second ~/ 10),
            itemBuilder: _digitBuilder,
            duration: const Duration(milliseconds: 450),
            initValue: seconds ~/ 10,
          ),
        ),
        Padding(
          padding: spacing,
          child: FlipPanel<int>.stream(
            itemStream: timeStream.map((time) => time.second % 10),
            itemBuilder: _digitBuilder,
            duration: const Duration(milliseconds: 450),
            initValue: seconds % 10,
          ),
        ),
      ],
    );
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

enum FlipDirection{ up, down }

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
    this.period,
    this.duration = const Duration(milliseconds: 500),
    this.loop = 1,
    this.startIndex = 0,
    this.spacing = 0.5,
    this.direction = FlipDirection.up,
  })
    : assert(itemBuilder != null),
      assert(itemsCount != null),
      assert(startIndex < itemsCount),
      assert(period == null || period.inMilliseconds >= 2 * duration.inMilliseconds),
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
  }): assert(itemStream != null),
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

class _FlipPanelState<T> extends State<FlipPanel> with TickerProviderStateMixin {
  AnimationController _controller;
  Animation _animation;
  int _currentIndex;
  bool _isReversePhase;
  bool _isStreamMode;
  bool _running;
  final _perspective = 0.006;
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

    _controller = new AnimationController(duration: widget.duration, vsync: this)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _isReversePhase = true;
              _controller.reverse();
            }
            if (status == AnimationStatus.dismissed) {
              _currentValue = _nextValue;
            }
          })
          ..addListener(() {
            setState(() {
              _running = true;
            });
          });
    _animation = Tween(begin: 0.0, end: math.pi / 2).animate(_controller);

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
          _running = false;
          _currentIndex = (_currentIndex + 1) % widget.itemsCount;
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
            : widget.indexedItemBuilder(context, _currentIndex % widget.itemsCount);
        _child2 = null;
        _upperChild1 = _upperChild2 != null ? _upperChild2 : makeUpperClip(_child1);
        _lowerChild1 = _lowerChild2 != null ? _lowerChild2 : makeLowerClip(_child1);
      }
      if (_child2 == null) {
        _child2 = _isStreamMode
            ? widget.streamItemBuilder(context, _nextValue)
            : widget.indexedItemBuilder(context, (_currentIndex + 1) % widget.itemsCount);
        _upperChild2 = makeUpperClip(_child2);
        _lowerChild2 = makeLowerClip(_child2);
      }
    } else {
      _child1 = _isStreamMode
          ? widget.streamItemBuilder(context, _currentValue)
          : widget.indexedItemBuilder(context, _currentIndex);
      _upperChild1 = makeUpperClip(_child1);
      _lowerChild1 = makeLowerClip(_child1);
    }
  }

  Widget _buildUpperFlipPanel() =>
      widget.direction == FlipDirection.up
          ? Stack(
            children: [
              _upperChild1,
              Transform(
                alignment: Alignment.bottomCenter,
                transform: (Matrix4.identity()..setEntry(3, 2, _perspective)) *
                    Matrix4.rotationX(_isReversePhase ? _animation.value : math.pi / 2),
                child: _upperChild2,
              ),
            ],
          )
          : Stack(
            children: [
              _upperChild2,
              Transform(
                alignment: Alignment.bottomCenter,
                transform: (Matrix4.identity()..setEntry(3, 2, _perspective)) *
                    Matrix4.rotationX(_isReversePhase ? math.pi / 2 : _animation.value),
                child: _upperChild1,
              ),
            ],
          );

  Widget _buildLowerFlipPanel() =>
      widget.direction == FlipDirection.up
          ? Stack(
            children: [
              _lowerChild2,
              Transform(
                alignment: Alignment.topCenter,
                transform: (Matrix4.identity()..setEntry(3, 2, _perspective)) *
                    Matrix4.rotationX(_isReversePhase ? math.pi / 2 : -_animation.value),
                child: _lowerChild1,
              )
            ],
          )
          : Stack(
            children: [
              _lowerChild1,
              Transform(
                alignment: Alignment.topCenter,
                transform: (Matrix4.identity()..setEntry(3, 2, _perspective)) *
                    Matrix4.rotationX(_isReversePhase ? -_animation.value : math.pi / 2),
                child: _lowerChild2,
              )
            ],
          );

  Widget _buildPanel() {
    return _running
        ? Column(
          mainAxisSize: MainAxisSize.min,
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
            children: [
              _upperChild1,
              Padding(
                padding: EdgeInsets.only(top: widget.spacing),
              ),
              _lowerChild1
            ],
          );
  }
}
