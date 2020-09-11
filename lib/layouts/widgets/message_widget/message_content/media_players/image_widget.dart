import 'dart:io';

import 'package:bluebubbles/layouts/image_viewer/image_viewer.dart';
import 'package:bluebubbles/layouts/widgets/message_widget/message_content/message_attachments.dart';
import 'package:bluebubbles/database/models/attachment.dart';
import 'package:bluebubbles/helpers/attachment_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageWidget extends StatefulWidget {
  ImageWidget({Key key, this.file, this.attachment, this.savedAttachmentData})
      : super(key: key);
  final File file;
  final Attachment attachment;
  final SavedAttachmentData savedAttachmentData;

  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (!widget.savedAttachmentData.imageData
        .containsKey(widget.attachment.guid)) {
      // If it's an image, compress the image when loading it
      if (AttachmentHelper.canCompress(widget.attachment)) {
        widget.savedAttachmentData.imageData[widget.attachment.guid] =
            await FlutterImageCompress.compressWithFile(
                widget.file.absolute.path,
                quality: 70 // This is arbitrary
                );

        // All other attachments can be held in memory as bytes
      } else {
        widget.savedAttachmentData.imageData[widget.attachment.guid] =
            await widget.file.readAsBytes();
      }

      if (this.mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.savedAttachmentData.imageData[widget.attachment.guid] == null
            ? Container(
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey,
                  valueColor:
                      AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                ),
                padding: EdgeInsets.all(2.0),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width / 3,
                ))
            : Hero(
                tag: widget.attachment.guid,
                child: Image.memory(widget
                    .savedAttachmentData.imageData[widget.attachment.guid]),
              ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ImageViewer(
                      file: widget.file,
                      bytes: widget.savedAttachmentData
                          .imageData[widget.attachment.guid],
                      tag: widget.attachment.guid,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
