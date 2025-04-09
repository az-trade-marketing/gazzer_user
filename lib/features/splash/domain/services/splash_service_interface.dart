import 'package:gazzer_userapp/features/splash/domain/models/cache_version_model.dart';
import 'package:gazzer_userapp/features/splash/domain/models/config_model.dart';
import 'package:get/get_connect/http/src/response/response.dart';

abstract class SplashServiceInterface {
  Future<Response> getConfigData();

  Future<Response> getCacheVersionData();

  ConfigModel? prepareConfigData(Response response);

  CacheVersionModel? prepareCacheVersion(Response response);

  Future<bool> initSharedData();

  bool? showIntro();

  void disableIntro();

  Future<void> saveCookiesData(bool data);

  bool getCookiesData();

  void cookiesStatusChange(String? data);

  bool getAcceptCookiesStatus(String data);

  Future<bool> subscribeMail(String email);

  void toggleTheme(bool darkTheme);

  Future<bool> loadCurrentTheme();

  bool getReferBottomSheetStatus();

  Future<void> saveReferBottomSheetStatus(bool data);
}
