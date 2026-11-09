import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/services/location_service.dart';

import '../../../core/services/address_search_controller.dart';
import '../../../core/services/places_search_service.dart';
import '../../widgets/app_gradient_box.dart';
import '../../widgets/custom_tap.dart';
import '../../widgets/location_animation_widget.dart';
import '../location_models/address_details.dart';
import 'address_search_error.dart';

/// A reusable widget for searching and selecting an address using
/// Google Places Autocomplete + Geocoding APIs.
class AddressSearchField extends StatefulWidget {
  /// Controller for the text input field.
  final TextEditingController controller;
  final LocationService? locationService;
  final String searchFieldId;

  /// FocusNode for controlling and detecting focus.
  final FocusNode? focusNode;

  /// Optional callback fired when the user selects a suggestion
  /// and full address details have been fetched.
  final Function(AddressDetails addressDetails)? onDetailsFetched;

  /// Optional callback fired when the user selects a custom typed address
  /// instead of a Google Places suggestion.
  final Function(String customAddress)? onCustomAddressSelected;

  /// Optional callback fired when the address field is modified or cleared
  /// without a confirmed suggestion.
  final VoidCallback? onAddressCleared;

  /// Optional callback fired when the address field is restored to its
  /// last confirmed Google Places address on focus loss.
  final VoidCallback? onAddressRestored;

  /// Custom hint text for the text field
  final String? hintText;

  /// Form validator
  final String? Function(String?)? validator;

  /// TextInputAction (e.g. TextInputAction.next)
  final TextInputAction? textInputAction;

  /// Max length constraint
  final int? maxLength;

  /// Custom input formatters
  final List<TextInputFormatter>? inputFormatters;

