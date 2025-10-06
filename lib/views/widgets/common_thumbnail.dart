// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/media_manager_data.dart';
import '../../utils/utils.dart';
import 'curation_container.dart';

class CommonThumbnail extends StatelessWidget {
  const CommonThumbnail({
    super.key,
    required this.image,
    required this.placeholder,
    this.width,
    this.height,
    this.radius,
    this.isRound,
    this.isTopRound,
    this.isLeftRound,
    this.fit,
    this.useDefaultNoMedia = true,
    this.isPfp = false,
  });

  final String image;
  final String placeholder;
  final double? width;
  final double? height;
  final double? radius;
  final bool? isRound;
  final bool? isTopRound;
  final bool? isLeftRound;
  final BoxFit? fit;
  final bool useDefaultNoMedia;
  final bool isPfp;

  // Cache for base64 decoded data to avoid repeated decoding
  static final Map<String, Uint8List> _base64Cache = {};

  @override
  Widget build(BuildContext context) {
    final cleanImage = image.trim();

    if (cleanImage.isEmpty) {
      return _buildPlaceholder(PlaceholderType.error);
    }

    if (isBase64(cleanImage)) {
      return _buildBase64Image();
    }

    return _buildNetworkImage(context, cleanImage);
  }

  Widget _buildBase64Image() {
    try {
      // Use cached data if available, otherwise decode and cache
      final imageData = _base64Cache[image] ?? decodeBase64(image);

      if (imageData == null) {
        return _buildPlaceholder(PlaceholderType.error);
      }

      return _buildExtendedImage(
        imageProvider: ExtendedMemoryImageProvider(
          imageData,
          cacheRawData: true,
        ),
      );
    } catch (_) {
      return _buildPlaceholder(PlaceholderType.error);
    }
  }

  Widget _buildNetworkImage(BuildContext context, String image) {
    return ExtendedImage.network(
      image,
      width: width,
      height: _getEffectiveHeight(),
      compressionRatio: _getCompressionRatio(),
      shape: BoxShape.rectangle,
      borderRadius: _getBorderRadius(),
      fit: fit ?? BoxFit.cover,
      border: _getBorder(context),
      loadStateChanged: _handleLoadState,
    );
  }

  Widget _buildExtendedImage({required ImageProvider imageProvider}) {
    return ExtendedImage(
      image: imageProvider,
      width: width,
      height: _getEffectiveHeight(),
      fit: fit ?? BoxFit.cover,
      borderRadius: _getBorderRadius(),
      shape: BoxShape.rectangle,
      loadStateChanged: _handleLoadState,
    );
  }

  Widget? _handleLoadState(ExtendedImageState state) {
    switch (state.extendedImageLoadState) {
      case LoadState.loading:
        return _buildPlaceholder(PlaceholderType.loading);
      case LoadState.completed:
        return null;
      case LoadState.failed:
        return _getFallback();
    }
  }

  Widget _buildPlaceholder(PlaceholderType type) {
    final effectiveHeight = _getEffectiveHeight();
    final placeholderWidget = _getPlaceholderWidget(type);

    // Handle aspect ratio case
    if (height == 0) {
      return AspectRatio(
        key: const ValueKey('aspectRatio'),
        aspectRatio: 16 / 9,
        child: SizedBox(width: width, child: placeholderWidget),
      );
    }

    return SizedBox(
      width: width,
      height: effectiveHeight,
      child: placeholderWidget,
    );
  }

  Widget _getPlaceholderWidget(PlaceholderType type) {
    final commonProps = _PlaceholderProps(
      height: height,
      width: width,
      isRound: isRound,
      radius: radius,
      isTopRounded: isTopRound,
      isLeftRounded: isLeftRound,
      isPfp: isPfp,
    );

    switch (type) {
      case PlaceholderType.loading:
        return LoadingMediaPlaceHolder(
          height: commonProps.height,
          width: commonProps.width,
          isRound: commonProps.isRound,
          value: commonProps.radius,
          isTopRounded: commonProps.isTopRounded,
          isLeftRounded: commonProps.isLeftRounded,
          isPfp: commonProps.isPfp,
        );
      case PlaceholderType.error:
        return NoMediaPlaceHolder(
          height: commonProps.height,
          width: commonProps.width,
          isRound: commonProps.isRound,
          image: placeholder,
          isError: true,
          value: commonProps.radius,
          useDefault: useDefaultNoMedia,
          isTopRounded: commonProps.isTopRounded,
          isLeftRounded: commonProps.isLeftRounded,
        );
    }
  }

  BorderRadius? _getBorderRadius() {
    final defaultRadius = radius ?? kDefaultPadding;

    if (isTopRound ?? false) {
      return BorderRadius.only(
        topLeft: Radius.circular(defaultRadius),
        topRight: Radius.circular(defaultRadius),
      );
    }

    if (isLeftRound ?? false) {
      return BorderRadius.only(
        topLeft: Radius.circular(defaultRadius),
        bottomLeft: Radius.circular(defaultRadius),
      );
    }

    return BorderRadius.circular(defaultRadius);
  }

  Border? _getBorder(BuildContext context) {
    return radius != null
        ? null
        : Border.all(color: Theme.of(context).primaryColorLight);
  }

  double? _getEffectiveHeight() {
    return height == 0 ? null : height;
  }

  double _getCompressionRatio() {
    if (height == 0 || width == 0 || height == null || width == null) {
      return 1.0;
    }
    return width! / height!;
  }

  Widget _getFallback() {
    return FutureBuilder<BlossomFetchResult>(
      future: mediaServersCubit.fetchBlossomBlob(url: image),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildPlaceholder(PlaceholderType.loading);
        }

        final data = snapshot.data!;
        if (data.success && data.data != null) {
          return _buildBlobImage(data.data!);
        }

        return _buildPlaceholder(PlaceholderType.error);
      },
    );
  }

  Widget _buildBlobImage(Uint8List imageData) {
    try {
      return _buildExtendedImage(
        imageProvider: ExtendedMemoryImageProvider(
          imageData,
          cacheRawData: true,
        ),
      );
    } catch (_) {
      return _buildPlaceholder(PlaceholderType.error);
    }
  }
}

class _PlaceholderProps {
  const _PlaceholderProps({
    required this.height,
    required this.width,
    required this.isRound,
    required this.radius,
    required this.isTopRounded,
    required this.isLeftRounded,
    required this.isPfp,
  });

  final double? height;
  final double? width;
  final bool? isRound;
  final double? radius;
  final bool? isTopRounded;
  final bool? isLeftRounded;
  final bool isPfp;
}
