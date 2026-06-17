import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('coin-flip filmstrip', (tester) async {
    tester.view.physicalSize = const Size(2400, 520);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const brand = Color(0xFF6260FF);
    final key = GlobalKey();
    final frames = [0.0, 0.12, 0.22, 0.33, 0.46, 0.6, 0.78, 1.0];

    double scaleFor(double t) {
      if (t <= 0.35) return 1 + 0.3 * Curves.easeOut.transform(t / 0.35);
      return 1.3 + (1.0 - 1.3) * Curves.elasticOut.transform((t - 0.35) / 0.65);
    }

    Widget cell(double t) {
      final flip = Curves.easeOutCubic.transform(t) * 2 * math.pi;
      final s = scaleFor(t);
      final m = Matrix4.identity()
        ..setEntry(3, 2, 0.0016)
        ..rotateY(flip)
        ..scaleByDouble(s, s, s, 1);
      return Container(
        width: 96, height: 96,
        margin: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF23232B), width: 1.5)),
        child: Center(child: Transform(alignment: Alignment.center, transform: m,
          child: const Icon(Icons.shopping_basket_rounded, size: 42, color: brand))),
      );
    }

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF4F5FB),
        body: Center(
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: const Color(0xFFF4F5FB),
              padding: const EdgeInsets.all(24),
              child: Row(mainAxisSize: MainAxisSize.min, children: [for (final t in frames) cell(t)]),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('/tmp/coin_flip_filmstrip.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
