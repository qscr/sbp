import 'dart:async';

import 'package:flutter/services.dart';

/// Плагин Flutter, с помощью которого можно получить список банков, установленных на устройстве
/// пользователя, а также запустить ссылку для оплаты СБП вида https://qr.nspk.ru/.../
class Sbp {
  static const MethodChannel _channel = MethodChannel('sbp');

  /// Получение списка банков, установленных на устройстве пользователя: Android
  /// передаем модель json, который приходит с https://qr.nspk.ru/.well-known/assetlinks.json
  static Future<List<String>> getAndroidInstalledPackageNames(
      List<String> packageNamesApplications) async {
    /// отдаем список поддерживаемых банков(SBP) из https://qr.nspk.ru/.well-known/assetlinks.json
    /// (application_package_names) и сравниваем с установленными возвращаем список установленных банков
    final installedBanks = (await _channel.invokeMethod(
            'getInstalledBanks', {'application_package_names': packageNamesApplications}) as List)
        .map(
          (installedBank) => installedBank as String,
        )
        .toList();
    return installedBanks;
  }

  /// Получение списка банков, установленных на устройстве пользователя: IOS
  /// передаем список schemes
  static Future<List<String>> getIOSInstalledBySchemesBanks(List<String> schemes) async {
    /// получаем список schema установленных банков
    final List<String> installedSchemas = (await _channel.invokeMethod('getInstalledBanks', {
      'schema_applications': schemes,
    }) as List)
        .map((installed) => installed as String)
        .toList();

    return installedSchemas;
  }

  /// открываем банк: Android
  /// отдаем ссылку в виде 'https://qr.nspk.ru/...'
  /// package_name: com.example.android
  static Future<bool> openAndroidBank(
    String url,
    String packageName,
  ) async =>
      await _channel.invokeMethod(
        'openBank',
        {
          'url': url,
          'package_name': packageName,
        },
      );

  /// открываем банк: IOS
  /// отдаем ссылку в виде 'https://qr.nspk.ru/...'
  /// schema: bank10000000000
  static Future<bool> openBankIOS(String url, String schema) async => await _channel.invokeMethod(
        'openBank',
        {
          'url': url,
          'schema': schema,
        },
      );
}
