// O MVP atende uma cidade só, sem consultar todos os postos no Firestore.
import 'package:completai/shared/models/service_area.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cidade atendida no MVP é somente Bebedouro', () {
    expect(ServiceArea.primaryCity, 'Bebedouro');
    expect(ServiceArea.cities, const ['Bebedouro']);
  });
}
