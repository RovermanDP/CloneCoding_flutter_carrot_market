import 'package:flutter/material.dart';
import 'package:flutter_carrot_market/pages/detail.dart';
import 'package:flutter_carrot_market/repository/contents_repository.dart';
import 'package:flutter_carrot_market/utils/data_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyFavoriteContents extends StatefulWidget {
  const MyFavoriteContents({super.key});

  @override
  State<MyFavoriteContents> createState() => _MyFavoriteContentsState();
}

class _MyFavoriteContentsState extends State<MyFavoriteContents> {
  final ContentsRepository contentsRepository = ContentsRepository();

  Future<List<ContentItem>> _loadMyFavoriteContentList() async {
    return contentsRepository.loadFavoriteContents();
  }

  PreferredSizeWidget _appBarWidget() {
    return AppBar(
      elevation: 0,
      title: const Text(
        'Favorites',
        style: TextStyle(fontSize: 15),
      ),
      centerTitle: false,
    );
  }

  Widget _makeDataList(List<ContentItem> datas) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: datas.length,
      itemBuilder: (BuildContext context, int index) {
        final ContentItem data = datas[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 7),
          child: GestureDetector(
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
              padding: const EdgeInsets.all(10),
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
                                  'assets/svg/heart_on.svg',
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
          ),
        );
      },
    );
  }

  Widget _bodyWidget() {
    return FutureBuilder<List<ContentItem>>(
      future: _loadMyFavoriteContentList(),
      builder:
          (BuildContext context, AsyncSnapshot<List<ContentItem>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load favorites.'));
        }

        final List<ContentItem> items = snapshot.data ?? <ContentItem>[];
        if (items.isEmpty) {
          return const Center(child: Text('No favorites yet.'));
        }

        return _makeDataList(items);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBarWidget(),
      body: _bodyWidget(),
      backgroundColor: Colors.grey.withValues(alpha: 0.05),
    );
  }
}
