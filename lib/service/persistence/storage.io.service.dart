

import 'package:path_provider/path_provider.dart';

class StorageIOService {
  String picturesPath;

  Future<String> getPicturesPath() async {
    if (picturesPath == null) {
      final appStorageDirectory = await getExternalStorageDirectory();
      picturesPath = appStorageDirectory.path + '/Pictures';;
    }

    return picturesPath;
  }
}
