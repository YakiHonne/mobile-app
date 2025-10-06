// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'article_image_selector_cubit.dart';

class ArticleImageSelectorState extends Equatable {
  final List<String> imagesLinks;
  final File? localImage;
  final bool isLocalImage;
  final bool isImageSelected;
  final String imageLink;

  const ArticleImageSelectorState({
    required this.imagesLinks,
    required this.isLocalImage,
    required this.isImageSelected,
    required this.imageLink,
    this.localImage,
  });

  @override
  List<Object> get props => [
        imagesLinks,
        isLocalImage,
        isImageSelected,
        imageLink,
      ];

  ArticleImageSelectorState copyWith({
    List<String>? imagesLinks,
    File? localImage,
    bool? isLocalImage,
    bool? isImageSelected,
    String? imageLink,
  }) {
    return ArticleImageSelectorState(
      imagesLinks: imagesLinks ?? this.imagesLinks,
      localImage: localImage ?? this.localImage,
      isLocalImage: isLocalImage ?? this.isLocalImage,
      isImageSelected: isImageSelected ?? this.isImageSelected,
      imageLink: imageLink ?? this.imageLink,
    );
  }
}
