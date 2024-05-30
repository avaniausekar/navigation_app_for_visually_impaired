import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart' as tts;
import 'api_send_data.dart';
import 'readdocument.dart';
import 'summarizedocument.dart';
import 'notes.dart';
import 'email.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final stt.SpeechToText _speech;
  bool _isListening = false;
  late final tts.FlutterTts _flutterTts;
  var url;
  var Data;

  // Trigger word to activate speech recognition
  final String _triggerWord = 'assistant';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = tts.FlutterTts();
    _initSpeechState();
    _speakIntroMessage();
  }

  Future<void> _initSpeechState() async {
    bool available = await _speech.initialize();
    if (!available) {
      print('Speech recognition not available');
    } else {
      print('Speech recognition initialized successfully');
    }
  }

  Future<void> _speakIntroMessage() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setLanguage("en-IN");


    await _flutterTts.speak(
        "hello, I am your verbal assistant.      I will help you navigate this app through voice commands.   Your options are-    one   reed a document using command     recite document            two       read the summary of a document using command     summary         three        maintain your notes using the command      notes          four   send and have emails read using command       mail     five       to exit the app say          exit");

    // Start listening for commands after speaking intro message
    await Future.delayed(Duration(seconds: 27));
    _toggleListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text(
          "NLP application",
          style: TextStyle(
              color: Colors.black, fontSize: 40),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildButton(context, 'Read Document', () {
                    setState(() => _isListening = false);
                    _speech.stop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReadDocument()),
                    );
                  }),
                  SizedBox(height: 20),
                  buildButton(context, 'Summarize Document', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SummarizeDocument()),
                    );
                  }),
                  SizedBox(height: 20),
                  buildButton(context, 'Notes', () {
                    setState(() => _isListening = false);
                    _speech.stop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Notes()),
                    );
                  }),
                  SizedBox(height: 20),
                  buildButton(context, 'Email', () {
                    setState(() => _isListening = false);
                    _speech.stop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Email()),
                    );
                  }),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _toggleListening,
              tooltip: 'Listen',
              child: Icon(_isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.black),
              backgroundColor: Colors
                  .lightBlueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButton(BuildContext context, String text, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.only(top: 15,bottom: 10), // Adjust the top margin as needed
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.lightBlueAccent.withOpacity(0);
            }
            return Colors.lightBlueAccent;
          }),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.all(0)),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(60),
              side: BorderSide(color: Colors.white, width: 1.0),
            ),
          ),
        ),
        child: Container(
          width: 350,
          height: 200,
          child: Center(
            child: Text(
              text,
              style: TextStyle(fontSize: 34),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToReadDocument() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReadDocument()),
    );
  }

  void _navigateToSummarizeDocument() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SummarizeDocument()),
    );
  }

  void _navigateToNotes() {
    setState(() => _isListening = false);
    _speech.stop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Notes()),
    );
  }

  void _navigateToMail() {
    setState(() => _isListening = false);
    _speech.stop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Email()),
    );
  }
  Future<List<String>> getSynonyms(String word) async {
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/get_synonyms?word=$word'));
    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      List<String> synonyms = List<String>.from(decodedData['synonyms']);
      return synonyms;
    } else {
      throw Exception('Failed to load synonyms');
    }
  }
  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      await _flutterTts.speak("Please speak your command now");

      await Future.delayed(Duration(seconds: 3));
      if (!available) {
        print('Speech recognition not available');
        return;
      }
      setState(() => _isListening = true);
      print("listening");

      List<String> read_syn = await getSynonyms('read');
      List<String> summary_syn = await getSynonyms('summary');
      List<String> note_syn = await getSynonyms('note');
      bool detected=false;
      await _speech.listen(
        onResult: (result) {
          print(result.recognizedWords);
          if (result.finalResult) {
            String recognizedWord = result.recognizedWords.toLowerCase();
            for (String synonym in read_syn) {
            if (recognizedWord.contains(synonym) || recognizedWord.contains('read') || recognizedWord.contains('recite') || recognizedWord.contains('speak')  ) {
              detected=true;
              _navigateToReadDocument();
            }
            } for (String synonym in summary_syn) {
            if (recognizedWord.contains(synonym) || recognizedWord.contains('summary') || recognizedWord.contains('summarize') || recognizedWord.contains('summarise')) {
              detected=true;
              _navigateToSummarizeDocument();
            }
            } for (String synonym in note_syn) {
              if (recognizedWord.contains(synonym) ||
                  recognizedWord.contains('notes') ||
                  recognizedWord.contains('note') ||
                  recognizedWord.contains('nodes')) {
                detected=true;
                _navigateToNotes();
              }
            }
            if (recognizedWord == 'exit') {
              SystemNavigator.pop();
              return;
            }
            if (recognizedWord.contains('mail') ||
                recognizedWord.contains('e mail') ||
                recognizedWord.contains('g mail')) {
              detected=true;
              _navigateToMail();
            }
            if(detected==false){
              _flutterTts.speak("No valid commands were detected. Do you want me to repeat the menu?");

              _startListeningForRepeatMenu();
            }

          }
        },
      );

      if (!_isListening) {
        return;
      }


    } else {
      print("not listening");
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _startListeningForCommands() async {
    await _speech.listen(
      onResult: (result) {
        print(result.recognizedWords);
        if (result.finalResult) {
          String recognizedWord = result.recognizedWords.toLowerCase();
          if (recognizedWord.contains('read') || recognizedWord.contains('recite') || recognizedWord.contains('speak')  ) {
            _navigateToReadDocument();
          } else if (recognizedWord.contains('summary') || recognizedWord.contains('summarize') || recognizedWord.contains('summarise')) {
            _navigateToSummarizeDocument();
          } else if (recognizedWord.contains('notes') || recognizedWord.contains('note') || recognizedWord.contains('nodes')) {
            _navigateToNotes();
          }
        }
      },
    );
  }

  Future<void> _startListeningForRepeatMenu() async {
    print("no valid commands");
    await Future.delayed(Duration(seconds:5));
    await _speech.listen(
      onResult: (result) {
        print(result.recognizedWords);
        if (result.finalResult) {
          String recognizedWord = result.recognizedWords.toLowerCase();
          if (recognizedWord == 'yes') {
            _isListening=false;
            _speakIntroMessage();
          } else if (recognizedWord == 'no') {
            // Do nothing or handle as required
          }
        }
      },
    );
  }
}

