import 'package:flutter/material.dart';
import 'package:sballoquiz/widget/sballo_button.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as parser;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';

void main() {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'L\'Quiz',
            theme: ThemeData(        
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
            ),
            home: const MyHomePage(title: 'QUIZZZ'),
        );
    }
}

class MyHomePage extends StatefulWidget {
    const MyHomePage({super.key, required this.title});
    final String title;

    @override
    State<MyHomePage> createState() => _MyHomePageState();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

const defaultTries = 3;

class _MyHomePageState extends State<MyHomePage> {
    var _questionIndex = 0;
  	late var _questions;
    bool _reload = true;
    final url = 'https://opentdb.com/api.php?amount=10&category=9&difficulty=medium&type=multiple';

    /////////////// INIT ///////////////

    int _status = 7;
    int _tries = defaultTries;

    final maxTime = Duration(milliseconds: 10000);
    late Duration _currentTime;
    bool _timerGo = true;

    final player = AudioPlayer();

    @override
    void initState() {
        super.initState();
        _currentTime = maxTime;
        _timer();

        _getQuestions();

        player.setAsset("sounds/xbox.mp3").then((_) => player.play()).then((_) => player.setLoopMode(LoopMode.all));
    }

    void _getQuestions() {
        http.get(Uri.parse(url)).then((res) {

            setState(() {
                _questions = json.decode(res.body)['results'];
            });
        });
    }

    ///////////////////// MAIN LOOP /////////////////////

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(widget.title),
            ),
            body: Container(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                width: double.infinity,
                child: Center(          
                    child: Column(            
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                            Slider(
                                activeColor: Colors.green,
                                inactiveColor: Colors.grey,
                                min: 0,
                                max: maxTime.inMilliseconds.toDouble(),
                                value: _currentTime.inMilliseconds.toDouble(),
                                onChanged: (value) {},
                            ),
                            Text(
                                parser.DocumentFragment.html(_questions[_questionIndex]['question'] as String).text.toString(),
                                style: const TextStyle(
                                    fontSize: 30
                                ), 
                            ),
                            ..._shuffle([...(_questions[_questionIndex]['incorrect_answers'].map<String>((item) => item.toString())), (_questions[_questionIndex]['correct_answer'] as String)])
                            .map((answer) {
                                return SballoButton(
                                    text: answer,
                                    action: () => _checkAnswer(answer, _questions[_questionIndex]['correct_answer'] as String),
                                    background: Colors.lime,
                                    primary: Colors.indigoAccent,
                                );
                            })
                        ]
                    ),
                ),
            )
        );
    }

    ///////////////////// MAIN FUNCTIONS /////////////////////

    void _checkAnswer(String answer, String correctAnswer) {
        if (answer == correctAnswer) {
            _status = 1;
            _timerGo = false;
        } else {
            _tries--;
            if (_tries <= 0) {
                _timerGo = false;
                _status = -1;
            } else {
                _status = 0;
            }
        }
        _displayStatus();
    }

    void _displayStatus() {
        const fontSize = 25.0;
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                title: const Text('Attenzione'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget> [
                        if (_status <= 0) const Text(
                            'Risposta errata!!!',
                            style: TextStyle(
                                color: Color.fromARGB(255, 236, 12, 12),
                                fontSize: fontSize,
                            ),
                        ),
                        if (_status == 1) const Text(
                            'Risposta corretta!!!',
                            style: TextStyle(
                                color: Color.fromARGB(255, 12, 206, 12),
                                fontSize: fontSize,
                            ),
                        ),
                        if (_status == -1) const Text(
                            'Hai esaurito i tentativi!!!',
                            style: TextStyle(
                                color: Color.fromARGB(255, 23, 5, 211),
                                fontSize: fontSize,
                            ),
                        ),
                        if (_status == -7) const Text(
                            'Hai esaurito il tempo per rispondere!!!',
                            style: TextStyle(
                                color: Color.fromARGB(255, 23, 5, 211),
                                fontSize: fontSize,
                            ),
                        )
                    ],
                ),
                actions: <Widget> [
                    TextButton(
                        autofocus: true,
                        child: const Text('LETSGOSKI'),
                        onPressed: () {
                            Navigator.of(ctx).pop(true);
                            if (_status == 1 || _status == -1 || _status == -7 ) _nextQuestion();
                        },
                    )
                ],
            )
       );
    }

    void _nextQuestion() {
        _status = 7;
        _tries = 5;
        _reload = true;
        _currentTime = maxTime;
        _timerGo = true;
        setState(() => _questionIndex = (_questionIndex + 1) % [..._questions].length);
        _timer();
    }

    Future<void> _timer() async {
        const timeStep = Duration(milliseconds: 10);
        while (_timerGo && _currentTime >= Duration.zero) {
            await Future.delayed(timeStep);
            _currentTime -= timeStep;
            setState(() {});
        }
    }

    ///////////////////// UTILS /////////////////////

    List<String> _shuffle(List<String> list) {
        if (_reload) {
            list.shuffle();
            _reload = false;
        }
        return list;
    }
}
