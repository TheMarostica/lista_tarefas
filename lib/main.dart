import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
  runApp(const MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoController = TextEditingController();

  List _toDoList = [];
  late Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos = 0;

  @override
  void initState(){
    super.initState();

    _readData().then((value) {
      setState(() {
        _toDoList = json.decode(value);
      });
    });
  }

  void _addToDo(){
    Map<String, dynamic> newTodo = {};
    newTodo["title"] = _toDoController.text;
    _toDoController.text = "";
    newTodo["ok"] = false;
    _toDoList.add(newTodo);
    
    _saveData();
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    _toDoList.sort((a,b){
    
      if(a["ok"] && !b["ok"]) {
        return 1;
      } else if(!a["ok"] && b["ok"]) {
        return -1;
      } else {
        return 0;
      }
    });

    setState(() {
      _saveData();
    });

    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Lista de Tarefas",
        ),
      ),

      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),

            child: Row(
              children: [  
                Expanded(
                  child: TextFormField(
                    controller: _toDoController,
                    decoration: const InputDecoration(
                      labelText: "Nova Tarefa",
                    ),
                  ),
                ),
                
                ElevatedButton(
                  onPressed: (){
                    setState(() {
                      _addToDo();
                    });
                  }, 
                  child: const Text("ADD")
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder( // construtor que permiti eu ir construindo a lista conforme eu vou rodando ela (elementos que estão escondidos não vão ser renderizados (não vão consumir recursos))
                padding: const EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index){ // index -> elemento da lista que ele está desenhando no momento
    return Dismissible( // para arrastar o item
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()), // estamos dando o nome para cada uma das tarefas que forem criadas, para que ele saiba qual vai ser arrastada

      background: Container( // o que vai aparecer quando deslizar
        color: Colors.red,
        child: const Align( // para colcoar o filho do lado esquerdo
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),

      direction: DismissDirection.startToEnd, // direção que eu vou arrastar

      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(
            _toDoList[index]["ok"] ? Icons.check : Icons.error,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _toDoList[index]["ok"] = value; // vamos armazenar se marcamos ou não
            _saveData();
          });
        },
      ),

      onDismissed: (direction){
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index); // aqui removemos ele da lista

          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
            
            action: SnackBarAction(
              label: "Desfazer",

              onPressed: (){
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),

            duration: const Duration(seconds: 3),
          );

          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }  

  Future<File> _getFile() async {
  final directory = await getApplicationDocumentsDirectory(); // vai pegar o diretório onde eu posso armazenar os documentos do app
  return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile(); // vai esperar o meu arquivo
    return file.writeAsString(data); // vamos pegar os nossos dados e escrever em forma de texto dentro do arquivo
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return await file.readAsString(); // vamos ler como string
    } catch (e) {
      throw Exception("Erro ao ler o arquivo: $e");
    }
  }
}


