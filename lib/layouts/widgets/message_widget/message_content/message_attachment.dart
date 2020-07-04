import 'dart:io';

import 'package:bluebubble_messages/helpers/attachment_downloader.dart';
import 'package:bluebubble_messages/helpers/utils.dart';
import 'package:bluebubble_messages/layouts/widgets/message_widget/message_content/media_file.dart';
import 'package:bluebubble_messages/layouts/widgets/message_widget/message_content/media_players/audio_player_widget.dart';
import 'package:bluebubble_messages/layouts/widgets/message_widget/message_content/media_players/contact_widget.dart';
import 'package:bluebubble_messages/layouts/widgets/message_widget/message_content/media_players/image_widget.dart';
import 'package:bluebubble_messages/layouts/widgets/message_widget/message_content/media_players/loaction_widget.dart';
import 'package:bluebubble_messages/layouts/widgets/message_widget/message_content/media_players/regular_file_opener.dart';
import 'package:bluebubble_messages/layouts/widgets/message_widget/message_content/media_players/video_widget.dart';
import 'package:bluebubble_messages/repository/models/attachment.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessageAttachment extends StatefulWidget {
  MessageAttachment({
    Key key,
    @required this.content,
    @required this.attachment,
    @required this.updateAttachment,
  }) : super(key: key);
  final content;
  final Attachment attachment;
  final Function() updateAttachment;

  @override
  _MessageAttachmentState createState() => _MessageAttachmentState();
}

class _MessageAttachmentState extends State<MessageAttachment>
    with AutomaticKeepAliveClientMixin {
  String blurhash;
  Widget placeHolder;
  Widget attachmentWidget;
  var content;

  @override
  void initState() {
    super.initState();
    content = widget.content;

    // Pull the blurhash from the attachment, based on the class type
    blurhash = content is AttachmentDownloader
        ? content.attachment.blurhash
        : content is Attachment ? content.blurhash : null;

    placeHolder = (blurhash == null)
        ? Container()
        : FutureBuilder(
            future: blurHashDecode(blurhash),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 3 / 4,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: AspectRatio(
                      aspectRatio:
                          widget.attachment.width / widget.attachment.height,
                      child: Image.memory(
                        snapshot.data,
                        width: 300,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                );
              } else {
                return Container();
              }
            },
          );
    if (blurhash != null) debugPrint(blurhash);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 3 / 4,
          // maxHeight: 600,
        ),
        child: _buildAttachmentWidget(),
      ),
    );
  }

  Widget _buildAttachmentWidget() {
    // If it's a file, it's already been downlaoded, so just display it
    if (content is File) {
      String mimeType = widget.attachment.mimeType;
      if (mimeType != null)
        mimeType = mimeType.substring(0, mimeType.indexOf("/"));
      if (mimeType == null || mimeType == "image") {
        return MediaFile(
          child: ImageWidget(
            attachment: widget.attachment,
            file: content,
          ),
          attachment: widget.attachment,
        );
      } else if (mimeType == "video") {
        return MediaFile(
          attachment: widget.attachment,
          child: VideoWidget(
            attachment: widget.attachment,
            file: content,
          ),
        );
      } else if (mimeType == "audio") {
        //TODO fix this stuff
        return MediaFile(
          attachment: widget.attachment,
          child: AudioPlayerWiget(
            attachment: widget.attachment,
            file: content,
          ),
        );
      } else if (widget.attachment.mimeType == "text/x-vlocation") {
        return MediaFile(
          attachment: widget.attachment,
          child: LocationWidget(
            file: content,
            attachment: widget.attachment,
          ),
        );
      } else if (widget.attachment.mimeType == "text/vcard") {
        return MediaFile(
          attachment: widget.attachment,
          child: ContactWidget(file: content, attachment: widget.attachment),
        );
      } else {
        return MediaFile(
          attachment: widget.attachment,
          child: RegularFileOpener(
            file: content,
            attachment: widget.attachment,
          ),
        );
      }

      // If it's an attachment, then it needs to be manually downloaded
    } else if (content is Attachment) {
      return Stack(
        alignment: Alignment.center,
        children: <Widget>[
          placeHolder,
          CupertinoButton(
            padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
            onPressed: () {
              content = new AttachmentDownloader(content);
              widget.updateAttachment();
              setState(() {});
            },
            color: Colors.transparent,
            child: Column(
              children: <Widget>[
                Text(
                  content.getFriendlySize(),
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                Icon(Icons.cloud_download, size: 28.0),
                (content.mimeType != null)
                    ? Text(
                        content.mimeType,
                        style: Theme.of(context).textTheme.bodyText1,
                      )
                    : Container()
              ],
            ),
          ),
        ],
      );

      // If it's an AttachmentDownloader, it is currently being downloaded
    } else if (content is AttachmentDownloader) {
      (content as AttachmentDownloader).stream.listen((event) {
        if (event is File) {
          content = event;
          setState(() {});
        }
      });
      return StreamBuilder(
        stream: content.stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return Text(
              "Error loading",
              style: Theme.of(context).textTheme.bodyText1,
            );
          }
          if (snapshot.data is File) {
            // widget.updateAttachment();
            content = snapshot.data;
            return Container();
          } else {
            double progress = 0.0;
            if (snapshot.hasData) {
              progress = snapshot.data["Progress"];
            } else {
              progress = content.progress;
            }

            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                placeHolder,
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    children: <Widget>[
                      CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                      ((content as AttachmentDownloader).attachment.mimeType !=
                              null)
                          ? Container(height: 5.0)
                          : Container(),
                      (content.attachment.mimeType != null)
                          ? Text(
                              content.attachment.mimeType,
                              style: Theme.of(context).textTheme.bodyText1,
                            )
                          : Container()
                    ],
                  ),
                )
              ],
            );
          }
        },
      );
    } else {
      return Text(
        "Error loading",
        style: Theme.of(context).textTheme.bodyText1,
      );
      //     return Container();
    }
  }

  @override
  bool get wantKeepAlive => true;
}
