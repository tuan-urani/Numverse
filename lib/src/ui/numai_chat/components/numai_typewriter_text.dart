import 'package:flutter/material.dart';

typedef NumAiTypewriterSpansBuilder =
    List<InlineSpan> Function(String visibleText, TextStyle baseStyle);

class NumAiTypewriterText extends StatefulWidget {
  const NumAiTypewriterText({
    required this.text,
    required this.baseStyle,
    required this.animate,
    this.spansBuilder,
    this.onCompleted,
    super.key,
  });

  final String text;
  final TextStyle baseStyle;
  final bool animate;
  final NumAiTypewriterSpansBuilder? spansBuilder;
  final VoidCallback? onCompleted;

  @override
  State<NumAiTypewriterText> createState() => _NumAiTypewriterTextState();
}

class _NumAiTypewriterTextState extends State<NumAiTypewriterText>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasReportedCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
    _applyAnimation();
  }

  @override
  void didUpdateWidget(covariant NumAiTypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text && oldWidget.animate == widget.animate) {
      return;
    }

    _controller.dispose();
    _controller = _buildController();
    _applyAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _buildVisibleText(widget.text);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        final int visibleLength = (widget.text.length * _controller.value)
            .round()
            .clamp(0, widget.text.length);
        final String visibleText = widget.text.substring(0, visibleLength);
        return _buildVisibleText(visibleText);
      },
    );
  }

  AnimationController _buildController() {
    final AnimationController controller = AnimationController(
      vsync: this,
      duration: _resolveDuration(widget.text.length),
    );
    controller.addStatusListener(_onAnimationStatusChanged);
    return controller;
  }

  void _applyAnimation() {
    if (!widget.animate) {
      _controller.value = 1;
      return;
    }
    if (widget.text.isEmpty) {
      _controller.value = 1;
      _notifyCompleted();
      return;
    }
    _hasReportedCompleted = false;
    _controller.forward(from: 0);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    _notifyCompleted();
  }

  void _notifyCompleted() {
    if (_hasReportedCompleted) {
      return;
    }
    _hasReportedCompleted = true;
    widget.onCompleted?.call();
  }

  Duration _resolveDuration(int length) {
    final int milliseconds = (length * 16).clamp(280, 2200);
    return Duration(milliseconds: milliseconds);
  }

  Widget _buildVisibleText(String text) {
    final NumAiTypewriterSpansBuilder? spansBuilder = widget.spansBuilder;
    if (spansBuilder == null) {
      return Text(text, style: widget.baseStyle);
    }

    return Text.rich(TextSpan(children: spansBuilder(text, widget.baseStyle)));
  }
}
