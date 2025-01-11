import 'package:flutter/material.dart';
import 'package:kantin/Component/my_Description_Box.dart';
import 'package:kantin/Component/my_Silver_App_Bar.dart';
import 'package:kantin/Component/my_Tab_Bar.dart';
import 'package:kantin/Component/my_current_location.dart';
import 'package:kantin/Component/my_drawer.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
                MySilverAppBar(
                    title: MyTabBar(tabController: _tabController),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Divider(
                          indent: 25,
                          endIndent: 25,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        MyCurrentLocation(),
                        MyDescriptionBox()
                      ],
                    )),
              ],
          body: TabBarView(
            controller: _tabController,
            children: [
              ListView.builder(
                itemBuilder: (context, index) => Text('data'),
                itemCount: 5,
              ),
              ListView.builder(
                itemBuilder: (context, index) => Text('data'),
                itemCount: 5,
              ),
              ListView.builder(
                itemBuilder: (context, index) => Text('data'),
                itemCount: 5,
              ),
            ],
          )),
    );
  }
}
