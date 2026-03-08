import 'package:get/get.dart';
import '../../core/services/storage_service.dart';
import '../../shared/models/progress_model.dart';

class ProgressController extends GetxController {
  final _storage = Get.find<StorageService>();
  late final Rx<UserProgress> progress;

  @override
  void onInit() {
    super.onInit();
    progress = _storage.getProgress().obs;
  }

  void refresh() => progress.value = _storage.getProgress();
}
