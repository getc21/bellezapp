import 'package:get/get.dart';

class LoadingController extends GetxController {
  var loading = false.obs;

  void setLoading(bool l) => loading.value = l;
  void setOnLoading() => setLoading(true);
  void setOffLoading() => setLoading(false);
  bool get getLoading => loading.value;
}
