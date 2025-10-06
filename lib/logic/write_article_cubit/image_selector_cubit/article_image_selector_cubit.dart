import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../repositories/localdatabase_repository.dart';
import '../../../repositories/nostr_data_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'article_image_selector_state.dart';

class ArticleImageSelectorCubit extends Cubit<ArticleImageSelectorState> {
  ArticleImageSelectorCubit({
    required this.localDatabaseRepository,
    required this.nostrRepository,
  }) : super(
          const ArticleImageSelectorState(
            imageLink: '',
            isLocalImage: false,
            isImageSelected: false,
            imagesLinks: [],
          ),
        ) {
    setImageLinks();
  }

  final LocalDatabaseRepository localDatabaseRepository;
  final NostrDataRepository nostrRepository;

  Future<void> setImageLinks() async {
    final links = await localDatabaseRepository
        .getImagesLinks(currentSigner!.getPublicKey());
    if (!isClosed) {
      emit(
        state.copyWith(
          imagesLinks: links,
        ),
      );
    }
  }

  Future<void> selectProfileImage({
    required Function() onFailed,
  }) async {
    try {
      final XFile? image;
      image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image != null) {
        final file = File(image.path);

        if (!isClosed) {
          emit(
            state.copyWith(
              localImage: file,
              isLocalImage: true,
              imageLink: '',
              isImageSelected: true,
            ),
          );
        }
      }
    } catch (e) {
      onFailed.call();
    }
  }

  void removeImage() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isLocalImage: false,
          isImageSelected: false,
          imageLink: '',
        ),
      );
    }
  }

  Future<void> addImage({
    required Function(String) onSuccess,
    required Function(String) onFailure,
  }) async {
    final cancel = BotToast.showLoading();

    try {
      final link = (await mediaServersCubit.uploadMedia(
        file: state.localImage!,
      ))['url'];

      if (link == null) {
        BotToastUtils.showError(
          t.errorUploadingImage.capitalizeFirst(),
        );
        cancel.call();
        return;
      }

      final newLinks = List<String>.from(state.imagesLinks)..add(link);

      localDatabaseRepository.setImagesLinks(
        currentSigner!.getPublicKey(),
        newLinks,
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            imagesLinks: newLinks,
          ),
        );
      }

      cancel.call();
      onSuccess.call(link);
    } catch (_) {
      cancel.call();
      onFailure.call(
        t.errorUploadingImage.capitalizeFirst(),
      );
    }
  }
}
