import '../../../services/service_config.dart';
import '../index.dart';
import 'prestashop_service.dart';

mixin PrestashopMixin on ConfigMixin {
  @override
  void configPrestashop(appConfig) {
    final preService = PrestashopService(
      domain: appConfig['url'],
      blogDomain: appConfig['blog'],
      key: appConfig['key'],
    );
    api = preService;
    widget = PrestashopWidget(preService);
  }
}
