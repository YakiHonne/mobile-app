// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
// import 'package:nostr_core_enhanced/nostr/event_signer/event_signer.dart';
// import 'package:responsive_framework/responsive_framework.dart';

// import '../../../logic/add_media_cubit/add_media_cubit.dart';
// import '../../../models/picture_model.dart';
// import '../../../models/video_model.dart';
// import '../../../utils/utils.dart';
// import '../../widgets/common_thumbnail.dart';
// import '../../widgets/dotted_container.dart';
// import '../../widgets/publish_content_final_step.dart';
// import '../../widgets/single_image_selector.dart';
// import '../related_adding_views/article_widgets/article_details.dart';

// class AddMediaSpecificationView extends HookWidget {
//   const AddMediaSpecificationView({
//     required this.signer,
//     required this.media,
//     required this.isVideo,
//     super.key,
//   });

//   final EventSigner signer;
//   final File media;
//   final bool isVideo;

//   @override
//   Widget build(BuildContext context) {
//     final title = useState<String>('');
//     final description = useState<String>('');
//     final imageLink = useState<String>('');
//     final tags = useState<List<String>>([]);
//     final isSensitive = useState<bool>(false);

//     return Container(
//       width: double.infinity,
//       padding:
//           EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//         border: Border.all(
//           color: Theme.of(context).dividerColor,
//           width: 0.5,
//         ),
//         color: Theme.of(context).scaffoldBackgroundColor,
//       ),
//       child: DraggableScrollableSheet(
//         initialChildSize: 0.95,
//         minChildSize: 0.60,
//         maxChildSize: 0.95,
//         expand: false,
//         builder: (context, scrollController) => Column(
//           children: [
//             const ModalBottomSheetHandle(),
//             Expanded(
//               child: MediaDetails(
//                 scrollController: scrollController,
//                 onTitleChanged: (value) => title.value = value,
//                 onDescChanged: (value) => description.value = value,
//                 onImageLinkChanged: (value) => imageLink.value = value,
//                 onTagsChanged: (value) => tags.value = value,
//                 onSensitiveChanged: (value) => isSensitive.value = value,
//                 isVideo: isVideo,
//               ),
//             ),
//             Container(
//               height: kBottomNavigationBarHeight +
//                   MediaQuery.of(context).padding.bottom,
//               padding: EdgeInsets.only(
//                 left: kDefaultPadding / 2,
//                 right: kDefaultPadding / 2,
//                 bottom: MediaQuery.of(context).padding.bottom / 2,
//               ),
//               child: _publish(
//                 context: context,
//                 title: title.value,
//                 description: description.value,
//                 tags: tags.value,
//                 imageLink: imageLink.value,
//                 isSensitive: isSensitive.value,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _publish({
//     required BuildContext context,
//     required String title,
//     required String description,
//     required List<String> tags,
//     required String imageLink,
//     required bool isSensitive,
//   }) {
//     return Row(
//       children: [
//         Expanded(
//           child: TextButton(
//             onPressed: () {
//               context.read<AddMediaCubit>().addMedia(
//                     signer: signer,
//                     media: media,
//                     isVideo: isVideo,
//                     title: title,
//                     description: description,
//                     tags: tags,
//                     imageLink: imageLink,
//                     isSensitive: isSensitive,
//                     onSuccess: (e) {
//                       Navigator.pop(context);
//                       Navigator.pop(context);

//                       showModalBottomSheet(
//                         context: context,
//                         elevation: 0,
//                         builder: (_) {
//                           return PublishContentFinalStep(
//                             appContentType: isVideo
//                                 ? AppContentType.video
//                                 : AppContentType.picture,
//                             event: isVideo
//                                 ? VideoModel.fromEvent(e)
//                                 : PictureModel.fromEvent(e),
//                           );
//                         },
//                         isScrollControlled: true,
//                         useRootNavigator: true,
//                         useSafeArea: true,
//                         backgroundColor:
//                             Theme.of(context).scaffoldBackgroundColor,
//                       );
//                     },
//                   );
//             },
//             child: Text(
//               context.t.publish.capitalize(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class MediaDetails extends HookWidget {
//   const MediaDetails({
//     super.key,
//     this.scrollController,
//     required this.onTitleChanged,
//     required this.onDescChanged,
//     required this.onImageLinkChanged,
//     required this.onTagsChanged,
//     required this.onSensitiveChanged,
//     required this.isVideo,
//   });

//   final bool isVideo;
//   final ScrollController? scrollController;
//   final Function(String) onTitleChanged;
//   final Function(String) onDescChanged;
//   final Function(String) onImageLinkChanged;
//   final Function(List<String>) onTagsChanged;
//   final Function(bool) onSensitiveChanged;

