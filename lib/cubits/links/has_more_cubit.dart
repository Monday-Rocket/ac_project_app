import 'package:flutter_bloc/flutter_bloc.dart';

class HasMoreCubit extends Cubit<ScrollableType> {
  HasMoreCubit(): super(ScrollableType.cannot);

}

enum ScrollableType {
  can, cannot
}
