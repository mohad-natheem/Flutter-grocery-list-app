import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main(){
  runApp(MaterialApp(
    home: HomeScreen(),
    theme: ThemeData(appBarTheme: AppBarTheme(
      color: Color.fromARGB(255, 171, 46, 193),
    )),
  ));
  
}

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final textController = TextEditingController();

  List<double> prices=[5.04,3.50,6.32];

  int? groceryIndex;
  IconData buttonLabel = Icons.add;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          title: Text('Grocery List',style: TextStyle(fontSize: 25),)
        ),
      ),
      body: Stack(
        children:[ Container(
            child: FutureBuilder<List<Grocery>>(
              future: DatabaseHelper.instance.getGroceries(),
              builder: (BuildContext context, AsyncSnapshot<List<Grocery>> snapshot){
                if(!snapshot.hasData){
                  return Center(child: Text('Loading...'),);
                }
                
                return snapshot.data!.isEmpty
                ? Center(child :Text('No Groceries in List.'))
                :ListView(
                    children: snapshot.data!.map((grocery) {
                      return Center(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)
                          ),
            
                          
                          shadowColor: Colors.purple[100],
                          margin: EdgeInsets.symmetric(vertical: 5,horizontal: 10),
                          color: groceryIndex == grocery.id ?Colors.purple[300]: Colors.purple[200],
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
      
                            onTap: () {
                              setState(() {
                                if(groceryIndex==null){
                                groceryIndex= grocery.id;
                                textController.text = grocery.name;
                                buttonLabel =Icons.save;
                                }
                                else{
                                  textController.text='';
                                  groceryIndex=null;
                                  buttonLabel=Icons.add;
      
                                }
                              });
                            },
                            onLongPress: (){
                              setState(() {
                              DatabaseHelper.instance.delete(grocery.id!);  
                              });
                              
                            },
                            title: Text(grocery.name,style: TextStyle(fontSize: 18,color: Colors.black,fontWeight: FontWeight.w500),),
            
                          ),
                        ),
                      );
                    }).toList(),
                  );
                
      
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
        children: [
          Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15,vertical: 5),
            margin: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 20
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: const[BoxShadow(
                color: Colors.blueGrey
              )]
            ),
          child: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: 'Enter grocery item...',
              border: InputBorder.none,
            ),
            

          ),
            )),
          Container(
            margin: EdgeInsets.only(right: 20,bottom: 20),
            child: ElevatedButton(
              
              style:ElevatedButton.styleFrom(
                primary: Colors.purple,
                minimumSize: Size(60, 60),
                elevation: 10
              ),
              onPressed: (){
                groceryIndex!=null 
                ? DatabaseHelper.instance.update(Grocery(id: groceryIndex,name: textController.text))
                : DatabaseHelper.instance.add(Grocery(name: textController.text));
                setState(() {
                  textController.clear();
                  groceryIndex=null;
                  buttonLabel=Icons.add;
                });
                
                
               
              
            }, 
            child: Icon(buttonLabel),
                
            ),
          )

        ],
      ),
          )
        ]
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const[
          NavigationDestination(
            icon: Icon(Icons.person),
             label: 'Profile'
             ),
             NavigationDestination(
              icon: Icon(Icons.settings), 
              label: 'Settings')
             ]
            
             ),

    );
  }
}

class Grocery{
  final int? id;
  final String name ;

  Grocery({this.id,required this.name});

  factory Grocery.fromMap(Map<String,dynamic> json) => new Grocery(
    id: json['id'],
    name: json['name'],
  );
  
  Map<String,dynamic> toMap(){
    return{
      'id':id,
      'name':name,
    };
  }
}

class DatabaseHelper{
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database??=await _initDatabase();

  Future<Database> _initDatabase() async{
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path,'groceries.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db,int version) async{
    await db.execute('''
CREATE TABLE groceries(
  id INTEGER PRIMARY KEY,
  name TEXT
)

''');
}

Future<List<Grocery>> getGroceries() async{
  Database db = await instance.database;
  var groceries = await db.query('groceries',orderBy: 'name');
  List<Grocery> groceryList = groceries.isNotEmpty?groceries.map((c) => Grocery.fromMap(c)).toList() :[];

  return groceryList;
}

Future<int> add(Grocery grocery) async{
  Database db = await instance.database;
  return await db.insert('groceries', grocery.toMap());
}

Future<int> delete(int id) async{
  Database db = await instance.database;
  return await db.delete('groceries',where: 'id=?',whereArgs: [id]);
}
Future<int> update(Grocery grocery)async{
Database db = await instance.database;
return await db.update('groceries', grocery.toMap(),where: 'id=?',whereArgs: [grocery.id]);
}

}