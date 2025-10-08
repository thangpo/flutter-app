import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/code_picker_widget.dart';
import 'package:provider/provider.dart';


class CustomTextFieldWidget extends StatefulWidget {
  final String? hintText;
  final String? titleText;
  final String? labelText;
  final TextAlign textAlign;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputType inputType;
  final TextInputAction inputAction;
  final bool isPassword;
  final bool isAmount;
  final bool showCodePicker;
  final bool isRequiredFill;
  final bool readOnly;
  final bool filled;
  final void Function()? onTap;
  final void Function()? suffixOnTap;
  final void Function()? suffix2OnTap;
  final void Function()? prefixOnTap;
  final void Function(String value)? onChanged;
  final String? Function(String?)? validator;
  final bool isEnabled;
  final int maxLines;
  final TextCapitalization capitalization;
  final double borderRadius;
  final String? prefixIcon;
  final String? suffixIcon;
  final String? suffixIcon2;
  final double suffixIconSize;
  final bool showBorder;
  final bool showLabelText;
  final String? countryDialCode;
  final double prefixHeight;
  final Color borderColor;
  final List<TextInputFormatter>? inputFormatters;
  final Function(CountryCode countryCode)? onCountryChanged;
  final bool required;
  final Color? prefixColor;
  final Color? suffixColor;
  final bool isShowBorder;
  final bool isToolTipSuffix;
  final String? toolTipMessage;
  final GlobalKey? toolTipKey;
  final TextStyle? labelTextStyle;

  const CustomTextFieldWidget({
    super.key,
    this.hintText = 'Write something...',
    this.controller,
    this.focusNode,
    this.titleText,
    this.nextFocus,
    this.isEnabled = true,
    this.borderColor = const Color(0xFFBFBFBF),
    this.inputType = TextInputType.text,
    this.inputAction = TextInputAction.next,
    this.maxLines = 1,
    this.onChanged,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixIconSize= 12,
    this.capitalization = TextCapitalization.none,
    this.readOnly = false,
    this.isPassword = false,
    this.isAmount = false,
    this.showCodePicker = false,
    this.isRequiredFill = false,
    this.showLabelText = true,
    this.showBorder = false,
    this.filled = true,
    this.borderRadius = 8,
    this.prefixHeight = 50,
    this.countryDialCode,
    this.onCountryChanged,
    this.validator,
    this.inputFormatters,
    this.labelText,
    this.textAlign = TextAlign.start,
     this.required = false, this.suffixOnTap, this.suffix2OnTap, this.prefixOnTap,
    this.prefixColor,
    this.suffixColor,
    this.suffixIcon2,
    this.isShowBorder = false,
    this.isToolTipSuffix = false,
    this.toolTipMessage,
    this.toolTipKey,
    this.labelTextStyle
  });

  @override
  State<CustomTextFieldWidget> createState() => _CustomTextFieldWidgetState();
}

class _CustomTextFieldWidgetState extends State<CustomTextFieldWidget> {
  bool _obscureText = true;
  bool isFocusActive = false;

  @override
  void initState() {
    widget.focusNode?.addListener(() {
      isFocusActive = widget.focusNode!.hasFocus;
      setState(() {});
    });
    widget.toolTipKey != null ? showAndCloseTooltip(widget.toolTipKey) : null;
    super.initState();
  }

