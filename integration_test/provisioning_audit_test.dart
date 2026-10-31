// Runs the same spec assertions on Android, with real Flutter platform bindings.
// No backend, Firebase authentication or actual ESP32 is involved in this test.
import 'package:integration_test/integration_test.dart';
import '../audit_tests/provisioning_requirements_test.dart' as requirements;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  requirements.main();
}
