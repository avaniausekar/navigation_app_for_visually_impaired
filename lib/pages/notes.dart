import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'homepage.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';

void main() {
    runApp(NoteApp());
}

class NoteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Notes(),
    );
  }
}

class Notes extends StatefulWidget {
  const Notes({Key? key});
  @override
  _NoteState createState() => _NoteState();
}

enum TtsState { playing, stopped, paused, continued }

class _NoteState extends State<Notes> {
  final TextEditingController _noteController = TextEditingController();
  final List<String> _notes = [];
  final SpeechToText _speechToText = SpeechToText();
  late FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  bool _speechEnabled = false;
  String _lastWords = '';
  bool isDone=false;

  
  static bool isListening=false;


  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;
  bool get isPaused => ttsState == TtsState.paused;
  bool get isContinued => ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await initTts();
    await _loadNotes();
    await _speakInstructions();
  }

  dynamic initTts() {
    flutterTts = FlutterTts();
    flutterTts.getMaxSpeechInputLength;
     flutterTts.setVolume(1.0);
     flutterTts.setSpeechRate(0.4);
     flutterTts.setPitch(1.0);
     flutterTts.setLanguage("en-IN");
    
    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }


  Future<void> _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
     // print(engine);
    }
  }

  Future<void> _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
     // print(voice);
    }
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future<void> _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  Future<void> _speakInstructions() async {
    String text =
        "You are on the notes page. To add a note use command add note and to read the notes use command read note.";
    await _saySpeech(text);
   // await Future.delayed(Duration(seconds: 5));
    await _initSpeech();

   // await Future.delayed(Duration(seconds: 5));
    await _chooseOption();
  }

  Future<void> _saySpeech(String text) async {
    await flutterTts.setSpeechRate(0.4);
    var result = await flutterTts.speak(text);
    if (result == 1) {
      setState(() => ttsState = TtsState.playing);
    }
    bool isSpeechPlaying = true;
    flutterTts.setCompletionHandler(() {
      if (isSpeechPlaying) {
        isSpeechPlaying = false;
      }
    });
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

   Future<void> _startListening() async {
    
    if(!isListening){
    isListening=true;
     
    await Future.delayed(Duration(seconds: 5)); //required 25
    _saySpeech("say your command now");
    await Future.delayed(Duration(seconds: 5));
    print("App is start listening.");
     _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: Duration(seconds: 15),
    );
     Future.delayed(Duration(seconds: 5)); //required

    setState(() {
      isListening=false;
    });
    }
   
  }

  Future<void> _onSpeechResult(SpeechRecognitionResult result) async {
    setState(() {
      _lastWords = result.recognizedWords;
    });
    print("Last words: " + _lastWords);
  }

  Future<void> _chooseOption() async {
    await Future.delayed(Duration(seconds: 5));

    await _startListening();
    await Future.delayed(Duration(seconds: 5)); //required
    print("App is deciding.");
    print("Last words: " + _lastWords);
    if(_lastWords!=""){
    if (_lastWords.contains("add") ||
        _lastWords.contains("create") ||
        _lastWords.contains("write") ||
        _lastWords.contains("right")) {
      await _saySpeech("Okay. Please say out the content you want to note down.");
      await _addNote();
    //  Future.delayed(Duration(seconds: 15));
      await _askUser();
      isDone=true;
    } else if (_lastWords.contains("read") ||
        _lastWords.contains("recite") ||
        _lastWords.contains("speak")) {
      await _saySpeech("Okay. I am reading out contents of all notes for you.");
      await _readNotes();
   //   Future.delayed(Duration(seconds: 15));
      await _askUser();
      isDone=true;
    } else {
      await _saySpeech("No valid commands were detected. Do you want me to repeat the menu? Say yes or no");
      await Future.delayed(Duration(seconds: 15));
      await _startListeningForRepeatMenu();
    }
    }
   // await _speakInstructions(); //not required
  }

  Future<void> _startListeningForRepeatMenu() async {
    if(isDone){
      isListening=false;
    await Future.delayed(Duration(seconds: 5));
    await _saySpeech("say your command now");
    await Future.delayed(Duration(seconds: 5));
    print("App is menu listening.");
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: Duration(seconds: 15), // Listen for 60 seconds
    );
    await Future.delayed(Duration(seconds: 10));
    if (_lastWords.toLowerCase().contains("yes")) {
            isListening=false;
            _speakInstructions();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyHomePage(title: "NLP application")),
            );
          }
    setState(() {});
  }
  }

  Future<void> _addNote() async {
    await Future.delayed(Duration(seconds: 5));

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: Duration(seconds: 15),
    );
    await Future.delayed(Duration(seconds: 10));
    print("saving note as: " + _lastWords);
    String newNote = _lastWords;
    if (newNote.isNotEmpty) {
      setState(() {
        _notes.add(newNote);
        
      });
      _noteController.clear();
       _saveNotes();
      
      
    }
  }

  Future<void> _readNotes() async {
    String result = '';

    for (int i = 0; i < _notes.length; i++) {
      result += '${i + 1}. ${_notes[i]}.    ';
    }
    print(result);
    var re = await flutterTts.speak(result);
    if (re == 1) {
      setState(() => ttsState = TtsState.playing);
    }
    bool isSpeechPlaying = true;
    flutterTts.setCompletionHandler(() {
      if (isSpeechPlaying) {
        isSpeechPlaying = false;
      }
    });
  }

  Future<void> _saveNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
      prefs.setStringList('notes', _notes);
   
  }

  Future<void> _askUser() async {
    await _saySpeech(
        "Do you have anything else you wish to do or should I take you back to the home page? Say 'yes' to stay on this page.");
    await Future.delayed(Duration(seconds: 5));
    isDone=true;
    await _startListeningForRepeatMenu();
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  _loadNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notes.addAll(prefs.getStringList('notes') ?? []);
    });
  }

  _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text(
          'Notes',
          style: TextStyle(color: Colors.black, fontSize: 35),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_notes[index], style: TextStyle(fontSize: 27)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteNote(index),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              style: TextStyle(fontSize: 26),
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Add a new note',
                floatingLabelStyle: TextStyle(fontSize: 26),
                suffixIcon: FloatingActionButton(
                  onPressed: _addNote,
                  tooltip: 'Listen',
                  child: Icon(
                    _speechEnabled ? Icons.mic : Icons.mic_none,
                    color: Colors.black,
                  ),
                  backgroundColor: Colors.lightBlueAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
