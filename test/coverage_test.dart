/// *** GENERATED FILE - ANY CHANGES WOULD BE OBSOLETE ON NEXT GENERATION *** ///

/// Helper to test coverage for all project files
import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/consts.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/feed/feed_view_cubit.dart';
import 'package:ac_project_app/cubits/folders/folder_name_cubit.dart';
import 'package:ac_project_app/cubits/folders/folder_view_type_cubit.dart';
import 'package:ac_project_app/cubits/folders/folder_visible_cubit.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_selected_folder_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/home/get_job_list_cubit.dart';
import 'package:ac_project_app/cubits/home/search_links_cubit.dart';
import 'package:ac_project_app/cubits/home/topic_list_state.dart';
import 'package:ac_project_app/cubits/home_second_view_cubit.dart';
import 'package:ac_project_app/cubits/home_view_cubit.dart';
import 'package:ac_project_app/cubits/links/detail_edit_cubit.dart';
import 'package:ac_project_app/cubits/links/edit_state.dart';
import 'package:ac_project_app/cubits/links/feed_data_state.dart';
import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_folder_cubit.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_job_group_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_link_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_result_state.dart';
import 'package:ac_project_app/cubits/login/login_cubit.dart';
import 'package:ac_project_app/cubits/login/login_type.dart';
import 'package:ac_project_app/cubits/login/login_user_state.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/cubits/profile/selected_image_cubit.dart';
import 'package:ac_project_app/cubits/report/report_cubit.dart';
import 'package:ac_project_app/cubits/scroll/scroll_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/button_state_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/job_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/job_list_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/nickname_check_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/nickname_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/sign_up_cubit.dart';
import 'package:ac_project_app/cubits/tool_tip/my_link_upload_tool_tip_cubit.dart';
import 'package:ac_project_app/cubits/tool_tip/upload_tool_tip_cubit.dart';
import 'package:ac_project_app/cubits/url_data_cubit.dart';
import 'package:ac_project_app/enums/navigator_pop_type.dart';
import 'package:ac_project_app/firebase_options.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/gen/fonts.gen.dart';
import 'package:ac_project_app/initial_settings.dart';
import 'package:ac_project_app/main.dart';
import 'package:ac_project_app/models/feed/feed_data.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/job/topic.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/models/link/upload_type.dart';
import 'package:ac_project_app/models/login/login_type.dart';
import 'package:ac_project_app/models/net/api_error.dart';
import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/models/report/report.dart';
import 'package:ac_project_app/models/report/report_result_type.dart';
import 'package:ac_project_app/models/report/report_type.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/models/tutorial/tutorial.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/models/user/user.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/provider/api/report/report_api.dart';
import 'package:ac_project_app/provider/api/user/profile_api.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/comment_temp_data_provider.dart';
import 'package:ac_project_app/provider/login/apple_login.dart';
import 'package:ac_project_app/provider/login/email_login.dart';
import 'package:ac_project_app/provider/login/email_password.dart';
import 'package:ac_project_app/provider/login/firebase_auth_remote_data_source.dart';
import 'package:ac_project_app/provider/login/google_login.dart';
import 'package:ac_project_app/provider/login/kakao_login.dart';
import 'package:ac_project_app/provider/login/naver_login.dart';
import 'package:ac_project_app/provider/logout.dart';
import 'package:ac_project_app/provider/profile_images.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:ac_project_app/provider/tool_tip_check.dart';
import 'package:ac_project_app/routes.dart';
// ignore_for_file: unused_import
import 'package:ac_project_app/ui/page/home/home_page.dart';
import 'package:ac_project_app/ui/page/my_folder/folder_visible_state.dart';
import 'package:ac_project_app/ui/page/my_folder/my_folder_page.dart';
import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/ui/view/home_view.dart';
import 'package:ac_project_app/ui/view/links/link_detail_view.dart';
import 'package:ac_project_app/ui/view/links/my_link_view.dart';
import 'package:ac_project_app/ui/view/links/search_view.dart';
import 'package:ac_project_app/ui/view/links/user_feed_view.dart';
import 'package:ac_project_app/ui/view/profile/change_profile_view.dart';
import 'package:ac_project_app/ui/view/profile/profile_selector.dart';
import 'package:ac_project_app/ui/view/report_view.dart';
import 'package:ac_project_app/ui/view/splash_view.dart';
import 'package:ac_project_app/ui/view/terms_view.dart';
import 'package:ac_project_app/ui/view/tutorial_view.dart';
import 'package:ac_project_app/ui/view/upload_view.dart';
import 'package:ac_project_app/ui/view/user/email_login_view.dart';
import 'package:ac_project_app/ui/view/user/login_view.dart';
import 'package:ac_project_app/ui/view/user/sign_up_job_view.dart';
import 'package:ac_project_app/ui/view/user/sign_up_nickname_view.dart';
import 'package:ac_project_app/ui/widget/add_folder/folder_add_title.dart';
import 'package:ac_project_app/ui/widget/add_folder/horizontal_folder_list.dart';
import 'package:ac_project_app/ui/widget/add_folder/subtitle.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/buttons/apple/apple_login_button.dart';
import 'package:ac_project_app/ui/widget/buttons/apple/apple_logo_painter.dart';
import 'package:ac_project_app/ui/widget/buttons/bottom_sheet_button.dart';
import 'package:ac_project_app/ui/widget/custom_reorderable_list_view.dart';
import 'package:ac_project_app/ui/widget/only_back_app_bar.dart';
import 'package:ac_project_app/ui/widget/scaffold_with_tool_tip.dart';
import 'package:ac_project_app/ui/widget/shape/reverse_triangle_painter.dart';
import 'package:ac_project_app/ui/widget/shape/triangle_painter.dart';
import 'package:ac_project_app/ui/widget/slidable/link_slidable_widget.dart';
import 'package:ac_project_app/ui/widget/sliver/custom_header_delegate.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:ac_project_app/ui/widget/user/user_info.dart';
import 'package:ac_project_app/ui/widget/widget_offset.dart';
import 'package:ac_project_app/util/date_utils.dart';
import 'package:ac_project_app/util/fade_page_route.dart';
import 'package:ac_project_app/util/get_arguments.dart';
import 'package:ac_project_app/util/get_screen_mode.dart';
import 'package:ac_project_app/util/list_utils.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/number_commas.dart';
import 'package:ac_project_app/util/offset_utils.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:ac_project_app/util/url_valid.dart';

void main() {}
