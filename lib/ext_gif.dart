library ext_gif;

import 'dart:async';
import 'dart:ui';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

final Client _sharedHttpClient = Client();

Client get _httpClient {
  Client client = _sharedHttpClient;
  return client;
}

/// How to auto start the gif.
enum Autostart {
  /// Don't start.
  no,

  /// Run once everytime a new gif is loaded.
  once,

  /// Loop playback.
  loop,
}

class CachedInfo {
  List<FrameInfo> image;
  Uint8List bytes;

  CachedInfo(this.image, this.bytes);
}

class ExtGifCached {
  // 工厂模式
  factory ExtGifCached() => _getInstance();

  static ExtGifCached get instance => _getInstance();
  static ExtGifCached? _instance;

  ExtGifCached._internal() {
    // 初始化
  }

  static ExtGifCached _getInstance() {
    _instance ??= ExtGifCached._internal();
    return _instance!;
  }

  final Map<Object, CachedInfo> _cache = <Object, CachedInfo>{};

  CachedInfo? get(Object key) => _cache[key];

  void add(Object key, CachedInfo cachedInfo) => _cache[key] = cachedInfo;

  bool remove(Object key) => _cache.remove(key) != null ? true : false;

  void clear() => _cache.clear();

  bool contain(Object key) {
    return _cache[key] != null;
  }

  int get maximumSize => _maximumSize;
  int _maximumSize = 100;

  set maximumSize(int value) {
    assert(value >= 0);
    if (value == maximumSize) {
      return;
    }
    _maximumSize = value;
    if (maximumSize == 0) {
      clear();
    } else {
      _checkCacheSize();
    }
  }

  int get maximumSizeBytes => _maximumSizeBytes;
  int _maximumSizeBytes = 50 << 20; // 50 MiB
  set maximumSizeBytes(int value) {
    assert(value >= 0);
    if (value == _maximumSizeBytes) {
      return;
    }
    _maximumSizeBytes = value;
    if (_maximumSizeBytes == 0) {
      clear();
    } else {
      _checkCacheSize();
    }
  }

  int get currentSizeBytes => _currentSizeBytes;
  int _currentSizeBytes = 0;

  // Remove images from the cache until both the length and bytes are below
  // maximum, or the cache is empty.
  void _checkCacheSize() {
    while (
        _currentSizeBytes > _maximumSizeBytes || _cache.length > _maximumSize) {
      final Object key = _cache.keys.first;
      final CachedInfo cachedInfo = _cache[key]!;
      _currentSizeBytes -= cachedInfo.bytes.length;
      _cache.remove(key);
    }
    assert(_currentSizeBytes >= 0);
    assert(_cache.length <= maximumSize);
    assert(_currentSizeBytes <= maximumSizeBytes);
  }
}

///
/// A widget that renders a Gif controllable with [AnimationController].
///
@immutable
class ExtGif extends StatefulWidget {
  /// [ImageProvider] of this gif. Like [NetworkImage], [AssetImage], [MemoryImage]
  final ImageProvider image;

  /// This playback controller.
  final ExtGifController? controller;

  /// If and how to start this gif.
  final Autostart autostart;

  /// Rendered when gif frames fetch is still not completed.
  final Widget Function(BuildContext context)? placeholder;

  /// Called when gif frames fetch is completed.
  final VoidCallback? onFetchCompleted;

  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect? centerSlice;
  final bool matchTextDirection;
  final String? semanticLabel;
  final bool excludeFromSemantics;

  /// Creates a widget that displays a controllable gif.
  ///
  /// [fps] frames per second at which this should be rendered.
  ///
  /// [duration] whole playback duration for this gif.
  ///
  /// [autostart] if and how to start this gif. Defaults to [Autostart.no].
  ///
  /// [placeholder] this widget is rendered during the gif frames fetch.
  ///
  /// [onFetchCompleted] is called when the frames fetch finishes and the gif can be
  /// rendered.
  ///
  /// Only one of the two can be set: [fps] or [duration]
  /// If [controller.duration] and [fps] are not specified, the original gif
  /// framerate will be used.
  const ExtGif({
    Key? key,
    required this.image,
    this.controller,
    this.autostart = Autostart.no,
    this.placeholder,
    this.onFetchCompleted,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
  }) : super(key: key);

