import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'places_search_service.dart';

/// Owned by a field or a composite screen, never registered as a singleton.
class AddressSearchController {
  final PlacesSearchService service;
  final PlacesContext Function() contextProvider;
  final Future<PlacesContext> Function(PlacesContext)? prepareContext;
  final String Function() tokenGenerator;
  final Duration debounce;
  final Duration legacyDebounce;
  final void Function()? onChanged;
  final void Function()? onDispose;
  Timer? _timer;
  CancelToken? _cancel;
  int _generation = 0;
  bool _disposed = false;
  String _query = '', _field = '';
  PlacesContext? _baseContext, _context;
  Future<PlacesContext>? _preparing;
  String? _token, _interaction;
  Future<ResolvedPlace?>? _selection;
  PlaceSuggestion? _retrySuggestion;
  List<PlaceSuggestion> suggestions = const [];
  bool loading = false, selecting = false;
  PlacesFailure? error;

  AddressSearchController({
    required this.service,
    required this.contextProvider,
    this.prepareContext,
    this.onChanged,
    this.onDispose,
    String Function()? tokenGenerator,
    this.debounce = const Duration(milliseconds: 400),
    this.legacyDebounce = const Duration(milliseconds: 300),
  }) : tokenGenerator = tokenGenerator ?? newPlacesId;

  bool get enabled => (_baseContext ?? contextProvider()).enabled;
  bool get canRetrySelection => _retrySuggestion != null && !selecting;
  bool get canRetry => !selecting && (error?.retryable ?? false);
  int get _minimumLength => enabled ? 2 : 1;
  int get generation => _generation;
  void _notify() {
    if (!_disposed) onChanged?.call();
  }

  bool _sameConfiguration(PlacesContext a, PlacesContext b) =>
      a.enabled == b.enabled &&
      a.apiKey == b.apiKey &&
      a.language == b.language &&
      a.region == b.region &&
      jsonEncode(a.configurationGeography) ==
          jsonEncode(b.configurationGeography);
  bool _current(int generation) {
    if (_disposed || generation != _generation || _baseContext == null) {
      return false;
    }
    if (!_sameConfiguration(_baseContext!, contextProvider())) {
      abandon();
      return false;
    }
    return true;
  }

  void edit(String input, {required String field}) {
    if (_disposed) return;
    final query = input.trim();
    final config = contextProvider();
    final sameContext =
        _baseContext != null && _sameConfiguration(_baseContext!, config);
    if (field == _field && query == _query && sameContext && error == null) {
      return;
    }
    if (field != _field ||
        !sameContext ||
        _selection != null ||
        _retrySuggestion != null) {
      abandon(notify: false);
    }
    _generation++;
    _timer?.cancel();
    _cancel?.cancel();
    _query = query;
    _field = field;
    _baseContext ??= config;
    suggestions = const [];
    error = null;
    loading = false;
    if (query.isEmpty) {
      abandon();
      return;
    }
    if (query.length < _minimumLength) {
      _notify();
      return;
    }
    final generation = _generation;
    _timer = Timer(
      enabled ? debounce : legacyDebounce,
      () => _search(generation),
    );
    _notify();
  }

  Future<void> _search(int generation) async {
    if (!_current(generation)) return;
    loading = true;
    _notify();
    try {
      _preparing ??=
          prepareContext?.call(_baseContext!) ?? Future.value(_baseContext!);
      final context = await _preparing!;
      if (!_current(generation)) return;
      _context = context;
      if (_interaction == null) {
        _interaction = newPlacesId();
        if (context.enabled) _token = tokenGenerator();
        service.observe({
          'event': 'interaction_started',
          'interaction': _interaction!,
          'field': _field,
          'strategy': context.enabled ? 'v2' : 'legacy',
        });
      }
      final cancel = CancelToken();
      _cancel = cancel;
      final result = await service.search(
        _query,
        context,
        token: _token,
        interaction: _interaction!,
        field: _field,
        cancelToken: cancel,
      );
      if (_current(generation)) suggestions = result;
    } on PlacesException catch (failure) {
      if (_current(generation) && failure.category != PlacesFailure.cancelled) {
        error = failure.category;
      }
    } catch (_) {
      if (_current(generation)) error = PlacesFailure.network;
    } finally {
      if (_current(generation)) {
        loading = false;
        _notify();
      }
    }
  }

