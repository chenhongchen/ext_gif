import 'package:flutter_test/flutter_test.dart';
import 'package:ext_gif/ext_gif.dart';
import 'package:ext_gif/ext_gif_platform_interface.dart';
import 'package:ext_gif/ext_gif_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockExtGifPlatform
    with MockPlatformInterfaceMixin
    implements ExtGifPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ExtGifPlatform initialPlatform = ExtGifPlatform.instance;

  test('$MethodChannelExtGif is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelExtGif>());
  });
}
