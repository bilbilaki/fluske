import 'dart:async';
import 'dart:io';
import 'package:chewie/chewie.dart' as chewei;
import 'package:flutter/services.dart';
import 'package:fluske/common/styles.dart';
import 'package:provider/provider.dart';
import 'package:subtitle_wrapper_package/data/models/style/subtitle_position.dart';
import 'package:subtitle_wrapper_package/data/models/style/subtitle_style.dart';
import 'package:subtitle_wrapper_package/subtitle_controller.dart';
import 'package:subtitle_wrapper_package/subtitle_wrapper.dart';
import 'package:video_player/video_player.dart';
import '../common/apipath.dart';
import '../models/Subtitles.dart';
import '../providers/app_config.dart';
import '../providers/user_profile_provider.dart';
import '/common/global.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MyCustomPlayer extends StatefulWidget {
  MyCustomPlayer({
    required this.title,
    required this.url,
    this.downloadStatus,
    required this.subtitles,
  });

  final String title;
  String url;
  final dynamic downloadStatus;
  final Subtitles1? subtitles;

  @override
  State<StatefulWidget> createState() {
    return _MyCustomPlayerState();
  }
}

class _MyCustomPlayerState extends State<MyCustomPlayer>
    with WidgetsBindingObserver {
  TargetPlatform? platform;
  chewei.ChewieController? _betterPlayerController;
  VideoPlayerController? _videoPlayerController;
  SubtitleController? _subtitleController;
  bool _isFullScreen = false;
  var betterPlayerConfiguration;
  DateTime? currentBackPressTime;
  bool _subtitleOn = false;

  dynamic selectedVideoIndex;

  Future<bool> onWillPopS() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Navigator.pop(context);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      return Future.value(true);
    }
    return Future.value(true);
  }

  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        if (_betterPlayerController != null) _betterPlayerController!.pause();
        debugPrint("Inactive");
        break;
      case AppLifecycleState.resumed:
        if (_betterPlayerController != null) _betterPlayerController!.pause();
        break;
      case AppLifecycleState.paused:
        if (_betterPlayerController != null) _betterPlayerController!.pause();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializePlayer();
    WakelockPlus.enable();
    setState(() {
      playerTitle = widget.title;
    });


    String os = Platform.operatingSystem;

    if (os == 'android') {
      setState(() {
        platform = TargetPlatform.android;
      });
    } else {
      setState(() {
        platform = TargetPlatform.iOS;
      });
    }
  }

  @override
  void dispose() {
    _betterPlayerController?.dispose();
    _videoPlayerController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> initializePlayer() async {
    widget.url = widget.url.contains(' ')
        ? widget.url.replaceAll(RegExp(r' '), '%20')
        : widget.url;
    print('Video URL :-> ${widget.url}');

    if (widget.subtitles != null && widget.subtitles!.subtitles!.isNotEmpty) {
      _subtitleController = SubtitleController(
        subtitleType: SubtitleType.srt,
        subtitleUrl: '${APIData.subtitlePlayer}${widget.subtitles!.subtitles![0].subT}',
        showSubtitles: true,
      );
    }


    try {
      // ignore: unused_local_variable
      int _startAt = 0;
      if (await storage.containsKey(key: widget.url)) {
        String? s = await storage.read(key: widget.url);
        if (s != null) {
          _startAt = int.parse(s);
        } else {
          _startAt = 0;
        }
      }

      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoPlayerController!.initialize();
      _betterPlayerController = chewei.ChewieController(
        videoPlayerController: _videoPlayerController!,
        showControls: true,
        showControlsOnInitialize: true,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        materialProgressColors: chewei.ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.redAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white,
        ),
        placeholder: Container(
          color: Colors.black,
        ),
        autoInitialize: true,
        additionalOptions: (context) {
          List<chewei.OptionItem> options = [
            chewei.OptionItem(
                onTap: (context) {
                  setState(() {
                    _subtitleOn = !_subtitleOn;
                  });
                },
                iconData: Icons.subtitles,
                title: 'Subtitles'),
          ];
          var z = widget.subtitles!.subtitles;
          for (int i = 0; i < z!.length; i++) {
            options.add(chewei.OptionItem(
              onTap: (context) {
                print('${APIData.subtitlePlayer}${z[i].subT}');
                _subtitleController!.updateSubtitleUrl(
                    url: '${APIData.subtitlePlayer}${z[i].subT}');
              },
              iconData: Icons.sign_language,
              title: "${z[i].subLang}",
            ));
          }

          return options;
        },
        optionsBuilder: (context, defaultOptions) async {
          await showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext ctx) {
              return Container(
                height: 300,
                decoration: BoxDecoration(color: kDarkBgDark),
                child: ListView.builder(
                  itemCount: defaultOptions.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: Icon(defaultOptions[i].iconData),
                    title: Text(defaultOptions[i].title),
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      defaultOptions[i]
                          .onTap(context); // Execute the selected option's onTap function
                    },
                  ),
                ),
              );
            },
          );
        },
      );

      setState(() {
        WakelockPlus.enable(); // Enable Wakelock when initialized
      });

      _betterPlayerController!.play();

      _betterPlayerController!.videoPlayerController.addListener(
            () {
          if (currentPositionInSec == 0) setState(() {});
          currentPositionInSec = _betterPlayerController!
              .videoPlayerController.value.position.inSeconds;
          print('Position in Seconds : $currentPositionInSec');
        },
      );
    } catch (e) {
      print('Chewei Player Error :-> $e');
    }
  }

  int currentPositionInSec = 0, durationInSec = 0;

  void saveCurrentPosition() {
    durationInSec =
        _betterPlayerController!.videoPlayerController.value.duration.inSeconds;
    print('Duration in Seconds :$durationInSec');
    if (currentPositionInSec == durationInSec) {
      storage.write(key: widget.url, value: '0');
    } else {
      storage.write(key: widget.url, value: '$currentPositionInSec');
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  bool canPop = false;

  @override
  Widget build(BuildContext context) {
    final userDetails = Provider.of<UserProfileProvider>(context, listen: false)
        .userProfileModel!;
    final appconfig = Provider.of<AppConfig>(context, listen: false).appModel;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, context) async {
        canPop = await onWillPopS();
        if (canPop == true) {
          canPop = true;
        }
      },
      child: Scaffold(
        appBar: _isFullScreen
            ? null
            : AppBar(
          backgroundColor: Colors.transparent,
        ),
        backgroundColor: Theme.of(context).primaryColorDark,
        body: Stack(
          children: [
            _betterPlayerController == null
                ? Center(child: CircularProgressIndicator())
                : Center(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Stack(
                      children: [
                        //Video Player
                        Positioned.fill(
                          child: _subtitleController != null
                              ? SubtitleWrapper(
                            videoPlayerController:
                            _betterPlayerController!.videoPlayerController,
                            subtitleController: _subtitleController!,
                            subtitleStyle: SubtitleStyle(
                              position: _isFullScreen
                                  ? SubtitlePosition(bottom: 0, top: constraints.maxHeight * 0.7, left: 0, right: 0)  // Adjust for fullscreen
                                  : SubtitlePosition(bottom: 0, top: 150, left: 0, right: 0), // Adjust values
                              textColor: Colors.white,
                              hasBorder: true,
                            ),
                            videoChild: chewei.Chewie(
                              controller: _betterPlayerController!,
                            ),
                          )
                              : chewei.Chewie(
                            controller: _betterPlayerController!,
                          ),
                        ),
                        //Fullscreen Button
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: IconButton(
                            icon: Icon(
                              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: Colors.white,
                            ),
                            onPressed: _toggleFullScreen,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            //Ads
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if ((userDetails.removeAds == "0" || userDetails.removeAds == 0) &&
                    (appconfig?.appConfig?.removeAds == 0 || appconfig?.appConfig?.removeAds == '0'))
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: FractionalOffset.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: Container(
                          alignment: Alignment.center,
                          //child: adWidget, //TODO
                          //width: _bannerAd!.size.width.toDouble(),
                          //height: _bannerAd!.size.height.toDouble(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}