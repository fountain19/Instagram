import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram/models/User.dart';
import 'package:instagram/pages/profilePage.dart';
import 'package:instagram/widget/headerWidget.dart';
import 'package:instagram/widget/progressWidget.dart';
import '../constent.dart';
import 'commentPage.dart';
import 'homePage.dart';

class TimeLinePage extends StatefulWidget {
  //argment from homepage for get dat from User
  final String userProfileId;
  TimeLinePage({this.userProfileId});
  @override
  _TimeLinePageState createState() => _TimeLinePageState();
}

class _TimeLinePageState extends State<TimeLinePage>
    with AutomaticKeepAliveClientMixin<TimeLinePage> {
  final String postId;
  final String postOwnerid;
  final String postImageUrl;
  _TimeLinePageState({this.postId, this.postImageUrl, this.postOwnerid});
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: FutureBuilder<QuerySnapshot>(
        future: Firestore.instance
            .collection('timeline')
            .orderBy('timestamp', descending: false)
            .getDocuments(),
        // ignore: missing_return
        builder: (context, dataSnapShot) {
          if (!dataSnapShot.hasData) {
            return circularProgres();
          }
          List<AllPosts> allPosts = [];
          dataSnapShot.data.documents.forEach((document) {
            allPosts.add(AllPosts.fromDocument(document));
          });
          return ListView(
            children: allPosts,
          );
        },
      ),
    );
  }
}

class AllPosts extends StatefulWidget {
  final String id;
  final String postID;
  final String ownerID;
  final dynamic likes;
  final String username;
  final String description;
  final String url;
  final String location;
  final Timestamp timestamp;

  AllPosts(
      {this.postID,
        this.id,
        this.ownerID,
        this.description,
        this.likes,
        this.username,
        this.location,
        this.url,
        this.timestamp});
  factory AllPosts.fromDocument(DocumentSnapshot doc) {
    return AllPosts(
      id: doc.documentID,
      postID: doc['postID'],
      ownerID: doc['ownerID'],
      username: doc['username'],
      likes: doc['likes'],
      url: doc['url'],
      description: doc['description'],
      location: doc['location'],
      timestamp: doc['timestamp'],
    );
  }

  // this method for count Number likes
  int getNumberOfLikes(likes) {
    if (likes == null) {
      return 0;
    } else {
      int counter = 0;
      likes.values.forEach((eachValues) {
        if (eachValues == true) {
          counter = counter + 1;
        }
      });
      return counter;
    }
  }

  @override
  _AllPostsState createState() => _AllPostsState(
      postID: this.postID,
      ownerID: this.ownerID,
      likes: this.likes,
      username: this.username,
      description: this.description,
      url: this.url,
      location: this.location,
      likesCount: getNumberOfLikes(this.likes));
}