  @override
  State<ExtGif> createState() => _ExtGifState();

  static startCache(ImageProvider provider, {String? cacheKey}) {
    if (cacheKey == null) return;
    if (ExtGifCached.instance.contain(cacheKey)) return;
    _fetchFrames(provider, cacheKey: cacheKey);
  }

  /// Fetches the single gif frames and saves them into the [GifCache] of [ExtGif]
  static Future<List<FrameInfo>> _fetchFrames(ImageProvider provider,
      {String? cacheKey}) async {
    late final Uint8List bytes;

    if (provider is ExtendedNetworkImageProvider) {
      Uint8List? temBytes = await provider.getNetworkImageData();
      if (temBytes == null) {
        return [];
      } else {
        bytes = temBytes;
      }
    } else if (provider is NetworkImage) {
      final Uri resolved = Uri.base.resolve(provider.url);
      final Response response = await _httpClient.get(
        resolved,
        headers: provider.headers,
      );
      bytes = response.bodyBytes;
    } else if (provider is AssetImage) {
      AssetBundleImageKey key =
          await provider.obtainKey(const ImageConfiguration());
      bytes = (await key.bundle.load(key.name)).buffer.asUint8List();
    } else if (provider is FileImage) {
      bytes = await provider.file.readAsBytes();
    } else if (provider is MemoryImage) {
      bytes = provider.bytes;
    }

    final buffer = await ImmutableBuffer.fromUint8List(bytes);
    Codec codec = await PaintingBinding.instance.instantiateImageCodecWithSize(
      buffer,
    );
    List<FrameInfo> frames = [];

    for (int i = 0; i < codec.frameCount; i++) {
      FrameInfo frameInfo = await codec.getNextFrame();
      frames.add(frameInfo);
    }

    if (frames.isNotEmpty && cacheKey != null) {
      ExtGifCached.instance.add(cacheKey, CachedInfo(frames, bytes));
    }

    return frames;
  }
}

///
/// Controller that wraps [AnimationController] and protects the [duration] parameter.
/// This falls into a design choice to keep the duration control to the [ExtGif]
/// widget.
///
class ExtGifController {
  _ExtGifState? _state;

  repeat() {
    _state?._repeat();
  }

  forward() {
    _state?._forward();
  }

  reset() {
    _state?._reset();
  }

  stop() {
    _state?._stop();
  }

  ExtGifController();

  dispose() {
    _state = null;
  }
}

class _ExtGifState extends State<ExtGif> with SingleTickerProviderStateMixin {
  late ExtGifController _controller;
  int? _curKey;

  /// List of [FrameInfo] of every frame of this gif.
  List<FrameInfo> _frames = [];

  int _frameIndex = 0;

  /// Current rendered frame.
  FrameInfo? _frame;
  String? _cacheKey;

  String? get cacheKey {
    if (_cacheKey != null) return _cacheKey!;
    ImageProvider provider = widget.image;
    if (provider is ExtendedNetworkImageProvider) {
      _cacheKey = provider.url;
    } else if (provider is NetworkImage) {
      _cacheKey = provider.url;
    } else if (provider is AssetImage) {
      _cacheKey = provider.keyName;
    } else if (provider is FileImage) {
      _cacheKey = provider.file.path;
    }
    return _cacheKey;
  }

  @override
  Widget build(BuildContext context) {
    if (_frame == null) {
      _loadFramesFromCache();
    }
    final RawImage image = RawImage(
      image: _frame?.image,
      width: widget.width,
      height: widget.height,
      scale: 1.0,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
    );
    return widget.placeholder != null && _frame == null
        ? widget.placeholder!(context)
        : widget.excludeFromSemantics
            ? image
            : Semantics(
                container: widget.semanticLabel != null,
                image: true,
                label: widget.semanticLabel ?? '',
                child: image,
              );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFrames().then((value) => _autostart());
  }

