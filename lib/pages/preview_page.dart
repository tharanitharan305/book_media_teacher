import 'package:flutter/material.dart';
import '../models/page_model.dart';
import '../widgets/canvas/a4_canvas.dart';

class PreviewPage extends StatefulWidget {
  final List<PageModel> pages;
  final VoidCallback onExport;

  const PreviewPage({super.key, required this.pages, required this.onExport});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) {
      return Scaffold(body: Center(child: Text("No pages to preview")));
    }

    final currentPage = widget.pages[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          "Book Preview",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: OutlinedButton.icon(
              onPressed: widget.onExport,
              icon: Icon(Icons.download, size: 16),
              label: Text("Export JSON"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side:  BorderSide(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon:  Icon(Icons.arrow_back_ios, size: 32),
              onPressed: _currentIndex > 0
                  ? () => setState(() => _currentIndex--)
                  : null,
              color: _currentIndex > 0 ? Colors.black87 : Colors.black12,
            ),
             SizedBox(width: 20),
            Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRect(
                // REMOVED AbsorbPointer to allow audio/video controls to work
                child: A4Canvas(
                  page: currentPage,
                  // No callbacks provided means no editing capabilities
                ),
              ),
            ),

             SizedBox(width: 20),

            // Next Button
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, size: 32),
              onPressed: _currentIndex < widget.pages.length - 1
                  ? () => setState(() => _currentIndex++)
                  : null,
              color: _currentIndex < widget.pages.length - 1
                  ? Colors.black87
                  : Colors.black12,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding:  EdgeInsets.all(16),
        color: Colors.white,
        child: Text(
          "Page ${_currentIndex + 1} of ${widget.pages.length}",
          textAlign: TextAlign.center,
          style:  TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
