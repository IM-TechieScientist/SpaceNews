import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_keys.dart';

class MarsImage {
  final String imageUrl;
  final String cameraName;

  MarsImage({
    required this.imageUrl,
    required this.cameraName,
  });

  factory MarsImage.fromJson(Map<String, dynamic> json) {
    return MarsImage(
      imageUrl: json['img_src'] ?? '',
      cameraName: json['camera']['name'] ?? '',
    );
  }
}

class MarsRoverScreen extends StatefulWidget {
  const MarsRoverScreen({super.key});

  @override
  State<MarsRoverScreen> createState() => _MarsRoverScreenState();
}

class _MarsRoverScreenState extends State<MarsRoverScreen> {
  MarsImage? _currentImage;
  List<MarsImage> _images = [];
  bool _isLoading = false;
  String? _error;
  int _currentIndex = 0;

  Future<void> _fetchLatestImages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.https(
        'api.nasa.gov',
        '/mars-photos/api/v1/rovers/perseverance/latest_photos',
        {"api_key": ApiKeys.nasaApiKey},
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['latest_photos'] != null && data['latest_photos'].isNotEmpty) {
          final images = (data['latest_photos'] as List)
              .map((photo) => MarsImage.fromJson(photo))
              .where((image) => [
                    'NAVCAM_LEFT',
                    'NAVCAM_RIGHT',
                    'FRONT_HAZCAM_LEFT_A',
                    'FRONT_HAZCAM_RIGHT_A',
                    'REAR_HAZCAM_LEFT',
                    'REAR_HAZCAM_RIGHT',
                  ].contains(image.cameraName))
              .toList();
          
          if (images.isNotEmpty) {
            setState(() {
              _images = images;
              _currentImage = images[0];
              _currentIndex = 0;
              _isLoading = false;
            });
          } else {
            setState(() {
              _error = 'No images found';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _error = 'No images found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load images (Status: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching Mars Rover images: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _showNextImage() {
    if (_images.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _images.length;
      _currentImage = _images[_currentIndex];
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchLatestImages();
  }

  Widget _buildImageWidget() {
    if (_currentImage == null) return const SizedBox.shrink();

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _currentImage!.imageUrl,
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
                      onPressed: _fetchLatestImages,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Camera: ${_currentImage!.cameraName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Image ${_currentIndex + 1} of ${_images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
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
        title: const Text('Mars Rover Images'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLatestImages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchLatestImages,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _currentImage == null
                  ? const Center(child: Text('No image available'))
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
                                            'Camera: ${_currentImage!.cameraName}',
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Image ${_currentIndex + 1} of ${_images.length}',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                          const SizedBox(height: 16),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              _currentImage!.imageUrl,
                                              fit: BoxFit.contain,
                                              headers: const {
                                                'Accept': 'image/*',
                                                'User-Agent': 'Mozilla/5.0',
                                              },
                                            ),
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
                            child: Center(
                              child: ElevatedButton.icon(
                                onPressed: _showNextImage,
                                icon: const Icon(Icons.arrow_forward,color: Colors.white,),
                                label: const Text('Next Image'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
} 