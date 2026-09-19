import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

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
    final theme = Theme.of(context);
    final predictionsAsync = ref.watch(autocompleteProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search for a pickup location',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _handleClear,
                      tooltip: 'Clear search',
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: predictions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final prediction = predictions[index];
          return ListTile(
            leading: const Icon(Icons.place_outlined),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Search failed: $message',
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
