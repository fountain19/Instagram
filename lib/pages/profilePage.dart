import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:instagram/models/User.dart';
import 'package:instagram/widget/headerWidget.dart';
import 'package:instagram/widget/postTileWidget.dart';
import 'package:instagram/widget/postWidget.dart';
import 'package:instagram/widget/progressWidget.dart';

import '../constent.dart';
import 'editProfilePage.dart';
import 'homePage.dart';

class ProfilePage extends StatefulWidget {
  //argment from homepage for get dat from User
  final String userProfileId;
  ProfilePage({this.userProfileId});



  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int countTotalFollowers = 0;
  int countTotalFollowing = 0;
  bool following = false;
  // this for if Profile post is true or not
  bool loading = false;
  //for cunt Number posts
  int countPost = 0;
  //this list for postes that came from fireStore PostCollection
  List<Post> postList = [];
  //for switch view way to listView or gridview
  String postOraintion = 'grid';
  // ignore: must_call_super
  void initState() {
    //for get data from fireStore PostCollection
    getAllProfilePosts();
    getAllFollowers();
    getAllFollowing();
    cheackifAlreadyFollwing();
  }

// this method to know who is following you
  cheackifAlreadyFollwing() async {
    DocumentSnapshot documentSnapshot = await followersReference
        .document(widget.userProfileId)
        .collection(kUsersFollowersColl)
        .document(currentOnlineUserId)
        .get();
    setState(() {
      following = documentSnapshot.exists;
    });
  }

  getAllFollowing() async {
    QuerySnapshot querySnapshot = await followingReference
        .document(widget.userProfileId)
        .collection(kUserFollowingColl)
        .getDocuments();
    setState(() {
      countTotalFollowing=querySnapshot.documents.length;
    });
  }

  getAllFollowers() async
  {
    QuerySnapshot querySnapshot = await followersReference
        .document(widget.userProfileId)
        .collection(kUsersFollowersColl)
        .getDocuments();
    setState(() {
      countTotalFollowers=querySnapshot.documents.length;
    });
  }

