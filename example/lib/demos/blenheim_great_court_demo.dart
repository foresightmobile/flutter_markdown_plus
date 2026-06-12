// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../shared/markdown_demo_widget.dart';

// ignore_for_file: public_member_api_docs

// The rich, formatted version of the tour shown on screen as Markdown.
const String _tourMarkdown = """
# The Great Court

Welcome to **The Great Court** — the vast paved forecourt that greets every
visitor to Blenheim Palace. Stand for a moment and take it in: this is one of
the grandest entrance courts in England, deliberately designed to take your
breath away before you ever step inside.

## Where you are standing

You have come through the **East Gate** into an enormous open square, roughly
the size of several football pitches. Ahead of you rises the **north (entrance)
front** of the palace, with its great **Corinthian portico** and pediment. To
your left and right, long, low **colonnades** sweep outward and curve around to
enclose the court, linking the main house to its two great service ranges — the
**kitchen court** on one side and the **stable court** on the other.

Look up at the rooflines. Those soaring **finials** and carved ornaments are
not just decoration — many take the form of the **ducal coronet** and the
**fleur-de-lis** from the Marlborough coat of arms. The whole court is a piece
of theatre in stone.

## What to look for

- **The portico and pediment** straight ahead — the ceremonial front door of
  the palace, framed by towering columns.
- **The colonnades** curving around you — walk along them and notice how they
  frame views back across the court.
- **The Clock Tower and Bell Tower** above the flanking courts.
- **The honey-coloured stone**, quarried locally, which glows golden in the
  afternoon sun.
- The sheer **scale and symmetry** — everything is balanced left to right,
  pulling your eye toward the centre.

## A little history

Blenheim Palace was a **gift from Queen Anne and a grateful nation** to **John
Churchill, the 1st Duke of Marlborough**, to reward his great victory at the
**Battle of Blenheim in 1704**, during the War of the Spanish Succession.

The palace was designed by the playwright-turned-architect **Sir John
Vanbrugh**, working with **Nicholas Hawksmoor**, and built between **1705 and
1722** in the dramatic **English Baroque** style. It is the only non-royal,
non-episcopal country house in England to hold the title of *palace*, and it is
a **UNESCO World Heritage Site**.

It is also the **birthplace of Sir Winston Churchill**, born here in 1874 — a
fine fact to share with the family as you look up at the great front.

> *Tip:* Turn around and look back at the East Gate the way you came in — the
> court is designed to be impressive in **both** directions.

---

*Press **Play audio overview** at the top of the screen to hear this tour read
aloud, so you can keep your eyes on the palace while you listen.*
""";

// A plain-text narration script for text-to-speech. Kept separate from the
// Markdown so the spoken version flows naturally without symbols or headings.
const String _tourNarration =
    'Welcome to the Great Court of Blenheim Palace. '
    'You are standing in one of the grandest entrance courts in England, '
    'designed to take your breath away before you ever step inside. '
    'You have come through the East Gate into an enormous open square. '
    'Ahead of you rises the north front of the palace, with its great '
    'Corinthian portico and pediment. To your left and right, long, low '
    'colonnades sweep outward and curve around to enclose the court, linking '
    'the main house to its two great service ranges: the kitchen court on one '
    'side and the stable court on the other. '
    'Look up at the rooflines. Those soaring finials and carved ornaments are '
    'not just decoration. Many take the form of the ducal coronet and the '
    'fleur-de-lis from the Marlborough coat of arms. The whole court is a piece '
    'of theatre in stone. '
    'A little history. Blenheim Palace was a gift from Queen Anne and a '
    'grateful nation to John Churchill, the first Duke of Marlborough, to '
    'reward his great victory at the Battle of Blenheim in 1704, during the War '
    'of the Spanish Succession. '
    'The palace was designed by the playwright turned architect Sir John '
    'Vanbrugh, working with Nicholas Hawksmoor, and built between 1705 and 1722 '
    'in the dramatic English Baroque style. It is the only non-royal, '
    'non-episcopal country house in England to hold the title of palace, and it '
    'is a UNESCO World Heritage Site. '
    'It is also the birthplace of Sir Winston Churchill, born here in 1874. '
    'Take your time, look around, and enjoy the symmetry and scale of the Great '
    'Court before you head inside.';

// TODO(goderbauer): Restructure the examples to avoid this ignore, https://github.com/flutter/flutter/issues/110208.
// ignore: avoid_implementing_value_types
class BlenheimGreatCourtDemo extends StatefulWidget implements MarkdownDemoWidget {
  const BlenheimGreatCourtDemo({super.key});

  static const String _title = 'Blenheim Palace: The Great Court';

  @override
  String get title => BlenheimGreatCourtDemo._title;

  @override
  String get description => 'A self-guided audio tour of the Great Court at '
      'Blenheim Palace. Renders the tour as Markdown with a press-to-play '
      'text-to-speech overview.';

  @override
  Future<String> get data => Future<String>.value(_tourMarkdown);

  @override
  Future<String> get notes => Future<String>.value(
        'This demo pairs a `Markdown` widget with the `flutter_tts` package to '
        'create a simple audio tour. The formatted Markdown is shown on screen '
        'while a separate plain-text narration is read aloud when you press the '
        '**Play audio overview** button.',
      );

  @override
  State<BlenheimGreatCourtDemo> createState() => _BlenheimGreatCourtDemoState();
}

class _BlenheimGreatCourtDemoState extends State<BlenheimGreatCourtDemo> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _configureTts();
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage('en-GB');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    // Keep the button state in sync with the engine.
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
    _tts.setErrorHandler((dynamic message) {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await _tts.stop();
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
      return;
    }

    setState(() => _isSpeaking = true);
    final dynamic result = await _tts.speak(_tourNarration);
    // On some platforms speak() returns immediately; the completion handler
    // resets the state. If the call failed outright, reset here.
    if (result == 0 && mounted) {
      setState(() => _isSpeaking = false);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _toggleSpeech,
            icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
            label: Text(_isSpeaking ? 'Stop audio' : 'Play audio overview'),
          ),
        ),
        Expanded(
          child: Markdown(
            data: _tourMarkdown,
          ),
        ),
      ],
    );
  }
}
