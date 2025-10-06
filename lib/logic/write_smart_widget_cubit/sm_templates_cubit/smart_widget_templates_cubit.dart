import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/smart_widgets_components.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../utils/utils.dart';

part 'smart_widget_templates_state.dart';

class SmartWidgetTemplatesCubit extends Cubit<SmartWidgetTemplatesState> {
  SmartWidgetTemplatesCubit()
      : super(
          const SmartWidgetTemplatesState(
            smartWidgets: [],
            updatingState: UpdatingState.progress,
          ),
        );

  Future<void> getSmartWidgetsTemplates() async {
    try {
      final templates = await HttpFunctionsRepository.getSmartWidgetTemplates();

      emit(
        state.copyWith(
          smartWidgets: templates,
          updatingState: UpdatingState.idle,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          updatingState: UpdatingState.idle,
          smartWidgets: [],
        ),
      );
    }
  }
}
