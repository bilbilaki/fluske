import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/common/apipath.dart';
import '/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YoutubePlayerMovieTrailer extends StatefulWidget {
  YoutubePlayerMovieTrailer({this.id, this.type, this.url});
  final dynamic id;
  final type;
  final url;
  @override
  _YoutubePlayerMovieTrailerState createState() =>
      _YoutubePlayerMovieTrailerState();
}

class _YoutubePlayerMovieTrailerState extends State<YoutubePlayerMovieTrailer>
    with WidgetsBindingObserver {
  WebViewController? _controller1;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
    super.dispose();
  }

  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        print("1000");
        _controller1?.reload();
        break;
      case AppLifecycleState.paused:
        print("1001");
        _controller1?.reload();
        break;
      case AppLifecycleState.resumed:
        print("1003");
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  static String? convertUrlToId(String url, {bool trimWhitespaces = true}) {
    if (!url.contains("http") && (url.length == 11)) return url;
    if (trimWhitespaces) url = url.trim();

    for (var exp in [
      RegExp(
          r"^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(
          r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(r"^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$")
    ]) {
      Match? match = exp.firstMatch(url);
      if (match != null && match.groupCount >= 1) return match.group(1);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    var userDetails = Provider.of<UserProfileProvider>(context, listen: false)
        .userProfileModel;
    print("url:" +
        APIData.trailerPlayer +
        '${userDetails!.user!.id}/${userDetails.code}/${widget.id}');
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    return new Scaffold(
        body: Stack(
      children: <Widget>[
        Container(
          width: width,
          height: height,
          child: WebView(
            initialUrl: Uri.dataFromString(
              '''
                      <html>
                      <body style="width:100%;height:100%;display:block;background:black;">
                      <iframe width="100%" height="100%"
                      style="width:100%;height:100%;display:block;background:black;"
                      src="https://www.youtube.com/embed/${convertUrlToId(widget.url)}"
                      frameborder="0"
                      allow="accelerometer; autoplay; encrypted-media; gyroscope;"
                       allowfullscreen="allowfullscreen"
                        mozallowfullscreen="mozallowfullscreen"
                        msallowfullscreen="msallowfullscreen"
                        oallowfullscreen="oallowfullscreen"
                        webkitallowfullscreen="webkitallowfullscreen"
                       >
                      </iframe>
                      </body>
                      </html>
                    ''',
              mimeType: 'text/html',
              encoding: Encoding.getByName('utf-8'),
            ).toString(),
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller1 = webViewController;
            },
          ),
        ),
        Positioned(
          top: 26.0,
          left: 4.0,
          child: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                _controller1?.reload();
                Navigator.pop(context);
              }),
        )
      ],
    ));
  }
}
