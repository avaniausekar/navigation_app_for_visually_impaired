import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart' as tts;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:pdf_text/pdf_text.dart';
import 'homepage.dart';

class ReadDocument extends StatefulWidget {
  @override
  _ReadDocumentState createState() => _ReadDocumentState();
}

class _ReadDocumentState extends State<ReadDocument> {
  PDFDoc? _pdfDoc;
  String _text = "";
  late final tts.FlutterTts _flutterTts;
  bool _buttonsEnabled = true;
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = tts.FlutterTts();
    _speakIntroMessage();
  }

  Future<void> _speakIntroMessage() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setLanguage("en-IN");
    // Modified intro message
    await _flutterTts.speak(
        "You are now on the Read Document page. You can choose a file that I will read for you");

    await Future.delayed(Duration(seconds: 8));
    await _pickPDFText();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.lightBlueAccent,
          title: Text(
            'Read Document',
            style: TextStyle(color: Colors.black, fontSize: 35),
          ),
        ),
        body: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(10),
          child: ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _buttonsEnabled ? _pickPDFText : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(20),
                    backgroundColor: Colors.lightBlueAccent,
                  ),
                  child: Text("Pick PDF document",style: TextStyle(fontSize: 30,color: Colors.black),),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _buttonsEnabled ? _readWholeDoc : () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(20),
                    backgroundColor: Colors.lightBlueAccent,

                  ),
                  child: Text("Read whole document",style: TextStyle(fontSize: 30,color: Colors.black),),
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
              Text(_text, style:TextStyle(fontSize:26)),
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

  Future _pickPDFText() async {
    await _listen();
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

    /*await _flutterTts.speak(text);

    // Ask the user if they want to read another document or return to the homepage
    await _askUser();*/
    await Future.delayed(Duration(seconds:5));
    await _flutterTts.speak("Your file was uploaded");
    await Future.delayed(Duration(seconds:5));
    await _flutterTts.speak("Reciting the document now");
    await Future.delayed(Duration(seconds:5));
    await _flutterTts.speak(text);
      // Ask the user if they want to read another document or return to the homepage
    await Future.delayed(Duration(seconds: 87));
    await _askUser();

  }


  Future<void> _askUser() async {
    await _flutterTts.speak(
        "Do you have another document you want to read or should I take you back to the home page? Say 'yes' to stay on this page.");
    await Future.delayed(Duration(seconds: 10));
    await _listenForUserResponse();
  }

  Future<void> _listenForUserResponse() async {

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
               // Return to the previous screen (homepage)
            }

          }


        },
      );

  }

  void _handleUserResponse(String? response) {

    if (response?.toLowerCase() == 'stay') {
      _speakIntroMessage(); // Repeat intro message if user wants to stay
    } else {
      Navigator.pop(context); // Return to the previous screen (homepage)
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      await _flutterTts.speak("Please speak the name of your file");
      await Future.delayed(Duration(seconds: 4));
      bool available = await _speech.initialize(
        onStatus: (status) {},
        onError: (error) => print('Error: $error'),
      );

      if (available) {
        setState(() {
          _isListening = true;
        });
        print("listen method");
        await _speech.listen(
          onResult: (result) async {
            setState(() {
              _isListening = false; // Stop listening after receiving input
            });
            print(result.recognizedWords);
            await _selectFile(result.recognizedWords);
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

  Future<void> _selectFile(String? fileName) async {
    print("file");
    if (fileName == null) {
      print('No file name provided.');
      return;
    }

    // Assuming the file path is located in the downloads directory
    Directory directory = Directory('/storage/emulated/0/Download');
    List<FileSystemEntity> files = directory.listSync();
    FileSystemEntity? selectedFile = files.firstWhere(
          (file) {
        return file.path.split('/').last.toLowerCase().contains(fileName.toLowerCase());
      },
    );

    if (selectedFile != null) {
      _pdfDoc = await PDFDoc.fromPath(selectedFile.path);
      setState(() {});

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

    _readWholeDoc();
  }
}