  const AddressSearchField({
    super.key,
    required this.controller,
    this.locationService,
    this.searchFieldId = 'profile.address',
    this.focusNode,
    this.onDetailsFetched,
    this.onCustomAddressSelected,
    this.onAddressCleared,
    this.onAddressRestored,
    this.hintText,
    this.validator,
    this.textInputAction,
    this.maxLength = 255,
    this.inputFormatters,
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  /// Whether we are currently fetching suggestions from API.
  bool isLoading = false;

  /// The list of places suggestions returned by the API.
  List<Map<String, dynamic>> placeList = [];

  /// Timer used for debouncing API calls.
  late AddressSearchController _search;
  bool _applyingSelection = false;

  /// Search controller inside the dropdown.
  final TextEditingController _searchController = TextEditingController();

  /// Search field focus node inside the dropdown.
  final FocusNode _searchFocusNode = FocusNode();

  /// Whether the suggestions dropdown container is open.
  bool _isDropdownOpen = false;

  /// Internal focus node if none was provided.
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  /// Key used to scroll the entire AddressSearchField (text field + suggestions) into view.
  final GlobalKey _fieldKey = GlobalKey();

  /// Key used for FormField state validation.
  final GlobalKey<FormFieldState<String>> _formFieldKey =
      GlobalKey<FormFieldState<String>>();

  /// Delay duration for debounce

  @override
  void initState() {
    super.initState();
    _search = (widget.locationService ?? locator<LocationService>())
        .createAddressSearch(
          legacyDeviceOrigin: false,
          legacyDebounce: const Duration(milliseconds: 400),
          onChanged: () {
            if (!mounted) return;
            setState(() {
              placeList = _search.suggestions.map((s) => s.toUiMap()).toList();
              isLoading = _search.loading || _search.selecting;
            });
            if (placeList.isNotEmpty) _scrollToEnsureVisible();
          },
        );
    widget.controller.addListener(_handleControllerChange);
    _searchFocusNode.addListener(_onSearchFocusChange);
    _effectiveFocusNode.addListener(_onMainFocusChange);
  }

  void _handleControllerChange() {
    if (!_applyingSelection && _search.selecting) _search.abandon();
    if (mounted) {
      _formFieldKey.currentState?.didChange(widget.controller.text);
      if (mounted) setState(() {});
    }
  }

  void _onSearchFocusChange() {
    _checkFocusAndCloseDropdown();
  }

  void _onMainFocusChange() {
    if (_effectiveFocusNode.hasFocus) {
      setState(() {
        _isDropdownOpen = true;
      });
      // Delay requesting focus to avoid focus loop issues during build phase
      Future.microtask(() {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    } else {
      _checkFocusAndCloseDropdown();
    }
  }

  void _checkFocusAndCloseDropdown() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (!_searchFocusNode.hasFocus &&
          !_effectiveFocusNode.hasFocus &&
          !_search.selecting) {
        _search.abandon();
        setState(() {
          _isDropdownOpen = false;
          placeList = [];
        });
      }
    });
  }

  void _scrollToEnsureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _fieldKey.currentContext != null) {
        Scrollable.ensureVisible(
          _fieldKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  /// Called whenever the user types in the search box inside the dropdown.
  void _onQueryChanged(String value) {
    if (_search.enabled) {
      widget.onAddressCleared?.call();
      widget.controller.text = value;
    }
    _search.edit(value, field: widget.searchFieldId);
  }

  /// Called when the user taps on a suggestion.
  Future<void> _selectAddress(Map<String, dynamic> suggestion) async {
    if (_applyingSelection || _search.selecting) return;
    if (_search.enabled) {
      final prediction = suggestion['prediction'];
      if (prediction is! PlaceSuggestion) return;
      final place = await _search.select(prediction);
      if (!mounted || place == null) return;
      _applyResolved(place);
      return;
    }
    _search.abandon();
    final String description = (suggestion['description'] ?? '').toString();

    setState(() {
      _isDropdownOpen = false;
      placeList = [];
      _searchController.clear();
    });

    widget.controller.text = description;
    widget.controller.selection = TextSelection.collapsed(
      offset: description.length,
    );

    if (widget.onDetailsFetched != null) {
      try {
        final locationService =
            widget.locationService ?? locator<LocationService>();
        final String placeId = (suggestion['place_id'] ?? '').toString();
        final details = await locationService.getAddressDetailsFromPlaceId(
          placeId,
        );

        if (details != null && widget.onDetailsFetched != null) {
          widget.onDetailsFetched!(details);
        } else {
          final position = await locationService.getPlaceDetails(placeId);
          if (position != null && widget.onDetailsFetched != null) {
            widget.onDetailsFetched!(
              AddressDetails(
                latitude: position.latitude,
                longitude: position.longitude,
                city: '',
                state: '',
                country: '',
                zipCode: '',
              ),
            );
          }
        }
      } catch (_) {
        // Ignore geocoding errors if description text was set
      }
    }
  }

  void _applyResolved(ResolvedPlace place) {
    _applyingSelection = true;
    widget.controller.text = place.formattedAddress;
    widget.onDetailsFetched?.call(AddressDetails.fromResolvedPlace(place));
    setState(() {
      _isDropdownOpen = false;
      placeList = [];
      _searchController.clear();
    });
    _applyingSelection = false;
  }

  Future<void> _retrySelection() async {
    if (!_search.canRetrySelection) {
      _search.retrySearch();
      return;
    }
    final place = await _search.retrySelection();
    if (mounted && place != null) _applyResolved(place);
  }

  /// Called when the user taps on the typed custom address option.
  void _selectCustomAddress(String customAddress) {
    _search.abandon();
    setState(() {
      _isDropdownOpen = false;
      placeList = [];
      _searchController.clear();
    });

    widget.controller.text = customAddress;
    widget.controller.selection = TextSelection.collapsed(
      offset: customAddress.length,
    );

    if (widget.onCustomAddressSelected != null) {
      widget.onCustomAddressSelected!(customAddress);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _effectiveFocusNode.removeListener(_onMainFocusChange);
    _internalFocusNode?.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _formFieldKey,
      initialValue: widget.controller.text,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (FormFieldState<String> state) {
        return Column(
          key: _fieldKey,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppGradientBox(
              cornerRadius: 16,
              isPlain: true,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Address Row
                    CustomTap(
                      isNeedOverlay: false,
                      onTap: () {
                        setState(() {
                          _isDropdownOpen = !_isDropdownOpen;
                        });
                        if (!_isDropdownOpen) _search.abandon();
                        if (_isDropdownOpen) {
                          Future.microtask(() {
                            _searchFocusNode.requestFocus();
                          });
                        }
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Text(
                                  widget.controller.text.isEmpty
                                      ? widget.hintText ?? "Street Address"
                                      : widget.controller.text,
                                  // overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            // const Padding(
                            //   padding: EdgeInsets.only(right: 16),
                            //   child: Icon(Icons.arrow_drop_down),
                            // ),
                          ],
                        ),
                      ),
                    ),

                    if (_isDropdownOpen) ...[
                      const Divider(height: 1),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          textInputAction: TextInputAction.search,
                          maxLength: widget.maxLength ?? 255,
                          inputFormatters: widget.inputFormatters,
                          onChanged: _onQueryChanged,
                          decoration: InputDecoration(
                            hintText: context.l10n.search_address,
                            counterText: '',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onQueryChanged('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey,
                                width: 0.1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),

                      if (_search.error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AddressSearchError(
                            failure: _search.error!,
                            onRetry: _retrySelection,
                          ),
                        ),
                      if (placeList.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Google Maps', textAlign: TextAlign.end),
                        ),
                      if (isLoading)
                        const LocationLoadingAnimation()
                      else if (_searchController.text.trim().isNotEmpty &&
                          placeList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.l10n.we_couldnot_found,
                                style: TextStyle(
                                  color: Theme.of(context).disabledColor,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.location_on_outlined),
                                title: Text(
                                  _searchController.text.trim(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                // subtitle: Text(
                                //   context.l10n.use_this_address,
                                //   style: TextStyle(
                                //     fontSize: 12,
                                //     color: Theme.of(context).primaryColor,
                                //   ),
                                // ),
                                onTap: () => _selectCustomAddress(
                                  _searchController.text.trim(),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _searchController.text.trim().isNotEmpty
                                ? placeList.length + 1
                                : placeList.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) {
                              if (index < placeList.length) {
                                final place = placeList[index];

                                return ListTile(
                                  leading: const Icon(
                                    Icons.location_on_outlined,
                                  ),
                                  title: Text(place['description']),
                                  onTap: () => _selectAddress(place),
                                );
                              } else {
                                final query = _searchController.text.trim();

                                return ListTile(
                                  leading: const Icon(
                                    Icons.edit_location_alt_outlined,
                                  ),
                                  title: Text(query),
                                  subtitle: Text(
                                    context.l10n.use_this_address,

                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  onTap: () => _selectCustomAddress(query),
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            if (state.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
