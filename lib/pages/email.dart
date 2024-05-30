import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart' as tts;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'homepage.dart';

void main() {runApp(Email());}
class Email extends StatefulWidget {

  @override
  _EmailState createState() => _EmailState();
}

class _EmailState extends State<Email> {
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController mailboxController = TextEditingController();
  final TextEditingController searchTypeController = TextEditingController();
  final TextEditingController searchTermController = TextEditingController();
  late final tts.FlutterTts _flutterTts;
  bool _buttonsEnabled = true;
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _resultText = '';
  String _resTopics = '';
  String _mailres = '';
  String searchWord = '';
  String rec_mail= '';
  String message='';
  String mailbox='';
  String searchType='';
  String searchTerm='';
  List<dynamic> searchResults = [];

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

    await _flutterTts.speak(
        "You are now on the E mail page. To get the status of your mailbox use the command         status. to get the latest emails use the command        new mails. to search for a mail use the command           search. and to send a mail use command        send.");

    await Future.delayed(Duration(seconds: 17));
    _toggleListening();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text(
          'Email Operations',
          style: TextStyle(color: Colors.black, fontSize: 40),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  getMailboxStatus();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(20),
                  backgroundColor: Colors.lightBlueAccent,
                ),
                child: Text('Get Mailbox Status',style:TextStyle(fontSize: 30,color: Colors.black),),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  getLatestMails();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(20),
                  backgroundColor: Colors.lightBlueAccent,
                ),
                child: Text('Get Latest Emails',style:TextStyle(fontSize: 30,color: Colors.black),),
              ),
              SizedBox(height: 20.0),
              SizedBox(height: 16.0),

              _resultText.isNotEmpty
                  ? Text(
                _resultText,
                style: TextStyle(fontSize: 20.0),
              )
                  : SizedBox(),
              TextField(
                controller: recipientController,
                decoration: InputDecoration(
                  labelText: 'Recipient',labelStyle: TextStyle(fontSize: 30),
                ), style: TextStyle(fontSize: 30),
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'Message',labelStyle: TextStyle(fontSize: 30),
                ), style: TextStyle(fontSize: 30),
                maxLines: 5,
              ),
              SizedBox(height: 20.0),

              ElevatedButton(
                onPressed: () {
                  String recipient = recipientController.text.trim();
                  String message = messageController.text.trim();
                  if (recipient.isNotEmpty && message.isNotEmpty) {
                    sendMail(recipient, message);
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Error'),
                          content: Text('Recipient and message cannot be empty.'),
                          actions: <Widget>[
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
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(20),
                  backgroundColor: Colors.lightBlueAccent,
                ),
                child: Text('Send Email',style:TextStyle(fontSize: 30,color: Colors.black),),

              ),

              _mailres.isNotEmpty
                  ? Text(
                _mailres,
                style: TextStyle(fontSize: 20.0),
              )
                  : SizedBox(),
              SizedBox(height: 20.0),
              TextField(
                controller: mailboxController,
                decoration: InputDecoration(
                  labelText: 'mailbox',labelStyle: TextStyle(fontSize: 30),
                ), style: TextStyle(fontSize: 30),
                maxLines: 5,
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: searchTypeController,
                decoration: InputDecoration(
                  labelText: 'Search type',labelStyle: TextStyle(fontSize: 30),
                ), style: TextStyle(fontSize: 30),
                maxLines: 5,
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: searchTermController,
                decoration: InputDecoration(
                  labelText: 'Search term',labelStyle: TextStyle(fontSize: 30),
                ), style: TextStyle(fontSize: 30),
                maxLines: 5,
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  String mailbox = mailboxController.text.trim();
                  String searchType = searchTypeController.text.trim();
                  String searchWord = searchTermController.text.trim();
                  if (mailbox.isNotEmpty && searchType.isNotEmpty) {
                    searchEmails(mailbox,searchType,searchWord);
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Error'),
                          content: Text('Fill parameters'),
                          actions: <Widget>[
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
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(20),
                  backgroundColor: Colors.lightBlueAccent,
                ),
                child: Text('Search Email',style:TextStyle(fontSize: 30,color: Colors.black),),

              ),
              SizedBox(height: 20.0),

              if (searchResults.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Search Results:',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),

                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(searchResults[index]['subject']),
                          subtitle: Text(searchResults[index]['from']),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    ),
    );
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

      bool detected=false;
      await _speech.listen(
        onResult: (result) {
          print(result.recognizedWords);
          if (result.finalResult) {
            String recognizedWord = result.recognizedWords.toLowerCase();

              if (recognizedWord.contains('status') || recognizedWord.contains('update') || recognizedWord.contains('stay')  ) {
                detected=true;
                getMailboxStatus();
              }

              if (recognizedWord.contains('read') || recognizedWord.contains('new') || recognizedWord.contains('recite')) {
                detected=true;
                getLatestMails();
              }

              if (recognizedWord.contains('send') ||
                  recognizedWord.contains('sent') ) {
                detected=true;
                getMailInfo();
              }

            if (recognizedWord.contains('search')) {
              detected=true;
              getSearchInfo();
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
          } else  {

          }
        }
      },
    );
  }

  Future<void> getMailInfo() async {
    await _flutterTts.speak("Please spell out the email address you wish to send a mail to");
    await Future.delayed(Duration(seconds: 4));

    await _speech.listen(
      onResult: (result) async {
        if (result.finalResult) {
          setState(() {
            rec_mail = result.recognizedWords.trim();
          });
          print(rec_mail);
          await _flutterTts.speak("You said, $rec_mail. Is this correct?");

          await Future.delayed(Duration(seconds: 10));
          await _speech.listen(
            onResult: (confirmationResult) async {
              if (confirmationResult.finalResult) {
                if (confirmationResult.recognizedWords.toLowerCase() == "yes") {
                  await getMessageInfo();
                } else {

                  await getMailInfo();
                }
              }
            },
            listenFor: Duration(seconds: 15),
          );
        }
      },
      listenFor: Duration(seconds: 40),
    );
  }

  Future<void> getMessageInfo() async {

    await _flutterTts.speak("Please speak the message you want to send");
    await Future.delayed(Duration(seconds: 4));

    await _speech.listen(
      onResult: (result) async {
        if (result.finalResult) {
          setState(() {
            message = result.recognizedWords.trim();
          });

          print(message);
          await _flutterTts.speak("You said, $message. Is this correct?");

          await Future.delayed(Duration(seconds: 10));
          await _speech.listen(
            onResult: (confirmationResult) async {
              if (confirmationResult.finalResult) {
                if (confirmationResult.recognizedWords.toLowerCase() == "yes") {

                  await sendMail(rec_mail, message);
                } else {

                  await getMessageInfo();
                }
              }
            },
            listenFor: Duration(seconds: 15),
          );
        }
      },
      listenFor: Duration(seconds: 15),
    );
  }

  Future<void> sendMail(String recipient, String message) async {

    final url = Uri.parse('http://10.0.2.2:5000/sendMail');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sendTo': recipient, 'msg': message}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _mailres = "The mail was sent successfully";
      });

      await _flutterTts.speak(_mailres);
      await Future.delayed(Duration(seconds:3));
    } else {
      setState(() {
        _mailres = "Error The mail could not be sent";
      });

      await _flutterTts.speak(_mailres);
      await Future.delayed(Duration(seconds:3));
      print(response.body);
    }
    await _askUser();
  }


  Future<void> getSearchInfo() async {
    await _flutterTts.speak("Which mailbox do you want to search through? You may choose inbox, sent , drafts, spam.");
    await Future.delayed(Duration(seconds: 13));
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            mailbox= result.recognizedWords.trim();
          });
        }
        print(mailbox);
      },
    );
    await Future.delayed(Duration(seconds: 3));
    await _flutterTts.speak("Choose a search type between sender or subject");
    await Future.delayed(Duration(seconds: 6));
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            searchType= result.recognizedWords.trim();
          });
        }
        print(searchType);
      },
    );
    await Future.delayed(Duration(seconds: 4));
    await _flutterTts.speak("Choose the search term you want to find");
    await Future.delayed(Duration(seconds: 6));
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            searchTerm= result.recognizedWords.trim();
          });
        }
        print(searchTerm);
      },
    );
    await Future.delayed(Duration(seconds: 8));
    searchEmails(mailbox, searchType, searchTerm);
  }

  Future<void> searchEmails(String mailbox, String searchType, String searchTerm) async {
    print("searching");
    var url = Uri.parse('http://10.0.2.2:5000/searchMail');

    var body = jsonEncode({'mailbox': mailbox, 'search_type':searchType, 'search_term':searchTerm});

    var response = await http.post(url, body: body, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      setState(() {
        searchResults = jsonDecode(response.body);
      });

      print(searchResults);
      String ans="";
      ans = searchResults.map((res) => '${res['sender_email']} ${res['subject']}').join('\n');
      print(ans);
      await _flutterTts.speak(ans);
      /*for(var res in searchResults)
        {
           res.keys.forEach((key)  {ans+=res['sender_email']+res['subject'];});


        }
      print(ans);
      await _flutterTts.speak(ans);*/
      await Future.delayed(Duration(seconds: 15));
    } else {
      print('Error: ${response.reasonPhrase}');
    }
    await _askUser();
  }
  Future<void> getMailboxStatus() async {
    await _flutterTts.speak("fetching the status for you");
    final url = Uri.parse('http://10.0.2.2:5000/getMailBoxStatus');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      Map<String, dynamic> mailboxStatus = jsonDecode(response.body);
      String status = '';
      mailboxStatus.forEach((key, value) => status += '$key: $value\n');
      setState(() {
        _resultText = "The status of your mailbox is as follows:\n$status";
      });
      await _flutterTts.speak(_resultText);
      await Future.delayed(Duration(seconds:30));
    } else {
      setState(() {
        _resultText = "ERROR:\nfailed to load status";
      });

      await _flutterTts.speak(_resultText);
      print(response.body);
    }
    await Future.delayed(Duration(seconds:5));
    await _askUser();
  }

  Future<void> getLatestMails() async {
    await _flutterTts.speak("fetching your emails now");
    final url = Uri.parse('http://10.0.2.2:5000/getLatestMails');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      /*
      Map<String, dynamic> mailboxStatus = jsonDecode(response.body);
      String status = '';
      mailboxStatus.forEach((key, value) => status += '$key: $value\n');
      * */
      Map<String,dynamic> latestMails = jsonDecode(response.body);
      //print(latestMails);
      String emails = '';
      String topics = '';
      for (var mail in latestMails['latest_mails']) {
        emails += 'Subject: ${mail['subject']}\nFrom: ${mail['from']}\n\n';
      }

      for (var t in latestMails['topics']) {
        topics += t + '\n';
      }
      setState(() {
        _resultText = emails.isEmpty ? 'No new emails.' : emails;
        _resTopics = topics.isEmpty ? 'No new topics.' : topics;
      });

      await _flutterTts.speak("Your emails are as follows");
      await _flutterTts.speak(_resultText);
      await Future.delayed(Duration(seconds:36));

      await _categorization();
      await Future.delayed(Duration(seconds:55));
      //await _flutterTts.speak("Your topics are as follows");
      //await _flutterTts.speak(_resTopics);
    } else {
      setState(() {
        _resultText = 'ERROR:\nCould not load emails';
      });

      await _flutterTts.speak(_resultText);

      print(response.body);
    }
    await Future.delayed(Duration(seconds:5));
    await _askUser();
  }
  Future<void> _categorization() async{

    await _flutterTts.speak("The latest mails are classified as follows");
    await Future.delayed(Duration(seconds:10));
    await _flutterTts.speak(_resTopics);
    await Future.delayed(Duration(seconds: 5));

    await _flutterTts.speak("Please say the category you want to read");
    await Future.delayed(Duration(seconds: 4));

    await _speech.listen(
        onResult: (result) async {
          if (result.finalResult) {
            setState(() {
              message = result.recognizedWords.trim();
            });

            print(message);
            final url = Uri.parse('http://10.0.2.2:5000/classify');
            final response = await http.get(url);
            if (response.statusCode == 200) {

              Map<String, dynamic> jsonMap = jsonDecode(response.body);
              // Check if the key exists in the JSON object
              if (jsonMap.containsKey(message)) {
                //print(jsonMap[message]);
                await _flutterTts.speak(jsonMap[message].toString());
                await Future.delayed(Duration(seconds: 35));
                print(jsonMap[message]);
              } else {
                print("Key '$message' not found in the JSON object.");
              }
            }

          }
        }
    );
  }

  Future<void> _askUser() async {
    await Future.delayed(Duration(seconds: 5));
    await _flutterTts.speak(
        "Do you have anything else you want to do or should I take you back to the home page? Say 'yes' to stay on this page.");
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
            _isListening=false;
            _speakIntroMessage();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyHomePage(title: "NLP application")),
            );

          }
        }
      },
    );

  }


}
