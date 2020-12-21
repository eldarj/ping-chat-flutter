
extension DurationExtension on Duration {
  String format() {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(this.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(this.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
