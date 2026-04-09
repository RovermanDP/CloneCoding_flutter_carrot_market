import 'package:flutter/material.dart';
import 'package:flutter_carrot_market/pages/favorite.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'home.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentPageIndex = 0;

  Widget _bottomNavigationWidget() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentPageIndex,
      onTap: (int index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      selectedItemColor: Colors.black,
      items: <BottomNavigationBarItem>[
        _bottomNavigationBarItem('home', 'Home'),
        _bottomNavigationBarItem('notes', 'Local Life'),
        _bottomNavigationBarItem('location', 'Nearby'),
        _bottomNavigationBarItem('chat', 'Chat'),
        _bottomNavigationBarItem('user', 'My Carrot'),
      ],
    );
  }

  BottomNavigationBarItem _bottomNavigationBarItem(
      String iconName, String name) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        'assets/svg/${iconName}_off.svg',
        width: 22,
      ),
      activeIcon: SvgPicture.asset(
        'assets/svg/${iconName}_on.svg',
        width: 22,
      ),
      label: name,
    );
  }

  Widget _bodyWidget() {
    switch (_currentPageIndex) {
      case 0:
        return const Home();
      case 4:
        return const MyFavoriteContents();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _bodyWidget(),
      bottomNavigationBar: _bottomNavigationWidget(),
    );
  }
}
