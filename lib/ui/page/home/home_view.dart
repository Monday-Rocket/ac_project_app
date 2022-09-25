import 'dart:convert';

import 'package:ac_project_app/cubits/weather_cubit.dart';
import 'package:ac_project_app/models/today_weather.dart';
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
    BlocProvider.of<WeatherCubit>(context).getTodayWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: BlocBuilder<WeatherCubit, TodayWeather?>(builder: (context, state) {
            if (state != null) {
              return Text(jsonEncode(state));
            } else {
              return const SizedBox(
                width: 100,
                height: 100,
                child: RepaintBoundary(
                  child: CircularProgressIndicator(
                    color: Colors.red,
                  ),
                ),
              );
            }
          },),
        ),
      ),
    );
  }
}
