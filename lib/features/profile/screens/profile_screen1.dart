// lib/features/profile/screens/profile_screen1.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_loader_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/signup_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/enums/from_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/models/profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/widgets/delete_account_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen1 extends StatefulWidget {
  final bool formVerification;
  const ProfileScreen1({super.key, this.formVerification = false});

  @override
  State<ProfileScreen1> createState() => _ProfileScreen1State();
}

class _ProfileScreen1State extends State<ProfileScreen1> {
  final FocusNode _fNameFocus = FocusNode();
  final FocusNode _lNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool isMailChanged = false;
  bool isPhoneChanged = false;

  File? file;
  final picker = ImagePicker();

  void _choose() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxHeight: 500,
      maxWidth: 500,
    );
    setState(() {
      if (pickedFile != null) {
        file = File(pickedFile.path);
      }
    });
  }

  final phoneToolTipKey = GlobalKey<State<Tooltip>>();
  final emailToolTipKey = GlobalKey<State<Tooltip>>();

  Future<void> _updateUserAccount() async {
    final profileCtrl = context.read<ProfileController>();

    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirm = _confirmPasswordController.text.trim();

    // Validate
    if (profileCtrl.userInfoModel!.fName == _firstNameController.text &&
        profileCtrl.userInfoModel!.lName == _lastNameController.text &&
        profileCtrl.userInfoModel!.phone == _phoneController.text &&
        profileCtrl.userInfoModel!.email == _emailController.text &&
        file == null &&
        _passwordController.text.isEmpty &&
        _confirmPasswordController.text.isEmpty) {
      showCustomSnackBar(getTranslated('change_something_to_update', context), context);
      return;
    }
    if (firstName.isEmpty) {
      showCustomSnackBar(getTranslated('first_name_is_required', context), context);
      return;
    }
    if (lastName.isEmpty) {
      showCustomSnackBar(getTranslated('last_name_is_required', context), context);
      return;
    }
    if (email.isEmpty) {
      showCustomSnackBar(getTranslated('email_is_required', context), context);
      return;
    }
    if (phone.isEmpty) {
      showCustomSnackBar(getTranslated('phone_must_be_required', context), context);
      return;
    }
    if ((password.isNotEmpty && password.length < 8) ||
        (confirm.isNotEmpty && confirm.length < 8)) {
      showCustomSnackBar(getTranslated('minimum_password_is_8_character', context), context);
      return;
    }
    if (password != confirm) {
      showCustomSnackBar(getTranslated('confirm_password_not_matched', context), context);
      return;
    }

    // Update E-com
    final ProfileModel update = profileCtrl.userInfoModel!;
    update.method = 'put';
    update.fName = firstName;
    update.lName = lastName;
    update.phone = phone;
    update.email = email;

    final resp = await profileCtrl.updateUserInfo(
      update,
      password,
      file,
      context.read<AuthController>().getUserToken(),
    );

    if (!resp.isSuccess) {
      showCustomSnackBar(resp.message ?? '', context, isError: true);
      return;
    }

    // Sync sang Social (chỉ F/L name)
    await profileCtrl.syncEcomToSocial(
      context,
      source: update,
      currentPwd: null,
      newPwd: null,
    );

    if (!mounted) return;

    // Refresh E-com & báo OK
    await context.read<ProfileController>().getUserInfo(context);
    showCustomSnackBar(
      getTranslated('profile_info_updated_successfully', context),
      context,
      isError: false,
    );

    // Điều hướng theo yêu cầu:
    if (!mounted) return;
    if (widget.formVerification) {
      // Luôn về Dashboard và xoá stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashBoardScreen()),
            (route) => false,
      );
    } else {
      // Chỉ pop() một route
      Navigator.of(context).pop();
    }

    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final splashProvider = Provider.of<SplashController>(context, listen: false);
    final config = splashProvider.configModel;

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        if (widget.formVerification) {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashBoardScreen()),
                (route) => false,
          );
        } else {
          return;
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: getTranslated('profile', context),
          onBackPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const DashBoardScreen()),
                    (route) => false,
              );
            }
          },
        ),
        body: Consumer<AuthController>(
          builder: (context, authController, _) {
            return Consumer<ProfileController>(
              builder: (context, profile, _) {
                _firstNameController.text = profile.userInfoModel?.fName ?? '';
                _lastNameController.text = profile.userInfoModel?.lName ?? '';
                _emailController.text = profile.userInfoModel?.email ?? '';
                _phoneController.text = profile.userInfoModel?.phone ?? '';

                return profile.userInfoModel != null
                    ? Column(
                  children: [
                    // Header + avatar
                    Stack(
                      children: [
                        Container(
                          height: 140,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(Images.profileBgImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              height: 110,
                              width: 110,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                border: Border.all(color: Colors.white, width: 3),
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: file == null
                                        ? CustomImageWidget(
                                      image:
                                      "${profile.userInfoModel?.imageFullUrl?.path}",
                                      height: Dimensions.profileImageSize,
                                      fit: BoxFit.cover,
                                      width: Dimensions.profileImageSize,
                                    )
                                        : Image.file(
                                      file!,
                                      width: Dimensions.profileImageSize,
                                      height: Dimensions.profileImageSize,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: -5,
                                    child: Container(
                                      height: 29,
                                      width: 29,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).cardColor,
                                          width: 2.0,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        backgroundColor:
                                        Theme.of(context).primaryColor,
                                        radius: 14,
                                        child: IconButton(
                                          onPressed: _choose,
                                          padding: const EdgeInsets.all(0),
                                          icon: Icon(
                                            Icons.camera_alt_sharp,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 15,
                          top: 15,
                          child: InkWell(
                            onTap: () => showModalBottomSheet(
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (_) => DeleteAccountBottomSheet(
                                customerId: profile.userID,
                              ),
                            ),
                            child: Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    Dimensions.radiusDefault),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.50),
                                  width: 1.0,
                                ),
                                color: Theme.of(context).cardColor,
                              ),
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Form
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: Dimensions.paddingSizeDefault,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).highlightColor,
                          borderRadius: const BorderRadius.only(
                            topLeft:
                            Radius.circular(Dimensions.marginSizeDefault),
                            topRight:
                            Radius.circular(Dimensions.marginSizeDefault),
                          ),
                        ),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            CustomTextFieldWidget(
                              labelText: getTranslated('first_name', context),
                              inputType: TextInputType.name,
                              focusNode: _fNameFocus,
                              nextFocus: _lNameFocus,
                              hintText: profile.userInfoModel?.fName ?? '',
                              controller: _firstNameController,
                            ),
                            const SizedBox(height: Dimensions.paddingSizeLarge),

                            CustomTextFieldWidget(
                              labelText: getTranslated('last_name', context),
                              inputType: TextInputType.name,
                              focusNode: _lNameFocus,
                              nextFocus: _emailFocus,
                              hintText: profile.userInfoModel?.lName,
                              controller: _lastNameController,
                            ),
                            const SizedBox(height: Dimensions.paddingSizeLarge),

                            // Email + verify
                            CustomTextFieldWidget(
                              labelText: getTranslated('email', context),
                              inputType: TextInputType.emailAddress,
                              focusNode: _emailFocus,
                              nextFocus: _phoneFocus,
                              hintText: profile.userInfoModel?.email ?? '',
                              controller: _emailController,
                              isToolTipSuffix:
                              (isMailChanged || (config?.customerVerification?.email == 0))
                                  ? false
                                  : true,
                              suffixIcon: (isMailChanged ||
                                  (config?.customerVerification?.email == 0))
                                  ? null
                                  : (config?.customerVerification?.email == 1 &&
                                  profile.userInfoModel?.emailVerifiedAt == null)
                                  ? Images.notVerifiedSvg
                                  : Images.verifiedSvg,
                              toolTipMessage: (config?.customerVerification?.email == 1 &&
                                  profile.userInfoModel?.emailVerifiedAt == null)
                                  ? getTranslated('email_not_verified', context)!
                                  : '',
                              toolTipKey: emailToolTipKey,
                              suffixOnTap: () {
                                if (profile.userInfoModel?.emailVerifiedAt == null) {
                                  // gửi mã verify email nếu cần
                                }
                              },
                              onChanged: (value) {
                                if (profile.userInfoModel?.email != value) {
                                  setState(() => isMailChanged = true);
                                } else if (isMailChanged &&
                                    profile.userInfoModel?.email == value) {
                                  setState(() => isMailChanged = false);
                                }
                              },
                            ),
                            const SizedBox(height: Dimensions.paddingSizeLarge),

                            // Phone + verify
                            CustomTextFieldWidget(
                              isEnabled: profile.userInfoModel?.isPhoneVerified == 0,
                              labelText: getTranslated('phone', context),
                              inputType: TextInputType.phone,
                              focusNode: _phoneFocus,
                              hintText: profile.userInfoModel?.phone ?? "",
                              nextFocus: _addressFocus,
                              controller: _phoneController,
                              toolTipKey: phoneToolTipKey,
                              isToolTipSuffix: (isPhoneChanged ||
                                  (config?.customerVerification?.phone == 0))
                                  ? false
                                  : true,
                              toolTipMessage: (profile.userInfoModel?.isPhoneVerified == 0 &&
                                  config?.customerVerification?.phone == 1)
                                  ? getTranslated('phone_number_not_verified', context)!
                                  : '',
                              suffixIcon: (isPhoneChanged ||
                                  (config?.customerVerification?.phone == 0))
                                  ? null
                                  : config?.customerVerification?.phone == 1 &&
                                  profile.userInfoModel?.isPhoneVerified == 0
                                  ? Images.notVerifiedSvg
                                  : Images.verifiedSvg,
                              suffixOnTap: () {
                                // gửi mã verify phone nếu cần
                              },
                              isAmount: true,
                              onChanged: (value) {
                                if (profile.userInfoModel?.phone != value) {
                                  setState(() => isPhoneChanged = true);
                                } else if (isPhoneChanged &&
                                    profile.userInfoModel?.phone == value) {
                                  setState(() => isPhoneChanged = false);
                                }
                              },
                            ),
                            const SizedBox(height: Dimensions.paddingSizeLarge),

                            // Password
                            CustomTextFieldWidget(
                              isPassword: true,
                              labelText: getTranslated('password', context),
                              hintText: getTranslated('enter_7_plus_character', context),
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              nextFocus: _confirmPasswordFocus,
                              inputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: Dimensions.paddingSizeLarge),

                            CustomTextFieldWidget(
                              labelText: getTranslated('confirm_password', context),
                              hintText: getTranslated('enter_7_plus_character', context),
                              isPassword: true,
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocus,
                              inputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                          ],
                        ),
                      ),
                    ),

                    // Nút LƯU
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.marginSizeLarge,
                        vertical: Dimensions.marginSizeSmall,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).highlightColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(Dimensions.radiusSmall),
                          topRight: Radius.circular(Dimensions.radiusSmall),
                        ),
                      ),
                      child: !profile.isLoading
                          ? CustomButton(
                        onTap: _updateUserAccount,
                        buttonText:
                        getTranslated('update_profile', context),
                      )
                          : Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    : CustomLoaderWidget(
                  height: MediaQuery.sizeOf(context).height,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
