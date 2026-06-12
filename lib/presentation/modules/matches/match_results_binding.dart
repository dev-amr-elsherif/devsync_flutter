import 'package:get/get.dart';
import 'match_results_controller.dart';

class MatchResultsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MatchResultsController>(() => MatchResultsController());
  }
}
