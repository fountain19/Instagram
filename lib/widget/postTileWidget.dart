import 'package:flutter/material.dart';
import 'package:instagram/pages/postScreenPage.dart';
import 'package:instagram/widget/postWidget.dart';


class PostTile extends StatelessWidget {
  final Post post;
  PostTile(this.post);
  disPlayFullPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                PostScreenPage(postId: post.postID, userId: post.ownerID)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => disPlayFullPost(context),
      child: Image.network(post.url),
    );
  }
}