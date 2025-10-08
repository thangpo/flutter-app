import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/screens/cart_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/inbox_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/home_screens.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/screens/order_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/more/screens/more_screen_view.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/models/navigation_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/widgets/dashboard_menu_widget.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    this.title = '',
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _isLoading = true;
  late List<NavigationModel> _screens;

  @override
  void initState() {
    super.initState();

    // Khởi tạo WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() {
              _progress = progress;
            });
          },
          onPageStarted: (_) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
              _progress = 100;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // Khởi tạo danh sách màn hình cho Bottom Navigation Bar
    _screens = [
      NavigationModel(
        name: 'home',
        icon: Images.homeImage,
        screen: const HomePage(),
      ),
      NavigationModel(
        name: 'inbox',
        icon: Images.messageImage,
        screen: const InboxScreen(isBackButtonExist: false),
      ),
      NavigationModel(
        name: 'cart',
        icon: Images.cartArrowDownImage,
        screen: const CartScreen(showBackButton: false),
        showCartIcon: true,
      ),
      NavigationModel(
        name: 'orders',
        icon: Images.shoppingImage,
        screen: const OrderScreen(isBacButtonExist: false),
      ),
      NavigationModel(
        name: 'more',
        icon: Images.moreImage,
        screen: const MoreScreen(),
      ),
    ];
  }

  // Hàm xử lý nút back
  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    // Điều hướng về DashBoardScreen khi không còn lịch sử WebView
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(builder: (context) => const DashBoardScreen()),
      );
      return false;
    }
    return true;
  }

  // Hàm tạo các widget cho Bottom Navigation Bar
  List<Widget> _getBottomWidget() {
    List<Widget> list = [];
    for (int index = 0; index < _screens.length; index++) {
      list.add(Expanded(
        child: CustomMenuWidget(
          isSelected: false, // WebViewScreen không phải là một tab trong menu
          name: _screens[index].name,
          icon: _screens[index].icon,
          showCartCount: _screens[index].showCartIcon ?? false,
          onTap: () {
            // Điều hướng đến màn hình tương ứng
            navigatorKey.currentState!.pushReplacement(
              MaterialPageRoute(builder: (context) => const DashBoardScreen()),
            );
          },
        ),
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title.isEmpty ? "Web" : widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _progress < 100
                ? LinearProgressIndicator(value: _progress / 100.0)
                : const SizedBox.shrink(),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16), // Giả định sử dụng Dimensions.paddingSizeLarge
            ),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                spreadRadius: 1,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.125),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _getBottomWidget(),
          ),
        ),
      ),
    );
  }
}