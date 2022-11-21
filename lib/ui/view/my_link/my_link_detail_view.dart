import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MyLinkDetailView extends StatefulWidget {
  const MyLinkDetailView({super.key});

  @override
  State<MyLinkDetailView> createState() => _MyLinkDetailViewState();
}

class _MyLinkDetailViewState extends State<MyLinkDetailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder(
                    future: _getOpenGraph('https://www.naver.com'),
                    builder: (BuildContext ctx, AsyncSnapshot snapshot) {
                      if (snapshot.hasData == false) {
                        return const CircularProgressIndicator();
                      } else {
                        return InkWell(
                          onTap: () async {
                            await launchUrl(Uri.parse('${snapshot.data['url']}'));
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 10,
                            child: Column(
                              children: [
                                ClipRRect(
                                  child: Image.network(
                                    '${snapshot.data['image']}',
                                    fit: BoxFit.fitWidth,
                                    width:
                                        MediaQuery.of(context).size.width - 48,
                                    height: 193,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(19, 23, 19, 33),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${snapshot.data['description']}',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontFamily: 'Pretendard',
                                        color: Color(0xFF13181E),
                                        letterSpacing: -0.2,
                                        fontWeight: FontWeight.w700,
                                      ),),
                                      const SizedBox(height: 7,),
                                      Text('${snapshot.data['url']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Pretendard',
                                          color: Color(0xFFC0C2C4),
                                          letterSpacing: -0.1,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 44,),
                  //date
                  const Text(
                    'Dec 10, 2021',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: grey400,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 22),
                    color: const Color(0xffecedee),
                    height: 1,
                    width: MediaQuery.of(context).size.width,
                  ),
                  const Text(
                    '설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명설명',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      color: grey700,
                      letterSpacing: -0.1,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    color: const Color(0xffecedee),
                    height: 1,
                    width: MediaQuery.of(context).size.width - 48,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 19, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            //TODO. 좋아요
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.favorite,
                              color: true ? primary600 : grey500,
                              size: 20,
                            ),
                          ),
                        ),
                        const Text(
                          '${32}',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.4,
                            color: grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<Map<String, String?>> _getOpenGraph(String link) async {

    final response = await http.get(Uri.parse(link));

    final document = MetadataFetch.responseToDocument(response);

    final og = MetadataParser.openGraph(document);

    return og.toMap();
  }

}
