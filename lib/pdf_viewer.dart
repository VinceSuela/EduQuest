import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/widgets/my_button.dart';
import 'package:flutter_pomodoro/widgets/my_dialog.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

class PinchPage extends StatefulWidget {
  const PinchPage({Key? key}) : super(key: key);

  @override
  State<PinchPage> createState() => _PinchPageState();
}

enum DocShown { sample, tutorial, hello, password }

class _PinchPageState extends State<PinchPage> {
  int initialPage = 1;
  late PdfControllerPinch _pdfControllerPinch;
  late Uint8List bytes;
  late Timer timer;

  @override
  void initState() {
    bytes = Provider.of<MyFile>(
      NavigationService.navigatorKey.currentContext!,
    ).bytes;
    timer = Timer(Duration(seconds: 10), () {
      showBreakTime(NavigationService.navigatorKey.currentContext!);
    });
    initialPage = Provider.of<MyFile>(
      NavigationService.navigatorKey.currentContext!,
    ).page;
    if (kIsWeb) {
      _pdfControllerPinch = PdfControllerPinch(
        document: PdfDocument.openData(bytes),
        initialPage: initialPage,
      );
    } else {
      _pdfControllerPinch = PdfControllerPinch(
        document: PdfDocument.openFile(
          Provider.of<MyFile>(
            NavigationService.navigatorKey.currentContext!,
          ).path,
        ),
        initialPage: initialPage,
      );
    }
    _pdfControllerPinch.addListener(() {
      Provider.of<MyFile>(
        NavigationService.navigatorKey.currentContext!,
        listen: false,
      ).setPage(_pdfControllerPinch.page);
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    _pdfControllerPinch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Text(Provider.of<MyFile>(context).name),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: () {
              _pdfControllerPinch.previousPage(
                curve: Curves.ease,
                duration: const Duration(milliseconds: 100),
              );
            },
          ),
          PdfPageNumber(
            controller: _pdfControllerPinch,
            builder: (_, loadingState, page, pagesCount) => Container(
              alignment: Alignment.center,
              child: Text(
                '$page/${pagesCount ?? 0}',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: () {
              _pdfControllerPinch.nextPage(
                curve: Curves.ease,
                duration: const Duration(milliseconds: 100),
              );
            },
          ),
        ],
      ),
      body: PdfViewPinch(
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          pageLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, error) => Center(child: Text(error.toString())),
        ),
        controller: _pdfControllerPinch,
      ),
    );
  }

  Future<String?> showBreakTime(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => MyDialog(
        title: 'Have a break?',
        child: Column(
          children: [
            MyButton(
              label: 'Flappy Bird',
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushReplacementNamed(context, '/flappy');
              },
              isActive: false,
            ),
            MyButton(
              label: 'Snake',
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushReplacementNamed(context, '/snake');
              },
              isActive: false,
            ),
            MyButton(
              label: 'Trex',
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushReplacementNamed(context, '/trex');
              },
              isActive: false,
            ),
          ],
        ),
      ),
    );
  }
}
