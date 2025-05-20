import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsArticle {
  final String title;
  final String description;
  final String urlToImage;
  final String url;

  NewsArticle({
    required this.title,
    required this.description,
    required this.urlToImage,
    required this.url,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      urlToImage: json['urlToImage'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class NewsService {
  static const String _apiKey = 'YOUR_NEWS_API_KEY';

  static Future<List<NewsArticle>> fetchWomenNews() async {
    final url = Uri.parse(
      'https://newsapi.org/v2/everything?q=women%20safety&language=en&sortBy=publishedAt&pageSize=5&apiKey=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> articlesJson = jsonData['articles'];
      return articlesJson
          .map((json) => NewsArticle.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load news');
    }
  }
}
