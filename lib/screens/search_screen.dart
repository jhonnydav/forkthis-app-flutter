import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/fixtures.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/primitives.dart';

const _suggestions = [
  'something high-protein I can grab nearby',
  'what can I order at a coffee place that isn’t sugar',
  'a lunch that won’t wreck my afternoon',
  'I’ve got 400 calories left and I’m out',
];
const _suggestionTones = [AppColors.warmSurface, AppColors.mint, AppColors.blueberrySurface, AppColors.coralSurface];

/// Ported from `../app/src/screens/Search.tsx`.
class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late String _q = widget.initialQuery;

  void _setQuery(String q) => setState(() {
        _q = q;
        _controller.text = q;
      });

  @override
  Widget build(BuildContext context) {
    final hasQuery = _q.trim().isNotEmpty;
    final results = hasQuery ? fastHacks.where((h) => h.protein >= 24).toList() : <FastHack>[];
    final empty = hasQuery && (_q.startsWith('zzz') || results.isEmpty);

    return AppShell(
      header: ScreenHeader(eyebrow: 'Discovery', onBack: () => context.pop()),
      child: ListView(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFFF3F7EE), border: Border(bottom: BorderSide(color: Color(0x1A0F3A27)))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Ask in plain English', style: AppText.eyebrow(color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 8),
                  Text('What would make today easier?', style: AppText.h1()),
                  const SizedBox(height: 8),
                  Text('Describe the meal, the moment, or the goal. No perfect keywords needed.',
                      style: AppText.bodySm(color: AppColors.mutedForeground)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    onChanged: (v) => setState(() => _q = v),
                    decoration: const InputDecoration(
                      hintText: 'Ask for what you actually want…',
                      prefixIcon: Icon(Icons.search_rounded),
                      suffixIcon: Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!hasQuery) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('START FROM A REAL MOMENT', style: AppText.eyebrow(color: AppColors.primary)),
                const SizedBox(height: 2),
                Text('Try one of these', style: AppText.h2()),
              ]),
            ),
            Container(decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border)))),
            for (final (index, s) in _suggestions.indexed)
              InkWell(
                onTap: () => _setQuery(s),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _suggestionTones[index], shape: BoxShape.circle),
                      child: Text('0${index + 1}', style: AppText.label()),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(s, style: AppText.body().copyWith(fontWeight: FontWeight.w700))),
                    const Icon(Icons.north_east_rounded, color: AppColors.primary),
                  ]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: const DisclaimerNote(),
            ),
          ],
          if (empty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Nothing matched that one.', style: AppText.h2()),
                const SizedBox(height: 8),
                Text('Try fewer specifics, or browse the places we cover — it’s often faster.',
                    style: AppText.body(color: AppColors.mutedForeground)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(onPressed: () => context.go('/eat-out'), child: const Text('Browse places')),
                ),
              ]),
            ),
          if (hasQuery && !empty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('BEST AVAILABLE MATCHES', style: AppText.eyebrow(color: AppColors.primary)),
                const SizedBox(height: 2),
                Text('${results.length} orders worth a look', style: AppText.h2()),
                const SizedBox(height: 8),
                Text('For "$_q"', style: AppText.bodySm(color: AppColors.mutedForeground), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final h in results)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FastHackCard(hack: h, restaurant: restaurantById(h.restaurantId)),
                    ),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), child: const DisclaimerNote()),
          ],
        ],
      ),
    );
  }
}
