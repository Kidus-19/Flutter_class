import 'package:flutter/material.dart';
import 'edit_entry.dart';
import 'database.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Database _database;
  Future<List<Journal>> _loadJournals() async{
    await DatabaseFileRoutines().readJournals().then((journalJson){
      _database = databaseFromJson(journalJson);
      _database.journal.sort((comp1, comp2) => comp2.date!.compareTo(comp1!.date!));
    });
    return _database.journal;
  }

  void addOrEditJournal({required bool add, required int index,
    required Journal journal}) async{
    JournalEdit _journalEdit = JournalEdit(action: '', journal: journal);
    _journalEdit = await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context)=> EditEntry(
          add: add, 
          index: index, 
          journalEdit: _journalEdit),
          fullscreenDialog: true));
    switch(_journalEdit.action){
      case 'Save':
        if(add){
          setState(() {
            _database.journal.add(_journalEdit.journal);
          });
        } else {
            setState(() {
              _database.journal[index] = _journalEdit.journal;
            });
        }
        DatabaseFileRoutines().writeJournals(databaseToJson(_database));
        break;
      case 'Cancel':
        break;
        }
    }
  Widget _buildListViewSeparated(AsyncSnapshot snapshot) {
    return ListView.separated(
      itemCount: snapshot.data.length,
      itemBuilder: (BuildContext context, int index){
        String _titleDate = DateFormat.yMMMEd().format(DateTime.parse(snapshot.data[index].date));
        String _subtitle = snapshot.data[index].mood + "\n" + snapshot.data[index].note;
        return Dismissible(
          key: Key(snapshot.data[index].id), 
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(22.0),
            child: const Icon(Icons.delete,color: Colors.red,),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.all(22.0),
            child: const Icon(Icons.delete, color: Colors.red,),
          ),
          child: ListTile(
            leading: Column(
              children: [
                Text(DateFormat.d().format(DateTime.parse(snapshot.data[index].date)),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 48.0,
                      color: Colors.blue,
                  ),),
                Text(DateFormat.E().format(DateTime.parse(snapshot.data[index].date))),
              ],
              ),
              title:  Text(
                _titleDate,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_subtitle),
              onTap: (){
                addOrEditJournal(
                  add: false,
                  index: index,
                  journal: snapshot.data[index],
                );
              },
          ),
          onDismissed: (direction) {
            setState(() {
              _database.journal.removeAt(index);
            });
            DatabaseFileRoutines().writeJournals(databaseToJson(_database));
          },
          );
      },
      separatorBuilder:  (BuildContext context,int index)  {
        return const Divider( color:  Colors.grey,);
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          initialData: [],
          future: _loadJournals(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return !snapshot.hasData
                ? const Center(child: CircularProgressIndicator())
                : _buildListViewSeparated(snapshot);
          }),
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Padding(
          padding: EdgeInsets.all(32.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Journal Entry',
        child: const Icon(Icons.add),
        onPressed: () {
          addOrEditJournal(add: true, index: -1, journal: Journal());
        },
      ),
    );
  }
}
