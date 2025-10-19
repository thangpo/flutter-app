import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/discount_tag_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/shimmers/recommended_product_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/favourite_button_widget.dart';
import 'package:provider/provider.dart';

class RecommendedProductWidget extends StatelessWidget {
  final bool fromAsterTheme;
  const RecommendedProductWidget({super.key, this.fromAsterTheme = false});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isLtr =
        Provider.of<LocalizationController>(context, listen: false).isLtr;

    return Container(
      padding: const EdgeInsets.only(
          top: Dimensions.paddingSizeSmall,
          bottom: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.onTertiary,
            Theme.of(context).colorScheme.onTertiary.withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        children: [
          Consumer<ProductController>(
            builder: (context, recommended, child) {
              String? ratting = recommended.recommendedProduct != null &&
                      recommended.recommendedProduct!.rating != null &&
                      recommended.recommendedProduct!.rating!.isNotEmpty
                  ? recommended.recommendedProduct!.rating![0].average
                  : "0";

              return (recommended.recommendedProduct != null)
                  ? recommended.recommendedProduct?.id != -1
                      ? InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration:
                                    const Duration(milliseconds: 1000),
                                pageBuilder: (context, anim1, anim2) =>
                                    ProductDetails(
                                  productId: recommended.recommendedProduct!.id,
                                  slug: recommended.recommendedProduct!.slug,
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              // Animated glow background
                              const _AnimatedGlow(),

                              Column(
                                children: [
                                  // Header with fire icons
                                  fromAsterTheme
                                      ? Column(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: Dimensions
                                                          .paddingSizeSmall),
                                              child: Text(
                                                getTranslated(
                                                        'dont_miss_the_chance',
                                                        context) ??
                                                    '',
                                                style: textBold.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  color:
                                                      Provider.of<ThemeController>(
                                                                  context,
                                                                  listen: false)
                                                              .darkTheme
                                                          ? Theme.of(context)
                                                              .hintColor
                                                          : Theme.of(context)
                                                              .primaryColor,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: Dimensions
                                                      .paddingSizeSmall),
                                              child: Text(
                                                getTranslated(
                                                        'lets_shopping_today',
                                                        context) ??
                                                    '',
                                                style: textBold.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeExtraLarge,
                                                  color:
                                                      Provider.of<ThemeController>(
                                                                  context,
                                                                  listen: false)
                                                              .darkTheme
                                                          ? Theme.of(context)
                                                              .hintColor
                                                          : Theme.of(context)
                                                              .primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                            bottom:
                                                Dimensions.paddingSizeDefault,
                                            top: Dimensions
                                                .paddingSizeExtraSmall,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const _AnimatedFireIcon(
                                                  reverse: false),
                                              const SizedBox(width: 12),

                                              // Title with gradient
                                              ShaderMask(
                                                shaderCallback: (bounds) =>
                                                    const LinearGradient(
                                                  colors: [
                                                    Colors.orange,
                                                    Colors.red,
                                                    Colors.deepOrange,
                                                  ],
                                                ).createShader(bounds),
                                                child: Text(
                                                  getTranslated(
                                                          'deal_of_the_day',
                                                          context) ??
                                                      '',
                                                  style: textBold.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeExtraLarge,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 12),
                                              const _AnimatedFireIcon(
                                                  reverse: true),
                                            ],
                                          ),
                                        ),

                                  // Product card with enhanced design
                                  Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                Dimensions.homePagePadding),
                                        child: _AnimatedProductCard(
                                          child: Row(
                                            children: [
                                              // Product image
                                              recommended.recommendedProduct !=
                                                          null &&
                                                      recommended
                                                              .recommendedProduct!
                                                              .thumbnail !=
                                                          null
                                                  ? Container(
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .highlightColor,
                                                        border: Border.all(
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                          width: .5,
                                                        ),
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                          Radius.circular(
                                                              Dimensions
                                                                  .radiusDefault),
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.1),
                                                            blurRadius: 10,
                                                            offset:
                                                                const Offset(
                                                                    0, 4),
                                                          ),
                                                        ],
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                          Radius.circular(
                                                              Dimensions
                                                                  .radiusDefault),
                                                        ),
                                                        child: Stack(
                                                          children: [
                                                            CustomImageWidget(
                                                              height: ResponsiveHelper
                                                                      .isTab(
                                                                          context)
                                                                  ? 250
                                                                  : size.width *
                                                                      0.4,
                                                              width: ResponsiveHelper
                                                                      .isTab(
                                                                          context)
                                                                  ? 230
                                                                  : size.width *
                                                                      0.4,
                                                              image:
                                                                  '${recommended.recommendedProduct?.thumbnailFullUrl?.path}',
                                                            ),
                                                            if (recommended
                                                                        .recommendedProduct!
                                                                        .currentStock! ==
                                                                    0 &&
                                                                recommended
                                                                        .recommendedProduct!
                                                                        .productType ==
                                                                    'physical')
                                                              Positioned.fill(
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .bottomCenter,
                                                                  child:
                                                                      Container(
                                                                    width: ResponsiveHelper.isTab(
                                                                            context)
                                                                        ? 230
                                                                        : size.width *
                                                                            0.4,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .error
                                                                          .withOpacity(
                                                                              0.4),
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .only(
                                                                        topLeft:
                                                                            Radius.circular(Dimensions.radiusSmall),
                                                                        topRight:
                                                                            Radius.circular(Dimensions.radiusSmall),
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                      getTranslated(
                                                                              'out_of_stock',
                                                                              context) ??
                                                                          '',
                                                                      style: textBold
                                                                          .copyWith(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            Dimensions.fontSizeSmall,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                              const SizedBox(
                                                  width: Dimensions
                                                      .paddingSizeDefault),

                                              // Product details
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Rating with gradient
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            Colors.orange
                                                                .withOpacity(
                                                                    0.2),
                                                            Colors.amber
                                                                .withOpacity(
                                                                    0.2),
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.star,
                                                            color:
                                                                Colors.orange,
                                                            size: 16,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            double.parse(
                                                                    ratting!)
                                                                .toStringAsFixed(
                                                                    1),
                                                            style: titilliumBold
                                                                .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeDefault,
                                                            ),
                                                          ),
                                                          Text(
                                                            ' (${recommended.recommendedProduct?.reviewCount ?? '0'})',
                                                            style: textRegular
                                                                .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeSmall,
                                                              color: Theme.of(
                                                                      context)
                                                                  .hintColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: Dimensions
                                                            .paddingSizeSmall),

                                                    // Price section
                                                    FittedBox(
                                                      child: Row(
                                                        children: [
                                                          if (recommended.recommendedProduct != null &&
                                                              recommended
                                                                      .recommendedProduct!
                                                                      .discount !=
                                                                  null &&
                                                              (recommended.recommendedProduct!
                                                                          .discount! >
                                                                      0 ||
                                                                  (recommended
                                                                              .recommendedProduct
                                                                              ?.clearanceSale
                                                                              ?.discountAmount ??
                                                                          0) >
                                                                      0))
                                                            Text(
                                                              PriceConverter
                                                                  .convertPrice(
                                                                context,
                                                                recommended
                                                                    .recommendedProduct!
                                                                    .unitPrice,
                                                              ),
                                                              style: textRegular
                                                                  .copyWith(
                                                                color: Theme.of(
                                                                        context)
                                                                    .hintColor,
                                                                decoration:
                                                                    TextDecoration
                                                                        .lineThrough,
                                                                fontSize: Dimensions
                                                                    .fontSizeSmall,
                                                              ),
                                                            ),
                                                          const SizedBox(
                                                              width: Dimensions
                                                                  .paddingSizeExtraSmall),
                                                          if (recommended
                                                                      .recommendedProduct !=
                                                                  null &&
                                                              recommended
                                                                      .recommendedProduct!
                                                                      .unitPrice !=
                                                                  null)
                                                            ShaderMask(
                                                              shaderCallback:
                                                                  (bounds) =>
                                                                      const LinearGradient(
                                                                colors: [
                                                                  Colors.red,
                                                                  Colors.orange,
                                                                ],
                                                              ).createShader(
                                                                          bounds),
                                                              child: Text(
                                                                PriceConverter
                                                                    .convertPrice(
                                                                  context,
                                                                  recommended
                                                                      .recommendedProduct!
                                                                      .unitPrice,
                                                                  discountType: (recommended.recommendedProduct?.clearanceSale?.discountAmount ??
                                                                              0) >
                                                                          0
                                                                      ? recommended
                                                                          .recommendedProduct
                                                                          ?.clearanceSale
                                                                          ?.discountType
                                                                      : recommended
                                                                          .recommendedProduct
                                                                          ?.discountType,
                                                                  discount: (recommended.recommendedProduct?.clearanceSale?.discountAmount ??
                                                                              0) >
                                                                          0
                                                                      ? recommended
                                                                          .recommendedProduct
                                                                          ?.clearanceSale
                                                                          ?.discountAmount
                                                                      : recommended
                                                                          .recommendedProduct
                                                                          ?.discount,
                                                                ),
                                                                style: textBold
                                                                    .copyWith(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeExtraLarge,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: Dimensions
                                                            .paddingSizeSmall),

                                                    // Product name
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              2.5,
                                                      child: Text(
                                                        recommended
                                                                .recommendedProduct!
                                                                .name ??
                                                            '',
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: textRegular
                                                            .copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeLarge,
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.color,
                                                        ),
                                                      ),
                                                    ),

                                                    // CTA button with fire animation
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .only(
                                                          top: Dimensions
                                                              .paddingSizeDefault),
                                                      child: _AnimatedButton(
                                                        text: getTranslated(
                                                            'grab_this_deal',
                                                            context)!,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Favourite button
                                      Positioned(
                                        top: 8,
                                        right: isLtr ? 25 : null,
                                        left: !isLtr ? 25 : null,
                                        child: FavouriteButtonWidget(
                                          backgroundColor: Provider.of<
                                                      ThemeController>(context)
                                                  .darkTheme
                                              ? Theme.of(context).cardColor
                                              : Theme.of(context).primaryColor,
                                          productId: recommended
                                              .recommendedProduct?.id,
                                        ),
                                      ),

                                      // Discount tag
                                      if (recommended.recommendedProduct !=
                                              null &&
                                          recommended.recommendedProduct!
                                                  .discount !=
                                              null &&
                                          ((recommended.recommendedProduct!
                                                      .discount! >
                                                  0) ||
                                              (recommended
                                                          .recommendedProduct
                                                          ?.clearanceSale
                                                          ?.discountAmount ??
                                                      0) >
                                                  0))
                                        DiscountTagWidget(
                                          productModel:
                                              recommended.recommendedProduct!,
                                          positionedTop: 25,
                                          positionedLeft: 32,
                                          positionedRight: 32,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : const SizedBox()
                  : const RecommendedProductShimmer();
            },
          ),
        ],
      ),
    );
  }
}

// Animated Glow Background
class _AnimatedGlow extends StatefulWidget {
  const _AnimatedGlow();

  @override
  State<_AnimatedGlow> createState() => _AnimatedGlowState();
}

class _AnimatedGlowState extends State<_AnimatedGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: -50,
          left: MediaQuery.of(context).size.width * 0.25,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.orange.withOpacity(0.3 * _controller.value),
                  Colors.red.withOpacity(0.2 * _controller.value),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Animated Fire Icon
class _AnimatedFireIcon extends StatefulWidget {
  final bool reverse;
  const _AnimatedFireIcon({required this.reverse});

  @override
  State<_AnimatedFireIcon> createState() => _AnimatedFireIconState();
}

class _AnimatedFireIconState extends State<_AnimatedFireIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value =
            widget.reverse ? (1 - _controller.value) : _controller.value;
        return Transform.scale(
          scale: 1.0 + (value * 0.2),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: widget.reverse
                  ? [Colors.yellow, Colors.orange, Colors.red]
                  : [Colors.orange, Colors.red, Colors.yellow],
              stops: [value * 0.3, value * 0.6, value],
            ).createShader(bounds),
            child: const Icon(
              Icons.local_fire_department,
              size: 32,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

// Animated Product Card
class _AnimatedProductCard extends StatefulWidget {
  final Widget child;
  const _AnimatedProductCard({required this.child});

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(Dimensions.paddingSizeDefault),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).highlightColor,
                Theme.of(context).highlightColor.withOpacity(0.95),
              ],
            ),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3 + (_controller.value * 0.3)),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.2 * _controller.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.red.withOpacity(0.1 * _controller.value),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// Animated Button
class _AnimatedButton extends StatefulWidget {
  final String text;
  const _AnimatedButton({required this.text});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 190,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(Dimensions.paddingSizeOverLarge),
            ),
            gradient: const LinearGradient(
              colors: [
                Colors.orange,
                Colors.deepOrange,
                Colors.red,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.5 * _controller.value),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
