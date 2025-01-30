import 'dart:io';

class FileUtils {
  static File createFileWithStringContent(String content, String path) {
    return File(path)..writeAsStringSync(content);
  }

  static File copyAndDeleteOriginalFile(String generatedFilePath, String targetDirectory, String targetName) {
    final fileOriginal = File(generatedFilePath);
    final fileCopy = File('$targetDirectory/$targetName.pdf');
    fileCopy.writeAsBytesSync(fileOriginal.readAsBytesSync());
    fileOriginal.delete();
    return fileCopy;
  }

  static void appendStyleTagToHtmlFile(String htmlPath) {
    // String printStyleHtml = """
    //   <style>
    //     @media print {
    //     * {
    //         -webkit-print-color-adjust: exact !important;
    //       }
    //     }
    //   </style>
    // """;
    // File(htmlPath).writeAsStringSync(printStyleHtml, mode: FileMode.append);
  }
}
