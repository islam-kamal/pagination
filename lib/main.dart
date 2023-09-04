import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  ScrollController? _controller;
  int _page = 1;
  bool _hasNextPage = true;
  bool _isFirstLoadRunning = false;
  bool _isLoadMoreRunning = false;
  List _posts = [];
  bool _listview_forward_scroll = false;
  Dio dio = new Dio();
  void _firstLoad() async {
    setState(() {
      _isFirstLoadRunning = true;
    });
    try {
      final res = await dio.get("https://driver.tag-soft.com/api/v1/cities");
      setState(() {
        _posts = res.data['data']['data'];
      });
    } catch (err) {}

    setState(() {
      _isFirstLoadRunning = false;
    });
  }

  void _loadMore() async {
    if (_hasNextPage == true &&
        _isFirstLoadRunning == false &&
        _isLoadMoreRunning == false &&
        _controller!.position.extentAfter < 300) {
      setState(() {
        _isLoadMoreRunning = true; // Display a progress indicator at the bottom
      });
      _page += 1; // Increase _page by 1
      try {
        final res = await dio
            .get("https://driver.tag-soft.com/api/v1/cities?page=$_page");
        final List fetchedPosts = res.data['data']['data'];
        if (fetchedPosts.length > 0) {
          print("3");
          setState(() {
            _posts.addAll(fetchedPosts);
          });
        } else {
          setState(() {
            _hasNextPage = false;
          });
        }
      } catch (err) {}

      setState(() {
        _isLoadMoreRunning = false;
      });
    }
  }

  @override
  void initState() {
    _firstLoad();
    _controller = new ScrollController()..addListener(_loadMore);
    super.initState();
  }


  @override
  void dispose() {
    _controller!.removeListener(_loadMore);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Container(
          height: MediaQuery.of(context).size.height,
          child: Container(
            child: _isFirstLoadRunning
                ? Center(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                          child: _posts.length == 0
                              ? Center(
                                  child: Center(
                                    child: Text('Sorry! This is empty'),
                                  ),
                                )
                              : GridView.builder(
                                  controller: _controller,
                                  shrinkWrap: true,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 20 / 16),
                                  itemCount: _posts.length,
                                  itemBuilder: (context, index) {
                                    if (_hasNextPage == false &&
                                        _controller!
                                                .position.userScrollDirection ==
                                            ScrollDirection.forward) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        setState(() {
                                          _listview_forward_scroll = true;
                                        });
                                      });
                                    }

                                    return GridTile(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          CircleAvatar(
                                              child: Icon(Icons.location_city)),
                                          const SizedBox(height: 8),
                                          Text(_posts[index]['name']),
                                          const SizedBox(height: 8),
                                          Text("id : ${_posts[index]['id']}"),
                                        ],
                                      ),
                                    );
                                  },
                                )),
                      // when the _loadMore function is running
                      if (_isLoadMoreRunning == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 100),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      // When nothing else to load
                      _listview_forward_scroll
                          ? Container()
                          : _hasNextPage == false
                              ? Container(
                                  padding: const EdgeInsets.only(
                                      top: 20, bottom: 100),
                                  color: Colors.black,
                                  child: Center(
                                    child: Text(
                                      "You have fetched all of the content",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                              : Container(),

                      _listview_forward_scroll
                          ? SizedBox(
                              height: 100,
                            )
                          : SizedBox()
                    ],
                  ),
          ),
        )
        );
  }

}

