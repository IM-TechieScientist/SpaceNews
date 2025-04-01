import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NasaImageScreen extends StatefulWidget {
  const NasaImageScreen({super.key});

  @override
  State<NasaImageScreen> createState() => _NasaImageScreenState();
}

class _NasaImageScreenState extends State<NasaImageScreen> {
  Map<String, dynamic>? _apodData;
  bool _isLoading = true;
  bool _hasError = false;
  DateTime? _lastRequestTime;
  static const _minRequestInterval = Duration(seconds: 2);
  static const _cacheKey = 'nasa_apod_cache';
  static const _lastDateKey = 'nasa_apod_last_date';

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);
    final lastDate = prefs.getString(_lastDateKey);
    
    if (cachedData != null && lastDate != null) {
      final lastDateObj = DateTime.parse(lastDate);
      final today = DateTime.now();
      
      // Check if the cached data is from today
      if (lastDateObj.year == today.year && 
          lastDateObj.month == today.month && 
          lastDateObj.day == today.day) {
        setState(() {
          _apodData = json.decode(cachedData);
          _isLoading = false;
        });
        return;
      }
    }
    await _fetchImageOfTheDay();
  }

  Future<void> _saveToCache() async {
    if (_apodData != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(_apodData));
      await prefs.setString(_lastDateKey, DateTime.now().toIso8601String());
    }
  }

  Future<void> _fetchImageOfTheDay() async {
    // Rate limiting protection
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait a moment before refreshing again'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://api.nasa.gov/planetary/apod?api_key=DseycxYuSij12VV4dkOq3QxDAYqTFpdsWC7M5jFr'));

      print('NASA APOD API Response Status: ${response.statusCode}');
      print('NASA APOD API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          return;
        }
        setState(() {
          _apodData = data;
          _isLoading = false;
        });
        _lastRequestTime = DateTime.now();
        await _saveToCache();
      } else if (response.statusCode == 429) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rate limit exceeded. Please wait a few minutes before trying again.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching NASA APOD: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFromCache();
  }

  Widget _buildImageWidget() {
    if (_apodData == null) return const SizedBox.shrink();

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _apodData!['media_type'] == 'image'
              ? Image.network(
                  _apodData!['url'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 300,
                  headers: const {
                    'Accept': 'image/*',
                    'User-Agent': 'Mozilla/5.0',
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Image loading error: $error');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error loading image',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _fetchImageOfTheDay,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[800],
                  child: const Center(
                    child: Text(
                      "Today's APOD is a video. Visit NASA's site to view it.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Text(
              _apodData!['title'] ?? 'No Title',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NASA Image of the Day'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchImageOfTheDay,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Failed to load data. Try again later.',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchImageOfTheDay,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _apodData == null
                  ? const Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _apodData!['title'] ?? 'No Title',
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Date: ${_apodData!['date']}',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                          const SizedBox(height: 16),
                                          if (_apodData!['media_type'] == 'image')
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                _apodData!['url'],
                                                fit: BoxFit.contain,
                                                headers: const {
                                                  'Accept': 'image/*',
                                                  'User-Agent': 'Mozilla/5.0',
                                                },
                                              ),
                                            ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _apodData!['explanation'] ?? 'No Description Available',
                                            style: Theme.of(context).textTheme.bodyLarge,
                                          ),
                                          const SizedBox(height: 16),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: _buildImageWidget(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date: ${_apodData!['date']}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _apodData!['explanation'] ?? 'No Description Available',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
} 