  Future showAndCloseTooltip(dynamic key) async {
    await Future.delayed(const Duration(milliseconds: 10));
    final dynamic tooltip = key.currentState;
    tooltip?.ensureTooltipVisible();
    await Future.delayed(const Duration(milliseconds: 10));
    tooltip?.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.titleText != null)
          RichText(text: TextSpan(
              text: widget.titleText ?? "", style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 14, color: const Color(0xFF202532)), children: [
                if (widget.isRequiredFill)
                  TextSpan(text: " *", style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w500, fontSize: 16, color: Colors.red))])),
        if (widget.titleText != null) const SizedBox(height: 8),
        TextFormField(
          maxLines: widget.maxLines,
          controller: widget.controller,
          focusNode: widget.focusNode,
          validator: widget.validator,
          textAlign: widget.textAlign,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: textRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
          textInputAction: widget.inputAction,
          keyboardType:widget.inputType,
          cursorColor: Theme.of(context).primaryColor,
          textCapitalization: widget.capitalization,
          enabled: widget.isEnabled,
          autofocus: false,
          autofillHints: widget.inputType == TextInputType.name ? [AutofillHints.name]
              : widget.inputType == TextInputType.emailAddress ? [AutofillHints.email]
              : widget.inputType == TextInputType.phone ? [AutofillHints.telephoneNumber]
              : widget.inputType == TextInputType.streetAddress ? [AutofillHints.fullStreetAddress]
              : widget.inputType == TextInputType.url ? [AutofillHints.url]
              : widget.inputType == TextInputType.visiblePassword ? [AutofillHints.password] : null,
          obscureText: widget.isPassword ? _obscureText : false,
          inputFormatters: widget.inputType == TextInputType.phone ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))]
              : widget.isAmount ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : widget.inputFormatters,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(Dimensions.fontSizeDefault),
            alignLabelWithHint: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.borderColor,
                  width: widget.showBorder ? 0 : .75,)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).primaryColor,//widget.borderColor,
                  width: widget.showBorder ? 0 : .75,)),

            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.borderColor,
                  width: widget.showBorder ? 0 : .75,)),

            fillColor: Theme.of(context).cardColor,
            floatingLabelStyle: widget.showLabelText ? textRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor.withValues(alpha:.75)) : null,
            filled: widget.filled,
           // labelText : widget.showLabelText? widget.labelText?? widget.hintText : null,
            labelStyle : widget.showLabelText ? textRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).hintColor) : null,

            label: Text.rich(TextSpan(children: [
              TextSpan(text: widget.labelText??'', style: widget.labelTextStyle ?? textRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color)),
              if(widget.required && widget.labelText != null)
              TextSpan(text : ' *', style: textRegular.copyWith(color: Theme.of(context).colorScheme.error, fontSize: Dimensions.fontSizeLarge))
            ])),
            hintText : widget.hintText,
            hintStyle: widget.showLabelText ? textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor) : textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
            prefixIcon: widget.prefixIcon != null ? InkWell(
              onTap: widget.prefixOnTap,
              child: Container(
                  width: widget.prefixHeight,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(widget.borderRadius),
                      bottomLeft: Radius.circular(widget.borderRadius))),
                  child: Center(
                    child: CustomAssetImageWidget(height: 20, width: 20, widget.prefixIcon!, color: widget.prefixColor ?? Theme.of(context).primaryColor.withValues(alpha:.4)),
                  )),
            ) :
            widget.showCodePicker ? Padding(
              padding:  EdgeInsets.only(left: widget.isShowBorder == true ?  10 : 0),
              child: SizedBox(
                  width: ResponsiveHelper.isTab(context) ? 120 : 92,
                  child: Row(children: [

                    CodePickerWidget(
                      padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                      flagWidth: Dimensions.paddingSizeExtraLarge,
                      onChanged: widget.onCountryChanged,
                      initialSelection: widget.countryDialCode,
                      favorite: [widget.countryDialCode != null ? widget.countryDialCode! : 'BD'],
                      showDropDownButton: true,
                      showCountryOnly: false,
                      showOnlyCountryWhenClosed: false,
                      showFlagDialog: true,
                      hideMainText: false,
                      showFlagMain: false,
                      dialogBackgroundColor: Theme.of(context).cardColor,
                      barrierColor: Provider.of<ThemeController>(context).darkTheme ? Colors.black.withValues(alpha:0.4) : null,
                      textStyle: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraExtraSmall),
                      child: Container(
                        height: 20,
                        width: 1.5,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ]),
              ),
            )
                : null,
            suffixIcon: widget.isToolTipSuffix ?
            Tooltip(
              key: widget.toolTipKey,
              preferBelow: false,
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              triggerMode: TooltipTriggerMode.manual,
              message : widget.toolTipMessage ?? '',
              child: IconButton(
               onPressed: widget.suffixOnTap,
                // widget.suffixOnTap,
                icon: CustomAssetImageWidget(
                  widget.suffixIcon!,
                  width: 25,
                  height: 25,
                )),
            ) :
            InkWell(
              onTap: () {
              },
              child: Row( mainAxisSize: MainAxisSize.min, children: [
                widget.suffixIcon2 != null ? SizedBox(width: 30, height: 30, child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    child: InkWell(onTap: widget.suffix2OnTap, child: Image.asset(widget.suffixIcon2!),
                    ))) : const SizedBox.shrink(),


                  widget.isPassword ? IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Theme.of(context).primaryColor.withValues(alpha:.6),),
                    onPressed: _toggle) : widget.suffixIcon != null ? Row(
                      children: [
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        
                        SizedBox(width: 35, height: 35, child: Padding(
                          padding: const EdgeInsets.only(
                            top: Dimensions.paddingSizeExtraExtraSmall,
                            left: Dimensions.paddingSizeExtraExtraSmall,
                            bottom: Dimensions.paddingSizeExtraExtraSmall,
                            right: Dimensions.paddingSizeSmall,
                          ),
                          child: InkWell(onTap: widget.suffixOnTap, child: Image.asset(widget.suffixIcon!, color: widget.suffixColor ?? Theme.of(context).hintColor)),
                        )),
                        
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      ],
                    ) : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
          onFieldSubmitted: (text) => widget.nextFocus != null ? FocusScope.of(context).requestFocus(widget.nextFocus) : null,
          onChanged: (value) {
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
          }
        ),
      ],
    );
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
}
