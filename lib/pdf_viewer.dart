import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

class PinchPage extends StatefulWidget {
  const PinchPage({Key? key}) : super(key: key);

  @override
  State<PinchPage> createState() => _PinchPageState();
}

enum DocShown { sample, tutorial, hello, password }

class _PinchPageState extends State<PinchPage> {
  static const int _initialPage = 1;
  late PdfControllerPinch _pdfControllerPinch;
  late PdfDocument pdfDoc;

  @override
  void initState() {
    if (kIsWeb) {
      _pdfControllerPinch = PdfControllerPinch(
        // document: PdfDocument.openAsset('assets/hello.pdf'),
        document: PdfDocument.openData(
          Provider.of<MyFile>(
                NavigationService.navigatorKey.currentContext!,
              ).bytes
              as FutureOr<Uint8List>,
        ),
        initialPage: _initialPage,
      );
    } else {
      _pdfControllerPinch = PdfControllerPinch(
        // document: PdfDocument.openAsset('assets/hello.pdf'),
        document: PdfDocument.openFile(
          Provider.of<MyFile>(
            NavigationService.navigatorKey.currentContext!,
          ).path,
        ),
        initialPage: _initialPage,
      );
    }

    super.initState();
  }

  @override
  void dispose() {
    _pdfControllerPinch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Text(Provider.of<MyFile>(context).path.split('/').last),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: () {
              _pdfControllerPinch.previousPage(
                curve: Curves.ease,
                duration: const Duration(milliseconds: 100),
              );
              Navigator.pushNamed(context, '/');
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
}
