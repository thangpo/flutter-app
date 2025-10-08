// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

const Duration _kExpand = Duration(milliseconds: 200);

/// Enables control over a single [CustomExpansionTile]'s expanded/collapsed state.
///
/// It can be useful to expand or collapse an [CustomExpansionTile]
/// programmatically, for example to reconfigure an existing expansion
/// tile based on a system event. To do so, create an [CustomExpansionTile]
/// with an [CustomExpansionTileController] that's owned by a stateful widget
/// or look up the tile's automatically created [CustomExpansionTileController]
/// with [CustomExpansionTileController.of]
///
/// The controller's [expand] and [collapse] methods cause the
/// the [CustomExpansionTile] to rebuild, so they may not be called from
/// a build method.
class CustomExpansionTileController {
  /// Create a controller to be used with [CustomExpansionTile.controller].
  CustomExpansionTileController();

  _CustomExpansionTileState? _state;

  /// Whether the [CustomExpansionTile] built with this controller is in expanded state.
  ///
  /// This property doesn't take the animation into account. It reports `true`
  /// even if the expansion animation is not completed.
  ///
  /// See also:
  ///
  ///  * [expand], which expands the [CustomExpansionTile].
  ///  * [collapse], which collapses the [CustomExpansionTile].
  ///  * [CustomExpansionTile.controller] to create an CustomExpansionTile with a controller.
  bool get isExpanded {
    assert(_state != null);
    return _state!._isExpanded;
  }

  /// Expands the [CustomExpansionTile] that was built with this controller;
  ///
  /// Normally the tile is expanded automatically when the user taps on the header.
  /// It is sometimes useful to trigger the expansion programmatically due
  /// to external changes.
  ///
  /// If the tile is already in the expanded state (see [isExpanded]), calling
  /// this method has no effect.
  ///
  /// Calling this method may cause the [CustomExpansionTile] to rebuild, so it may
  /// not be called from a build method.
  ///
  /// Calling this method will trigger an [CustomExpansionTile.onExpansionChanged] callback.
  ///
  /// See also:
  ///
  ///  * [collapse], which collapses the tile.
  ///  * [isExpanded] to check whether the tile is expanded.
  ///  * [CustomExpansionTile.controller] to create an CustomExpansionTile with a controller.
  void expand() {
    assert(_state != null);
    if (!isExpanded) {
      _state!._toggleExpansion();
    }
  }

  /// Collapses the [CustomExpansionTile] that was built with this controller.
  ///
  /// Normally the tile is collapsed automatically when the user taps on the header.
  /// It can be useful sometimes to trigger the collapse programmatically due
  /// to some external changes.
  ///
  /// If the tile is already in the collapsed state (see [isExpanded]), calling
  /// this method has no effect.
  ///
  /// Calling this method may cause the [CustomExpansionTile] to rebuild, so it may
  /// not be called from a build method.
  ///
  /// Calling this method will trigger an [CustomExpansionTile.onExpansionChanged] callback.
  ///
  /// See also:
  ///
  ///  * [expand], which expands the tile.
  ///  * [isExpanded] to check whether the tile is expanded.
  ///  * [CustomExpansionTile.controller] to create an CustomExpansionTile with a controller.
  void collapse() {
    assert(_state != null);
    if (isExpanded) {
      _state!._toggleExpansion();
    }
  }

