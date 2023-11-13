import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Load JSON',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blueGrey,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/simpsonsphoto.png',
            fit: BoxFit.cover,
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DataPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  primary: const Color.fromARGB(255, 244, 244, 54),
                ),
                child: const Text(
                  'Click here to load data',
                  style: TextStyle(
                    color: Color.fromARGB(255, 2, 2, 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DataPage extends StatefulWidget {
  const DataPage({Key? key});

  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  List _items = [];
  List _filteredItems = [];

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPageData();
  }

  Future<void> loadPageData() async {
    await readJson();
    await loadStoredRatings();
  }

  Future<void> readJson() async {
    final String response =
        await rootBundle.loadString('assets/charactersSimpsons.json');
    final data = await json.decode(response);
    setState(() {
      _items = data["items"];
      _filteredItems = _items;
    });
  }

  Future<void> loadStoredRatings() async {
    for (var item in _items) {
      double storedRating = await _getStoredRating(item["character"]);
      setState(() {
        item["rating"] = storedRating;
      });
    }
  }

  Future<void> _saveRating(double rating, String character) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('rating_$character', rating);

    // Actualizar _items después de guardar la puntuación
    int index = _items.indexWhere((item) => item["character"] == character);
    if (index != -1) {
      setState(() {
        _items[index]["rating"] = rating;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rating saved successfully'),
      ),
    );
  }

  Future<double> _getStoredRating(String character) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getDouble('rating_$character') ?? 0.0);
  }

  void filterSearchResults(String query) {
    List dummySearchList = [];
    dummySearchList.addAll(_items);
    if (query.isNotEmpty) {
      List dummyListData = [];
      dummySearchList.forEach((item) {
        if (item['character'].toLowerCase().contains(query.toLowerCase())) {
          dummyListData.add(item);
        }
      });
      setState(() {
        _filteredItems = dummyListData;
      });
      return;
    } else {
      setState(() {
        _filteredItems = _items;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      backgroundColor: Color.fromARGB(255, 251, 255, 2),
      title: const Text('SIMPSONS'),
    ),
    body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/simpsonsphoto.png'), // Reemplaza con la ruta de tu imagen de fondo
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                filterSearchResults(value);
              },
              decoration: const InputDecoration(
                hintText: 'Search your character here',
              ),
            ),
            const SizedBox(height: 20),
            _filteredItems.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(
                                  image: _filteredItems[index]["image"],
                                  character: _filteredItems[index]["character"],
                                  quote: _filteredItems[index]["quote"],
                                  rating: _filteredItems[index]["rating"] ?? 0.0,
                                  onSaveRating: (value) {
                                    _saveRating(value, _filteredItems[index]["character"]);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Card(
                            key: ValueKey(_filteredItems[index]["id"]),
                            margin: const EdgeInsets.all(5),
                            color: Color.fromARGB(208, 30, 29, 25),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(5),
                              leading: CircleAvatar(
                                radius: 20,
                                child: ClipOval(
                                  child: Image.network(
                                    _filteredItems[index]["image"],
                                    fit: BoxFit.contain,
                                    width: 40,
                                    height: 40,
                                  ),
                                ),
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _filteredItems[index]["character"],
                                    style: const TextStyle(fontSize: 20, color: Colors.amberAccent),
                                  ),
                                  Text(
                                    "Quote: ${_filteredItems[index]["quote"]}",
                                    style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 202, 176, 80)),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Rating: ${(_filteredItems[index]["rating"] ?? 0.0).toStringAsFixed(1)}',
                                        style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 65, 255, 7)),
                                      ),
                                      const SizedBox(width: 5),
                                      RatingBar.builder(
                                        initialRating: _filteredItems[index]["rating"] ?? 0.0,
                                        minRating: 0,
                                        direction: Axis.horizontal,
                                        allowHalfRating: true,
                                        itemCount: 5,
                                        itemSize: 15,
                                        ignoreGestures: true,
                                        itemBuilder: (context, _) => const Icon(
                                          Icons.star,
                                          color: Color.fromARGB(255, 65, 255, 7),
                                        ),
                                        onRatingUpdate: (rating) {
                                          _saveRating(
                                              rating,
                                              _filteredItems[index]["character"]);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : const SizedBox(
                    height: 100,
                    child: Center(child: Text('No results found')),
                  ),
          ],
        ),
      ),
    ),
  );
}

}

class DetailPage extends StatefulWidget {
  final String image;
  final String character;
  final String quote;
  final double rating;
  final ValueChanged<double> onSaveRating;

  DetailPage({
    required this.image,
    required this.character,
    required this.quote,
    required this.rating,
    required this.onSaveRating,
  });

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onSaveRating(_currentRating);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Character details: ${widget.character}"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                widget.image,
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 20),
              Text(
                widget.character,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                widget.quote,
                style: const TextStyle(fontSize: 16),
              ),
              RatingBar.builder(
                initialRating: widget.rating,
                minRating: 0,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 10,
                itemSize: 20,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _currentRating = rating;
                  });
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Rating: ${_currentRating.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  widget.onSaveRating(_currentRating);
                  Navigator.pop(context); // Cierra la página de detalles
                },
                child: const Text('Save Rating'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
