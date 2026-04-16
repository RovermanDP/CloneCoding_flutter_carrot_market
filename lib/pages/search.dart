import 'package:flutter/material.dart';
import 'package:flutter_carrot_market/repository/contents_repository.dart';
import 'package:flutter_carrot_market/utils/data_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'detail.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.location});

  final String location;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ContentsRepository contentsRepository = ContentsRepository();
  final TextEditingController _controller = TextEditingController();
  String _submittedQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PreferredSizeWidget _appBarWidget() {
    return AppBar(
      elevation: 1,
      title: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Search items...',
          border: InputBorder.none,
        ),
        onSubmitted: (String value) {
          final String trimmed = value.trim();
          if (trimmed.isNotEmpty) {
            setState(() {
              _submittedQuery = trimmed;
            });
          }
        },
      ),
    );
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
    if (_submittedQuery.isEmpty) {
      return const Center(
        child: Text(
          'Enter a keyword to search.',
          style: TextStyle(fontSize: 14, color: Color(0xff999999)),
        ),
      );
    }

    return FutureBuilder<List<ContentItem>>(
      future: contentsRepository.searchContents(
          _submittedQuery, widget.location),
      builder:
          (BuildContext context, AsyncSnapshot<List<ContentItem>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load search results.'));
        }

        final List<ContentItem> items = snapshot.data ?? <ContentItem>[];
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No results found.',
              style: TextStyle(fontSize: 14, color: Color(0xff999999)),
            ),
          );
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
    );
  }
}
