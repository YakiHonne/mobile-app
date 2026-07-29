import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';

import '../../logic/blossom_cubit/blossom_cubit.dart';
import '../../logic/blossom_cubit/blossom_state.dart';
import '../../models/blossom_media.dart';
import '../../repositories/blossom_repository.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../add_content_view/add_content_view.dart';
import '../gallery_view/gallery_view.dart';
import '../profile_view/widgets/profile_media.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/common_thumbnail.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/empty_list.dart';
import '../widgets/link_previewer.dart';
import '../widgets/pull_down_global_button.dart';
import 'widgets/blossom_media_uploader.dart';

class BlossomManagementView extends StatelessWidget {
  const BlossomManagementView({
    super.key,
    required this.blossomServers,
  });

  final List<String> blossomServers;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BlossomCubit(
        repository: BlossomRepository(),
        blossomServers: blossomServers,
        pubkey: currentSigner!.getPublicKey(),
      ),
      child: const BlossomManagementContent(),
    );
  }
}

class BlossomManagementContent extends StatelessWidget {
  const BlossomManagementContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.t.blossomManagement.capitalizeFirst(),
        description: context.t.blossomManagementDesc.capitalizeFirst(),
        actions: [
          CustomIconButton(
            onClicked: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: context.read<BlossomCubit>(),
                  child: const BlossomMediaUploader(),
                ),
              );
            },
            icon: FeatureIcons.addRaw,
            size: 15,
            vd: -1,
            backgroundColor: Theme.of(context).cardColor,
          ),
          const SizedBox(width: kDefaultPadding / 2),
        ],
      ),
      body: BlocBuilder<BlossomCubit, BlossomState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildServerControls(context, state),
              Expanded(
                child: state.isLoading
                    ? Center(
                        child: SpinKitCircle(
                        size: kDefaultPadding,
                        color: Theme.of(context).primaryColorDark,
                      ))
                    : state.filteredMedia.isEmpty
                        ? EmptyList(
                            description: context.t.noContentFound,
                            icon: FeatureIcons.media,
                          )
                        : state.isGridView
                            ? _buildGridView(context, state)
                            : _buildListView(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServerControls(BuildContext context, BlossomState state) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 4),
              itemBuilder: (context, index) {
                final isSelected = state.selectedServerIndex == index - 1;
                final String title = index == 0
                    ? context.t.allServers
                    : state.servers[index - 1];

                return GestureDetector(
                  onTap: () =>
                      context.read<BlossomCubit>().selectFilter(index - 1),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index > 0)
                          DotContainer(
                            color: mainColorsList[
                                (index - 1) % mainColorsList.length],
                            size: 6,
                            isNotMarging: true,
                          ),
                        if (index > 0) const SizedBox(width: 4),
                        Text(
                          index == 0 ? title : title.split('//').last,
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: isSelected
                                        ? kWhite
                                        : Theme.of(context).primaryColorDark,
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemCount: state.servers.length + 1,
            ),
          ),
          const VerticalDivider(width: 1),
          CustomIconButton(
            onClicked: () => context.read<BlossomCubit>().toggleViewMode(),
            icon: state.isGridView ? FeatureIcons.grid : FeatureIcons.list,
            size: 18,
            backgroundColor: kTransparent,
            iconColor: Theme.of(context).primaryColorDark,
            vd: -1,
          ),
          const SizedBox(width: kDefaultPadding / 4),
        ],
      ),
    );
  }

  Widget _buildGridView(BuildContext context, BlossomState state) {
    return GridView.builder(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: kDefaultPadding / 4,
        mainAxisSpacing: kDefaultPadding / 4,
        childAspectRatio: 0.85,
      ),
      itemCount: state.filteredMedia.length,
      itemBuilder: (context, index) {
        final item = state.filteredMedia[index];
        return _BlossomMediaGridItem(
          item: item,
          allServers: state.servers,
        );
      },
    );
  }

  Widget _buildListView(BuildContext context, BlossomState state) {
    return ListView.separated(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      itemCount: state.filteredMedia.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: kDefaultPadding / 4),
      itemBuilder: (context, index) {
        final item = state.filteredMedia[index];
        return _BlossomMediaListItem(
          item: item,
          allServers: state.servers,
        );
      },
    );
  }
}

