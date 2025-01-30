// ignore_for_file: constant_identifier_names

enum PrintSize {
  A0,
  A1,
  A2,
  A3,
  A4,
  A5,
  A6,
  A7,
  A8,
  A9,
  A10,
}

extension PrintSizeExt on PrintSize {
  /// Returns the printing pixel dimensions for `72 PPI`
  List<int> get getDimensionsInPixels => switch (this) {
        PrintSize.A0 => [2384, 3370],
        PrintSize.A1 => [1684, 2384],
        PrintSize.A2 => [1191, 1684],
        PrintSize.A3 => [842, 1191],
        PrintSize.A4 => [595, 842],
        PrintSize.A5 => [420, 595],
        PrintSize.A6 => [298, 420],
        PrintSize.A7 => [210, 298],
        PrintSize.A8 => [147, 210],
        PrintSize.A9 => [105, 147],
        PrintSize.A10 => [74, 105]
      };

  /// Returns Key for android implementation
  String get printSizeKey => switch (this) {
        PrintSize.A0 => "A0",
        PrintSize.A1 => "A1",
        PrintSize.A2 => "A2",
        PrintSize.A3 => "A3",
        PrintSize.A4 => "A4",
        PrintSize.A5 => "A5",
        PrintSize.A6 => "A6",
        PrintSize.A7 => "A7",
        PrintSize.A8 => "A8",
        PrintSize.A9 => "A9",
        PrintSize.A10 => "A10"
      };
}

enum PrintOrientation { Portrait, Landscape }

extension PrintOrientationExt on PrintOrientation {
  /// Returns the index for getting width of print frame from array of
  int get getWidthDimensionIndex => switch (this) { PrintOrientation.Landscape => 1, PrintOrientation.Portrait => 0 };

  /// Returns the index for getting height of print frame from array of
  int get getHeightDimensionIndex => switch (this) { PrintOrientation.Landscape => 0, PrintOrientation.Portrait => 1 };

  /// Returns Key for android implementation
  String get orientationKey =>
      switch (this) { PrintOrientation.Landscape => "LANDSCAPE", PrintOrientation.Portrait => "PORTRAIT" };
}
