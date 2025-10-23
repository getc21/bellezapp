import 'package:get/get.dart';

class IndexPageController extends GetxController {
  var indexPage = 0.obs;

  void setIndexPage(int i) => indexPage.value = i;
  int get getIndexPage => indexPage.value;
}
