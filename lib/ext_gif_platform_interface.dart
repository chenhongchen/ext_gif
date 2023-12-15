import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ext_gif_method_channel.dart';

abstract class ExtGifPlatform extends PlatformInterface {
  /// Constructs a ExtGifPlatform.
  ExtGifPlatform() : super(token: _token);

  static final Object _token = Object();

  static ExtGifPlatform _instance = MethodChannelExtGif();

  /// The default instance of [ExtGifPlatform] to use.
  ///
  /// Defaults to [MethodChannelExtGif].
  static ExtGifPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ExtGifPlatform] when
  /// they register themselves.
  static set instance(ExtGifPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
