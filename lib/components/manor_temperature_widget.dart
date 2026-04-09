import 'package:flutter/material.dart';

class ManorTemperature extends StatelessWidget {
  const ManorTemperature({
    super.key,
    required this.manorTemp,
  });

  final double manorTemp;

  static const List<Color> _tempColors = <Color>[
    Color(0xff072038),
    Color(0xff0d3a65),
    Color(0xff186ec0),
    Color(0xff37b24d),
    Color(0xffffad13),
    Color(0xfff76707),
  ];

  int get _level {
    if (manorTemp <= 20) {
      return 0;
    }
    if (manorTemp <= 32) {
      return 1;
    }
    if (manorTemp <= 36.5) {
      return 2;
    }
    if (manorTemp <= 40) {
      return 3;
    }
    if (manorTemp <= 50) {
      return 4;
    }
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final int level = _level;
    final Color activeColor = _tempColors[level];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            SizedBox(
              width: 65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    '${manorTemp.toStringAsFixed(1)}C',
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 6,
                      color: Colors.black.withValues(alpha: 0.2),
                      child: Row(
                        children: <Widget>[
                          Container(
                            height: 6,
                            width: 65 / 99 * manorTemp,
                            color: activeColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            SizedBox(
              width: 30,
              height: 30,
              child: Image.asset('assets/images/level-$level.jpg'),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Manner Temp',
          style: TextStyle(
            decoration: TextDecoration.underline,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
