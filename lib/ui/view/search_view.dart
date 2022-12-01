// ignore_for_file: avoid_positional_boolean_parameters

import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final textController = TextEditingController();
  bool buttonState = false;
  bool searchState = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() {
            searchState = false;
          });
        }
      },
      child: KeyboardVisibilityBuilder(
        builder: (context, visible) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios_new),
                color: grey900,
                padding: const EdgeInsets.only(left: 24, right: 8),
              ),
              title: searchState ? buildSearchBar() : buildEmptySearchBar(),
              titleSpacing: 0,
              actions: [
                Center(
                  child: GestureDetector(
                    onTap: buttonState ? () {} : null,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 10, right: 22, top: 8, bottom: 8),
                      child: Text(
                        '검색',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: buttonState ? grey800 : grey300,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildSearchBar() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        child: Container(
          decoration: const BoxDecoration(
            color: grey100,
            borderRadius: BorderRadius.all(Radius.circular(7)),
          ),
          height: 36,
          margin: const EdgeInsets.only(right: 6),
          child: Center(
            child: TextField(
              textAlignVertical: TextAlignVertical.center,
              controller: textController,
              cursorColor: grey800,
              autofocus: true,
              style: const TextStyle(
                color: grey800,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                hintText: '검색어를 입력해주세요',
                hintStyle: TextStyle(
                  fontSize: 14,
                  letterSpacing: -0.1,
                  height: 18 / 14,
                  color: grey700,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  buttonState = value.isNotEmpty;
                });
                // context.read<GetFoldersCubit>().filter(value);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEmptySearchBar() {
    return GestureDetector(
      onTap: () {
        setState(() {
          searchState = true;
        });
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(left: 10),
          child: Container(
            decoration: const BoxDecoration(
              color: grey100,
              borderRadius: BorderRadius.all(Radius.circular(7)),
            ),
            height: 36,
            margin: const EdgeInsets.only(right: 6),
            child: Center(
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 10, right: 10),
                    child: Image.asset(
                      'assets/images/folder_search_icon.png',
                    ),
                  ),
                  const Text(
                    '검색어를 입력해주세요',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      letterSpacing: -0.1,
                      height: 18 / 14,
                      color: grey700,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