class _AllPostsState extends State<AllPosts> {
  final String postID;
  final String ownerID;
  final String username;
  final String description;
  final String url;
  final String location;
  final String currentOnlineUserId = currentUser?.id;
  Map likes;
  bool isLiked;
  int likesCount;
  bool showHeart = false;
  _AllPostsState(
      {this.likesCount,
        this.ownerID,
        this.postID,
        this.url,
        this.username,
        this.description,
        this.location,
        this.likes});

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentOnlineUserId] == true);
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: [

          Container(
            width: MediaQuery.of(context).size.width,
            child: Center(
                child: GestureDetector(
                  onDoubleTap: () => controlUserLikePost(),
                  // onLongPress:()=> storygram.firestore.collection('timeline').doc().delete(),
                  child: Padding(
                    padding:  EdgeInsets.only(top: 8.0,bottom: 8.0),
                    child: Stack(
                      children: [
                        Image(
                          image: NetworkImage(widget.url),
                        ),
                        showHeart
                            ? Icon(
                          Icons.favorite,
                          size: 140,
                          color: Colors.pink,
                        )
                            : Text(''),
                        Positioned(
                          bottom: 0,
                          child: Opacity(opacity: 0.6, child: Container(
                            height: 100,
                            width: MediaQuery.of(context).size.width ,
                            child: creatPostFooter(),
                          )),
                        ),
                        Positioned(
                          top: 0,
                          child: Opacity(opacity: 0.8, child: Container(
                            color: Colors.black12,
                            height: 60,
                            width: MediaQuery.of(context).size.width ,
                            child: createPostHead(),
                          )),
                        ),
                      ],
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  createPostHead() {
    return FutureBuilder(
      future: usersReference.document(widget.ownerID).get(),
      // ignore: missing_return
      builder: (context, dataSnapShot) {
        if (!dataSnapShot.hasData) {
          return circularProgres();
        }
        User user = User.fromDocument(dataSnapShot.data);
        bool isPostOwner = currentOnlineUserId == widget.ownerID;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
              onTap: () => disPlayUserProfile(context, userProfileId: user.id),
              child: Text(
                user.username,
                style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              )),
          subtitle: Text(
            widget.location,
            style: TextStyle(color: Colors.white),
          ),
          trailing: isPostOwner
              ? IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onPressed: () => controlDeletePost(context),
          )
              : Text(''),
        );
      },
    );
  }

  controlUserLikePost() {
    bool _liked = widget.likes[currentOnlineUserId] == true;
    try {
      if (_liked) {
        postsReference
            .document(widget.ownerID)
            .collection(kuserPostscollection)
            .document(widget.postID)
            .updateData({'likes.$currentOnlineUserId': false});
        removeLike();
        setState(() {
          likesCount = likesCount - 1;
          isLiked = false;
          widget.likes[currentOnlineUserId] = false;
        });
      } else if (!_liked) {
        postsReference
            .document(widget.ownerID)
            .collection(kuserPostscollection)
            .document(widget.postID)
            .updateData({'likes.$currentOnlineUserId': true});

        addLike();
        setState(() {
          likesCount = likesCount + 1;
          isLiked = true;
          widget.likes[currentOnlineUserId] = true;
          showHeart = true;
        });
        Timer(Duration(milliseconds: 800), () {
          setState(() {
            showHeart = false;
          });
        });
      }
    } catch (convertPlatformException) {
      throw convertPlatformException(e);
    }
  }

  removeLike() {
    try {
      bool isNotPostOwnerId = currentOnlineUserId != widget.ownerID;
      if (isNotPostOwnerId) {
        activityFeedReference
            .document(widget.ownerID)
            .collection('feedItems')
            .document(widget.postID)
            .get()
            .then((document) {
          if (document.exists) {
            document.reference.delete();
          }
        });
      }
    } catch (exremoveLike) {
      print(exremoveLike);
    }
  }

  // this method for add like if not our post to feedItems
  addLike() {
    try {
      bool isNotPostOwner = currentOnlineUserId != ownerID;
      if (isNotPostOwner) {
        activityFeedReference
            .document(ownerID)
            .collection('feedItems')
            .document(postID)
            .setData({
          'type': 'like',
          'username': currentUser.username,
          'userId': currentUser.id,
          'timestamp': DateTime.now(),
          'url': url,
          'postId': postID,
          'userProfileImg': currentUser.photoUrl,
        });
      }
    } catch (exaddLike) {
      print(exaddLike.toString());
    }
  }

  disPlayComment(BuildContext context,
      {String postID, String ownerID, String url}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      //argment to Comment Page
      return CommentPage(
          postID: postID, postOwnerid: ownerID, postImageUrl: url);
    }));
  }

  creatPostFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 40.0, left: 20.0),
              child: GestureDetector(
                onTap: () => controlUserLikePost(),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 28.0,
                  color: Colors.pink,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20.0, top: 40.0),
              child: GestureDetector(
                onTap: () => disPlayComment(context,
                    url: widget.url,
                    postID: widget.postID,
                    ownerID: widget.ownerID),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 28.0,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
                margin: EdgeInsets.only(left: 20.0),
                child: Text('$likesCount likes',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)))
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                margin: EdgeInsets.only(left: 20.0),
                child: Text(
                  '${widget.username} ',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                )),
            Expanded(
                child: Text('${widget.description}',
                    style: TextStyle(color: Colors.white))),
          ],
        ),
      ],
    );
  }

  disPlayUserProfile(BuildContext context, {String userProfileId}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProfilePage(
              userProfileId: userProfileId,
            )));
  }

//this method for prepare delete post
  controlDeletePost(BuildContext mcontext) {
    return showDialog(
        context: mcontext,
        builder: (context) {
          return SimpleDialog(
            title: Text(
              'What do you want to do ?',
              style: TextStyle(color: Colors.white),
            ),
            children: [
              SimpleDialogOption(
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  removeUserPost();
                },
              ),
              SimpleDialogOption(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

//this for delete post from firebase and storage and comment collection
  removeUserPost() async {
    // storageReference.child('post_$postID.jpg').delete();
    await Firestore.instance
        .collection('timeline')
        .document(postID)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
    QuerySnapshot commentquerySnapshot = await commentsReference
        .document(ownerID)
        .collection('comments')
        .where('postID', isEqualTo: postID)
        .getDocuments();
    commentquerySnapshot.documents.forEach((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
  }
}