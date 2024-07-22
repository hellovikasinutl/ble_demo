
import 'dart:ui';
class Layout{
  double get pixelRatio => window.devicePixelRatio;
  Size get size => window.physicalSize/pixelRatio;
  double get width => size.width;
  double get height  => size.height;
}

