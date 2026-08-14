import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppDocumentDatabasePath {
  const AppDocumentDatabasePath({this.fileName = 'networthy_spike.db'});

  final String fileName;

  Future<String> resolve() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, fileName);
  }
}
