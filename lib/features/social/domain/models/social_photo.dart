class SocialPhoto {
  final String id;
  final String fullUrl;   // url ảnh lớn
  final String? thumbUrl; // url thumbnail nếu có
  final int? width;
  final int? height;

  const SocialPhoto({
    required this.id,
    required this.fullUrl,
    this.thumbUrl,
    this.width,
    this.height,
  });

  static List<SocialPhoto> parseFromGetAlbums(dynamic json, {String baseUrl = ''}) {
    // Hàm này "chịu đựng" nhiều format:
    // - { api_status:200, albums:[ {photos:[{...}]} ] }
    // - { api_status:200, data:[ {full:..., image:...} ] }
    // - { api_status:200, albums:{ data:[...] } }
    final out = <SocialPhoto>[];

    String absolutize(String u) {
      if (u.isEmpty) return u;
      if (u.startsWith('http')) return u;
      return baseUrl.isNotEmpty ? baseUrl + u : u;
    }

    dynamic albums = json['albums'] ?? json['data'];
    // TH1: albums là List
    if (albums is List) {
      for (final a in albums) {
        final Map<String, dynamic> am = Map<String, dynamic>.from(a ?? {});
        // Nếu mỗi phần tử là "photo" luôn
        final String id = (am['id'] ?? am['post_id'] ?? am['photo_id'] ?? '').toString();
        final String full = (am['full'] ?? am['postFile_full'] ?? am['image'] ?? am['url'] ?? '').toString();
        final String thumb = (am['thumb'] ?? am['postFile'] ?? '').toString();

        // Nếu có mảng photos
        final photos = am['photos'] as List? ?? am['images'] as List?;
        if (photos != null && photos.isNotEmpty) {
          for (final p in photos) {
            final pm = Map<String, dynamic>.from(p ?? {});
            final pid = (pm['id'] ?? pm['photo_id'] ?? pm['post_id'] ?? '').toString();
            final pfull = (pm['full'] ?? pm['image'] ?? pm['url'] ?? '').toString();
            final pthumb = (pm['thumb'] ?? pm['thumbnail'] ?? '').toString();
            if (pfull.isNotEmpty) {
              out.add(SocialPhoto(
                id: pid.isNotEmpty ? pid : (id.isNotEmpty ? id : pfull),
                fullUrl: absolutize(pfull),
                thumbUrl: pthumb.isNotEmpty ? absolutize(pthumb) : null,
                width: int.tryParse('${pm['width'] ?? ''}'),
                height: int.tryParse('${pm['height'] ?? ''}'),
              ));
            }
          }
          continue;
        }

        // 1 phần tử = 1 ảnh
        if (full.isNotEmpty) {
          out.add(SocialPhoto(
            id: id.isNotEmpty ? id : full,
            fullUrl: absolutize(full),
            thumbUrl: thumb.isNotEmpty ? absolutize(thumb) : null,
            width: int.tryParse('${am['width'] ?? ''}'),
            height: int.tryParse('${am['height'] ?? ''}'),
          ));
        }
      }
    }
    // TH2: albums là Map (ví dụ {data:[...]})
    else if (albums is Map) {
      final list = albums['data'] as List?;
      if (list != null) {
        for (final p in list) {
          final pm = Map<String, dynamic>.from(p ?? {});
          final pid   = (pm['id'] ?? pm['photo_id'] ?? pm['post_id'] ?? '').toString();
          final pfull = (pm['full'] ?? pm['image'] ?? pm['url'] ?? '').toString();
          final pthumb= (pm['thumb'] ?? pm['thumbnail'] ?? '').toString();
          if (pfull.isNotEmpty) {
            out.add(SocialPhoto(
              id: pid.isNotEmpty ? pid : pfull,
              fullUrl: absolutize(pfull),
              thumbUrl: pthumb.isNotEmpty ? absolutize(pthumb) : null,
              width: int.tryParse('${pm['width'] ?? ''}'),
              height: int.tryParse('${pm['height'] ?? ''}'),
            ));
          }
        }
      }
    }

    return out;
  }
}
