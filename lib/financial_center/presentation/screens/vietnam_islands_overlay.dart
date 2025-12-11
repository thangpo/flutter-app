// vietnam_islands_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class VietnamIslandsOverlay extends StatelessWidget {
  final bool isDark;

  const VietnamIslandsOverlay({
    super.key,
    required this.isDark,
  });

  // Bounds ảnh Hoàng Sa (góc tây-nam & đông-bắc)
  static final LatLngBounds _hoangSaBounds = LatLngBounds(
    LatLng(15.6, 110.9), // southwest
    LatLng(17.6, 113.2), // northeast
  );

  // Bounds ảnh Trường Sa
  static final LatLngBounds _truongSaBounds = LatLngBounds(
    LatLng(8.2, 111.2),
    LatLng(11.8, 115.8),
  );

  @override
  Widget build(BuildContext context) {
    return OverlayImageLayer(
      overlayImages: [
        OverlayImage(
          bounds: _hoangSaBounds,
          opacity: 1.0,
          imageProvider: const AssetImage('assets/images/hoang_sa.png'),
        ),
        OverlayImage(
          bounds: _truongSaBounds,
          opacity: 1.0,
          imageProvider: const AssetImage('assets/images/truong_sa.png'),
        ),
      ],
    );
  }

  // Nếu sau này vẫn muốn test vùng cấm zoom thì giữ hàm này
  static bool isInForbiddenArea(LatLng p) {
    bool inHoangSa = p.latitude >= 15.8 &&
        p.latitude <= 17.3 &&
        p.longitude >= 111.1 &&
        p.longitude <= 113.0;

    bool inTruongSa = p.latitude >= 8.5 &&
        p.latitude <= 11.5 &&
        p.longitude >= 111.5 &&
        p.longitude <= 115.5;

    return inHoangSa || inTruongSa;
  }
}