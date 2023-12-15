import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ext_gif_platform_interface.dart';

/// An implementation of [ExtGifPlatform] that uses method channels.
class MethodChannelExtGif extends ExtGifPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ext_gif');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
