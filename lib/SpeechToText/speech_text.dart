import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
//非同期処理用ライブラリ
import 'dart:async';
//アプリがファイルを保存可能な場所を取得するライブラリ
import 'package:path_provider/path_provider.dart';

//出力するテキストファイル名
final _fileName = 'editTextField.txt';

class SpeechToText extends StatefulWidget {
  @override
  _SpeechToText createState() => _SpeechToText();
}

class _SpeechToText extends State<SpeechToText> {
  String _out = '';
  String lastWords = "　";
  String lastError = '';
  String lastStatus = '';
  stt.SpeechToText speech = stt.SpeechToText();

  bool flug = false;
  late Timer _timer;
  late int _currentSeconds;

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  void initState() {
    super.initState();
    final workMinuts = 0;
    _currentSeconds = workMinuts * 60;

    _timer = countTimer();
  }

  int strcount = 0;

  Timer countTimer() {
    return Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (!flug) {
          timer.cancel();
        } else {
          setState(() {
            _currentSeconds = _currentSeconds + 1;
            strcount = strcount + 1;

            getFilePath().then((File file) {
              file.writeAsString(
                '${strcount}\n${timerString(_currentSeconds)} --> ${timerString(_currentSeconds + 1)}\n${lastWords}\n\n',
                mode: FileMode.append,
              );
            });
          });
        }
      },
    );
  }

  Future<void> _speak() async {
    getFilePath().then((File file) {
      file.writeAsString("");
      //ファイルの初期化
    });

    bool available = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    if (available) {
      flug = true;
      if (!_timer.isActive) {
        setState(() {
          _timer = countTimer();
        });
      }

      speech.listen(
        onResult: resultListener,
        localeId: "Japanese",
      );
    } else {
      print("The user has denied the use of speech recognition.");
    }
  }

  //ファイルの出力処理

  //ファイルの読み込みと変数への格納処理
  void loadButton() async {
    setState(() {
      load().then((String value) {
        setState(() {
          _out = value;
          print(_out);
        });
      });
    });
  }

  Future<void> _stop() async {
    loadButton();

    //タイマーを止める
    if (_timer.isActive) {
      _timer.cancel();
    }

    speech.stop();
  }

  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      lastWords = '${result.recognizedWords}';
    });
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    setState(() {
      lastStatus = '$status';
      print(lastStatus);
    });
  }

  Widget _timeStr() {
    return Text(
      timerString(_currentSeconds),
      // style: TextStyle(fontSize: 32, color: Colors.black),
    );
  }

  String timerString(int leftSeconds) {
    // 00:00:06,000
    final minutes = (leftSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (leftSeconds % 60).floor().toString().padLeft(2, '0');
    return '00:$minutes:${seconds},000';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("speechtotext"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                IconButton(icon: Icon(Icons.add), onPressed: loadButton),
                _timeStr(),
                Text(
                  ' ステータス : ${lastStatus}',
                ),
              ],
            ),
            Text(
              ' 変換文字:${lastWords}',
            ),
          ],
        ),
      ),
      floatingActionButton:
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(onPressed: _speak, child: Icon(Icons.play_arrow)),
        FloatingActionButton(onPressed: _stop, child: Icon(Icons.stop)),
      ]),
    );
  }
}

//テキストファイルを保存するパスを取得する
Future<File> getFilePath() async {
  final directory = await getTemporaryDirectory();

  return File(directory.path + '/' + _fileName);
  // return File(
  //     '/Users/hasegawaitsuki/ghq/github.com/maropook/ffmpeg_flutter_test/assets/subtitle.srt');
}

//テキストファイルの読み込み
Future<String> load() async {
  final file = await getFilePath();
  return file.readAsString();
}
