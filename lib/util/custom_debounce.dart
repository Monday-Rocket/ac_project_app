import 'dart:async';
import 'dart:ui';


// https://medium.com/@jhonmunozromero/how-to-create-and-use-a-debounce-in-flutter-c84e7726b2e3
class CustomDebounce {
  // constructor
  CustomDebounce({required this.delay});

  // allow to choose a duration when an instance is created
  final Duration delay;

  // create a timer to measure the execution time inside the callback function in call method
  Timer? _timer;

  // use call to allow CustomDebounce instance acting as a function
  void call(VoidCallback callback) {
    // if already exists a timer when user types,
    // the timer must be canceled to avoid the previous callback
    _timer?.cancel();
    // when the user stops typing, the last timer created will not be canceled
    // and callback will be excecuted
    _timer = Timer(delay, callback);
  }

  void dispose() {
    // timer should be dispose
    _timer?.cancel();
  }
}