//   @override
//   Widget build(BuildContext context) {
//     final tagsController = useTextEditingController(text: '');
//     final tags = useState<List<String>>([]);
//     final isSensitive = useState<bool>(false);
//     final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
//     final components = <Widget>[];
//     final imageLink = useState('');

//     components.add(PublishPreviewContainer(
//       onTitleChanged: onTitleChanged,
//       onDescChanged: onDescChanged,
//       imageLink: imageLink.value,
//       isVideo: isVideo,
//       onImageLinkChanged: (value) {
//         imageLink.value = value;
//         onImageLinkChanged(value);
//       },
//     ));

//     components.add(
//       const SizedBox(
//         height: kDefaultPadding / 2,
//       ),
//     );

//     components.add(
//       ArticleCheckBoxListTile(
//         isEnabled: true,
//         status: isSensitive.value,
//         text: context.t.sensitiveContent,
//         onToggle: () {
//           onSensitiveChanged(isSensitive.value);
//           isSensitive.value = !isSensitive.value;
//         },
//       ),
//     );

//     components.add(
//       const SizedBox(
//         height: kDefaultPadding / 2,
//       ),
//     );

//     components.add(
//       TextFormField(
//         cursorColor: Theme.of(context).primaryColorDark,
//         decoration: InputDecoration(
//           hintText: context.t.typeKeywords,
//         ),
//         style: Theme.of(context).textTheme.bodyMedium,
//         controller: tagsController,
//         onFieldSubmitted: (text) {
//           if (text.isNotEmpty && !tags.value.contains(text.trim())) {
//             tags.value = [...tags.value, text.trim()];
//             tagsController.clear();
//             onTagsChanged(tags.value);
//           }
//         },
//       ),
//     );

