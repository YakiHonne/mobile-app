import 'package:equatable/equatable.dart';

class BlossomMedia extends Equatable {
  const BlossomMedia({
    required this.url,
    required this.sha256,
    required this.size,
    required this.type,
    required this.uploaded,
    this.blurhash,
    this.dim,
  });

  factory BlossomMedia.fromJson(Map<String, dynamic> json) {
    return BlossomMedia(
      url: json['url'] as String,
      sha256: json['sha256'] as String,
      size: json['size'] as int,
      type: json['type'] as String,
      uploaded: json['uploaded'] as int,
      blurhash: json['blurhash'] as String?,
      dim: json['dim'] as String?,
    );
  }
  final String url;
  final String sha256;
  final int size;
  final String type;
  final int uploaded;
  final String? blurhash;
  final String? dim;

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'sha256': sha256,
      'size': size,
      'type': type,
      'uploaded': uploaded,
      'blurhash': blurhash,
      'dim': dim,
    };
  }

  @override
  List<Object?> get props => [
        url,
        sha256,
        size,
        type,
        uploaded,
        blurhash,
        dim,
      ];
}

class BlossomAggregatedMedia extends Equatable {
  const BlossomAggregatedMedia({
    required this.media,
    required this.serverUrls,
  });
  final BlossomMedia media;
  final List<String> serverUrls;

  @override
  List<Object?> get props => [media, serverUrls];
}
