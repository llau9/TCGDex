import 'dart:io';

void main() {
  final credentialsPath = 'C:\\Users\\rossg\\Downloads\\reference-glass-429314-g8-b3210b4c2db5.json';
  final credentialsFile = File(credentialsPath);

  if (credentialsFile.existsSync()) {
    print('Credentials file exists.');
  } else {
    print('Credentials file does not exist.');
  }
}