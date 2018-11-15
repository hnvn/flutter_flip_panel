import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flip_panel/flip_panel.dart';
import 'dart:async';

import 'package:matcher/matcher.dart';

void main() {

  testWidgets('FlipPanel.builder() can be constructed', (tester) async {
    await tester.pumpWidget(FlipPanel.builder(
        itemBuilder: (context, index) => Container(),
        period: Duration(milliseconds: 1000),
        itemsCount: 2));
  });

  testWidgets('FlipPanel.stream() can be constructed', (tester) async {
    await tester.pumpWidget(FlipPanel.stream(
        itemStream: Stream.empty(),
        itemBuilder: (context, value) => Container()));
  });

  testWidgets('FlipPanel.builder() completes after expected loop number and displays expected value after animation finished', (tester) async {
    final digits = [0, 1, 2, 3];
    var count = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: new Material(
          child: Center(
            child: FlipPanel.builder(
                itemBuilder: (context, index) {
                  count++;
                  return Container(
                    color: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                    child: Text(
                      '${digits[index]}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30.0,
                      ),
                    ),
                  );
                },
                period: Duration(milliseconds: 1000),
                duration: Duration(milliseconds: 500),
                loop: 2,
                itemsCount: digits.length),
          ),
        ),
      ),
    );

    // wait for flip animation finished
    await tester.pumpAndSettle();

    // verify loop counter
    expect(count, equals(8));

    // verify the final digit displayed
    expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data)
            .last,
        equals('${digits.last}'));
  });

  testWidgets('FlipPanel.stream() displays expected value after animation finished', (tester) async {
    StreamController<int> controller = StreamController<int>();

    await tester.pumpWidget(
      MaterialApp(
        home: new Material(
          child: Center(
            child: FlipPanel.stream(
              itemBuilder: (context, value) {
                return Container(
                  color: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 6.0),
                  child: Text(
                    '$value',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30.0,
                    ),
                  ),
                );
              },
              itemStream: controller.stream,
              initValue: 0,
            ),
          ),
        ),
      ),
    );

    // add event to stream
    controller.add(1);
    controller.close();

    await tester.pumpAndSettle();

    // verify the value displayed
    expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data)
            .last,
        equals('1'));
  });
}
