import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'utils.dart' as utils;
import 'package:minsk8/import.dart';

typedef void ChangeRadiusCallback(double value);

class MapAreaLayerOptions extends LayerOptions {
  final double markerIconSize;
  final double initialRadius;
  final ChangeRadiusCallback onChangeRadius;
  final Widget currentPosition;
  final Widget readyButton;

  MapAreaLayerOptions({
    this.markerIconSize,
    this.initialRadius,
    this.onChangeRadius,
    this.currentPosition,
    this.readyButton,
  });
}

class MapAreaLayer implements MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    if (!(options is MapAreaLayerOptions)) {
      throw Exception('Unknown options type for MapAreaLayer'
          'plugin: $options');
    }
    return _AreaLayer(options: options, mapState: mapState);
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MapAreaLayerOptions;
  }
}

class _AreaLayer extends StatefulWidget {
  final MapAreaLayerOptions options;
  final MapState mapState;

  _AreaLayer({Key key, this.options, this.mapState}) : super(key: key);

  @override
  _AreaLayerState createState() => _AreaLayerState();
}

const maxRadius = 100.0;

class _AreaLayerState extends State<_AreaLayer>
    with SingleTickerProviderStateMixin {
  final _icon = Icons.location_on;
  final _iconSmallSize = 16.0;
  double _radius;

  @override
  void initState() {
    super.initState();
    _radius = widget.options.initialRadius ?? maxRadius / 2;
  }

  double get paintedRadius {
    final center = widget.mapState.center;
    final targetPoint =
        utils.calculateEndingGlobalCoordinates(center, 90, _radius * 1000);
    final start = widget.mapState.project(center);
    final end = widget.mapState.project(targetPoint);
    return end.x - start.x;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.options.onChangeRadius != null)
          Center(
            child: CustomPaint(
              painter: _AreaLayerPainter(
                radius: paintedRadius,
              ),
            ),
          ),
        if (widget.options.onChangeRadius != null)
          Container(
            margin: EdgeInsets.only(bottom: widget.options.markerIconSize),
            alignment: Alignment.center,
            child: Icon(
              _icon,
              size: widget.options.markerIconSize,
              color: Colors.pinkAccent,
            ),
          ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            widget.options.currentPosition,
            if (widget.options.onChangeRadius != null)
              Container(
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Material(
                  elevation: kButtonElevation,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    alignment: Alignment.center,
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Column(
                      children: [
                        Flexible(
                          flex: 1,
                          child: Container(
                            height: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    TextSpan(
                                      text: 'Радиус',
                                    ),
                                    WidgetSpan(
                                      child: SizedBox(
                                        height: _iconSmallSize,
                                        child: RichText(
                                          text: TextSpan(
                                            text: String.fromCharCode(
                                                _icon.codePoint),
                                            style: TextStyle(
                                              fontSize: _iconSmallSize,
                                              fontFamily: _icon.fontFamily,
                                              color: Colors.pinkAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      style: DefaultTextStyle.of(context)
                                          .style
                                          .copyWith(
                                              fontWeight: FontWeight.w600),
                                      text: '${_radius.toInt()} км',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: Container(
                            child: Slider(
                              value: _radius,
                              onChanged: (value) {
                                setState(() {
                                  _radius = value;
                                  widget.options.onChangeRadius(value);
                                });
                              },
                              min: 1,
                              max: maxRadius,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.options.readyButton != null) widget.options.readyButton,
          ],
        ),
      ],
    );
  }
}

class _AreaLayerPainter extends CustomPainter {
  final double radius;
  final Paint _paintFill;
  final Paint _paintStroke;
  // final double iconSize;
  // final TextPainter _textPainter;

  _AreaLayerPainter({
    this.radius,
    // this.iconSize,
    // IconData icon,
  })  : _paintFill = Paint()
          ..color = Colors.blue.withOpacity(0.1)
          ..strokeWidth = 0
          ..style = PaintingStyle.fill,
        _paintStroke = Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
  // _textPainter = TextPainter(textDirection: TextDirection.rtl)
  //   ..text = TextSpan(
  //       text: String.fromCharCode(icon.codePoint),
  //       style: TextStyle(
  //           fontSize: iconSize,
  //           fontFamily: icon.fontFamily,
  //           color: Colors.pinkAccent))
  //   ..layout();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(0, 0), radius, _paintFill);
    canvas.drawCircle(Offset(0, 0), radius, _paintStroke);
    // _textPainter.paint(
    //     canvas, Offset(-iconSize / 2, -iconSize)); // TODO: +4 ???
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