class _BlossomMediaGridItem extends StatelessWidget {
  const _BlossomMediaGridItem({
    required this.item,
    required this.allServers,
  });

  final BlossomAggregatedMedia item;
  final List<String> allServers;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.media.type.startsWith('video/');

    return GestureDetector(
      onTap: () => _showMediaDetails(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isVideo)
                    VideoThumbnailCard(
                      url: item.media.url,
                      onTap: () {},
                      useIcon: false,
                    )
                  else
                    CommonThumbnail(
                      image: item.media.url,
                      radius: kDefaultPadding / 2,
                    ),
                  if (isVideo)
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: AppIcon(
                          FeatureIcons.video,
                          color: kWhite,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.media.sha256.sixCharacters(),
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                        ),
                        const SizedBox(height: 1),
                        _buildServerIndicators(),
                      ],
                    ),
                  ),
                  _MediaPullDownButton(item: item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerIndicators() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: item.serverUrls.map((url) {
          final serverIndex = allServers.indexOf(url);
          if (serverIndex == -1) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: DotContainer(
              color: mainColorsList[serverIndex % mainColorsList.length],
              size: 6,
              isNotMarging: true,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BlossomMediaListItem extends StatelessWidget {
  const _BlossomMediaListItem({
    required this.item,
    required this.allServers,
  });

  final BlossomAggregatedMedia item;
  final List<String> allServers;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.media.type.startsWith('video/');

    return InkWell(
      onTap: () => _showMediaDetails(context, item),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CommonThumbnail(
                  image: item.media.url,
                  width: 50,
                  height: 50,
                  radius: 4,
                ),
                if (isVideo)
                  const Positioned.fill(
                    child: Center(
                      child: AppIcon(
                        FeatureIcons.video,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.media.type,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      Text(
                        _formatDate(item.media.uploaded),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  Text(
                    item.media.sha256.nineCharacters(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatBytes(item.media.size),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      _buildServerIndicators(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _MediaPullDownButton(item: item),
          ],
        ),
      ),
    );
  }

  Widget _buildServerIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: item.serverUrls.map((url) {
        final serverIndex = allServers.indexOf(url);
        if (serverIndex == -1) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: DotContainer(
            color: mainColorsList[serverIndex % mainColorsList.length],
            size: 8,
            isNotMarging: true,
          ),
        );
      }).toList(),
    );
  }
}

class _MediaPullDownButton extends StatelessWidget {
  const _MediaPullDownButton({required this.item});

  final BlossomAggregatedMedia item;

  @override
  Widget build(BuildContext context) {
    final servers = context.watch<BlossomCubit>().state.servers;
    final enableMirror =
        servers.length > 1 && item.serverUrls.length < servers.length;

    return PullDownGlobalButton(
      enableView: true,
      onView: () {
        final isVideo = item.media.type.startsWith('video/');

        openGallery(
          source:
              MapEntry(item.media.url, isVideo ? UrlType.video : UrlType.image),
          index: 0,
          context: context,
        );
      },
      enableDownload: !item.media.type.startsWith('video/'),
      onDownload: () => _downloadFile(context, item.media),
      enablePostInNote: true,
      onPostInNote: () => YNavigator.pushPage(
        context,
        (context) => AddContentView(
          contentType: AppContentType.note,
          content: '\n${item.media.url}',
        ),
      ),
      enableCopyHash: true,
      onCopyHash: () {
        Clipboard.setData(ClipboardData(text: item.media.sha256));
        BotToastUtils.showSuccess(context.t.textSuccesfulyCopied);
      },
      enableCopyUrl: true,
      onCopyUrl: () {
        Clipboard.setData(ClipboardData(text: item.media.url));
        BotToastUtils.showSuccess(context.t.textSuccesfulyCopied);
      },
      enableMirror: enableMirror,
      onMirror: () => context.read<BlossomCubit>().mirrorMedia(item),
      enableDelete: true,
      onDelete: () => _confirmDelete(context, item.media.sha256),
      buttonColor: Theme.of(context).cardColor.withValues(alpha: 0.8),
    );
  }
}

class BlossomMediaDetails extends StatelessWidget {
  const BlossomMediaDetails({super.key, required this.item});

  final BlossomAggregatedMedia item;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.media.type.startsWith('video/');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(kDefaultPadding),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: kDefaultPadding),
            _buildHeader(context),
            const SizedBox(height: kDefaultPadding),
            _buildMediaPreview(context, isVideo),
            const SizedBox(height: kDefaultPadding),
            if (!isVideo) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                child: TextButton(
                  onPressed: () => _downloadFile(context, item.media),
                  style: TextButton.styleFrom(
                    backgroundBuilder: (_, __, child) => child!,
                    backgroundColor: kMainColor,
                    foregroundColor: kWhite,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppIcon(
                        FeatureIcons.download,
                        size: 20,
                        color: kWhite,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.t.downloadFile.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: kWhite,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: kDefaultPadding),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _metadataColumn(context, context.t.mime, item.media.type),
          _metadataColumn(
              context, context.t.hashLabel, item.media.sha256.sixCharacters()),
          _metadataColumn(
              context, context.t.dateLabel, _formatDate(item.media.uploaded)),
          _metadataColumn(
              context, context.t.sizeLabel, _formatBytes(item.media.size)),
        ],
      ),
    );
  }

  Widget _metadataColumn(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).highlightColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).primaryColorDark,
              ),
        ),
      ],
    );
  }

  Widget _buildMediaPreview(BuildContext context, bool isVideo) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: isVideo
          ? AspectRatio(
              aspectRatio: 16 / 9,
              child: RegularVideoPlayer(
                link: item.media.url,
                autoPlay: true,
              ),
            )
          : CommonThumbnail(
              image: item.media.url,
              fit: BoxFit.cover,
              radius: kDefaultPadding / 2,
            ),
    );
  }
}

