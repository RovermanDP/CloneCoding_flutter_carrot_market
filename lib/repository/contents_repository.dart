import 'dart:convert';

import 'package:http/http.dart' as http;

typedef ContentItem = Map<String, dynamic>;
typedef RegionItem = Map<String, String>;

class ContentsRepository {
  ContentsRepository({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );
  static const String _demoUserId = String.fromEnvironment(
    'DEMO_USER_ID',
    defaultValue: 'demo-user',
  );

  final http.Client _client;
  final String _baseUrl;

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('$_baseUrl$path')
        .replace(queryParameters: queryParameters);
  }

  Map<String, String> _headers({bool includeJson = false}) {
    return <String, String>{
      'x-user-id': _demoUserId,
      if (includeJson) 'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> _getJson(
    String path, [
    Map<String, String>? queryParameters,
  ]) async {
    final http.Response response = await _client.get(
      _buildUri(path, queryParameters),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  ContentItem _mapListing(Map<String, dynamic> raw) {
    final Map<String, dynamic> seller =
        (raw['seller'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final List<dynamic> relatedRaw =
        (raw['relatedListings'] as List<dynamic>?) ?? <dynamic>[];

    return <String, dynamic>{
      'cid': raw['id']?.toString() ?? '',
      'image': raw['imageUrl'] as String? ?? '',
      'title': raw['title'] as String? ?? '',
      'location': raw['location'] as String? ?? '',
      'price': raw['price']?.toString() ?? '',
      'likes': raw['likes']?.toString() ?? '0',
      'description': raw['description'] as String? ?? '',
      'postedHoursAgo': raw['postedHoursAgo'] as int? ?? 0,
      'views': raw['views'] as int? ?? 0,
      'chatCount': raw['chatCount'] as int? ?? 0,
      'interestCount': raw['interestCount'] as int? ?? 0,
      'negotiable': raw['negotiable'] == true,
      'isFavorite': raw['isFavorite'] == true,
      'sellerId': seller['id']?.toString() ?? '',
      'sellerName': seller['name'] as String? ?? '',
      'sellerLocation': seller['regionName'] as String? ?? '',
      'sellerTemp': (seller['mannerTemp'] as num?)?.toDouble() ?? 36.5,
      'sellerProfileImage':
          seller['profileImageUrl'] as String? ?? 'assets/images/user.png',
      'relatedItems': relatedRaw
          .map(
            (dynamic item) => _mapListing(
                Map<String, dynamic>.from(item as Map<dynamic, dynamic>)),
          )
          .toList(),
    };
  }

  Future<List<RegionItem>> loadRegions() async {
    final Map<String, dynamic> json = await _getJson('/api/regions');
    final List<dynamic> regions =
        json['regions'] as List<dynamic>? ?? <dynamic>[];

    return regions.map((dynamic region) {
      final Map<String, dynamic> item =
          Map<String, dynamic>.from(region as Map<dynamic, dynamic>);
      return <String, String>{
        'id': item['id']?.toString() ?? '',
        'name': item['name'] as String? ?? '',
      };
    }).toList();
  }

  Future<List<ContentItem>> loadContentsFromLocation(String location) async {
    final Map<String, dynamic> json =
        await _getJson('/api/listings', <String, String>{
      'region': location,
    });
    final List<dynamic> items = json['items'] as List<dynamic>? ?? <dynamic>[];

    return items
        .map(
          (dynamic item) => _mapListing(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>)),
        )
        .toList();
  }

  Future<ContentItem> loadContentDetail(String id) async {
    final Map<String, dynamic> json = await _getJson('/api/listings/$id');
    return _mapListing(
      Map<String, dynamic>.from(json['item'] as Map<dynamic, dynamic>),
    );
  }

  Future<List<ContentItem>> loadFavoriteContents() async {
    final Map<String, dynamic> json = await _getJson('/api/favorites');
    final List<dynamic> items = json['items'] as List<dynamic>? ?? <dynamic>[];

    return items
        .map(
          (dynamic item) => _mapListing(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>)),
        )
        .toList();
  }

  Future<List<ContentItem>> searchContents(
      String query, String location) async {
    final Map<String, dynamic> json =
        await _getJson('/api/listings', <String, String>{
      'region': location,
      'query': query,
    });
    final List<dynamic> items = json['items'] as List<dynamic>? ?? <dynamic>[];

    return items
        .map(
          (dynamic item) => _mapListing(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>)),
        )
        .toList();
  }

  Future<bool> isMyFavoriteContents(String contentId) async {
    final List<ContentItem> favorites = await loadFavoriteContents();
    return favorites.any((ContentItem item) => item['cid'] == contentId);
  }

  Future<void> addMyFavoriteContent(ContentItem content) async {
    final http.Response response = await _client.post(
      _buildUri('/api/favorites'),
      headers: _headers(includeJson: true),
      body: jsonEncode(<String, dynamic>{'listingId': content['cid']}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to add favorite: ${response.statusCode}');
    }
  }

  Future<void> deleteMyFavoriteContent(String id) async {
    final http.Response response = await _client.delete(
      _buildUri('/api/favorites/$id'),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete favorite: ${response.statusCode}');
    }
  }
}
