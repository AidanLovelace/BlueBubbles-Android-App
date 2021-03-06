import 'dart:io';
import 'dart:typed_data';
import 'package:bluebubbles/helpers/attachment_helper.dart';
import 'package:bluebubbles/helpers/share.dart';
import 'package:bluebubbles/layouts/image_viewer/attachmet_fullscreen_viewer.dart';
import 'package:bluebubbles/repository/models/attachment.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewer extends StatefulWidget {
  ImageViewer({
    Key key,
    this.tag,
    this.file,
    this.attachment,
    this.showInteractions,
  }) : super(key: key);
  final String tag;
  final File file;
  final Attachment attachment;
  final bool showInteractions;

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with AutomaticKeepAliveClientMixin {
  double top = 0;
  int duration = 0;
  PhotoViewController controller;
  bool showOverlay = true;
  Uint8List bytes;

  @override
  void initState() {
    super.initState();
    controller = new PhotoViewController();

    controller.outputStateStream.listen((event) {
      if (AttachmentFullscreenViewer.of(context) == null ||
          event.boundaries == null ||
          event.scale == null) return;
      if (this.mounted) {
        AttachmentFullscreenViewerState state =
            AttachmentFullscreenViewer.of(context);
        if (event.scale > event.boundaries.minScale) {
          if (state.physics != NeverScrollableScrollPhysics()) {
            AttachmentFullscreenViewer.of(context).setState(() {
              AttachmentFullscreenViewer.of(context).physics =
                  NeverScrollableScrollPhysics();
            });
          }
        } else {
          if (state.physics !=
              AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics())) {
            AttachmentFullscreenViewer.of(context).setState(() {
              AttachmentFullscreenViewer.of(context).physics =
                  AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              );
            });
          }
        }
      }
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    bytes = await widget.file.readAsBytes();
    if (this.mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    Widget overlay = AnimatedOpacity(
      opacity: showOverlay ? 1.0 : 0.0,
      duration: Duration(milliseconds: 125),
      child: Container(
        height: 150.0,
        width: MediaQuery.of(context).size.width,
        color: Colors.black.withOpacity(0.65),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: CupertinoButton(
                onPressed: () async {
                  List<Widget> metaWidgets = [];
                  for (var entry
                      in widget.attachment.metadata?.entries ?? {}.entries) {
                    metaWidgets.add(RichText(
                        text: TextSpan(children: [
                      TextSpan(
                          text: "${entry.key}: ",
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              .apply(fontWeightDelta: 2)),
                      TextSpan(
                          text: entry.value.toString(),
                          style: Theme.of(context).textTheme.bodyText1)
                    ])));
                  }

                  if (metaWidgets.length == 0) {
                    metaWidgets.add(Text(
                      "No metadata available",
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .apply(fontWeightDelta: 2),
                      textAlign: TextAlign.center,
                    ));
                  }

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        "Metadata",
                        style: Theme.of(context).textTheme.headline1,
                        textAlign: TextAlign.center,
                      ),
                      backgroundColor: Theme.of(context).accentColor,
                      content: SizedBox(
                        width: MediaQuery.of(context).size.width * 3 / 5,
                        height: MediaQuery.of(context).size.height * 1 / 4,
                        child: Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              color: Theme.of(context).backgroundColor,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          child: ListView(
                            physics: AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            children: metaWidgets,
                          ),
                        ),
                      ),
                      actions: [
                        FlatButton(
                          child: Text(
                            "Close",
                            style:
                                Theme.of(context).textTheme.bodyText1.copyWith(
                                      color: Theme.of(context).primaryColor,
                                    ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  Icons.info,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: CupertinoButton(
                onPressed: () async {
                  await AttachmentHelper.saveToGallery(context, widget.file);
                },
                child: Icon(
                  Icons.file_download,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: CupertinoButton(
                onPressed: () async {
                  // final Uint8List bytes = await widget.file.readAsBytes();
                  await Share.file(
                    "Shared ${widget.attachment.mimeType.split("/")[0]} from BlueBubbles: ${widget.attachment.transferName}",
                    widget.attachment.transferName,
                    widget.file.path,
                    widget.attachment.mimeType,
                  );
                },
                child: Icon(
                  Icons.share,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    var loader = Center(
      child: CircularProgressIndicator(
        backgroundColor: Theme.of(context).accentColor,
        valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            if (!this.mounted || !widget.showInteractions) return;

            setState(() {
              showOverlay = !showOverlay;
            });
          },
          child: Stack(
            children: <Widget>[
              bytes != null
                  ? PhotoView(
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.contained * 13,
                      controller: controller,
                      imageProvider: MemoryImage(bytes),
                      loadingBuilder:
                          (BuildContext context, ImageChunkEvent ev) {
                        return loader;
                      },
                    )
                  : loader,
              overlay
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