void _showMediaDetails(BuildContext context, BlossomAggregatedMedia item) {
  final isVideo = item.media.type.startsWith('video/');

  openGallery(
    source: MapEntry(item.media.url, isVideo ? UrlType.video : UrlType.image),
    index: 0,
    context: context,
  );
}

void _confirmDelete(BuildContext context, String hash) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.t.delete),
      content: Text(context.t.confirmDeleteMedia),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<BlossomCubit>().deleteMedia(hash);
          },
          child: Text(
            context.t.delete,
            style: Theme.of(context)
                .textTheme
                .labelLarge!
                .copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    ),
  );
}

Future<void> _downloadFile(BuildContext context, BlossomMedia media) async {
  botUtilsLoadingProgressCubit.emitStatus(t.downloading);
  final cancel = BotToastUtils.showLoading();

  try {
    final dio = Dio();
    final response = await dio.get<List<int>>(
      media.url,
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.data == null) {
      return;
    }

    final result = await ImageGallerySaverPlus.saveImage(
      Uint8List.fromList(response.data!),
      name: media.sha256,
    );

    cancel();
    if (result['isSuccess'] == true) {
      BotToastUtils.showSuccess(t.downloadSuccessful);
    } else {
      BotToastUtils.showError(t.downloadFailed);
    }
  } catch (e) {
    cancel();
    BotToastUtils.showError(t.downloadFailed);
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
}

String _formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  return DateFormat('MMM dd, yyyy, h:mm a').format(date);
}
