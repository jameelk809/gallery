import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

void main() => runApp(GalleryApp());

class GalleryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gallery App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: GalleryHomePage(),
    );
  }
}

class GalleryHomePage extends StatefulWidget {
  @override
  _GalleryHomePageState createState() => _GalleryHomePageState();
}

class _GalleryHomePageState extends State<GalleryHomePage> {
  final List<File> _photos = [];
  List<String> _imageLabels = [];

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _photos.add(imageFile);
      // Detect image labels for the captured image
      _getImageLabels(imageFile);
    }
  }

  void _viewPhoto(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewPage(
          photos: _photos,
          imageLabels: _imageLabels,
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _getImageLabels(File image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    ImageLabeler imageLabeler =
    ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.75));
    // ImageLabeler imageLabeler =
    // ImageLabeler(imageLabelerOptions: ImageLabelerOptions(confidenceThreshold: 0.75));
    List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    List<String> imageLabels = [];
    for (ImageLabel imgLabel in labels) {
      String lblText = imgLabel.label;
      double confidence = imgLabel.confidence;
      String label = '$lblText : ${(confidence * 100).toStringAsFixed(2)}%';
      imageLabels.add(label);
    }
    imageLabeler.close();
    setState(() {
      _imageLabels = imageLabels;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _viewPhoto(index),
            child: Stack(
              children: [
                Image.file(
                  _photos[index],
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Text(
                    _imageLabels.length > index ? _imageLabels[index] : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePhoto,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class PhotoViewPage extends StatefulWidget {
  final List<File> photos;
  final List<String> imageLabels;
  final int initialIndex;

  PhotoViewPage({required this.photos, required this.imageLabels, required this.initialIndex});

  @override
  _PhotoViewPageState createState() => _PhotoViewPageState();
}

class _PhotoViewPageState extends State<PhotoViewPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo View'),
      ),
      body: Container(
        child: PhotoViewGallery.builder(
          itemCount: widget.photos.length,
          pageController: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: FileImage(widget.photos[index]),
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(tag: index),
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 1.8,
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Container(
          color: Colors.black.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                widget.imageLabels.length > _currentIndex ? widget.imageLabels[_currentIndex] : '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

