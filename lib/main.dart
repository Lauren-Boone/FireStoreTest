import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_database/firebase_database.dart';
//import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/rendering.dart';
// import 'package:firebase_core/firebase_core.dart'; not nessecary


//code from https://github.com/tensor-programming/flutter_firebase/blob/master/lib/main.dart
//to test our database
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context){
      return Scaffold(
        appBar: AppBar(
        title: Text('FireStore Test'),
        centerTitle: true,
        actions: <Widget>[//Widget to add a document to collection Projects
          IconButton(
          icon: Icon(Icons.add),
          onPressed: (){
            //code to add to collection. runTranasction prevent race condition
            Firestore.instance.runTransaction((Transaction transaction) async{
              //get data through reference (reference to entire collection of data)
              CollectionReference reference = 
                Firestore.instance.collection('Projects');
                await reference.add({"title": "", "editing": false, "score": 0});
            });
          },
          ),
        ],
        ),
        body: StreamBuilder(
          stream: Firestore.instance.collection('Projects').snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
            if(!snapshot.hasData) return CircularProgressIndicator();
            return FirestoreListView(documents: snapshot.data.documents);
  
          },

        ),
        );
      

        
    }

}

class FirestoreListView extends StatelessWidget{
  final List<DocumentSnapshot> documents;
  FirestoreListView({this.documents});

  @override 
  Widget build(BuildContext context){
    return ListView.builder(
      itemCount: documents.length,
      itemExtent: 90.0, //area that items take up on screen
      itemBuilder: (BuildContext context, int index){ //index iterating throug
        String title = documents[index].data['title'].toString();
        return ListTile(//Format dispaly
         title: Container(
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(5.0),
             border: Border.all(color: Colors.white),
           ),
           padding: EdgeInsets.all(5.0),
           child: Row(
             children: <Widget>[
               Expanded(
                 child: !documents[index].data['editing']
                  ? Text(title) : TextFormField(
                    initialValue: title,
                    onFieldSubmitted: (String item){
                      Firestore.instance
                        .runTransaction((transaction) async{
                          DocumentSnapshot snapshot = await transaction 
                            .get(documents[index].reference);

                            await transaction.update(
                              snapshot.reference, {'title': item});
                            
                            await transaction.update(snapshot.reference,
                              {"editing": !snapshot['editing']});

                              });


                        
                    },

                    
                  ),

               ),
             ],
           ),
         ),
         
         onTap:() => Firestore.instance.runTransaction((Transaction transaction) async{
           DocumentSnapshot snapshot = await transaction.get(documents[index].reference);
           await transaction.update(
             snapshot.reference,
             {"editing": !snapshot["editing"]});
           
         }));
        

      },
      );
  }

}
