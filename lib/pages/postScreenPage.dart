import 'package:flutter/material.dart';
import 'package:instagram/widget/headerWidget.dart';
import 'package:instagram/widget/postWidget.dart';
import 'package:instagram/widget/progressWidget.dart';

import '../constent.dart';
import 'homePage.dart';


class PostScreenPage extends StatelessWidget {
  final String postId;
  final String userId;
  PostScreenPage({this.postId, this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postsReference
          .document(userId)
          .collection(kuserPostscollection)
          .document(postId)
          .get(),
      builder: (context, dataSnapShot) {
        if (!dataSnapShot.hasData) {
          return circularProgres();
        }
        Post post = Post.fromDocument(dataSnapShot.data);
        return Center(
          child: Scaffold(
            appBar: header(context, strTitle: post.description),
            body: ListView(
              children: [
                Container(
                  child: post,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}