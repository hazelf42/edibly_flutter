import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:edibly/custom/widgets.dart';
import 'package:edibly/models/data.dart';

class EventPreviewWidget extends StatelessWidget {
  final FirebaseUser firebaseUser;
  final Data event;

  EventPreviewWidget({
    @required this.firebaseUser,
    @required this.event,
  }) : super(key: Key((event.key).toString()));

  List<Data> dynamicTagArrayToTagList(dynamic dynamicTagArray) {
    List<Data> tagList = [];
    if (dynamicTagArray != null) {
      Map<dynamic, dynamic> map = dynamicTagArray;
      map.forEach((key, value) {
        tagList.add(Data(map['num'], map['text']));
      });
    }
    return tagList;
  }

  Widget _photoAndDistance(String distance) {
    String url = (event.value['photo'] ?? event.value['photo'] ?? '').toString();
    bool hasPhoto = url.isNotEmpty && url.toLowerCase() != 'none';
    if (!hasPhoto) url = 'https://img2.10bestmedia.com/static/img/placeholder-restaurants.jpg';
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(4.0),
        topRight: Radius.circular(4.0),
      ),
      child: Container(
        height: 120.0,
        color: Colors.white,
        child: Stack(
          children: <Widget>[
            CachedNetworkImage(
              imageUrl: url,
              width: 200.0,
              height: 120.0,
              fit: BoxFit.cover,
              placeholder: (context, imageUrl) {
                return Container(
                  width: 200.0,
                  height: 120.0,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                );
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 6.0,
              ),
              color: Colors.black.withOpacity(0.5),
              child: SingleLineText(
                distance,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        String url = event.value['facebookUrl'] ?? event.value['facebookURL'];
        if (!url.startsWith('http')) url = 'http://$url';
        if (url != null && await canLaunch(url)) {
          await launch(url);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: 200.0,
        child: Card(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _photoAndDistance(event.value['distance'] != null
                  ? '${double.parse(event.value['distance'].toString()).toStringAsFixed(1)} km'
                  : '...'),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SingleLineText(
                                event.value['name'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                ),
                              ),
                              Container(height: 1.0),
                              SingleLineText(
                                event.value['rname'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 13.0,
                                ),
                              ),
                              Container(height: 2.0),
                              SingleLineText(
                                '${DateFormat('hh:mm').format(DateTime.fromMillisecondsSinceEpoch(event.value['start'] * 1000))}'
                                ' - '
                                '${DateFormat('hh:mm').format(DateTime.fromMillisecondsSinceEpoch(event.value['start'] * 1000))}',
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 13.0,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
