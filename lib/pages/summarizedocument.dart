import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:pdf_text/pdf_text.dart';
import 'api_send_data.dart';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart' as tts;
import 'homepage.dart';

void main() {runApp(SummarizeDocument());}
class SummarizeDocument extends StatefulWidget {
  @override
  _SummarizeDocumentState createState() => _SummarizeDocumentState();
}
enum TtsState { playing, stopped, paused, continued }
class _SummarizeDocumentState extends State<SummarizeDocument> {
  PDFDoc? _pdfDoc;
  String _text = "";
  var url;
  var Data;
  String QueryText = 'Query';
  late final tts.FlutterTts _flutterTts;

  bool _buttonsEnabled = true;
  stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  //late final VoidCallback? _send_data;
  String? _newVoiceText;
  int? _inputLength;

  TtsState ttsState = TtsState.stopped;

  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;
  bool get isPaused => ttsState == TtsState.paused;
  bool get isContinued => ttsState == TtsState.continued;
  @override
  void initState() {
    super.initState();
    initTts();
    //_speakIntroMessage();
  }
  dynamic initTts() {
    _flutterTts = tts.FlutterTts();

    _setAwaitOptions();
    _flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    _flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    _flutterTts.setPauseHandler(() {
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    });

    _flutterTts.setContinueHandler(() {
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
    _speakIntroMessage();
  }
  Future<void> _speakIntroMessage() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setLanguage("en-IN");

    var result = await _flutterTts.speak("You are now on the Summarize Document page. Say out the name of the pdf you want to summarize.");
    //await _flutterTts.speak("You are now on the Summarize Document page.");
    //await Future.delayed(Duration(seconds: 8));
    if (result == 1) setState(() => ttsState = TtsState.playing);
    bool isSpeechPlaying = true;
    _flutterTts.setCompletionHandler(() {
      if (isSpeechPlaying) {
        _pickPDFText();
        isSpeechPlaying = false;
      }
    });
    //_flutterTts.completionHandler!();
    //await Future.delayed(Duration(seconds: 8));
    //await _setAwaitOptions();
    //_pickPDFText();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.lightBlueAccent,
          title: Text(
            'Summarize Document',
            style: TextStyle(color: Colors.black,fontSize: 35),
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(10),
          child: ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  child: Text(
                    "Pick PDF document",
                    style: TextStyle(fontSize: 30,color: Colors.black),
                  ),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.all(5),
                      backgroundColor: Colors.lightBlueAccent),
                  onPressed: _buttonsEnabled ? _pickPDFText : null,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  child: Text(
                    "Read whole document",
                    style: TextStyle(fontSize: 30,color: Colors.black),
                  ),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.all(5),
                      backgroundColor: Colors.lightBlueAccent),
                  onPressed: _buttonsEnabled ? _readWholeDoc : () {},

                ),
              ),

              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  _pdfDoc == null
                      ? "Pick a new PDF document and wait for it to load..."
                      : "PDF document loaded, ${_pdfDoc!.length} pages\n",
                  style: TextStyle(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: SingleChildScrollView(
                  child: Text(
                    _text == "" ? "" : "Text:",
                    style: TextStyle(fontSize: 26),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),


              //Text(_text),
              Text(QueryText, style: TextStyle(fontSize: 26))


            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _listen,
          child: Icon(_isListening ? Icons.mic_off : Icons.mic),
        ),
      ),
    );
  }

  Future<void> _setAwaitOptions() async {
    await _flutterTts.awaitSpeakCompletion(true);
  }

  Future _pickPDFText() async {
    _listen();
  }

  Future _readWholeDoc() async {
    if (_pdfDoc == null) {
      return;
    }
    setState(() {
      _buttonsEnabled = false;
    });

    String text = await _pdfDoc!.text;

    setState(() {
      _text = text;
      _buttonsEnabled = true;
    });

    // send data code
    String value=_text;
    url = Uri.parse('http://10.0.2.2:5000/api?Query=$value');
    print("fetching data");
    Data = await Getdata(url);
    var DecodedData = jsonDecode(Data);
    QueryText = DecodedData;
    var res = _flutterTts.speak(QueryText);
    //if (res == 1) setState(() => ttsState = TtsState.playing);
    //_flutterTts.completionHandler!();
    //await Future.delayed(Duration(seconds: 44));

    //_askUser();
    if (res == 1) {
      setState(() => ttsState = TtsState.playing);}
    bool isSpeechPlaying = true;
    _flutterTts.setCompletionHandler(() {
      if (isSpeechPlaying) {
        _askUser();
        isSpeechPlaying = false;
      }
    });

  }
  Future<void> _askUser() async {
    await _flutterTts.speak(
        "Do you have another document you want to read or should I take you back to the home page? Say 'yes' to stay on this page.");
    await Future.delayed(Duration(seconds: 10));
    _listenForUserResponse();
  }

  void _listenForUserResponse() async {
    bool available = await _speech.initialize(
      onStatus: (status) {},
      onError: (error) => print('Error: $error'),
    );

    if (available) {
      setState(() {
        _isListening = true;
      });
      print("listen method");
      _speech.listen(
        onResult: (result) {
          print(result.recognizedWords);
          if (result.finalResult) {
            String recognizedWord = result.recognizedWords.toLowerCase();
            if (recognizedWord.toLowerCase() == 'yes') {
              _speakIntroMessage(); // Repeat intro message if user wants to stay
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyHomePage(title: "NLP application")),
              );
              //Navigator.pop(context); // Return to the previous screen (homepage)
            }

          }


        },
      );
    } else {
      print('The user has denied the use of speech recognition.');
    }
  }
// listens on pushing the button
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {},
        onError: (error) => print('Error: $error'),
      );

      if (available) {
        setState(() {
          _isListening = true;
        });

        _speech.listen(
          onResult: (result) {
            setState(() {
              _isListening = false; // Stop listening after receiving input
            });
            _selectFile(result.recognizedWords);
          },
        );
      } else {
        print('The user has denied the use of speech recognition.');
      }
    } else {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
    }
  }

//selects the file after listening with extenstion
  void _selectFile(String? fileName) async {
    if (fileName == null) {
      print('No file name provided.');
      return;
    }

    // Assuming the file path is located in the downloads directory
    Directory directory = Directory('/storage/emulated/0/Download');
    List<FileSystemEntity> files = directory.listSync();
    FileSystemEntity? selectedFile = files.firstWhere(
          (file) {
        return file.path
            .split('/')
            .last
            .toLowerCase()
            .contains(fileName.toLowerCase());
      },
    );

    if (selectedFile != null) {
      _pdfDoc = await PDFDoc.fromPath(selectedFile.path);
      setState(() {});
      //here
      _readWholeDoc();
    } else {
      print('File not found: $fileName');
      // Show a message or perform any action here
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('File Not Found'),
            content: Text('File not found: $fileName'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}





