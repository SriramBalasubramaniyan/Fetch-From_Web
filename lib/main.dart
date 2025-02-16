import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:js' as js;
import 'dart:ui_web' as ui;

void main() {
  //Create HTML ImageElement with pre defined size
  final imgElement = html.ImageElement()
    ..style.width = '300px'
    ..style.height = '300px';

  // set ImageElement as platform view for flutter
  ui.platformViewRegistry.registerViewFactory('image_element', (int viewId) {
    return imgElement;
  });

  // run MyApp and pass imgElement as parameter
  runApp(MyApp(imgElement: imgElement));
}

class MyApp extends StatefulWidget {
  final html.ImageElement imgElement;

  const MyApp({super.key, required this.imgElement});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  // Function to Toggle between light and dark mode.
  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: HomePage(
        toggleTheme: _toggleTheme, // Pass Theme Controller
        imgElement: widget.imgElement, // Pass imgElement to HomePage
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;  // Receive Theme Controller
  final html.ImageElement imgElement; // Receive imgElement

  const HomePage(
      {super.key, required this.toggleTheme, required this.imgElement});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  String? imageUrl;
  late html.ImageElement imgElement;
  bool showMenu = false;

  @override
  void initState() {
    super.initState();
    imgElement = html.ImageElement()..style.width = '100%'; // set imgElement width to 100% of the image
    html.document.body?.append(imgElement); // append image to HTML body
  }

  // JavaScript function to toggle full screen.
  void _toggleFullscreenJS() {
    js.context.callMethod('eval', [
      """
      if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen();
      } else {
        document.exitFullscreen();
      }
    """
    ]);
  }

  // Update the image based on the given URL
  Future<void> _updateImage() async {
    if (_urlController.text.isNotEmpty) {
      String newImageUrl = _urlController.text;

      setState(() {
        widget.imgElement.src = newImageUrl; //set imgElement source to given URL
        imageUrl = newImageUrl;
      });

      // listen to image load
      widget.imgElement.onLoad.listen((event) {
        print("Image loaded successfully: $newImageUrl");
      });

      // listen to image error
      widget.imgElement.onError.listen((event) {
        print("Failed to load image: $newImageUrl");
      });
    }
  }

  // toggle menu visibility
  void _toggleMenu() {
    setState(() {
      showMenu = !showMenu;
    });
  }

  // close floating menu if opened
  void _closeMenu() {
    if (showMenu) {
      setState(() {
        showMenu = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeMenu,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null)
                GestureDetector(
                  onDoubleTap: _toggleFullscreenJS,
                  child: const SizedBox(
                    height: 300,
                    width: 300,
                    child: HtmlElementView(viewType: 'image_element'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        hintText: 'Enter Image URL',
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _updateImage(),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _updateImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Submit"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Stack(
          children: [
            if (showMenu)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMenu,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showMenu) ...[
                    _fullscreenButton(),
                    const SizedBox(height: 8),
                  ],
                  FloatingActionButton(
                    onPressed: _toggleMenu,
                    backgroundColor: showMenu ? Colors.red : Colors.green,
                    child: showMenu
                        ? const Icon(Icons.close, color: Colors.white)
                        : const Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    onPressed: widget.toggleTheme,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                    child: Icon(
                      Theme.of(context).brightness == Brightness.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to create full screen toggle button
  Widget _fullscreenButton() {
    bool isFullscreen = html.document.fullscreenElement != null;
    return ElevatedButton(
      onPressed: () {
        _toggleFullscreenJS();
        _closeMenu();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(isFullscreen ? "Exit Fullscreen" : "Enter Fullscreen"),
    );
  }
}
