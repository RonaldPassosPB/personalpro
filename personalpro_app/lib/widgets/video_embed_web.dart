import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViewTypes = {};

Widget buildNativeWebVideoEmbed(String videoUrl, String? youtubeId) {
  final cleanUrl = videoUrl.trim();
  final viewType = 'personalpro-video-${cleanUrl.hashCode}-${youtubeId ?? "mp4"}';

  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      if (youtubeId != null && youtubeId.length == 11) {
        final iframe = web.HTMLIFrameElement()
          ..src =
              'https://www.youtube.com/embed/$youtubeId?rel=0&modestbranding=1&playsinline=1&autoplay=1&hl=pt-BR&cc_lang_pref=pt'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.borderRadius = '12px'
          ..allow =
              'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
          ..allowFullscreen = true;
        return iframe;
      } else {
        final video = web.HTMLVideoElement()
          ..src = cleanUrl
          ..controls = true
          ..autoplay = true
          ..loop = true
          ..muted = true
          ..playsInline = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.borderRadius = '12px'
          ..style.backgroundColor = '#000000';
        return video;
      }
    });
  }

  return HtmlElementView(viewType: viewType);
}
