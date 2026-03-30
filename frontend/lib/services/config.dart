// lib/services/config.dart

class ApiConfig {
  // Set via: flutter run --dart-define=BASE_URL=http://192.168.1.50:8000
  //From phone on same Wi‑Fi: flutter run --dart-define=BASE_URL=http://10.195.165.249:8000
  // Examples:
  //  - Local gateway on same machine: http://localhost:8000
  //  - LAN gateway from phone:       http://192.168.X.X:8000
  //  - Production public IP:         'http://16.16.143.243'

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
     defaultValue: 'http://173.249.12.47' 
     // local: port 8000, AWS: port 80
     //'http://192.168.0.104:8000'  //if local machine :'http://192.168.0.103:8000',  
  );
}


//ssh -i "C:\Users\Peter Wanyonyi\Downloads\fastapi-key.pem.pem" ubuntu@16.16.143.243
