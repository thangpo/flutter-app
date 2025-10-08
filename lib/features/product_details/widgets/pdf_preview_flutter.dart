import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';


class PdfPreview extends StatefulWidget {
  final String url;
  final String fileName;
  const PdfPreview({super.key, required this.url, required this.fileName});

  @override
  State<PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<PdfPreview> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();


  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      width: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).hintColor.withValues(alpha:0.50),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault)
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.fileName,
                  style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),


              SizedBox(
                height: 20, width: 20,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: ()=> Navigator.of(context, rootNavigator: true).pop(),
                  icon: Icon(Icons.close, color: Theme.of(context).hintColor, size: 20,)
                )
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          Expanded(
            child: SfPdfViewerTheme(
              data: const SfPdfViewerThemeData(
                backgroundColor: Colors.white,
              ),
              child: SfPdfViewer.network(
                widget.url,
                key: _pdfViewerKey,
              ),
            ),
          )
        ],
      ),
    );
  }
}