//     components.add(Builder(
//       builder: (context) {
//         if (tags.value.isNotEmpty) {
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(
//                 height: kDefaultPadding / 2,
//               ),
//               Wrap(
//                 runSpacing: kDefaultPadding / 4,
//                 spacing: kDefaultPadding / 4,
//                 children: tags.value
//                     .map(
//                       (keyword) => Chip(
//                         visualDensity: const VisualDensity(vertical: -4),
//                         backgroundColor: Theme.of(context).cardColor,
//                         label: Text(
//                           keyword,
//                           style:
//                               Theme.of(context).textTheme.labelMedium!.copyWith(
//                                     height: 1.5,
//                                   ),
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(200),
//                           side: const BorderSide(
//                             color: kTransparent,
//                           ),
//                         ),
//                         onDeleted: () {
//                           tags.value = [...tags.value..remove(keyword)];
//                           onTagsChanged(tags.value);
//                         },
//                       ),
//                     )
//                     .toList(),
//               )
//             ],
//           );
//         }

//         return const SizedBox.shrink();
//       },
//     ));

//     return ListView(
//       padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
//       controller: scrollController,
//       children: components,
//     );
//   }
// }

// class PublishPreviewContainer extends HookWidget {
//   const PublishPreviewContainer({
//     super.key,
//     required this.onTitleChanged,
//     required this.onDescChanged,
//     required this.imageLink,
//     required this.onImageLinkChanged,
//     required this.isVideo,
//   });

//   final Function(String) onTitleChanged;
//   final Function(String) onDescChanged;
//   final Function(String) onImageLinkChanged;
//   final bool isVideo;
//   final String imageLink;

//   @override
//   Widget build(BuildContext context) {
//     final titleController = useTextEditingController();
//     final summaryController = useTextEditingController();

//     return Container(
//       padding: const EdgeInsets.all(kDefaultPadding / 2),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
//         border: Border.all(
//           color: Theme.of(context).dividerColor,
//           width: 0.5,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             context.t.preview.capitalizeFirst(),
//             style: Theme.of(context).textTheme.titleLarge!.copyWith(
//                   fontWeight: FontWeight.w800,
//                 ),
//           ),
//           const Divider(
//             thickness: 0.5,
//           ),
//           const SizedBox(
//             height: kDefaultPadding / 4,
//           ),
//           _titleTextfield(titleController, context),
//           const SizedBox(
//             height: kDefaultPadding / 2,
//           ),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _summaryTextfield(summaryController, context),
//               if (isVideo) ...[
//                 const SizedBox(
//                   width: kDefaultPadding / 4,
//                 ),
//                 _imageContainer(),
//               ]
//             ],
//           )
//         ],
//       ),
//     );
//   }

//   Flexible _imageContainer() {
//     return Flexible(
//       flex: 2,
//       child: Builder(builder: (context) {
//         void addImage() {
//           showModalBottomSheet(
//             context: context,
//             isScrollControlled: true,
//             builder: (_) {
//               return SingleImageSelector(
//                 onUrlProvided: onImageLinkChanged,
//               );
//             },
//             backgroundColor: kTransparent,
//             useRootNavigator: true,
//             elevation: 0,
//             useSafeArea: true,
//           );
//         }

//         return Column(
//           children: [
//             _imageThumbnail(context),
//             if (imageLink.isEmpty)
//               GestureDetector(
//                 onTap: addImage,
//                 child: Padding(
//                   padding: const EdgeInsets.all(5),
//                   child: Text(
//                     context.t.uploadImage.capitalizeFirst(),
//                     style: Theme.of(context).textTheme.labelMedium,
//                   ),
//                 ),
//               )
//             else
//               _actionsRow(addImage, context)
//           ],
//         );
//       }),
//     );
//   }

//   IntrinsicHeight _actionsRow(Function() addImage, BuildContext context) {
//     return IntrinsicHeight(
//       child: Row(
//         children: [
//           Expanded(
//             child: GestureDetector(
//               onTap: addImage,
//               child: Padding(
//                 padding: const EdgeInsets.all(5),
//                 child: Text(
//                   context.t.edit.capitalizeFirst(),
//                   style: Theme.of(context).textTheme.labelMedium,
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//           ),
//           VerticalDivider(
//             color: Theme.of(context).highlightColor,
//             thickness: 0.5,
//             indent: 5,
//             endIndent: 5,
//             width: 0,
//           ),
//           Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 onImageLinkChanged('');
//               },
//               child: Padding(
//                 padding: const EdgeInsets.all(5),
//                 child: Text(
//                   context.t.delete.capitalizeFirst(),
//                   style: Theme.of(context).textTheme.labelMedium!.copyWith(
//                         color: kRed,
//                       ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   AspectRatio _imageThumbnail(BuildContext context) {
//     return AspectRatio(
//       aspectRatio: 16 / 9,
//       child: Container(
//         decoration: BoxDecoration(
//           color: Theme.of(context).scaffoldBackgroundColor,
//           borderRadius: BorderRadius.circular(
//             kDefaultPadding / 1.5,
//           ),
//           border: Border.all(
//             width: 0.5,
//             color: Theme.of(context).dividerColor,
//           ),
//         ),
//         child: imageLink.isEmpty
//             ? Center(
//                 child: SvgPicture.asset(
//                   FeatureIcons.imageAttachment,
//                   width: 25,
//                   height: 25,
//                   colorFilter: ColorFilter.mode(
//                     Theme.of(context).primaryColorDark,
//                     BlendMode.srcIn,
//                   ),
//                 ),
//               )
//             : LayoutBuilder(
//                 builder: (context, constraints) => CommonThumbnail(
//                   image: imageLink,
//                   placeholder:
//                       getRandomPlaceholder(input: imageLink, isPfp: false),
//                   width: constraints.maxWidth,
//                   height: constraints.maxHeight,
//                   isRound: true,
//                   radius: kDefaultPadding / 1.5,
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget _titleTextfield(
//     TextEditingController titleController,
//     BuildContext context,
//   ) {
//     return TextFormField(
//       controller: titleController,
//       textCapitalization: TextCapitalization.sentences,
//       autofocus: true,
//       decoration: InputDecoration(
//         hintText: context.t.title.capitalizeFirst(),
//         contentPadding: EdgeInsets.zero,
//         border: const OutlineInputBorder(
//           borderSide: BorderSide(color: kTransparent),
//         ),
//         focusedBorder: const OutlineInputBorder(
//           borderSide: BorderSide(color: kTransparent),
//         ),
//         enabledBorder: const OutlineInputBorder(
//           borderSide: BorderSide(color: kTransparent),
//         ),
//       ),
//       onChanged: onTitleChanged,
//     );
//   }

//   Expanded _summaryTextfield(
//       TextEditingController summaryController, BuildContext context) {
//     return Expanded(
//       flex: 3,
//       child: TextFormField(
//         controller: summaryController,
//         textCapitalization: TextCapitalization.sentences,
//         autofocus: true,
//         decoration: InputDecoration(
//           hintText: context.t.writeSummary.capitalizeFirst(),
//           contentPadding: EdgeInsets.zero,
//           border: const OutlineInputBorder(
//             borderSide: BorderSide(color: kTransparent),
//           ),
//           focusedBorder: const OutlineInputBorder(
//             borderSide: BorderSide(color: kTransparent),
//           ),
//           enabledBorder: const OutlineInputBorder(
//             borderSide: BorderSide(color: kTransparent),
//           ),
//         ),
//         minLines: 3,
//         maxLines: 3,
//         style: Theme.of(context).textTheme.bodyMedium,
//         onChanged: onDescChanged,
//       ),
//     );
//   }
// }
