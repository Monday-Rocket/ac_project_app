import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/oss_licenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class OssLicensesView extends StatelessWidget {
  const OssLicensesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '오픈소스 라이센스',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: SvgPicture.asset(Assets.images.icBack, width: 24.w, height: 24.w, fit: BoxFit.cover,),
          padding: EdgeInsets.only(left: 20.w, right: 8.w),
        ),
        leadingWidth: 44.w,
        toolbarHeight: 48.w,
      ),
      body: ListView.builder(
        itemCount: allDependencies.length,
        itemBuilder: (context, index) {
          final package = allDependencies[index];
          return ListTile(
            title: Text('${package.name} ${package.version}'),
            subtitle: package.description.isNotEmpty
                ? Text(package.description)
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<dynamic>(
                builder: (context) => MiscOssLicenseSingle(package: package),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MiscOssLicenseSingle extends StatelessWidget {
  const MiscOssLicenseSingle({required this.package, super.key});

  final Package package;

  String _bodyText() {
    return package.license!.split('\n').map((line) {
      if (line.startsWith('//')) line = line.substring(2);
      return line.trim();
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              '${package.name} ${package.version}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: SvgPicture.asset(Assets.images.icBack, width: 24.w, height: 24.w, fit: BoxFit.cover,),
          padding: EdgeInsets.only(left: 20.w, right: 8.w),
        ),
        leadingWidth: 44.w,
        toolbarHeight: 48.w,
      ),
      backgroundColor: Colors.white,
      body: ColoredBox(
        color: Colors.white,
        child: ListView(
          children: <Widget>[
            if (package.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                child: Text(
                  package.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            if (package.homepage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                child: InkWell(
                  child: Text(
                    package.homepage!,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () => launchUrl(
                    Uri.parse(package.homepage ?? ''),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            if (package.description.isNotEmpty || package.homepage != null)
              const Divider(),
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
              child: Text(
                _bodyText(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
