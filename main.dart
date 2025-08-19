import 'dart:convert';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:lets_code/rate.dart';

void main() {
  runApp(const MyApp());
}

Future<String> runCodeWithPiston(String language, String version, String code) async {

  final url = Uri.parse("https://emkc.org/api/v2/piston/execute");
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "language": language,
      "version": version,
      "files": [
        {"name": "main.$language", "content": code}
      ]
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["run"]["output"] ?? "No output";
  } else {
    return "Error: ${response.statusCode}\n${response.body}";
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isloading=false;
  bool codebtn=false;
  late CodeController _codeController;
  String _output = "";
  String _selectedLanguage = "python";
  String _selectedVersion = "3.10.0";

  final Map<String, dynamic> languages = {
    "python": {
      "version": "3.10.0",
      "highlighter": python,
      "sample": "print('Hello World python')"
    },
    "java": {
      "version": "15.0.2",
      "highlighter": java,
      "sample": """
public class Main {
  public static void main(String[] args) {
    System.out.println("Hello Java");
  }
}
"""
    },
    "cpp":{
      "version":"10.2.0",
      "highlighter":cpp,
      "sample":"""
      #include <iostream>
      int main() {
      std::cout << "Hello CPP";
      return 0;
      }
      """
    }
  };

  @override
  void initState() {
    super.initState();
    _loadEditor("python");
  }

  void _loadEditor(String lang) {
    final config = languages[lang];
    _codeController = CodeController(
      text: config["sample"],
      language: config["highlighter"],
      patternMap: {
        r'".*?"': TextStyle(color: Colors.orange),   // strings
        r'\b\d+\b': TextStyle(color: Colors.green),  // numbers
        r'\b(class|int|float|public|static|void|if|else)\b':
        TextStyle(color: Colors.blue, fontWeight: FontWeight.bold), // keywords
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme:IconThemeData(color: Colors.white),
        title: const Text("Lets_code", style: TextStyle(color: Colors.white,fontSize:30)),
        backgroundColor: Colors.black,
        actions: [
          DropdownButton<String>(
            dropdownColor: Colors.black87,
            borderRadius:BorderRadius.all(Radius.circular(20)),
            value: _selectedLanguage,
            items: languages.keys.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Text(
                  lang.toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (lang) {
              setState(() {
                _selectedLanguage = lang!;
                _selectedVersion = languages[lang]["version"];
                _loadEditor(lang);
              });
            },
          )
        ],
      ),
      drawer:Drawer(
        backgroundColor:Colors.black,
          child:ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                child:CircleAvatar(
                    child:Icon(Icons.person,size:40,),
                ),
              ),
              ListTile(
                title:Text("Home",style:TextStyle(color:Colors.white,fontSize:20),),
                onTap:(){
                  Navigator.push(context, MaterialPageRoute(builder:(context)=>MyHomePage()));
                },
              ),
              ListTile(
                title:Text("Article",style:TextStyle(color:Colors.white,fontSize:20),),
                onTap:(){},
              ),
              ListTile(
                title:Text("Practice",style:TextStyle(color:Colors.white,fontSize:20),),
                onTap:(){},
              ),
              ListTile(
                title:Text("Feedback",style:TextStyle(color:Colors.white,fontSize:20),),
                onTap:(){},
              ),
              ListTile(
                title:Text("Rate",style:TextStyle(color:Colors.white,fontSize:20),),
                onTap:(){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Rate()));
                },
              )
            ],
          ),
      ),
      body: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                    child: CodeField(
                      decoration:BoxDecoration(
                        borderRadius:BorderRadius.all(Radius.circular(20))
                      ),
                      controller: _codeController,
                      textStyle: const TextStyle(
                        fontFamily: 'Mozilla',
                        fontSize: 16,
                      ),
                    ),
                  
                ),
              ),
            ),

              AnimatedContainer(
                duration:Duration(seconds:1),
                curve:Curves.easeInOutQuad,
                height:codebtn==true?700:10,
                width:double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                  child: SingleChildScrollView(
                    child: Text(
                      _output,
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Courier'),
                    ),
                  ),
              ),

          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon:Icons.code,
        activeIcon: Icons.close,
        backgroundColor:Colors.blueAccent,
        overlayColor: Colors.transparent,
        children: [
          SpeedDialChild(
            child:const Icon(Icons.code),
            label:"Code",
            onTap:(){
              setState(() {
                codebtn=false;
              });
            }
          ),
          SpeedDialChild(
            child: const Icon(Icons.play_arrow),
            label:"Run",
            onTap:() async{
              isloading=true;
              String code=_codeController.text;
              String output= await runCodeWithPiston(_selectedLanguage, _selectedVersion, code);
              setState(() {
                codebtn=true;
                _output=output;
                isloading=false;
              });
            }
          ),
          SpeedDialChild(
            child: const Icon(Icons.chat),
            label:"AI assistant",
            onTap:(){
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content:Text("This feature will be available soon.."),duration:Duration(seconds:1),)
              );
            }
          )
        ],
      )
    );
  }
}
