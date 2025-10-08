import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/controllers/product_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';


class DownloadPreview extends StatefulWidget {
  final String url;
  final String fileName;
  const DownloadPreview({super.key, required this.url, required this.fileName});

  @override
  State<DownloadPreview> createState() => _DownloadPreviewState();
}

class _DownloadPreviewState extends State<DownloadPreview> {
  final ReceivePort _port = ReceivePort();


  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      setState((){ });
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }


  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }




  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      width: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault)
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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

          Image.asset(width:50, height: 50, Images.downloadPreviewIcon),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          Text('${getTranslated('download_preview_file', context)}',
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Text(widget.fileName,
            style: titilliumRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault)),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),


          Consumer<ProductDetailsController>(
            builder: (context, productDetailsController, _) {
              return productDetailsController.isDownloadLoading ? const Center(child: SizedBox(height: 40, width: 40, child:  CircularProgressIndicator())): SizedBox(
                width: 150,
                child: CustomButton(
                  buttonText : getTranslated('download_now', context),
                  onTap: () {
                    productDetailsController.previewDownload(url: widget.url, fileName: widget.fileName);
                  },
                ),
              );
            }
          ),


        ],
      ),
    );
  }
}