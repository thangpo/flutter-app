import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/enums/from_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/auth_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/forget_password_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/otp_login_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/social_login_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/only_social_login_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/number_checker_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';


class LoginScreen extends StatefulWidget {
  final bool fromLogout;
  const LoginScreen({super.key, this.fromLogout = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final FocusNode _emailNumberFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  TextEditingController? _emailPhoneController;
  TextEditingController? _passwordController;
  GlobalKey<FormState>? _formKeyLogin;
  String? countryCode;

  @override
  void initState() {
    super.initState();

    _formKeyLogin = GlobalKey<FormState>();
    _emailPhoneController = TextEditingController();
    _passwordController = TextEditingController();

    final ConfigModel configModel =
    Provider.of<SplashController>(context, listen: false).configModel!;

    final AuthController authController =
    Provider.of<AuthController>(context, listen: false);

    authController.setIsLoading = false;

    countryCode = CountryCode.fromCountryCode(configModel.countryCode!).dialCode;

    authController.toggleIsNumberLoginScreenText(value: false, isUpdate: false);
  }

  @override
  void dispose() {
    _emailPhoneController!.dispose();
    _passwordController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configModel =
    Provider.of<SplashController>(context, listen: false).configModel!;
    final localizationProvider =
    Provider.of<LocalizationController>(context, listen: false);
    final width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (widget.fromLogout) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DashBoardScreen()),
                    (route) => false);
          } else {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: CustomScrollView(
              slivers: [

                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Positioned(
                        top: Dimensions.paddingSizeThirtyFive,
                        left: localizationProvider.isLtr
                            ? Dimensions.paddingSizeLarge
                            : null,
                        right: localizationProvider.isLtr
                            ? null
                            : Dimensions.paddingSizeLarge,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios,
                              size: 20,
                              color: Theme.of(context).primaryColor),
                          onPressed: () {
                            if (widget.fromLogout) {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const DashBoardScreen()),
                                      (route) => false);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),

                      Column(
                        children: [

                          Padding(
                            padding:
                            const EdgeInsets.all(Dimensions.paddingSizeLarge),
                            child: Center(
                              child: Container(
                                width: width > 700 ? 500 : width,
                                child: Consumer<AuthController>(
                                  builder: (context, authProvider, _) =>
                                      Form(
                                        key: _formKeyLogin,
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [

                                            const SizedBox(height: 100),

                                            Center(
                                              child: Image.asset(
                                                Images.logoWithNameImage,
                                                width: 140,
                                              ),
                                            ),

                                            const SizedBox(height: 35),

                                            // Email / Phone
                                            _buildEmailPhoneField(authProvider),

                                            const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeLarge),

                                            // Password
                                            CustomTextFieldWidget(
                                              hintText: getTranslated(
                                                  'password_hint', context),
                                              labelText: getTranslated(
                                                  'password', context),
                                              isShowBorder: true,
                                              required: true,
                                              isPassword: true,
                                              focusNode: _passwordFocus,
                                              controller: _passwordController,
                                              prefixIcon: Images.lockSvg,
                                            ),

                                            const SizedBox(height: 20),

                                            // Remember / forgot
                                            _buildRememberForgot(authProvider),

                                            const SizedBox(height: 10),

                                            // Đăng nhập
                                            authProvider.isLoading
                                                ? Center(
                                              child:
                                              CircularProgressIndicator(
                                                valueColor:
                                                AlwaysStoppedAnimation(
                                                  Theme.of(context)
                                                      .primaryColor,
                                                ),
                                              ),
                                            )
                                                : CustomButton(
                                              buttonText: getTranslated(
                                                  'sign_in', context),
                                              onTap:
                                                  () => _submitLogin(
                                                  authProvider),
                                            ),

                                            const SizedBox(height: 20),

                                            // Social login
                                            if (configModel.customerLogin
                                                ?.loginOption
                                                ?.socialMediaLogin ==
                                                1)
                                              SocialLoginWidget(),

                                            const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeLarge),

                                            // Create account
                                            _buildSignupSection(context),

                                            const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeLarge),

                                            _buildGuestLogin(authProvider),
                                          ],
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  // Email / phone field
  Widget _buildEmailPhoneField(AuthController authProvider) {
    return Selector<AuthController, bool>(
      selector: (_, provider) => provider.isNumberLoginScreenText,
      builder: (_, isNumberLogin, __) {
        return CustomTextFieldWidget(
          countryDialCode: isNumberLogin ? countryCode : null,
          showCodePicker: isNumberLogin,
          onCountryChanged: (CountryCode value) {
            countryCode = value.dialCode;
          },
          onChanged: (text) {
            final isNum = RegExp(r'^[0-9]+$').hasMatch(text);
            if (isNum && !isNumberLogin) {
              authProvider.toggleIsNumberLoginScreenText();
            }
            if (!isNum && isNumberLogin) {
              authProvider.toggleIsNumberLoginScreenText();
            }
          },
          isShowBorder: true,
          focusNode: _emailNumberFocus,
          controller: _emailPhoneController,
          inputType:
          isNumberLogin ? TextInputType.phone : TextInputType.emailAddress,
          labelText: getTranslated('email/phone', context),
          required: true,
        );
      },
    );
  }

  // Remember me + Forgot password
  Widget _buildRememberForgot(AuthController authProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        InkWell(
          onTap: () => authProvider.toggleRememberMe(),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).primaryColor),
                ),
                child: authProvider.isActiveRememberMe
                    ? Icon(Icons.done,
                    color: Theme.of(context).primaryColor, size: 14)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(getTranslated('remember', context)!),
            ],
          ),
        ),

        InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ForgetPasswordScreen())),
          child: Text(
            "${getTranslated('forget_password', context)}?",
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      ],
    );
  }

  // Submit login
  Future<void> _submitLogin(AuthController authProvider) async {
    String user = _emailPhoneController!.text.trim();
    String password = _passwordController!.text.trim();

    if (user.isEmpty) {
      return showCustomSnackBar(
          getTranslated('enter_email_or_phone', context), context);
    }
    if (password.isEmpty) {
      return showCustomSnackBar(
          getTranslated('enter_password', context), context);
    }

    bool isNumber = NumberCheckerHelper.isNumber(user);
    if (isNumber) {
      user = "$countryCode$user";
    }

    String type = isNumber ? "phone" : "email";

    final result = await authProvider.login(user, password, type, FromPage.login);

    if (result.isSuccess) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashBoardScreen()),
              (route) => false);
    }
  }

  // Signup text
  Widget _buildSignupSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("${getTranslated('create_an_account', context)} "),
        InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AuthScreen())),
          child: Text(
            getTranslated('signup_here', context)!,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        )
      ],
    );
  }

  // Guest login
  Widget _buildGuestLogin(AuthController authProvider) {
    return Center(
      child: InkWell(
        onTap: () async {
          await authProvider.getGuestIdUrl();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashBoardScreen()),
                (route) => false,
          );
        },
        child: RichText(
          text: TextSpan(children: [
            TextSpan(
              text: "${getTranslated('continue_as', context)} ",
              style: TextStyle(color: Colors.grey),
            ),
            TextSpan(
              text: getTranslated('guest', context),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            )
          ]),
        ),
      ),
    );
  }
}