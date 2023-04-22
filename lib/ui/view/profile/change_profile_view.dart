import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/ui/view/profile/profile_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChangeProfileView extends StatelessWidget {
  const ChangeProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetProfileInfoCubit, ProfileState>(
      builder: (context, state) {
        Profile? profile;
        if (state is ProfileLoadedState) {
          profile = state.profile;
        } else {
          profile = null;
        }
        if (profile == null) return const SizedBox.shrink();
        return ProfileSelector(
          profile: profile,
          onChangeProfile: (profileImage) {
            context
                .read<GetProfileInfoCubit>()
                .updateProfileImage(profileImage)
                .then((value) => Navigator.pop(context, value));
          },
        );
      },
    );
  }
}
