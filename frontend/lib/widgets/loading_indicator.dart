import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Loading indicator type
enum LoadingType {
  spinner,
  dots,
  bars,
  pulse,
  wave,
}

/// Enhanced loading indicator with multiple animation styles
class LoadingIndicator extends StatelessWidget {
  final LoadingType type;
  final double size;
  final Color? color;
  final String? message;
  final bool fullScreen;

  const LoadingIndicator({
    super.key,
    this.type = LoadingType.spinner,
    this.size = 48,
    this.color,
    this.message,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = _buildIndicator();

    if (fullScreen) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            indicator,
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dsTextSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Center(child: indicator);
  }

  Widget _buildIndicator() {
    switch (type) {
      case LoadingType.spinner:
        return _SpinnerIndicator(size: size, color: color);
      case LoadingType.dots:
        return _DotsIndicator(size: size, color: color);
      case LoadingType.bars:
        return _BarsIndicator(size: size, color: color);
      case LoadingType.pulse:
        return _PulseIndicator(size: size, color: color);
      case LoadingType.wave:
        return _WaveIndicator(size: size, color: color);
    }
  }
}

/// Spinning circle indicator
class _SpinnerIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const _SpinnerIndicator({required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size * 0.1,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? dsAccent,
        ),
      ),
    );
  }
}

/// Animated dots indicator
class _DotsIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const _DotsIndicator({required this.size, this.color});

  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? dsAccent;
    final dotSize = widget.size * 0.15;

    return SizedBox(
      width: widget.size,
      height: dotSize * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final delay = index * 0.15;
              final progress = (_controller.value - delay).clamp(0.0, 1.0);
              final scale = 0.5 + (progress * 0.5);
              final opacity = 0.3 + (progress * 0.7);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: dotSize * 0.5),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha:opacity),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Animated bars indicator
class _BarsIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const _BarsIndicator({required this.size, this.color});

  @override
  State<_BarsIndicator> createState() => _BarsIndicatorState();
}

class _BarsIndicatorState extends State<_BarsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? dsAccent;
    final barWidth = widget.size * 0.12;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(4, (index) {
              final delay = index * 0.1;
              final progress = (_controller.value - delay).clamp(0.0, 1.0);
              final heightFactor = 0.3 + (progress * 0.7);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: barWidth * 0.3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(barWidth / 2),
                  child: Container(
                    width: barWidth,
                    height: widget.size * heightFactor,
                    color: color,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Pulsing indicator
class _PulseIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const _PulseIndicator({required this.size, this.color});

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? dsAccent;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 0.5 + (_controller.value * 0.5);
          final opacity = 1.0 - _controller.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * scale,
                height: widget.size * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha:opacity),
                    width: 3,
                  ),
                ),
              ),
              Container(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Wave indicator
class _WaveIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const _WaveIndicator({required this.size, this.color});

  @override
  State<_WaveIndicator> createState() => _WaveIndicatorState();
}

class _WaveIndicatorState extends State<_WaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? dsAccent;
    final dotSize = widget.size * 0.15;

    return SizedBox(
      width: widget.size,
      height: dotSize * 2.5,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final delay = index * 0.1;
              final progress = (_controller.value - delay).clamp(0.0, 1.0);
              final offsetY = (progress * -1.0) * dotSize;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: dotSize * 0.3),
                child: Transform.translate(
                  offset: Offset(0, offsetY),
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
