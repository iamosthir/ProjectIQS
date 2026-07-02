import 'package:flutter/material.dart';

import 'package:iqs_flutter/core/api/api_models.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'app_states.dart';

/// Reusable infinite-scroll list driven by the backend's `meta.pagination`.
///
/// Give it a [loader] `(page) => Future<Paginated<T>>`; it loads page 1, appends
/// subsequent pages near the bottom, supports pull-to-refresh, and renders the
/// shared loading/error/offline/empty placeholders. Reads `hasMore` to stop.
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.loader,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding,
    this.emptyTitle,
    this.emptySubtitle,
    this.header,
    this.firstPage = 1,
    this.physics,
    this.shrinkWrap = false,
  });

  /// Loads a single page. `page` starts at [firstPage].
  final Future<Paginated<T>> Function(int page) loader;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final String? emptyTitle;
  final String? emptySubtitle;

  /// Optional sliver-free header rendered above the first item.
  final Widget? header;
  final int firstPage;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scroll = ScrollController();
  final List<T> _items = [];

  PageMeta? _meta;
  Object? _error; // first-page error only
  bool _loadingFirst = true;
  bool _loadingMore = false;
  bool _moreError = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadFirst();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  bool get _hasMore => _meta?.hasMore ?? false;
  int get _nextPage => (_meta?.currentPage ?? widget.firstPage - 1) + 1;

  Future<void> _loadFirst() async {
    setState(() {
      _loadingFirst = true;
      _error = null;
    });
    try {
      final page = await widget.loader(widget.firstPage);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _meta = page.meta;
        _loadingFirst = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loadingFirst = false;
      });
    }
  }

  /// Explicit retry from the footer button — clears the error gate first so the
  /// suppressed auto-trigger can run once.
  void _retryMore() {
    setState(() => _moreError = false);
    _loadMore();
  }

  Future<void> _loadMore() async {
    // `_moreError` is in the guard so a failed page does NOT auto-retry on every
    // scroll frame — the user must tap the retry footer (which calls _retryMore).
    if (_loadingMore || _moreError || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _moreError = false;
    });
    try {
      final page = await widget.loader(_nextPage);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _meta = page.meta;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _moreError = true;
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFirst) return const LoadingState();
    if (_error != null) {
      return appErrorView(_error!, onRetry: _loadFirst);
    }
    if (_items.isEmpty) {
      final empty = SizedBox(
        height: 320,
        child: EmptyState(
          title: widget.emptyTitle,
          subtitle: widget.emptySubtitle,
          onRetry: _loadFirst,
        ),
      );
      // When embedded in an outer scrollable (shrinkWrap), don't introduce our
      // own unbounded scrollable — compose with a non-scrolling Column.
      if (widget.shrinkWrap) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.header != null) widget.header!,
            empty,
          ],
        );
      }
      return RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: _loadFirst,
        child: ListView(
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          padding: widget.padding,
          children: [
            if (widget.header != null) widget.header!,
            empty,
          ],
        ),
      );
    }

    final headerOffset = widget.header != null ? 1 : 0;
    final footer = 1; // loader / retry / end-spacer slot
    final count = _items.length + headerOffset + footer;

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: _loadFirst,
      child: ListView.separated(
        controller: _scroll,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        shrinkWrap: widget.shrinkWrap,
        padding: widget.padding ?? const EdgeInsets.all(18),
        itemCount: count,
        separatorBuilder: (context, index) {
          final itemIndex = index - headerOffset;
          if (index < headerOffset || itemIndex >= _items.length - 1) {
            return const SizedBox.shrink();
          }
          return widget.separatorBuilder?.call(context, itemIndex) ??
              const SizedBox(height: 14);
        },
        itemBuilder: (context, index) {
          if (index < headerOffset) return widget.header!;
          final itemIndex = index - headerOffset;
          if (itemIndex < _items.length) {
            return widget.itemBuilder(context, _items[itemIndex], itemIndex);
          }
          return _footer();
        },
      ),
    );
  }

  Widget _footer() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      );
    }
    if (_moreError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child:
              GreenPillButton(label: context.l10n.loadMore, onTap: _retryMore),
        ),
      );
    }
    if (_hasMore) {
      // Trigger handled by scroll listener; show a light hint.
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}

/// Lightweight inline "end of list" label (optional helper).
class EndOfListLabel extends StatelessWidget {
  const EndOfListLabel({super.key, this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
          child: Text(text ?? context.l10n.endOfList, style: AppText.muted)),
    );
  }
}
