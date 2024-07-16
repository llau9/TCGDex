import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;

class ImagePreprocessor {
  static List<Offset> orderPoints(List<Offset> pts) {
    List<Offset> rect = List.filled(4, Offset.zero);
    List<double> s = pts.map((p) => p.dx + p.dy).toList();
    rect[0] = pts[s.indexOf(s.reduce((a, b) => a < b ? a : b))];
    rect[2] = pts[s.indexOf(s.reduce((a, b) => a > b ? a : b))];
    List<double> diff = pts.map((p) => p.dx - p.dy).toList();
    rect[1] = pts[diff.indexOf(diff.reduce((a, b) => a < b ? a : b))];
    rect[3] = pts[diff.indexOf(diff.reduce((a, b) => a > b ? a : b))];

    return rect;
  }

  Future<img.Image?> fourPointTransform(img.Image image, List<Offset> pts) async {
    List<Offset> rect = orderPoints(pts);
    Offset tl = rect[0], tr = rect[1], br = rect[2], bl = rect[3];

    double widthA = (br - bl).distance;
    double widthB = (tr - tl).distance;
    int maxWidth = widthA > widthB ? widthA.round() : widthB.round();
    double heightA = (tr - br).distance;
    double heightB = (tl - bl).distance;
    int maxHeight = heightA > heightB ? heightA.round() : heightB.round();

    var srcPoints = cv.VecPoint2f.fromList([
      cv.Point2f(tl.dx, tl.dy),
      cv.Point2f(tr.dx, tr.dy),
      cv.Point2f(br.dx, br.dy),
      cv.Point2f(bl.dx, bl.dy),
    ]);
    
    var dstPoints = cv.VecPoint2f.fromList([
      cv.Point2f(0, 0),
      cv.Point2f(maxWidth - 1.0, 0),
      cv.Point2f(maxWidth - 1.0, maxHeight - 1.0),
      cv.Point2f(0, maxHeight - 1.0),
    ]);

    Uint8List srcBytes = Uint8List.fromList(image.getBytes());
    var srcImageMat = cv.imdecode(srcBytes, cv.IMREAD_COLOR);
    var transformMatrix = cv.getPerspectiveTransform2f(srcPoints, dstPoints);
    var dstImageMat = cv.warpPerspective(srcImageMat, transformMatrix, (maxWidth, maxHeight));

    Uint8List dstBytes = cv.imencode(".png", dstImageMat);
    return img.decodeImage(dstBytes);
  }

  Future<List<img.Image>> isolateRegions(File imageFile) async {
    img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;

    Uint8List srcBytes = Uint8List.fromList(image.getBytes());
    var srcMat = cv.imdecode(srcBytes, cv.IMREAD_COLOR);
    var grayMat = cv.cvtColor(srcMat, cv.COLOR_BGR2GRAY);
    var cannyMat = cv.canny(grayMat, 50, 200);

    // Capture the tuple returned by findContours
    var contoursResult = cv.findContours(cannyMat, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
    var contours = contoursResult.$1;
    var hierarchy = contoursResult.$2;

    var sortedContours = contours.toList();
    sortedContours.sort((a, b) => cv.contourArea(b).compareTo(cv.contourArea(a)));

    var largestContour = sortedContours[0];
    var approx = cv.approxPolyDP(largestContour, 0.02 * cv.arcLength(largestContour, true), true);

    List<Offset> approxOffsets = approx.toList().map((p) => Offset(p.x.toDouble(), p.y.toDouble())).toList();

    img.Image? warped = await fourPointTransform(image, approxOffsets);

    img.Image normalizedImage = img.copyResize(warped!, width: 600, height: 825);

    img.Image nameRegion = img.copyCrop(
      normalizedImage,
      x: 5,
      y: 0,
      width: 400,
      height: 90
    );
    img.Image hpRegion = img.copyCrop(
      normalizedImage,
      x: 400,
      y: 0,
      width: 200,
      height: 90
    );
    img.Image moveRegion = img.copyCrop(
      normalizedImage,
      x: 10,
      y: 420,
      width: 580,
      height: 310
    );
    img.Image setSymbolRegion = img.copyCrop(
      normalizedImage,
      x: 10,
      y: 730,
      width: 580,
      height: 95
    );

    return [normalizedImage, nameRegion, hpRegion, moveRegion, setSymbolRegion];
  }
}
