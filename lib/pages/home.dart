import 'package:flutter/material.dart';
import 'package:flutter_carrot_market/repository/contents_repository.dart';
import 'package:flutter_carrot_market/utils/data_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'detail.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final ContentsRepository contentsRepository = ContentsRepository();
  String currentLocation = 'ara';
  List<RegionItem> regions = const <RegionItem>[];

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      final List<RegionItem> loadedRegions =
          await contentsRepository.loadRegions();
      if (!mounted) {
        return;
      }

      setState(() {
        regions = loadedRegions;
        if (regions.isNotEmpty &&
            !regions.any((RegionItem item) => item['id'] == currentLocation)) {
          currentLocation = regions.first['id']!;
        }
      });
    } catch (_) {
      // Keep the current fallback UI if region loading fails.
    }
  }

  String get _currentRegionName {
    for (final RegionItem region in regions) {
      if (region['id'] == currentLocation) {
        return region['name'] ?? currentLocation;
      }
    }
    return currentLocation;
  }

  PreferredSizeWidget _appbarWidget() {
    return AppBar(
      title: PopupMenuButton<String>(
        offset: const Offset(0, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_currentRegionName),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
        onSelected: (String value) {
          setState(() {
            currentLocation = value;
          });
        },
        itemBuilder: (BuildContext context) {
          final List<RegionItem> menuRegions = regions.isEmpty
              ? <RegionItem>[
                  <String, String>{'id': 'ara', 'name': 'Ara-dong'},
                  <String, String>{'id': 'ora', 'name': 'Ora-dong'},
                ]
              : regions;

          return menuRegions
              .map(
                (RegionItem region) => PopupMenuItem<String>(
                  value: region['id'],
                  child: Text(region['name'] ?? ''),
                ),
              )
              .toList();
        },
      ),
      elevation: 1,
      actions: <Widget>[
        IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
        IconButton(
          onPressed: () {},
          icon: SvgPicture.asset(
            'assets/svg/bell.svg',
            width: 22,
          ),
        ),
      ],
    );
  }

  Future<List<ContentItem>> _loadContents() async {
    return contentsRepository.loadContentsFromLocation(currentLocation);
  }

  Widget _makeDataList(List<ContentItem> datas) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      physics: const ClampingScrollPhysics(),
      itemCount: datas.length,
      itemBuilder: (BuildContext context, int index) {
        final ContentItem data = datas[index];

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => DetailContentView(data: data),
              ),
            );
            if (mounted) {
              setState(() {});
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  child: Hero(
                    tag: data['cid']!,
                    child: Image.asset(
                      data['image']!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 100,
                    padding: const EdgeInsets.only(left: 20, top: 2),
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          data['title']!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          data['location']!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff999999),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          DataUtils.calcStringToWon(data['price']!),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              SvgPicture.asset(
                                data['isFavorite'] == true
                                    ? 'assets/svg/heart_on.svg'
                                    : 'assets/svg/heart_off.svg',
                                width: 13,
                                height: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(data['likes']!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Container(
          height: 1,
          color: Colors.black.withValues(alpha: 0.1),
        );
      },
    );
  }

  Widget _bodyWidget() {
    return FutureBuilder<List<ContentItem>>(
      future: _loadContents(),
      builder:
          (BuildContext context, AsyncSnapshot<List<ContentItem>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load items.'));
        }

        final List<ContentItem> items = snapshot.data ?? <ContentItem>[];
        if (items.isEmpty) {
          return const Center(child: Text('No items found for this area.'));
        }

        return _makeDataList(items);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appbarWidget(),
      body: _bodyWidget(),
    );
  }
}