  // this for bool inside createButton
  final String currentOnlineUserId = currentUser?.id;
  // this method for view data UserProfile from the up page
  creatProfileTopView() {
    return FutureBuilder(
      future: usersReference.document(widget.userProfileId).get(),
      builder: (context, dataSnapShot) {
        if (!dataSnapShot.hasData) {
          return circularProgres();
        }
        User user = User.fromDocument(dataSnapShot.data);
        return Padding(
          padding: EdgeInsets.all(17.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 45.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        //*1 this for number: {posts/followers/following}
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            createColumns('posts', countPost),
                            createColumns('followers', countTotalFollowers),
                            createColumns('following', countTotalFollowing),
                          ],
                        ),
                        Row(
                          children: [
                            createButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 13.0),
                  child: Text(
                    user.username.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 14.0),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 5.0),
                  child: Text(
                    user.email.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 14.0),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 3.0),
                  child: Text(
                    user.bio,
                    style: TextStyle(color: Colors.white70, fontSize: 18.0),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //*1 this for number: {posts/followers/following}
  Column createColumns(String title, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
              color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 5.0),
          child: Text(
            title,
            style: TextStyle(
                color: Colors.grey,
                fontSize: 16.0,
                fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

// *2 this for follow/UnFollowButton
  createButton() {
    // ignore: unrelated_type_equality_checks
    bool ownProfile = currentOnlineUserId == widget.userProfileId;
    if (ownProfile) {
      //*3this if it is my profile fpr edit
      return createButtonTitleAndFunction(
        title: 'EditProfile',
        performFunction: editProfile,
      );
    } else if (following) {
      //*3this if it is my profile fpr edit
      return createButtonTitleAndFunction(
        title: 'UnFollow',
        performFunction: controlUnFollowUser,
      );
    } else if (!following) {
      //*3this if it is my profile fpr edit
      return createButtonTitleAndFunction(
        title: 'Follow',
        performFunction: controlFollowUser,
      );
    }
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                EditProfilePage(currentOnlineUserId: currentOnlineUserId)));
  }

  controlUnFollowUser() {
    setState(() {
      following = false;
    });
    followersReference
        .document(widget.userProfileId)
        .collection(kUsersFollowersColl)
        .document(currentOnlineUserId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
    followingReference
        .document(currentOnlineUserId)
        .collection(kUserFollowingColl)
        .document(widget.userProfileId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
    activityFeedReference
        .document(widget.userProfileId)
        .collection(kFeedItemCollection)
        .document(currentOnlineUserId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
  }

  controlFollowUser() {
    setState(() {
      following = true;
    });
    followersReference
        .document(widget.userProfileId)
        .collection(kUsersFollowersColl)
        .document(currentOnlineUserId)
        .setData({});

    followingReference
        .document(currentOnlineUserId)
        .collection(kUserFollowingColl)
        .document(widget.userProfileId)
        .setData({});
    activityFeedReference
        .document(widget.userProfileId)
        .collection(kFeedItemCollection)
        .document(currentOnlineUserId)
        .setData({
      'type': 'follow',
      'ownerId': widget.userProfileId,
      'username': currentUser.username,
      'timestamp': DateTime.now(),
      'userProfileImg': currentUser.photoUrl,
      'userId': currentOnlineUserId,
    });
  }

// *3 this if it is my profile for edit Info
  Container createButtonTitleAndFunction(
      {String title, Function performFunction}) {
    return Container(
      child: Padding(
        padding: EdgeInsets.only(top: 3.0,left: 50.0),
        child: GestureDetector(
          onTap: performFunction,
          child: Container(
            width: 180.0,
            height: 26.0,
            child: Text(
              title,
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(6.0)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, strTitle: 'Profile'),
      body: ListView(
        children: [
          creatProfileTopView(),
          Divider(),
          createListAndGRIDPostOrintion(),
          Divider(
            height: 0.0,
          ),
          disPlayProfilePost(),
        ],
      ),
    );
  }

//this method if userProfile page found his posts or no post
  disPlayProfilePost() {
    if (loading) {
      return circularProgres();
    } else if (postList.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
                padding: EdgeInsets.all(30.0),
                child: Icon(
                  Icons.photo_library,
                  size: 200,
                  color: Colors.grey,
                )),
            Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No POST YET',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 40.0,
                      fontWeight: FontWeight.bold),
                ))
          ],
        ),
      );
    } else if (postOraintion == 'grid') {
      List<GridTile> gridTileList = [];
      postList.forEach((eachPost) {
        gridTileList.add(GridTile(child: PostTile(eachPost)));
      });
      return GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        physics: NeverScrollableScrollPhysics(),
        children: gridTileList,
      );
    } else if (postOraintion == 'list') {
      return Column(
        children: postList,
      );
    }
  }

//this method for get from fireStor postCollection
  getAllProfilePosts() async {
    setState(() {
      loading = true;
    });
    QuerySnapshot querySnapshot = await postsReference
        .document(widget.userProfileId)
        .collection(kuserPostscollection)
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      loading = false;
      countPost = querySnapshot.documents.length;
      postList = querySnapshot.documents
          .map((docsSnapShot) => Post.fromDocument(docsSnapShot))
          .toList();
    });
  }

//this for view list or grid
  createListAndGRIDPostOrintion() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => setOraintion('grid'),
          icon: Icon(Icons.grid_on),
          color: postOraintion == 'grid'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          onPressed: () => setOraintion('list'),
          icon: Icon(Icons.list),
          color: postOraintion == 'grid'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ],
    );
  }

  // this method for swithch bettwen view Way by grid or list
  setOraintion(String oraintion) {
    setState(() {
      this.postOraintion = oraintion;
    });
  }
}