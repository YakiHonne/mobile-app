import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../logic/blossom_cubit/blossom_cubit.dart';
import '../../logic/blossom_cubit/blossom_state.dart';
import '../../logic/media_servers_cubit/media_servers_cubit.dart';
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
import '../widgets/custom_icon_buttons.dart';
import '../widgets/empty_list.dart';
import '../widgets/fluid_scaffold.dart';
import '../widgets/fluid_sheet.dart';
import '../widgets/link_previewer.dart';
import '../widgets/pull_down_global_button.dart';
import 'widgets/blossom_media_uploader.dart';
import 'widgets/blossom_server_card.dart';
import 'widgets/blossom_summary_header.dart';

class BlossomManagementView extends StatelessWidget {
  const BlossomManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    // The server list is live: adding the YakiHonne server from the card has to
    // rebuild the cubit, hence the ValueKey.
    return BlocBuilder<MediaServersCubit, MediaServersState>(
      bloc: mediaServersCubit,
      buildWhen: (prev, curr) => prev.blossomServers != curr.blossomServers,
      builder: (context, serversState) {
        final servers = serversState.blossomServers;

        return BlocProvider(
          key: ValueKey(servers.join(',')),
          create: (context) => BlossomCubit(
            repository: BlossomRepository(),
            blossomServers: servers,
            pubkey: currentSigner!.getPublicKey(),
          ),
          child: const BlossomManagementContent(),
        );
      },
    );
  }
}

class BlossomManagementContent extends StatelessWidget {
  const BlossomManagementContent({super.key});

  @override
  Widget build(BuildContext context) {
    return FluidScaffold(
      title: context.t.blossomManagement.capitalizeFirst(),
      description: context.t.blossomManagementDesc.capitalizeFirst(),
      actions: [
        AppIconButton(
          onClicked: () {
            showAppModalSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => BlocProvider.value(
                value: context.read<BlossomCubit>(),
                child: const BlossomMediaUploader(),
              ),
            );
          },
          icon: FeatureIcons.addRaw,
          size: 22,
        ),
      ],
      body: BlocBuilder<BlossomCubit, BlossomState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: fluidScaffoldTopInset(context)),
              ),
              if (state.servers.isNotEmpty)
                SliverToBoxAdapter(child: _buildServerControls(context, state)),
              SliverToBoxAdapter(child: YakiBlossomBanner(state: state)),
              SliverToBoxAdapter(child: BlossomSummaryHeader(state: state)),
              if (state.isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SpinKitCircle(
                      size: kDefaultPadding,
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                )
              else if (state.filteredMedia.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyList(
                    description: context.t.noContentFound,
                    icon: FeatureIcons.media,
                  ),
                )
              else if (state.isGridView)
                _buildGridView(context, state)
              else
                _buildListView(context, state),
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
                        // Our own server gets a crown so it stands out among
                        // the user's third-party ones.
                        if (index > 0 && _isYakiBlossomServer(title))
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: AppIcon(
                              LucideIcons.crown,
                              size: 12,
                              color: isSelected
                                  ? kWhite
                                  : Theme.of(context).primaryColorDark,
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
    return SliverPadding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      sliver: SliverGrid.builder(
        // Extent-based so the grid gains columns on tablets instead of
        // stretching two giant thumbnails across the screen.
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
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
      ),
    );
  }

  Widget _buildListView(BuildContext context, BlossomState state) {
    return SliverPadding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      sliver: SliverList.separated(
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
      ),
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
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showMediaDetails(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        // ponytail: hardEdge, not antiAlias — an antialiased clip costs a
        // saveLayer per tile, and the children already paint their own
        // antialiased rounded corners inside this rect.
        clipBehavior: Clip.hardEdge,
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
                    const Positioned(
                      top: kDefaultPadding / 2 - 2,
                      left: kDefaultPadding / 2 - 2,
                      child: AppIcon(
                        FeatureIcons.video,
                        size: 20,
                        color: kWhite,
                      ),
                    ),
                  Positioned(
                    left: kDefaultPadding / 4,
                    right: kDefaultPadding / 4,
                    bottom: kDefaultPadding / 4,
                    // ponytail: solid pill, not FluidBlurContainer — a
                    // BackdropFilter per tile is the grid's dominant scroll
                    // cost, and at this height a sigma-16 blur is invisible.
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2 - 2,
                        vertical: kDefaultPadding / 4 - 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor.withValues(
                          alpha:
                              theme.brightness == Brightness.dark ? 0.75 : 0.85,
                        ),
                        borderRadius: BorderRadius.circular(300),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _formatShortDate(item.media.uploaded),
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.primaryColorDark,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          const SizedBox(width: kDefaultPadding / 4),
                          Text(
                            formatMediaBytes(item.media.size),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.primaryColorDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kDefaultPadding / 2 - 2,
                kDefaultPadding / 4,
                kDefaultPadding / 4,
                kDefaultPadding / 4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shortHash(item.media.sha256, 8),
                          style: theme.textTheme.labelSmall!.copyWith(
                            color: theme.primaryColorDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: kDefaultPadding / 4 - 3),
                        _ServerDots(
                          serverUrls: item.serverUrls,
                          allServers: allServers,
                        ),
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
}

class _ServerDots extends StatelessWidget {
  const _ServerDots({
    required this.serverUrls,
    required this.allServers,
    this.size = 6.0,
  });

  final List<String> serverUrls;
  final List<String> allServers;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: serverUrls.map((url) {
        final idx = allServers.indexOf(url);
        if (idx == -1) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(right: kDefaultPadding / 4 - 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: mainColorsList[idx % mainColorsList.length],
              shape: BoxShape.circle,
            ),
          ),
        );
      }).toList(),
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
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showMediaDetails(context, item),
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2 - 2),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CommonThumbnail(
                  image: item.media.url,
                  width: 52,
                  height: 52,
                  radius: kDefaultPadding / 4,
                ),
                if (isVideo)
                  const Positioned.fill(
                    child: Center(
                      child: AppIcon(
                        FeatureIcons.video,
                        size: 20,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: kDefaultPadding / 2 + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.media.type,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.primaryColor,
                        ),
                      ),
                      Text(
                        _formatShortDate(item.media.uploaded),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  Text(
                    _shortHash(item.media.sha256, 12),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatMediaBytes(item.media.size),
                        style: theme.textTheme.labelSmall,
                      ),
                      _ServerDots(
                        serverUrls: item.serverUrls,
                        allServers: allServers,
                        size: 8,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: kDefaultPadding / 2 - 2),
            _MediaPullDownButton(item: item),
          ],
        ),
      ),
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
      iconBackgroundColor: kTransparent,
      iconColor: Theme.of(context).highlightColor,
      iconSize: 16,
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
              context, context.t.sizeLabel, formatMediaBytes(item.media.size)),
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

/// `true` when [url] points at the YakiHonne-run blossom server; compared by
/// host so a trailing slash or scheme difference still matches.
bool _isYakiBlossomServer(String url) =>
    Uri.tryParse(url)?.host == Uri.parse(yakiProBlossomServer).host;

String _shortHash(String hash, int length) =>
    hash.length > length ? hash.substring(0, length) : hash;

String _formatShortDate(int timestamp) => DateFormat('MMM d, yyyy')
    .format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));

String _formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  return DateFormat('MMM dd, yyyy, h:mm a').format(date);
}
