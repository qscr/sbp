import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sbp/data/asset_links_data.dart';
import 'package:sbp/data/c2bmembers_data.dart';
import 'package:sbp/models/application_info_model.dart';
import 'package:sbp/models/asset_link_model.dart';
import 'package:sbp/models/c2bmembers_model.dart';
import 'package:sbp/sbp.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  final url =
      'https://qr.nspk.ru/AS10003P3RH0LJ2A9ROO038L6NT5RU1M?type=01&bank=000000000001&sum=10000&cur=RUB&crc=F3D0';

  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    getInstalledBanks();
  }

  List<dynamic> informations = [];

  /// Получаем установленные банки
  Future<void> getInstalledBanks() async {
    try {
      if (Platform.isAndroid) {
        final List<String> packageNamesApplications = assetLinksData
            .map((assetLink) => AssetLinkModel.fromJson(assetLink).assetLinkTargetModel.packageName)
            .toList();
        informations = await Sbp.getAndroidInstalledPackageNames(packageNamesApplications);
      }
      if (Platform.isIOS) {
        final schemesList =
            C2bmembersModel.fromJson(c2bmembersData).c2bmembersModel.map((e) => e.schema).toList();
        informations = await Sbp.getIOSInstalledBySchemesBanks(schemesList);
      }
    } on Exception catch (e) {
      throw Exception(e);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('СБП'),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: const BoxDecoration(
                color: Colors.tealAccent, borderRadius: BorderRadius.all(Radius.circular(10))),
            child: Builder(builder: (context) {
              return GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  //isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (ctx) => SbpModalBottomSheetWidget(informations, widget.url),
                ),
                child: const Text('Открыть модальное окно'),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class SbpHeaderModalSheet extends StatelessWidget {
  const SbpHeaderModalSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          height: 5,
          width: 50,
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
              color: Colors.grey),
        ),
        const SizedBox(height: 20),
        // Image.asset(
        //   'assets/sbp.png',
        //   width: 100,
        // ),
        const SizedBox(height: 10),
        const Text('Выберите банк для оплаты по СБП'),
        const SizedBox(height: 20),
      ],
    );
  }
}

class SbpModalBottomSheetEmptyListBankWidget extends StatelessWidget {
  const SbpModalBottomSheetEmptyListBankWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SbpHeaderModalSheet(),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: const Center(
                child: Text('У вас нет банков для оплаты по СБП'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}

/// Модальное окно с банками
class SbpModalBottomSheetWidget extends StatelessWidget {
  final List<dynamic> informations;
  final String url;

  const SbpModalBottomSheetWidget(this.informations, this.url, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allBanks = C2bmembersModel.fromJson(c2bmembersData).c2bmembersModel;

    /// если есть информация о банках, то отображаем их
    if (informations.isNotEmpty) {
      return Column(
        children: [
          const SbpHeaderModalSheet(),
          Expanded(
            child: ListView.separated(
              itemCount: allBanks.length,
              itemBuilder: (ctx, index) {
                if (Platform.isAndroid) {
                  final information = informations[index] as ApplicationInfoModel;
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () => openAndroidBank(url, information.packageName),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Image.memory(
                            information.bitmap!,
                            width: 80,
                          ),
                          const SizedBox(width: 20),
                          Center(
                            child: Text(information.name),
                          ),
                          const SizedBox(width: 10)
                        ],
                      ),
                    ),
                  );
                }
                final information = informations[index] as String;
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => openIOSBank(url, allBanks[index].schema),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        Center(
                          child: Text(allBanks[index].bankName),
                        ),
                        const SizedBox(width: 10)
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 10),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    } else {
      return const SbpModalBottomSheetEmptyListBankWidget();
    }
  }

  /// передается package_name
  Future<void> openAndroidBank(String url, String packageName) async =>
      await Sbp.openAndroidBank(url, packageName);

  /// передается scheme
  Future<void> openIOSBank(String url, String scheme) async => await Sbp.openBankIOS(url, scheme);
}
