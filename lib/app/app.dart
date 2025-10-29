import 'package:chime/common/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:chime/common/helper/ui_helper.dart';
import 'routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final UiHelper uiHelper = UiHelper();
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: Routes().router,
      theme: uiHelper.themeData(Constants.themeConfig.LIGHT),
    );
  }
}
