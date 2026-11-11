import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/place_prediction.dart';
import '../providers/autocomplete_notifier.dart';

/// Floating search bar with a live Autocomplete suggestions list.
/// Purely presentational + wires up to [autocompleteProvider]; the actual
/// "move camera + drop marker" behavior lives in the parent screen via
/// [onPlaceSelected].
class PlaceSearchBar extends ConsumerStatefulWidget {
  final LatLng? locationBias;
  final ValueChanged<PlacePrediction> onPlaceSelected;

  const PlaceSearchBar({
    super.key,
    required this.locationBias,
    required this.onPlaceSelected,
  });

  @override
  ConsumerState<PlaceSearchBar> createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends ConsumerState<PlaceSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSelect(PlacePrediction prediction) {
    _controller.text = prediction.mainText;
    _focusNode.unfocus();
    ref.read(autocompleteProvider.notifier).clear();
    widget.onPlaceSelected(prediction);
  }

  void _handleClear() {
    _controller.clear();
    ref.read(autocompleteProvider.notifier).clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final predictionsAsync = ref.watch(autocompleteProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusInput),
            boxShadow: AppShadows.floating,
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            style: AppFonts.sans(fontSize: 14, color: palette.ink),
            decoration: InputDecoration(
              hintText: 'Search for a pickup location',
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: _handleClear,
                      tooltip: 'Clear search',
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {});
              ref.read(autocompleteProvider.notifier).search(
                    value,
                    bias: widget.locationBias,
                  );
            },
          ),
        ),
        predictionsAsync.when(
          data: (predictions) {
            if (predictions.isEmpty) return const SizedBox.shrink();
            return _SuggestionsList(
              predictions: predictions,
              onSelected: _handleSelect,
            );
          },
          loading: () => const _SuggestionsLoading(),
          error: (error, _) => _SuggestionsError(message: error.toString()),
        ),
      ],
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  final List<PlacePrediction> predictions;
  final ValueChanged<PlacePrediction> onSelected;

  const _SuggestionsList({required this.predictions, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: AppShadows.floating,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: predictions.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, indent: 52, color: palette.border),
          itemBuilder: (context, index) {
            final prediction = predictions[index];
            return ListTile(
              leading: Icon(Icons.place_outlined, color: palette.inkMuted),
              title: Text(
                prediction.mainText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: prediction.secondaryText.isNotEmpty
                  ? Text(
                      prediction.secondaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              onTap: () => onSelected(prediction),
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionsLoading extends StatelessWidget {
  const _SuggestionsLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: AppShadows.floating,
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _SuggestionsError extends StatelessWidget {
  final String message;
  const _SuggestionsError({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.dangerBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusInput),
      ),
      child: Text(
        'Search failed: $message',
        style: AppFonts.sans(fontSize: 12, color: palette.danger),
      ),
    );
  }
}
