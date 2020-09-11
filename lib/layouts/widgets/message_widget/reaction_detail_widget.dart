import 'package:bluebubbles/helpers/utils.dart';
import 'package:bluebubbles/layouts/widgets/contact_avatar_widget.dart';
import 'package:bluebubbles/database/models/handle.dart';
import 'package:bluebubbles/database/models/message.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReactionDetailWidget extends StatefulWidget {
  ReactionDetailWidget({
    Key key,
    this.handle,
    this.message,
  }) : super(key: key);
  final Handle handle;
  final Message message;

  @override
  _ReactionDetailWidgetState createState() => _ReactionDetailWidgetState();
}

class _ReactionDetailWidgetState extends State<ReactionDetailWidget> {
  ImageProvider contactImage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Contact contact = getContact(widget.handle.address);
    if (contact != null && contact.avatar.length > 0) {
      contactImage = MemoryImage(contact.avatar);
      if (this.mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(
        getContactTitle(widget.handle.id, widget.handle.address), " ");

    Color iconColor = Colors.white;
    if (Theme.of(context).accentColor.computeLuminance() >= 0.179) {
      iconColor = Colors.black.withAlpha(95);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
            child: ContactAvatarWidget(
              contactImage: contactImage,
              initials: initials,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              getContactTitle(widget.handle.id, widget.handle.address),
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  .apply(fontSizeDelta: -5),
            ),
          ),
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Theme.of(context).accentColor,
              boxShadow: [
                new BoxShadow(
                  blurRadius: 1.0,
                  color: Colors.black,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 8.0, left: 7.0, right: 7.0, bottom: 7.0),
              child: SvgPicture.asset(
                'assets/reactions/${widget.message.associatedMessageType}-black.svg',
                color: widget.message.associatedMessageType == "love"
                    ? Colors.pink
                    : iconColor,
              ),
            ),
          )
        ],
      ),
    );
  }
}
