import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/util/favicon_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 링크 썸네일.
///
/// 동작 순서:
/// 1. [imageUrl] 이 있으면 먼저 시도
/// 2. 실패/없음 → [linkUrl] 에서 favicon 을 조회해 시도 ([useFavicon] true 일 때만)
/// 3. 그래도 없으면 [placeholder] (기본값: 링크 아이콘 placeholder)
///
/// favicon 조회 결과는 앱 세션 메모리에 캐시되어 같은 URL 에 대해 반복 호출되지 않는다.
///
/// 상세 화면처럼 저해상도 favicon 이 큰 영역을 채운 뒤 og:image 로 교체되는
/// 플리커를 피해야 하는 경우 [useFavicon] 을 false 로 준다.
class LinkThumbnail extends StatefulWidget {
  const LinkThumbnail({
    required this.imageUrl,
    required this.linkUrl,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.useFavicon = true,
  });

  final String? imageUrl;
  final String? linkUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final bool useFavicon;

  /// 테스트/초기화 용도의 캐시 클리어.
  @visibleForTesting
  static void clearCache() => _faviconCache.clear();

  @override
  State<LinkThumbnail> createState() => _LinkThumbnailState();
}

class _LinkThumbnailState extends State<LinkThumbnail> {
  String? _resolvedImage;
  bool _primaryFailed = false;

  @override
  void initState() {
    super.initState();
    final primary = widget.imageUrl;
    if (primary != null && primary.isNotEmpty) {
      _resolvedImage = primary;
    } else if (widget.useFavicon) {
      unawaited(_resolveFavicon());
    }
  }

  @override
  void didUpdateWidget(covariant LinkThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.linkUrl != widget.linkUrl ||
        oldWidget.useFavicon != widget.useFavicon) {
      _primaryFailed = false;
      final primary = widget.imageUrl;
      if (primary != null && primary.isNotEmpty) {
        _resolvedImage = primary;
      } else {
        _resolvedImage = null;
        if (widget.useFavicon) {
          unawaited(_resolveFavicon());
        }
      }
    }
  }

  Future<void> _resolveFavicon() async {
    final linkUrl = widget.linkUrl;
    if (linkUrl == null || linkUrl.isEmpty) return;

    final cached = _faviconCache[linkUrl];
    if (cached != null) {
      if (mounted) setState(() => _resolvedImage = cached.value);
      return;
    }

    final fetched = await FaviconLoader.fetch(linkUrl);
    _faviconCache[linkUrl] = _Cached(fetched);
    if (!mounted) return;
    setState(() => _resolvedImage = fetched);
  }

  void _onPrimaryError() {
    if (_primaryFailed) return;
    _primaryFailed = true;
    _resolvedImage = null;
    if (widget.useFavicon) {
      unawaited(_resolveFavicon());
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final content = _resolvedImage == null || _resolvedImage!.isEmpty
        ? _buildPlaceholder()
        : CachedNetworkImage(
            imageUrl: _resolvedImage!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            fadeInDuration: const Duration(milliseconds: 200),
            errorWidget: (_, __, ___) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onPrimaryError();
              });
              return _buildPlaceholder();
            },
          );

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: content,
        ),
      );
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: content,
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) return widget.placeholder!;
    return _DefaultPlaceholder(
      width: widget.width,
      height: widget.height,
    );
  }
}

class _DefaultPlaceholder extends StatelessWidget {
  const _DefaultPlaceholder({this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: grey100,
      alignment: Alignment.center,
      child: Icon(
        Icons.link_rounded,
        color: grey600,
        size: _iconSize(width, height),
      ),
    );
  }

  double _iconSize(double? w, double? h) {
    final base = [w, h].whereType<double>().fold<double>(
          0,
          (acc, v) => acc == 0 ? v : (v < acc ? v : acc),
        );
    if (base == 0) return 24.w;
    return (base * 0.4).clamp(16.w, 48.w);
  }
}

class _Cached {
  const _Cached(this.value);
  final String? value;
}

/// 앱 세션 동안 유지되는 링크 URL → favicon URL 캐시.
/// 실패한 경우도 value=null 로 저장해서 재시도하지 않는다.
final Map<String, _Cached> _faviconCache = {};
