import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:js' as js;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: HomePage(toggleTheme: _toggleTheme),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const HomePage({super.key, required this.toggleTheme});

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
    imgElement = html.ImageElement()..style.width = '100%';
    html.document.body?.append(imgElement);
  }

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

  void _updateImage() {
    if (_urlController.text.isNotEmpty) {
      String newImageUrl = _urlController.text;
      setState(() {
        imageUrl = null;
      });

      imgElement = html.ImageElement()
        ..src = newImageUrl
        ..onLoad.listen((event) {
          setState(() {
            imageUrl = newImageUrl;
          });
        })
        ..onError.listen((event) {
          print("Failed to load image: $newImageUrl");
        });
    }
  }


  void _toggleMenu() {
    setState(() {
      showMenu = !showMenu;
    });
  }

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
                    child: showMenu ? const Icon(Icons.close, color: Colors.white) : const Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    onPressed: widget.toggleTheme,
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
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
