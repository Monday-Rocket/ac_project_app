import 'package:ac_project_app/cubits/url_data_cubit.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<UrlDataCubit>(context).loadUrls();// 처음에 그냥 호출
  }

  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final metadataList = context.watch<UrlDataCubit>().state;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  color: Colors.black,
                  height: 400,
                  child: ListView.builder(
                    itemCount: metadataList.length,
                    itemBuilder: (_, index) {
                      return GestureDetector(
                        onTap: () {
                          Log.i(metadataList[index].url);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: ColoredBox(
                            color: Colors.black,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(
                                  metadataList[index].image ?? '',
                                  errorBuilder: (_, __, ___) {
                                    return const Icon(Icons.error);
                                  },
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'title: ${metadataList[index].title ?? ''}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Text(
                                  'des: ${metadataList[index].description ?? ''}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
