import 'package:flutter/material.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VTC Command',
      home: TransportForm(),
    );
  }
}

class TransportForm extends StatefulWidget {
  const TransportForm({super.key});

  @override
  _TransportFormState createState() => _TransportFormState();
}

class _TransportFormState extends State<TransportForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  // Votre clé API Google
  final String apiKey = 'AIzaSyDHVRzTLsti8ObF4jCg0cjEUz-CNDDXi4A';

  Future<void> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          pickupController.text =
              "${place.street}, ${place.locality}, ${place.country}";
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> calculatePrice() async {
    final pickup = pickupController.text;
    final destination = destinationController.text;

    if (pickup.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer les deux adresses.")),
      );
      return;
    }

    var response = await http.get(
      Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(pickup)}&key=$apiKey&language=fr&components=country:fr'),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body) as Map<String, dynamic>;
      // Traitez les données de réponse ici
      // Par exemple, extraire l'ID de lieu et obtenir les détails
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${response.statusCode}")),
      );
    }
    print(amountController.text);
  }

  Future<void> sendEmail() async {
    final email = emailController.text;
    final amount = amountController.text;

    if (email.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tous les champs sont requis.")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:3030/send-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "to": email,
        "subject": "Votre commande VTC",
        "htmlContent": "Le montant estimé est de $amount €",
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email envoyé avec succès !")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'envoi de l'email.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Envoyer un bon de commande VTC")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Pour éviter les débordements
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: emailController,
                  decoration:
                      const InputDecoration(labelText: "Email du client"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: GooglePlaceAutoCompleteTextField(
                  textEditingController: pickupController,
                  googleAPIKey: apiKey,
                  inputDecoration: const InputDecoration(
                    labelText: "Adresse de prise en charge",
                    border: OutlineInputBorder(),
                  ),
                  debounceTime: 800,
                  countries: const ["fr"],
                  itemClick: (Prediction prediction) {
                    print("Adresse sélectionnée: ${prediction.description}");
                    setState(() {
                      pickupController.text = prediction.description ?? '';
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: GooglePlaceAutoCompleteTextField(
                  textEditingController: destinationController,
                  googleAPIKey: apiKey,
                  inputDecoration: const InputDecoration(
                    labelText: "Adresse de destination",
                    border: OutlineInputBorder(),
                  ),
                  debounceTime: 800,
                  countries: const ["fr"],
                  itemClick: (Prediction prediction) {
                    print("Destination sélectionnée: ${prediction.description}");
                    setState(() {
                      destinationController.text = prediction.description ?? '';
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: amountController,
                  decoration:
                      const InputDecoration(labelText: "Montant de la course (€)"),
                  readOnly: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: calculatePrice,
                  child: const Text("Calculer le prix"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: sendEmail,
                  child: const Text("Envoyer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