  Future<ResolvedPlace?> select(
    PlaceSuggestion suggestion, {
    bool retry = false,
  }) {
    if (_selection != null) return _selection!;
    if (_disposed || _context == null || !_current(_generation)) {
      return Future.value(null);
    }
    if (retry
        ? !identical(suggestion, _retrySuggestion)
        : !suggestions.any((s) => identical(s, suggestion))) {
      return Future.value(null);
    }
    _timer?.cancel();
    _cancel?.cancel();
    final token = retry ? null : _token;
    _token = null;
    final generation = ++_generation;
    final field = _field;
    selecting = true;
    loading = false;
    error = null;
    suggestions = const [];
    _notify();
    final future = _resolve(suggestion, generation, field, token, retry);
    _selection = future;
    return future;
  }

  void retrySearch() {
    if (_query.length >= _minimumLength &&
        canRetry &&
        _retrySuggestion == null) {
      edit(_query, field: _field);
    }
  }

  Future<ResolvedPlace?> retrySelection() {
    final suggestion = _retrySuggestion;
    return suggestion == null
        ? Future.value(null)
        : select(suggestion, retry: true);
  }

  Future<ResolvedPlace?> _resolve(
    PlaceSuggestion suggestion,
    int generation,
    String field,
    String? token,
    bool retry,
  ) async {
    final cancel = CancelToken();
    _cancel = cancel;
    try {
      if (retry) {
        service.observe({
          'event': 'retry',
          'interaction': _interaction!,
          'field': field,
          'reason': 'explicit_details',
        });
      }
      final result = await service.resolve(
        suggestion,
        _context!,
        token: token,
        interaction: _interaction!,
        field: field,
        cancelToken: cancel,
      );
      if (!_current(generation)) return null;
      service.observe({
        'event': 'interaction_completed',
        'interaction': _interaction!,
        'field': field,
        'strategy': enabled ? 'v2' : 'legacy',
      });
      _retrySuggestion = null;
      _interaction = null;
      _context = null;
      _baseContext = null;
      _preparing = null;
      _query = '';
      return result;
    } on PlacesException catch (failure) {
      if (_current(generation) && failure.category != PlacesFailure.cancelled) {
        error = failure.category;
        _retrySuggestion = failure.category.retryable ? suggestion : null;
        service.observe({
          'event': 'selection_failed',
          'interaction': _interaction!,
          'field': field,
          'category': failure.category.name,
        });
      }
      return null;
    } catch (_) {
      if (_current(generation)) {
        error = PlacesFailure.network;
        _retrySuggestion = suggestion;
      }
      return null;
    } finally {
      if (!_disposed && generation == _generation) {
        _selection = null;
        selecting = false;
        _notify();
      }
    }
  }

  void abandon({bool notify = true}) {
    _generation++;
    _timer?.cancel();
    _cancel?.cancel();
    if (_interaction != null) {
      service.observe({
        'event': 'interaction_abandoned',
        'interaction': _interaction!,
        'field': _field,
        'strategy': enabled ? 'v2' : 'legacy',
      });
    }
    _token = null;
    _interaction = null;
    _baseContext = null;
    _context = null;
    _preparing = null;
    _selection = null;
    _retrySuggestion = null;
    _query = '';
    _field = '';
    suggestions = const [];
    loading = false;
    selecting = false;
    error = null;
    if (notify) _notify();
  }

  void dispose() {
    if (_disposed) return;
    abandon(notify: false);
    _disposed = true;
    onDispose?.call();
  }
}
