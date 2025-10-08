import 'package:flutter_sixvalley_ecommerce/data/model/image_full_url.dart';

class SupportReplyModel {
  int? id;
  String? customerMessage;
  String? adminMessage;
  String? createdAt;
  String? updatedAt;
  List<String>? attachment;
  List<ImageFullUrl>? attachmentFullUrl;
  String? adminId;

  SupportReplyModel(
      {this.id,
        this.customerMessage,
        this.adminMessage,
        this.createdAt,
        this.updatedAt,
        this.attachment,
        this.adminId,
        this.attachmentFullUrl
      });

  SupportReplyModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    customerMessage = json['customer_message'];
    adminMessage = json['admin_message'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    adminId = json['admin_id'].toString();
    if(json['attachment'] != null && json['attachment'] is !String){
      attachment = json['attachment'].cast<String>();
    }else{
      attachment = [];
    }
    if (json['attachment_full_url'] != null) {
      attachmentFullUrl = <ImageFullUrl>[];
      json['attachment_full_url'].forEach((v) {
        attachmentFullUrl!.add(ImageFullUrl.fromJson(v));
      });
    }
  }


}
