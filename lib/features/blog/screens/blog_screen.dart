import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_loader_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';


class BlogScreen extends StatefulWidget {
  final String url;
  const BlogScreen({super.key, required this.url});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  late final WebViewController _controller;
  bool isWebLoadingFinished = false;
  late String currentUrl;
  

  void _instantiateWebController(){
    final SplashController splashController = Provider.of<SplashController>(context, listen: false);

    final WebViewController controller = WebViewController();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');

          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            if(!isWebLoadingFinished) {
              setState(() {
                isWebLoadingFinished = true;
              });
            }
            if(_isBlogNotActive(redirectUrl: url)) {
              splashController.initConfig(context, null, null);

              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => const DashBoardScreen()));

            }
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
            Page resource error:
              code: ${error.errorCode}
              description: ${error.description}
              errorType: ${error.errorType}
              isForMainFrame: ${error.isForMainFrame}
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse(currentUrl));

    _controller = controller;
  }

  bool _isBlogNotActive({required String redirectUrl}) => !redirectUrl.contains('app/');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    final String locale = Provider.of<LocalizationController>(context, listen: false).locale.languageCode;
    final String theme = Provider.of<ThemeController>(context, listen: false).darkTheme ? 'dark' : 'light';

    currentUrl = '${widget.url}?theme=$theme&locale=$locale';

    _instantiateWebController();
  }

  @override
  Widget build(BuildContext context) {
    /// WebView background color
    _controller.setBackgroundColor(Theme.of(context).highlightColor);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (canPop, _) async {
        if(await _controller.canGoBack()) {
          _controller.goBack();
          return;
        }

        if(canPop) return;

        if(context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: getTranslated('blog', context)!,
          centerTitle: true,
          onBackPressed: () async {
            if(await _controller.canGoBack()) {
              _controller.goBack();

            }else {
              if(context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          reset: InkWell(
            splashColor: Theme.of(context).splashColor,
            highlightColor: Theme.of(context).splashColor,
            onTap: (){
              Navigator.pop(context);
            },
            child: const _CrossIconButtonAppBar(),
          ),
          showResetIcon: true,
        ),
          body: Stack(children: [
            WebViewWidget(controller: _controller),

            isWebLoadingFinished ? const SizedBox.shrink() : const Center(child: CustomLoaderWidget())
          ])
      ),
    );
  }

}

class _CrossIconButtonAppBar extends StatelessWidget {
  const _CrossIconButtonAppBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
      child: CustomAssetImageWidget(Images.crossIcon),
    );
  }
}
