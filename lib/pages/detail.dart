import 'package:flutter/material.dart';
import 'package:flutter_carrot_market/components/manor_temperature_widget.dart';
import 'package:flutter_carrot_market/repository/contents_repository.dart';
import 'package:flutter_carrot_market/utils/data_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DetailContentView extends StatefulWidget {
  const DetailContentView({
    super.key,
    required this.data,
  });

  final ContentItem data;

  @override
  State<DetailContentView> createState() => _DetailContentViewState();
}

class _DetailContentViewState extends State<DetailContentView>
    with TickerProviderStateMixin {
  final ContentsRepository contentsRepository = ContentsRepository();
  late ContentItem currentItem;
  late Size size;
  late List<String> imgList;
  int _current = 0;
  final PageController _pageController = PageController();
  final ScrollController controller = ScrollController();
  double locationAlpha = 0;
  late AnimationController _animationController;
  late Animation<Color?> _colorTween;
  bool isMyFavoriteContent = false;
  bool isLoadingDetail = true;
  String? detailError;

  @override
  void initState() {
    super.initState();
    currentItem = Map<String, dynamic>.from(widget.data);
    isMyFavoriteContent = currentItem['isFavorite'] == true;
    imgList = List<String>.filled(5, currentItem['image'] as String? ?? '');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _colorTween = ColorTween(begin: Colors.white, end: Colors.black)
        .animate(_animationController);

    _loadContentDetail();
    controller.addListener(() {
      setState(() {
        locationAlpha = controller.offset.clamp(0, 255).toDouble();
        _animationController.value = locationAlpha / 255;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    size = MediaQuery.of(context).size;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadContentDetail() async {
    try {
      final ContentItem loadedItem = await contentsRepository.loadContentDetail(
        currentItem['cid'] as String,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        currentItem = loadedItem;
        isMyFavoriteContent = loadedItem['isFavorite'] == true;
        imgList = List<String>.filled(5, loadedItem['image'] as String? ?? '');
        isLoadingDetail = false;
        detailError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingDetail = false;
        detailError = 'Failed to load item details.';
      });
    }
  }

  Widget _makeIcon(IconData icon) {
    return AnimatedBuilder(
      animation: _colorTween,
      builder: (BuildContext context, Widget? child) {
        return Icon(icon, color: _colorTween.value);
      },
    );
  }

  PreferredSizeWidget _appbarWidget() {
    return AppBar(
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: _makeIcon(Icons.arrow_back),
      ),
      backgroundColor: Colors.white.withAlpha(locationAlpha.toInt()),
      elevation: 0,
      actions: <Widget>[
        IconButton(onPressed: () {}, icon: _makeIcon(Icons.share)),
        IconButton(onPressed: () {}, icon: _makeIcon(Icons.more_vert)),
      ],
    );
  }

  Widget _makeSliderImage() {
    return SizedBox(
      height: size.width * 0.8,
      child: Stack(
        children: <Widget>[
          Hero(
            tag: currentItem['cid'] as String? ?? '',
            child: PageView(
              controller: _pageController,
              onPageChanged: (int index) {
                setState(() {
                  _current = index;
                });
              },
              children: imgList.map((String imagePath) {
                return Image.asset(
                  imagePath,
                  width: size.width,
                  height: size.width,
                  fit: BoxFit.cover,
                );
              }).toList(),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(imgList.length, (int index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 5,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _current == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sellerSimpleInfo() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage(
              currentItem['sellerProfileImage'] as String? ??
                  'assets/images/user.png',
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                currentItem['sellerName'] as String? ?? 'Seller',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(currentItem['sellerLocation'] as String? ?? ''),
            ],
          ),
          Expanded(
            child: ManorTemperature(
              manorTemp:
                  (currentItem['sellerTemp'] as num?)?.toDouble() ?? 36.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _line() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }

  Widget _contentDetail() {
    final int postedHoursAgo = currentItem['postedHoursAgo'] as int? ?? 0;
    final int chatCount = currentItem['chatCount'] as int? ?? 0;
    final int interestCount = currentItem['interestCount'] as int? ?? 0;
    final int views = currentItem['views'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 20),
          Text(
            currentItem['title'] as String? ?? '',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Posted $postedHoursAgo hours ago',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          Text(
            currentItem['description'] as String? ?? '',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 15),
          Text(
            'Chat $chatCount  Interest $interestCount  Views $views',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (detailError != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              detailError!,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _otherCellContents() {
    return const Padding(
      padding: EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            'More from this seller',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            'See all',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _relatedContentsGrid() {
    final List<ContentItem> relatedItems =
        (currentItem['relatedItems'] as List<dynamic>? ?? <dynamic>[])
            .map(
              (dynamic item) =>
                  Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            )
            .toList();

    if (relatedItems.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final ContentItem item = relatedItems[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => DetailContentView(data: item),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      item['image'] as String? ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'] as String? ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  DataUtils.calcStringToWon(item['price'] as String? ?? ''),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }, childCount: relatedItems.length),
      ),
    );
  }

  Widget _bodyWidget() {
    return CustomScrollView(
      controller: controller,
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildListDelegate(
            <Widget>[
              _makeSliderImage(),
              _sellerSimpleInfo(),
              _line(),
              _contentDetail(),
              _line(),
              _otherCellContents(),
              if (isLoadingDetail)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
        _relatedContentsGrid(),
      ],
    );
  }

  Widget _bottomBarWidget() {
    final bool negotiable = currentItem['negotiable'] == true;

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: 55,
      color: Colors.white,
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () async {
              try {
                if (isMyFavoriteContent) {
                  await contentsRepository.deleteMyFavoriteContent(
                    currentItem['cid'] as String,
                  );
                } else {
                  await contentsRepository.addMyFavoriteContent(currentItem);
                }

                if (!mounted) {
                  return;
                }

                setState(() {
                  isMyFavoriteContent = !isMyFavoriteContent;
                  currentItem['isFavorite'] = isMyFavoriteContent;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 1000),
                    content: Text(
                      isMyFavoriteContent
                          ? 'Added to favorites.'
                          : 'Removed from favorites.',
                    ),
                  ),
                );
              } catch (_) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    duration: Duration(milliseconds: 1000),
                    content: Text('Failed to update favorite.'),
                  ),
                );
              }
            },
            child: SvgPicture.asset(
              isMyFavoriteContent
                  ? 'assets/svg/heart_on.svg'
                  : 'assets/svg/heart_off.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xfff08f4f),
                BlendMode.srcIn,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 15, right: 10),
            height: 40,
            width: 1,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                DataUtils.calcStringToWon(
                    currentItem['price'] as String? ?? ''),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                negotiable ? 'Price is negotiable' : 'Fixed price',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: const Color(0xfff08f4f),
                  ),
                  child: const Text(
                    'Chat',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _appbarWidget(),
      body: _bodyWidget(),
      bottomNavigationBar: _bottomBarWidget(),
    );
  }
}
