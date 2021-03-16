import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/src/marker_popup.dart';
import 'package:flutter_map_marker_popup/src/popup_marker_layer_options.dart';
import 'package:latlong/latlong.dart';

class PopupMarkerLayer extends StatelessWidget {
  /// For normal layer behaviour
  final PopupMarkerLayerOptions layerOpts;
  final MapState map;
  final Stream<Null> stream;
  Marker _lastClick;
  final Distance _distance = Distance();

  PopupMarkerLayer(this.layerOpts, this.map, this.stream);

  bool _boundsContainsMarker(Marker marker) {
    var pixelPoint = map.project(marker.point);

    final width = marker.width - marker.anchor.left;
    final height = marker.height - marker.anchor.top;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y - height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);
    return map.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream, // a Stream<int> or null
      builder: (BuildContext _, AsyncSnapshot<int> __) {
        var markers = <Widget>[];

        for (var markerOpt in layerOpts.markers) {
          var pos = map.project(markerOpt.point);
          pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
              map.getPixelOrigin();

          var pixelPosX =
              (pos.x - (markerOpt.width - markerOpt.anchor.left)).toDouble();
          var pixelPosY =
              (pos.y - (markerOpt.height - markerOpt.anchor.top)).toDouble();

          if (!_boundsContainsMarker(markerOpt)) {
            continue;
          }

          var bottomPos = map.pixelBounds.max;
          bottomPos =
              bottomPos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
                  map.getPixelOrigin();

          markers.add(
            Positioned(
              width: markerOpt.width,
              height: markerOpt.height,
              left: pixelPosX,
              top: pixelPosY,
              child: GestureDetector(
                onTap: () {
                  // 找到当前点附近的marker < 20米
                  var markers = layerOpts.markers
                      .where((element) =>
                          _distance.distance(element.point, markerOpt.point) <
                          20)
                      .toList();

                  if (markers.isEmpty) {
                    _lastClick = markerOpt;
                    layerOpts.popupController.togglePopup(markerOpt);
                    return;
                  }

                  var nextIndex = 0;

                  // 找到_lastClick对应的坐标 如果找不到就第一个
                  for (var i = 0; i < markers.length; i++) {
                    var current = markers[i];
                    // 如果上次点击和当前点击的一样
                    if (_lastClick == current) {
                      nextIndex = i + 1;
                      break;
                    }
                  }

                  if (nextIndex == markers.length) {
                    nextIndex = 0;
                  }
                  _lastClick = markers[nextIndex];
                  layerOpts.popupController.togglePopup(_lastClick);
                },
                child: markerOpt.builder(context),
              ),
            ),
          );
        }

        markers.add(
          MarkerPopup(
            mapState: map,
            popupController: layerOpts.popupController,
            snap: layerOpts.popupSnap,
            popupHeight: layerOpts.popupHeight,
            popupBuilder: layerOpts.popupBuilder,
          ),
        );

        return Container(
          child: Stack(
            children: markers,
          ),
        );
      },
    );
  }
}
