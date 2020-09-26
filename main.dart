import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

void main() => runApp(MaterialApp(
      home: Homeku(),
      routes: <String, WidgetBuilder>{
        "/Homeku": (BuildContext context) => new Homeku(),
        "/Jadwal": (BuildContext context) =>
            new Jadwal(npm: vnpm, nama: vnama, matakuliah: vdaftarmatakuliah),
      },
    ));

String vnpm = "";
String vnama = "";
List vdaftarmatakuliah = [];

class Homeku extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Homeku> {
  void _login() {
    if (txtNPM.text == "") {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: new Text("Pesan"),
              content: new Text("Masukkan NPM!"),
              actions: <Widget>[
                new FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: new Text("Tutup"),
                )
              ],
            );
          });
    } else {
      cekMahasiswa(txtNPM.text);
    }
  }

  TextEditingController txtNPM = TextEditingController();

  String pesan = "";

  Future<List> cekMahasiswa(String npm) async {
    final resp = await http
        .get("https://elsantry.000webhostapp.com/simak/rest/validasi/" + npm);
    var datcek = json.decode(resp.body);
    if (datcek[0]['jlh'] == 1) {
      setState(() {
        vnpm = datcek[0]['npm'];
        vnama = datcek[0]['nama'];
        vdaftarmatakuliah = datcek[0]['matakuliah'];
      });
      Navigator.pushReplacementNamed(context, "/Jadwal");
    } else {
      setState(() {
        pesan = "Login salah!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Akses Mahasiswa"),
        centerTitle: true,
        backgroundColor: Colors.red[500],
      ),
      body: Center(
        child: new Container(
          margin: EdgeInsets.all(30.0),
          child: Column(
            children: <Widget>[
              ListTile(
                title: TextField(
                  controller: txtNPM,
                  decoration: InputDecoration(
                    hintText: "NPM",
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: RaisedButton(
                  onPressed: _login,
                  child: Text("Login!"),
                ),
              ),
              Text(
                pesan,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Jadwal extends StatefulWidget {
  Jadwal({this.npm, this.nama, this.matakuliah});
  final String npm;
  final String nama;
  final List matakuliah;

  @override
  _JadwalState createState() => _JadwalState();
}

class _JadwalState extends State<Jadwal> {
  Future<List> listMataKuliah() async {
    final resp = await http.get(
        "https://elsantry.000webhostapp.com/simak/rest/matakuliah/" + vnpm);
    return json.decode(resp.body);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: new Text("Mata Kuliah [$vnpm/$vnama]"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: new FutureBuilder<List>(
        future: listMataKuliah(),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);
          return snapshot.hasData
              ? new ItemList(list: snapshot.data)
              : new Center(child: new CircularProgressIndicator());
        },
      ),
    );
  }
}

class ItemList extends StatelessWidget {
  final List list;
  ItemList({this.list});

  Future diScan() async {
    String resCode = await FlutterBarcodeScanner.scanBarcode(
        "#009922", "CANCEL", true, ScanMode.DEFAULT);
    print(resCode);
    inputHadir(resCode);
  }

  Future inputHadir(String rcode) async {
    var url = "https://elsantry.000webhostapp.com/simak/rest/inputhadir/" +
        vnpm +
        "/" +
        rcode;
    http.post(url);
  }

  @override
  Widget build(BuildContext context) {
    return new ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        return new Container(
          padding: EdgeInsets.all(10),
          child: new GestureDetector(
            onTap: () {
              if (list[i]['buka'] == 'y') {
                //print(list[i]['kode']);
                diScan();
              } else {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: new Text("Pesan"),
                        content: new Text("Kuliah ini belum dibuka!"),
                        actions: <Widget>[
                          new FlatButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: new Text("Tutup"),
                          )
                        ],
                      );
                    });
              }
            },
            child: new Card(
              child: new ListTile(
                title: new Text(
                  list[i]['nama'],
                  style: new TextStyle(fontSize: 20),
                ),
                leading: new Icon(Icons.widgets),
                subtitle: new Text(
                  list[i]['kode'] +
                      " | " +
                      list[i]['hari'] +
                      " | " +
                      list[i]['jam'],
                  style: new TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
