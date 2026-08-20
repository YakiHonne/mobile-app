// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
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
    this.memoryUrl,
    this.assetUrl,
    this.width,
    this.height,
    this.radius,
    this.isRound,
    this.isTopRound,
    this.isLeftRound,
    this.fit,
    this.useDefaultNoMedia = true,
    this.isPfp = false,
    this.fullResolution = false,
  });

  final String image;
  final String? memoryUrl;
  final String? assetUrl;
  final double? width;
  final double? height;
  final double? radius;
  final bool? isRound;
  final bool? isTopRound;
  final bool? isLeftRound;
  final BoxFit? fit;
  final bool useDefaultNoMedia;
  final bool isPfp;

  /// Decode at the image's native resolution instead of capping at the
  /// display size. Only for zoomable full-screen viewers.
  final bool fullResolution;

  @override
  Widget build(BuildContext context) {
    if (memoryUrl != null) {
      final file = File(memoryUrl!);
      return _buildFileImage(context, file);
    }

    if (assetUrl != null && image.isEmpty) {
      return _buildAssetImage(context, assetUrl!);
    }

    final cleanImage = image.trim();

    if (cleanImage.isEmpty) {
      return _buildPlaceholder(PlaceholderType.error);
    }

    if (isBase64(cleanImage)) {
      return _buildBase64Image(context);
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: _getBorderRadius(),
      ),
      child: _buildNetworkImage(
        context,
        cleanImage,
      ),
    );
  }

  ExtendedImage _buildFileImage(BuildContext context, File file) {
    return ExtendedImage.file(
      file,
      width: width,
      height: height,
      cacheWidth: _getCacheWidth(context),
      fit: fit,
      borderRadius: _getBorderRadius(),
      shape: BoxShape.rectangle,
      border: _getBorder(context),
      loadStateChanged: _handleLoadState,
    );
  }

  Widget _buildAssetImage(BuildContext context, String assetUrl) {
    if (assetUrl.trim().endsWith('.svg')) {
      return SvgPicture.asset(
        assetUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
      );
    }
    return ExtendedImage.asset(
      assetUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: _getBorderRadius(),
      shape: BoxShape.rectangle,
      border: _getBorder(context),
      loadStateChanged: _handleLoadState,
    );
  }

  Widget _buildBase64Image(BuildContext context) {
    try {
      final imageData = decodeBase64(image);

      if (imageData == null) {
        return _buildPlaceholder(PlaceholderType.error);
      }

      return _buildExtendedImage(
        context: context,
        imageProvider: ExtendedMemoryImageProvider(imageData),
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
      cacheWidth: _getCacheWidth(context),
      shape: BoxShape.rectangle,
      borderRadius: _getBorderRadius(),
      fit: fit ?? BoxFit.cover,
      border: _getBorder(context),
      loadStateChanged: _handleLoadState,
    );
  }

  Widget _buildExtendedImage({
    required BuildContext context,
    required ImageProvider imageProvider,
  }) {
    return ExtendedImage(
      image: ExtendedResizeImage.resizeIfNeeded(
        provider: imageProvider,
        cacheWidth: _getCacheWidth(context),
      ),
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
          value: commonProps.radius,
          isTopRounded: commonProps.isTopRounded,
          isLeftRounded: commonProps.isLeftRounded,
          isPfp: isPfp,
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

  /// Decode target in physical pixels: the widget's own width when known,
  /// otherwise the screen width. Without this, large images are decoded at
  /// their native resolution (a 4000x3000 photo is ~48MB decoded) even when
  /// rendered as a small thumbnail, which piles up fast in feeds and gets the
  /// app killed on low-RAM devices.
  int? _getCacheWidth(BuildContext context) {
    if (fullResolution) {
      return null;
    }

    final logicalWidth = (width != null && width! > 0 && width!.isFinite)
        ? width!
        : MediaQuery.sizeOf(context).width;

    return (logicalWidth * MediaQuery.devicePixelRatioOf(context)).round();
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
          return _buildBlobImage(context, data.data!);
        }

        return _buildPlaceholder(PlaceholderType.error);
      },
    );
  }

  Widget _buildBlobImage(BuildContext context, Uint8List imageData) {
    try {
      return _buildExtendedImage(
        context: context,
        imageProvider: ExtendedMemoryImageProvider(imageData),
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
