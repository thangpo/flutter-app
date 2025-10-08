import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class CustomCalendarWidget extends StatefulWidget {
  final PickerDateRange? initDateRange;
  final Function(PickerDateRange? dateRange) onSubmit;
  const CustomCalendarWidget({super.key, required this.onSubmit, this.initDateRange});

  @override
  State<CustomCalendarWidget> createState() => _CustomCalendarWidgetState();
}

class _CustomCalendarWidgetState extends State<CustomCalendarWidget> {

  @override
  Widget build(BuildContext context) {

    return Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
            child: Container(
              color: themeController.darkTheme ? Theme.of(context).dividerColor : Theme.of(context).canvasColor,
              child: SfDateRangePicker(
                confirmText: getTranslated('ok', context)!,
                showActionButtons: true,
                cancelText: getTranslated('cancel', context)!,
                onCancel: () => Navigator.of(context).pop(),
                onSubmit: (value){

                  if(value is PickerDateRange) {

                    widget.onSubmit(value);

                    Navigator.pop(context);
                  }

                },
                todayHighlightColor: themeController.darkTheme ? Colors.white : Theme.of(context).primaryColor,
                selectionMode: DateRangePickerSelectionMode.range,
                rangeSelectionColor: Theme.of(context).primaryColor.withValues(alpha:.50),
                view: DateRangePickerView.month,

                startRangeSelectionColor: Theme.of(context).colorScheme.primary,
                endRangeSelectionColor: Theme.of(context).colorScheme.primary,
                initialSelectedRange:  PickerDateRange(
                  widget.initDateRange?.startDate ?? DateTime.now().subtract(const Duration(days: 2)),
                  widget.initDateRange?.endDate ?? DateTime.now().add(const Duration(days: 2)),
                ),
              ),),
          );
        }
    );

  }
}
