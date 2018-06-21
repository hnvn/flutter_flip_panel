import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flip_panel/flip_panel.dart';

void main() {

  testWidgets('test flip animation run', (tester) async {
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
        equals('${digits.last}')
    );
  });

}
