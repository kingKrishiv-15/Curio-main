import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_ui.dart';
import 'auth_layout.dart';
import 'auth_page.dart';
import 'widgets/welcome_art.dart';

/// Three short slides that explain Curio before a parent is asked for an
/// email. Shown once per device; "Get started" goes straight to sign-up
/// after that.
class IntroPage extends StatefulWidget {
  const IntroPage({required this.authService, super.key});
  final AuthService authService;

  static const _seenKey = 'curio_intro_seen';

  static Future<bool> hasBeenSeen() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_seenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _markSeen() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_seenKey, true);
    } catch (_) {
      // Best effort: worst case the intro shows once more.
    }
  }

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _Slide {
  const _Slide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.skill,
    required this.art,
  });

  final String eyebrow, title, body;
  final WelcomeSkill skill;
  final Widget Function(double height) art;
}

final _slides = [
  _Slide(
    eyebrow: 'Play',
    title: 'Five minutes.\nOne big idea.',
    body:
        'A fresh game in Maths, Memory, English and Logic every day. Pick a little adventure, think it through and earn points for your daily play.',
    skill: WelcomeSkill.all[0],
    art: (h) => GameFanArt(height: h),
  ),
  _Slide(
    eyebrow: 'Discover',
    title: 'Every win unlocks a discovery.',
    body:
        'Finish a game and a surprising fact joins their collection. Come back tomorrow to keep the streak glowing.',
    skill: WelcomeSkill.all[1],
    art: (h) => DiscoveryArt(height: h),
  ),
  _Slide(
    eyebrow: 'Grow',
    title: 'You’ll see the growth, too.',
    body:
        'A calm parent view shows which skills are growing — with gentle reminders and an optional weekly email, all on your terms.',
    skill: WelcomeSkill.all[2],
    art: (h) => GrowthArt(height: h),
  ),
];

class _IntroPageState extends State<IntroPage> {
  final _pages = PageController();
  int _index = 0;

  bool get _last => _index == _slides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish({AuthMode mode = AuthMode.signUp}) async {
    await IntroPage._markSeen();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      authRoute(AuthPage(authService: widget.authService, mode: mode)),
    );
  }

  void _next() {
    if (_last) {
      _finish();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(_index + 1);
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CurioPage(
      maxWidth: 1160,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 880;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Center(child: CurioLogo(markSize: 28)),
                    ),
                    AnimatedOpacity(
                      opacity: _last ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: TextButton(
                        onPressed: _last ? null : _finish,
                        child: const Text('Skip'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) =>
                      _SlideView(slide: _slides[i], wide: wide, position: i),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, wide ? 32 : 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _Dots(count: _slides.length, index: _index),
                          const Spacer(),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              '${_index + 1} of ${_slides.length}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('intro_next'),
                        onPressed: _next,
                        child: Text(_last ? 'Create a family account' : 'Next'),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => _finish(mode: AuthMode.signIn),
                        child: const Text('I already have an account'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.wide,
    required this.position,
  });

  final _Slide slide;
  final bool wide;
  final int position;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CurioEyebrow(slide.eyebrow, color: slide.skill.ink(context)),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            slide.title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: wide ? 48 : 34,
              height: 1.04,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          slide.body,
          style: TextStyle(color: muted, height: 1.6, fontSize: wide ? 17 : 15),
        ),
      ],
    );
    final art = LayoutBuilder(
      builder: (context, constraints) {
        final height = math.min(
          math.min(constraints.maxHeight * .9, constraints.maxWidth / 1.55),
          wide ? 380.0 : 290.0,
        );
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: slide.art(math.max(height, 140)),
          ),
        );
      },
    );
    if (wide) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          children: [
            Expanded(child: art),
            const SizedBox(width: 40),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: text,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Short screens and large text get a scrollable column instead of a
        // squeezed one; everyone else gets art filling the space above.
        final roomy = constraints.maxHeight >= 520;
        final content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: text,
        );
        if (!roomy) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 220, child: art),
                const SizedBox(height: 12),
                content,
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: art),
            const SizedBox(height: 12),
            Flexible(flex: 0, child: SingleChildScrollView(child: content)),
          ],
        );
      },
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count, index;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final idle = curioColor(
      context,
      CurioColors.outline,
      CurioColorsLight.outline,
    );
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 6),
              width: i == index ? 26 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? coral : idle,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }
}
