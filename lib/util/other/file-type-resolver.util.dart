class FileTypeResolverUtil {
  static Map<String, String> types = {
    '.jpg': 'IMAGE',
    '.png': 'IMAGE',
    '.jpeg': 'IMAGE',
    '.mp4': 'MEDIA',
    '.mp3': 'MEDIA',
  };

  static resolve(String extension) {
    var type = types[extension];

    if (type == null) {
      type = 'FILE';
    }

    return type;
  }
}