  @override
  void didUpdateWidget(ExtGif oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller._state = null;
    _controller = widget.controller ?? ExtGifController();
    _controller._state = this;
    if (widget.image != oldWidget.image) {
      _frames = [];
      _frame = null;
      _frameIndex = 0;
      _loadFrames().then((value) {
        _autostart();
      });
    } else if ((widget.autostart != oldWidget.autostart)) {
      _autostart();
    }
  }

  @override
  void dispose() {
    _controller._state = null;
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ExtGifController();
    _controller._state = this;
  }

  /// Start this gif according to [widget.autostart] and [widget.loop].
  void _autostart() {
    if (_frames.length <= 1) {
      return;
    }
    if (mounted && widget.autostart != Autostart.no) {
      // _reset();
      if (widget.autostart == Autostart.loop) {
        _repeat();
      } else {
        _forward();
      }
    } else {
      _stop();
    }
  }

  _repeat() {
    if (_frames.length <= 1) {
      _curKey = null;
      return;
    }
    int key = DateTime.now().microsecondsSinceEpoch;
    _curKey = key;
    _repeatWithKey(key);
  }

  void _repeatWithKey(int key) {
    if (key != _curKey) return;
    _frameIndex = _frameIndex + 1; // 更新帧的索引
    if (_frameIndex >= _frames.length) {
      _frameIndex = 0;
    }
    _frame = _frames[_frameIndex];
    setState(() {});
    Timer(_frame!.duration, () {
      _repeatWithKey(key);
    });
  }

  void _forward() {
    if (_frames.length <= 1) {
      _curKey = null;
      return;
    }
    int key = DateTime.now().microsecondsSinceEpoch;
    _curKey = key;
    _forwardWithKey(key);
  }

  void _forwardWithKey(int key) {
    if (key != _curKey) return;
    _frameIndex = _frameIndex + 1; // 更新帧的索引
    if (_frameIndex >= _frames.length) {
      _frameIndex = _frames.length - 1;
    }
    _frame = _frames[_frameIndex];
    setState(() {});
    if (_frameIndex == _frames.length - 1) {
      _curKey = null;
      return;
    }
    Timer(_frame!.duration, () {
      _forwardWithKey(key);
    });
  }

  void _stop() {
    _curKey = null;
    if (_frames.length <= 1) {
      return;
    }
    // _reset();
  }

  void _reset() {
    if (_frames.length <= 1) {
      return;
    }
    _frameIndex = 0;
    setState(() {});
  }

  _loadFramesFromCache() {
    if (cacheKey == null) return;
    CachedInfo? cachedInfo = ExtGifCached.instance.get(cacheKey!);
    if (cachedInfo != null) {
      ExtGifCached.instance.remove(cacheKey!);
      _frames = cachedInfo.image;
      if (_frames.isNotEmpty && _frameIndex < _frames.length) {
        _frame = _frames[_frameIndex];
      }
      ExtGifCached.instance.add(cacheKey!, cachedInfo);
      if (widget.onFetchCompleted != null) {
        widget.onFetchCompleted!();
      }
    }
  }

  /// Fetches the frames with [_fetchFrames] and saves them into [_frames].
  ///
  /// When [_frames] is updated [onFetchCompleted] is called.
  Future<void> _loadFrames() async {
    if (!mounted) return;

    _loadFramesFromCache();
    if (_frame != null) return;

    List<FrameInfo> frames =
        await ExtGif._fetchFrames(widget.image, cacheKey: cacheKey);

    if (!mounted) return;

    setState(() {
      _frames = frames;
      if (_frames.isNotEmpty) {
        _frame = _frames.first;
        _frameIndex = 0;
      }
      if (widget.onFetchCompleted != null) {
        widget.onFetchCompleted!();
      }
    });
  }
}