  /// Finds the [CustomExpansionTileController] for the closest [CustomExpansionTile] instance
  /// that encloses the given context.
  ///
  /// If no [CustomExpansionTile] encloses the given context, calling this
  /// method will cause an assert in debug mode, and throw an
  /// exception in release mode.
  ///
  /// To return null if there is no [CustomExpansionTile] use [maybeOf] instead.
  ///
  /// {@tool dartpad}
  /// Typical usage of the [CustomExpansionTileController.of] function is to call it from within the
  /// `build` method of a descendant of an [CustomExpansionTile].
  ///
  /// When the [CustomExpansionTile] is actually created in the same `build`
  /// function as the callback that refers to the controller, then the
  /// `context` argument to the `build` function can't be used to find
  /// the [CustomExpansionTileController] (since it's "above" the widget
  /// being returned in the widget tree). In cases like that you can
  /// add a [Builder] widget, which provides a new scope with a
  /// [BuildContext] that is "under" the [CustomExpansionTile]:
  ///
  /// ** See code in examples/api/lib/material/expansion_tile/expansion_tile.1.dart **
  /// {@end-tool}
  ///
  /// A more efficient solution is to split your build function into
  /// several widgets. This introduces a new context from which you
  /// can obtain the [CustomExpansionTileController]. With this approach you
  /// would have an outer widget that creates the [CustomExpansionTile]
  /// populated by instances of your new inner widgets, and then in
  /// these inner widgets you would use [CustomExpansionTileController.of].
  static CustomExpansionTileController of(BuildContext context) {
    final _CustomExpansionTileState? result = context.findAncestorStateOfType<_CustomExpansionTileState>();
    if (result != null) {
      return result._tileController;
    }
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(
        'CustomExpansionTileController.of() called with a context that does not contain a CustomExpansionTile.',
      ),
      ErrorDescription(
        'No CustomExpansionTile ancestor could be found starting from the context that was passed to CustomExpansionTileController.of(). '
            'This usually happens when the context provided is from the same StatefulWidget as that '
            'whose build function actually creates the CustomExpansionTile widget being sought.',
      ),
      ErrorHint(
        'There are several ways to avoid this problem. The simplest is to use a Builder to get a '
            'context that is "under" the CustomExpansionTile. For an example of this, please see the '
            'documentation for CustomExpansionTileController.of():\n'
            '  https://api.flutter.dev/flutter/material/CustomExpansionTile/of.html',
      ),
      ErrorHint(
        'A more efficient solution is to split your build function into several widgets. This '
            'introduces a new context from which you can obtain the CustomExpansionTile. In this solution, '
            'you would have an outer widget that creates the CustomExpansionTile populated by instances of '
            'your new inner widgets, and then in these inner widgets you would use CustomExpansionTileController.of().\n'
            'An other solution is assign a GlobalKey to the CustomExpansionTile, '
            'then use the key.currentState property to obtain the CustomExpansionTile rather than '
            'using the CustomExpansionTileController.of() function.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// Finds the [CustomExpansionTile] from the closest instance of this class that
  /// encloses the given context and returns its [CustomExpansionTileController].
  ///
  /// If no [CustomExpansionTile] encloses the given context then return null.
  /// To throw an exception instead, use [of] instead of this function.
  ///
  /// See also:
  ///
  ///  * [of], a similar function to this one that throws if no [CustomExpansionTile]
  ///    encloses the given context. Also includes some sample code in its
  ///    documentation.
  static CustomExpansionTileController? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_CustomExpansionTileState>()?._tileController;
  }
}

/// A single-line [ListTile] with an expansion arrow icon that expands or collapses
/// the tile to reveal or hide the [children].
///
/// This widget is typically used with [ListView] to create an "expand /
/// collapse" list entry. When used with scrolling widgets like [ListView], a
/// unique [PageStorageKey] must be specified as the [key], to enable the
/// [CustomExpansionTile] to save and restore its expanded state when it is scrolled
/// in and out of view.
///
/// This class overrides the [ListTileThemeData.iconColor] and [ListTileThemeData.textColor]
/// theme properties for its [ListTile]. These colors animate between values when
/// the tile is expanded and collapsed: between [iconColor], [collapsedIconColor] and
/// between [textColor] and [collapsedTextColor].
///
/// The expansion arrow icon is shown on the right by default in left-to-right languages
/// (i.e. the trailing edge). This can be changed using [controlAffinity]. This maps
/// to the [leading] and [trailing] properties of [CustomExpansionTile].
///
/// {@tool dartpad}
/// This example demonstrates how the [CustomExpansionTile] icon's location and appearance
/// can be CustomExpansionTileized.
///
/// ** See code in examples/api/lib/material/expansion_tile/expansion_tile.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example demonstrates how an [CustomExpansionTileController] can be used to
/// programmatically expand or collapse an [CustomExpansionTile].
///
/// ** See code in examples/api/lib/material/expansion_tile/expansion_tile.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ListTile], useful for creating expansion tile [children] when the
///    expansion tile represents a sublist.
///  * The "Expand and collapse" section of
///    <https://material.io/components/lists#types>
class CustomExpansionTile extends StatefulWidget {
  /// Creates a single-line [ListTile] with an expansion arrow icon that expands or collapses
  /// the tile to reveal or hide the [children]. The [initiallyExpanded] property must
  /// be non-null.
  const CustomExpansionTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.onExpansionChanged,
    this.children = const <Widget>[],
    this.trailing,
    this.showTrailingIcon = true,
    this.initiallyExpanded = false,
    this.maintainState = false,
    this.tilePadding,
    this.expandedCrossAxisAlignment,
    this.expandedAlignment,
    this.childrenPadding,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.textColor,
    this.collapsedTextColor,
    this.iconColor,
    this.collapsedIconColor,
    this.shape,
    this.collapsedShape,
    this.clipBehavior,
    this.controlAffinity,
    this.controller,
    this.dense,
    this.visualDensity,
    this.minTileHeight,
    this.enableFeedback = true,
    this.enabled = true,
    this.expansionAnimationStyle,
  }) : assert(
  expandedCrossAxisAlignment != CrossAxisAlignment.baseline,
  'CrossAxisAlignment.baseline is not supported since the expanded children '
      'are aligned in a column, not a row. Try to use another constant.',
  );

  /// A widget to display before the title.
  ///
  /// Typically a [CircleAvatar] widget.
  ///
  /// Depending on the value of [controlAffinity], the [leading] widget
  /// may replace the rotating expansion arrow icon.
  final Widget? leading;

  /// The primary content of the list item.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Additional content displayed below the title.
  ///
  /// Typically a [Text] widget.
  final Widget? subtitle;

  /// Called when the tile expands or collapses.
  ///
  /// When the tile starts expanding, this function is called with the value
  /// true. When the tile starts collapsing, this function is called with
  /// the value false.
  final ValueChanged<bool>? onExpansionChanged;

  /// The widgets that are displayed when the tile expands.
  ///
  /// Typically [ListTile] widgets.
  final List<Widget> children;

  /// The color to display behind the sublist when expanded.
  ///
  /// If this property is null then [CustomExpansionTileThemeData.backgroundColor] is used. If that
  /// is also null then Colors.transparent is used.
  ///
  /// See also:
  ///
  /// * [CustomExpansionTileTheme.of], which returns the nearest [CustomExpansionTileTheme]'s
  ///   [CustomExpansionTileThemeData].
  final Color? backgroundColor;

  /// When not null, defines the background color of tile when the sublist is collapsed.
  ///
  /// If this property is null then [CustomExpansionTileThemeData.collapsedBackgroundColor] is used.
  /// If that is also null then Colors.transparent is used.
  ///
  /// See also:
  ///
  /// * [CustomExpansionTileTheme.of], which returns the nearest [CustomExpansionTileTheme]'s
  ///   [CustomExpansionTileThemeData].
  final Color? collapsedBackgroundColor;

  /// A widget to display after the title.
  ///
  /// Depending on the value of [controlAffinity], the [trailing] widget
  /// may replace the rotating expansion arrow icon.
  final Widget? trailing;

  /// Specifies if the [CustomExpansionTile] should build a default trailing icon if [trailing] is null.
  final bool showTrailingIcon;

  /// Specifies if the list tile is initially expanded (true) or collapsed (false, the default).
  final bool initiallyExpanded;

  /// Specifies whether the state of the children is maintained when the tile expands and collapses.
  ///
  /// When true, the children are kept in the tree while the tile is collapsed.
  /// When false (default), the children are removed from the tree when the tile is
  /// collapsed and recreated upon expansion.
  final bool maintainState;

  /// Specifies padding for the [ListTile].
  ///
  /// Analogous to [ListTile.contentPadding], this property defines the insets for
  /// the [leading], [title], [subtitle] and [trailing] widgets. It does not inset
  /// the expanded [children] widgets.
  ///
  /// If this property is null then [CustomExpansionTileThemeData.tilePadding] is used. If that
  /// is also null then the tile's padding is `EdgeInsets.symmetric(horizontal: 16.0)`.
  ///
  /// See also:
  ///
  /// * [CustomExpansionTileTheme.of], which returns the nearest [CustomExpansionTileTheme]'s
  ///   [CustomExpansionTileThemeData].
  final EdgeInsetsGeometry? tilePadding;

  /// Specifies the alignment of [children], which are arranged in a column when
  /// the tile is expanded.
  ///
  /// The internals of the expanded tile make use of a [Column] widget for
  /// [children], and [Align] widget to align the column. The [expandedAlignment]
  /// parameter is passed directly into the [Align].
  ///
  /// Modifying this property controls the alignment of the column within the
  /// expanded tile, not the alignment of [children] widgets within the column.
  /// To align each child within [children], see [expandedCrossAxisAlignment].
  ///
  /// The width of the column is the width of the widest child widget in [children].
  ///
  /// If this property is null then [CustomExpansionTileThemeData.expandedAlignment]is used. If that
  /// is also null then the value of [expandedAlignment] is [Alignment.center].
  ///
  /// See also:
  ///
  /// * [CustomExpansionTileTheme.of], which returns the nearest [CustomExpansionTileTheme]'s
  ///   [CustomExpansionTileThemeData].
  final Alignment? expandedAlignment;

  /// Specifies the alignment of each child within [children] when the tile is expanded.
  ///
  /// The internals of the expanded tile make use of a [Column] widget for
  /// [children], and the `crossAxisAlignment` parameter is passed directly into
  /// the [Column].
  ///
  /// Modifying this property controls the cross axis alignment of each child
  /// within its [Column]. The width of the [Column] that houses [children] will
  /// be the same as the widest child widget in [children]. The width of the
  /// [Column] might not be equal to the width of the expanded tile.
  ///
  /// To align the [Column] along the expanded tile, use the [expandedAlignment]
  /// property instead.
  ///
  /// When the value is null, the value of [expandedCrossAxisAlignment] is
  /// [CrossAxisAlignment.center].
  final CrossAxisAlignment? expandedCrossAxisAlignment;

  /// Specifies padding for [children].
  ///
  /// If this property is null then [CustomExpansionTileThemeData.childrenPadding] is used. If that
  /// is also null then the value of [childrenPadding] is [EdgeInsets.zero].
  ///
  /// See also:
  ///
  /// * [CustomExpansionTileTheme.of], which returns the nearest [CustomExpansionTileTheme]'s
  ///   [CustomExpansionTileThemeData].
  final EdgeInsetsGeometry? childrenPadding;

  /// The icon color of tile's expansion arrow icon when the sublist is expanded.
  ///
  /// Used to override to the [ListTileThemeData.iconColor].
  ///
  /// If this property is null then [CustomExpansionTileThemeData.iconColor] is used. If that
  /// is also null then the value of [ColorScheme.primary] is used.
  ///
  /// See also:
  ///
  /// * [CustomExpansionTileTheme.of], which returns the nearest [CustomExpansionTileTheme]'s
  ///   [CustomExpansionTileThemeData].
  final Color? iconColor;

  /// The icon color of tile's expansion arrow icon when the sublist is collapsed.
  ///
  /// Used to override to the [ListTileThemeData.iconColor].
  ///
  /// If this property is null then [CustomExpansionTileThemeData.collapsedIconColor] is used. If that
  /// is also null and [ThemeData.useMaterial3] is true, [ColorScheme.onSurface] is used. Otherwise,
  /// defaults to [ThemeData.unselectedWidgetColor] color.
  ///
  /// See also:
  ///
  /// * [CustomExpansionTileTheme.of], which returns the nearest [CustomExpansionTileTheme]'s
  ///   [CustomExpansionTileThemeData].
  final Color? collapsedIconColor;


  /// The color of the tile's titles when the sublist is expanded.
  ///
  /// Used to override to the [ListTileThemeData.textColor].
  ///
  /// If this property is null then [CustomExpansionTileThemeData.textColor] is used. If that
  /// is also null then and [ThemeData.useMaterial3] is true, color of the [TextTheme.bodyLarge]
  /// will be used for the [title] and [subtitle]. Otherwise, defaults to [ColorScheme.primary] color.
  ///
  /// See also:
  ///
  /// * [CustomExpansionTileTheme.of], which returns the nearest [CustomExpansionTileTheme]'s
  ///   [CustomExpansionTileThemeData].
  final Color? textColor;

  /// The color of the tile's titles when the sublist is collapsed.
  ///
  /// Used to override to the [ListTileThemeData.textColor].
  ///
  /// If this property is null then [CustomExpansionTileThemeData.collapsedTextColor] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, color of the
  /// [TextTheme.bodyLarge] will be used for the [title] and [subtitle]. Otherwise,
  /// defaults to color of the [TextTheme.titleMedium].
  ///
  /// See also:
  ///
  /// * [CustomExpansionTileTheme.of], which returns the nearest [CustomExpansionTileTheme]'s
  ///   [CustomExpansionTileThemeData].
  final Color? collapsedTextColor;

  /// The tile's border shape when the sublist is expanded.
  ///
  /// If this property is null, the [CustomExpansionTileThemeData.shape] is used. If that
  /// is also null, a [Border] with vertical sides default to [ThemeData.dividerColor] is used
  ///
  /// See also:
  ///
  /// * [CustomExpansionTileTheme.of], which returns the nearest [CustomExpansionTileTheme]'s
  ///   [CustomExpansionTileThemeData].
  final ShapeBorder? shape;

  /// The tile's border shape when the sublist is collapsed.
  ///
  /// If this property is null, the [CustomExpansionTileThemeData.collapsedShape] is used. If that
  /// is also null, a [Border] with vertical sides default to Color [Colors.transparent] is used
  ///
  /// See also:
  ///
  /// * [CustomExpansionTileTheme.of], which returns the nearest [CustomExpansionTileTheme]'s
  ///   [CustomExpansionTileThemeData].
  final ShapeBorder? collapsedShape;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// If this is not null and a CustomExpansionTile collapsed or expanded shape is provided,
  /// the value of [clipBehavior] will be used to clip the expansion tile.
  ///
  /// If this property is null, the [CustomExpansionTileThemeData.clipBehavior] is used. If that
  /// is also null, defaults to [Clip.antiAlias].
  ///
  /// See also:
  ///
  /// * [CustomExpansionTileTheme.of], which returns the nearest [CustomExpansionTileTheme]'s
  ///   [CustomExpansionTileThemeData].
  final Clip? clipBehavior;

  /// Typically used to force the expansion arrow icon to the tile's leading or trailing edge.
  ///
  /// By default, the value of [controlAffinity] is [ListTileControlAffinity.platform],
  /// which means that the expansion arrow icon will appear on the tile's trailing edge.
  final ListTileControlAffinity? controlAffinity;

  /// If provided, the controller can be used to expand and collapse tiles.
  ///
  /// In cases were control over the tile's state is needed from a callback triggered
  /// by a widget within the tile, [CustomExpansionTileController.of] may be more convenient
  /// than supplying a controller.
  final CustomExpansionTileController? controller;

  /// {@macro flutter.material.ListTile.dense}
  final bool? dense;

  /// Defines how compact the expansion tile's layout will be.
  ///
  /// {@macro flutter.material.themedata.visualDensity}
  final VisualDensity? visualDensity;

  /// {@macro flutter.material.ListTile.minTileHeight}
  final double? minTileHeight;

  /// {@macro flutter.material.ListTile.enableFeedback}
  final bool? enableFeedback;

  /// Whether this expansion tile is interactive.
  ///
  /// If false, the internal [ListTile] will be disabled, changing its
  /// appearance according to the theme and disabling user interaction.
  ///
  /// Even if disabled, the expansion can still be toggled programmatically
  /// through an [CustomExpansionTileController].
  final bool enabled;

  /// Used to override the expansion animation curve and duration.
  ///
  /// If [AnimationStyle.duration] is provided, it will be used to override
  /// the expansion animation duration. If it is null, then [AnimationStyle.duration]
  /// from the [CustomExpansionTileThemeData.expansionAnimationStyle] will be used.
  /// Otherwise, defaults to 200ms.
  ///
  /// If [AnimationStyle.curve] is provided, it will be used to override
  /// the expansion animation curve. If it is null, then [AnimationStyle.curve]
  /// from the [CustomExpansionTileThemeData.expansionAnimationStyle] will be used.
  /// Otherwise, defaults to [Curves.easeIn].
  ///
  /// If [AnimationStyle.reverseCurve] is provided, it will be used to override
  /// the collapse animation curve. If it is null, then [AnimationStyle.reverseCurve]
  /// from the [CustomExpansionTileThemeData.expansionAnimationStyle] will be used.
  /// Otherwise, the same curve will be used as for expansion.
  ///
  /// To disable the theme animation, use [AnimationStyle.noAnimation].
  ///
  /// {@tool dartpad}
  /// This sample showcases how to override the [CustomExpansionTile] expansion
  /// animation curve and duration using [AnimationStyle].
  ///
  /// ** See code in examples/api/lib/material/expansion_tile/expansion_tile.2.dart **
  /// {@end-tool}
  final AnimationStyle? expansionAnimationStyle;

  @override
  State<CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile> with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeOutTween = CurveTween(curve: Curves.easeOut);
  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _halfTween = Tween<double>(begin: 0.0, end: 0.5);

  final ShapeBorderTween _borderTween = ShapeBorderTween();
  final ColorTween _headerColorTween = ColorTween();
  final ColorTween _iconColorTween = ColorTween();
  final ColorTween _backgroundColorTween = ColorTween();
  final Tween<double> _heightFactorTween = Tween<double>(begin: 0.0, end: 1.0);

  late AnimationController _animationController;
  late Animation<double> iconTurns;
  late CurvedAnimation _heightFactor;
  late Animation<ShapeBorder?> _border;
  late Animation<Color?> headerColor;
  late Animation<Color?> iconColor;
  late Animation<Color?> _backgroundColor;

  bool _isExpanded = false;
  late CustomExpansionTileController _tileController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: _kExpand, vsync: this);
    _heightFactor = CurvedAnimation(
      parent: _animationController.drive(_heightFactorTween),
      curve: Curves.easeIn,
    );
    iconTurns = _animationController.drive(_halfTween.chain(_easeInTween));
    _border = _animationController.drive(_borderTween.chain(_easeOutTween));
    headerColor = _animationController.drive(_headerColorTween.chain(_easeInTween));
    iconColor = _animationController.drive(_iconColorTween.chain(_easeInTween));
    _backgroundColor = _animationController.drive(_backgroundColorTween.chain(_easeOutTween));

    _isExpanded = PageStorage.maybeOf(context)?.readState(context) as bool? ?? widget.initiallyExpanded;
    if (_isExpanded) {
      _animationController.value = 1.0;
    }

    assert(widget.controller?._state == null);
    _tileController = widget.controller ?? CustomExpansionTileController();
    _tileController._state = this;
  }

  @override
  void dispose() {
    _tileController._state = null;
    _animationController.dispose();
    _heightFactor.dispose();
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _toggleExpansion() {
    final TextDirection textDirection = WidgetsLocalizations.of(context).textDirection;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final String stateHint = _isExpanded ? localizations.expandedHint : localizations.collapsedHint;
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse().then<void>((void value) {
          if (!mounted) {
            return;
          }
          setState(() {
            // Rebuild without widget.children.
          });
        });
      }
      PageStorage.maybeOf(context)?.writeState(context, _isExpanded);
    });
    widget.onExpansionChanged?.call(_isExpanded);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // TODO(tahatesser): This is a workaround for VoiceOver interrupting
      // semantic announcements on iOS. https://github.com/flutter/flutter/issues/122101.
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 1), () {
        SemanticsService.announce(stateHint, textDirection);
        _timer?.cancel();
        _timer = null;
      });
    } else {
      SemanticsService.announce(stateHint, textDirection);
    }
  }

  void _handleTap() {
    _toggleExpansion();
  }


  Widget _buildChildren(BuildContext context, Widget? child) {
    final ThemeData theme = Theme.of(context);
    final ExpansionTileThemeData customExpansionTileTheme = ExpansionTileTheme.of(context);
    final Color backgroundColor = _backgroundColor.value ?? customExpansionTileTheme.backgroundColor ?? Colors.transparent;
    final ShapeBorder customExpansionTileBorder = _border.value ?? const Border(
      top: BorderSide(color: Colors.transparent),
      bottom: BorderSide(color: Colors.transparent),
    );
    final Clip clipBehavior = widget.clipBehavior ?? customExpansionTileTheme.clipBehavior ?? Clip.antiAlias;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final String onTapHint = _isExpanded
        ? localizations.expansionTileExpandedTapHint
        : localizations.expansionTileCollapsedTapHint;
    String? semanticsHint;
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        semanticsHint = _isExpanded
            ? '${localizations.collapsedHint}\n ${localizations.expansionTileExpandedHint}'
            : '${localizations.expandedHint}\n ${localizations.expansionTileCollapsedHint}';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        break;
    }

    final Decoration decoration = ShapeDecoration(
      color: backgroundColor,
      shape: customExpansionTileBorder,
    );

    final Widget tile = Padding(
      padding: decoration.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            hint: semanticsHint,
            onTapHint: onTapHint,
            child:  InkWell(
              highlightColor: Theme.of(context).primaryColor.withValues(alpha:0),
              splashColor: Theme.of(context).primaryColor.withValues(alpha:0),
              onTap: () {_handleTap();},
              child: Padding(
                padding: const EdgeInsets.only(left: Dimensions.iconSizeSmall, top:Dimensions.iconSizeSmall, right:Dimensions.iconSizeSmall, bottom: Dimensions.paddingSizeExtraSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Expanded(child: SizedBox(child: widget.title)),

                      if (widget.showTrailingIcon && widget.trailing != null)
                        Transform.translate(offset: const Offset(0, -11),
                          child: SizedBox(
                            child: widget.trailing,)) else Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    ],),

                    SizedBox(child: widget.subtitle,),


                  ],),
              ),
            ),
          ),
          ClipRect(
            child: Align(
              alignment: widget.expandedAlignment
                  ?? customExpansionTileTheme.expandedAlignment
                  ?? Alignment.center,
              heightFactor: _heightFactor.value,
              child: child,
            ),
          ),
        ],
      ),
    );

    final bool isShapeProvided = widget.shape != null || customExpansionTileTheme.shape != null
        || widget.collapsedShape != null || customExpansionTileTheme.collapsedShape != null;

    if (isShapeProvided) {
      return Material(
        clipBehavior: clipBehavior,
        color: backgroundColor,
        shape: customExpansionTileBorder,
        child: tile,
      );
    }

    return DecoratedBox(
      decoration: decoration,
      child: tile,
    );
  }

  @override
  void didUpdateWidget(covariant CustomExpansionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ThemeData theme = Theme.of(context);
    final ExpansionTileThemeData customExpansionTileTheme = ExpansionTileTheme.of(context);

    if (widget.collapsedShape != oldWidget.collapsedShape
        || widget.shape != oldWidget.shape) {
      _updateShapeBorder(customExpansionTileTheme, theme);
    }
    if (widget.collapsedTextColor != oldWidget.collapsedTextColor
        || widget.textColor != oldWidget.textColor) {
      _updateHeaderColor(customExpansionTileTheme, customExpansionTileTheme);
    }
    if (widget.collapsedIconColor != oldWidget.collapsedIconColor
        || widget.iconColor != oldWidget.iconColor) {
      _updateIconColor(customExpansionTileTheme, customExpansionTileTheme);
    }
    if (widget.backgroundColor != oldWidget.backgroundColor
        || widget.collapsedBackgroundColor != oldWidget.collapsedBackgroundColor) {
      _updateBackgroundColor(customExpansionTileTheme);
    }
    if (widget.expansionAnimationStyle != oldWidget.expansionAnimationStyle) {
      _updateAnimationDuration(customExpansionTileTheme);
      _updateHeightFactorCurve(customExpansionTileTheme);
    }
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    final ExpansionTileThemeData customExpansionTileTheme = ExpansionTileTheme.of(context);

    _updateAnimationDuration(customExpansionTileTheme);
    _updateShapeBorder(customExpansionTileTheme, theme);
    _updateHeaderColor(customExpansionTileTheme, customExpansionTileTheme);
    _updateIconColor(customExpansionTileTheme, customExpansionTileTheme);
    _updateBackgroundColor(customExpansionTileTheme);
    _updateHeightFactorCurve(customExpansionTileTheme);
    super.didChangeDependencies();
  }

  void _updateAnimationDuration(ExpansionTileThemeData customExpansionTileTheme) {
    _animationController.duration = widget.expansionAnimationStyle?.duration
        ?? customExpansionTileTheme.expansionAnimationStyle?.duration
        ?? _kExpand;
  }

  void _updateShapeBorder(ExpansionTileThemeData customExpansionTileTheme, ThemeData theme) {
    _borderTween
      ..begin = widget.collapsedShape
          ?? customExpansionTileTheme.collapsedShape
          ?? const Border(
            top: BorderSide(color: Colors.transparent),
            bottom: BorderSide(color: Colors.transparent),
          )
      ..end = widget.shape
          ?? customExpansionTileTheme.shape
          ?? Border(
            top: BorderSide(color: theme.dividerColor.withValues(alpha:0)),
            bottom: BorderSide(color: theme.dividerColor.withValues(alpha:0)),
          );
  }

  void _updateHeaderColor(ExpansionTileThemeData customExpansionTileTheme, ExpansionTileThemeData defaults) {
    _headerColorTween
      ..begin = widget.collapsedTextColor
          ?? customExpansionTileTheme.collapsedTextColor
          ?? defaults.collapsedTextColor
      ..end = widget.textColor ?? customExpansionTileTheme.textColor ?? defaults.textColor;
  }

  void _updateIconColor(ExpansionTileThemeData customExpansionTileTheme, ExpansionTileThemeData defaults) {
    _iconColorTween
      ..begin = widget.collapsedIconColor
          ?? customExpansionTileTheme.collapsedIconColor
          ?? defaults.collapsedIconColor
      ..end = widget.iconColor ?? customExpansionTileTheme.iconColor ?? defaults.iconColor;
  }

  void _updateBackgroundColor(ExpansionTileThemeData customExpansionTileTheme) {
    _backgroundColorTween
      ..begin = widget.collapsedBackgroundColor ?? customExpansionTileTheme.collapsedBackgroundColor
      ..end = widget.backgroundColor ?? customExpansionTileTheme.backgroundColor;
  }

  void _updateHeightFactorCurve(ExpansionTileThemeData customExpansionTileTheme) {
    _heightFactor.curve = widget.expansionAnimationStyle?.curve
        ?? customExpansionTileTheme.expansionAnimationStyle?.curve
        ?? Curves.easeIn;
    _heightFactor.reverseCurve = widget.expansionAnimationStyle?.reverseCurve
        ?? customExpansionTileTheme.expansionAnimationStyle?.reverseCurve;
  }

  @override
  Widget build(BuildContext context) {
    final ExpansionTileThemeData customExpansionTileTheme = ExpansionTileTheme.of(context);
    final bool closed = !_isExpanded && _animationController.isDismissed;
    final bool shouldRemoveChildren = closed && !widget.maintainState;

    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(
        enabled: !closed,
        child: Padding(
          padding: widget.childrenPadding ?? customExpansionTileTheme.childrenPadding ?? EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: widget.expandedCrossAxisAlignment ?? CrossAxisAlignment.center,
            children: widget.children,
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _animationController.view,
      builder: _buildChildren,
      child: shouldRemoveChildren ? null : result,
    );
  }
}

// END GENERATED TOKEN PROPERTIES - CustomExpansionTile
