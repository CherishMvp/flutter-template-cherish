import 'package:flutter/material.dart';

class CustomSliverWithSearchBar extends StatefulWidget {
  const CustomSliverWithSearchBar({super.key});

  @override
  _CustomSliverWithSearchBarState createState() =>
      _CustomSliverWithSearchBarState();
}

class _CustomSliverWithSearchBarState extends State<CustomSliverWithSearchBar> {
  ScrollController _scrollController = ScrollController();
  bool _isTabBarVisible = true;

  @override
  void initState() {
    super.initState();
    // 监听滚动事件
    _scrollController.addListener(() {
      // 当滚动超过一定距离时隐藏TabBar
      if (_scrollController.position.pixels > 200) {
        if (_isTabBarVisible) {
          setState(() {
            _isTabBarVisible = false;
          });
        }
      } else {
        if (!_isTabBarVisible) {
          setState(() {
            _isTabBarVisible = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // SliverAppBar
              SliverAppBar(
                floating: true,
                pinned: true,
                expandedHeight: 200.0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text("Custom Sliver AppBar"),
                  background: Image.network(
                    "https://via.placeholder.com/350x150",
                    fit: BoxFit.cover,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(50.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 40.0,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // SliverList for content
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return ListTile(
                      title: Text('Item #$index'),
                    );
                  },
                  childCount: 50,
                ),
              ),
            ],
          ),
          // 自定义悬浮的TabBar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _isTabBarVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Container(
                color: Colors.blueAccent,
                child: TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.home)),
                    Tab(icon: Icon(Icons.star)),
                    Tab(icon: Icon(Icons.person)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
