/// Converts Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩) to Western-Arabic digits (0-9).
/// Leaves all other characters unchanged.
String arabicToEnglishDigits(String s) {
  return s
      .replaceAll('٠', '0')
      .replaceAll('١', '1')
      .replaceAll('٢', '2')
      .replaceAll('٣', '3')
      .replaceAll('٤', '4')
      .replaceAll('٥', '5')
      .replaceAll('٦', '6')
      .replaceAll('٧', '7')
      .replaceAll('٨', '8')
      .replaceAll('٩', '9');
}
