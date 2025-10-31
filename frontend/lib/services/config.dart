// lib/services/config.dart

class ApiConfig {
  // Set via: flutter run --dart-define=BASE_URL=http://192.168.1.50:8000
  //From phone on same Wi‑Fi: flutter run --dart-define=BASE_URL=http://10.195.165.249:8000
  // Examples:
  //  - Local gateway on same machine: http://localhost:8000
  //  - LAN gateway from phone:       http://192.168.X.X:8000
  //  - Production public IP:         http://152.70.28.112
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
     defaultValue: 'http://16.16.124.14:8000', // ✅ Public AWS VM IP //if local machine :'http://192.168.0.103:8000', //if oracle: 'http://152.70.28.112', 
  );
}
//

//ssh -i "C:\Users\Peter Wanyonyi\Downloads\fastapi-key.pem.pem" ubuntu@16.16.124.14