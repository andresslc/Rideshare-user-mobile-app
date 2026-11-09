import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/params/location_params.dart';
import 'package:ride_app/features/settings/presentation/providers/saved_locations_provider.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/models/selected_location.dart';
import 'package:ride_app/shared/shared.dart';

import '../../../../shared/widgets/bottom_sheets/draggable_sheet_widget.dart';

class AddLocationSheet extends ConsumerStatefulWidget {
  final bool isEdit;
  final String? locationId;
  final String? locationName;
  final String? locationAddress;
  final Address? initialAddress;

  const AddLocationSheet({
    super.key,
    this.isEdit = false,
    this.locationId,
    this.locationName,
    this.locationAddress,
    this.initialAddress,
  });

  @override
  ConsumerState<AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends ConsumerState<AddLocationSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _nameFocusNode = FocusNode();
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _nameController.text = widget.locationName ?? '';
      _locationController.text = widget.locationAddress ?? '';
    } else {
      _nameController.text = widget.locationName ?? '';
      _locationController.text =
          widget.initialAddress?.formattedAddress ??
          widget.locationAddress ??
          '';
    }
    _selectedAddress = widget.initialAddress;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _onPickLocation() async {
    final result = await context.pushNamed<Address>(
      Routes.placePicker.name,
      extra: _selectedAddress ?? widget.initialAddress,
    );
    if (result != null) {
      setState(() {
        _selectedAddress = result;
        _locationController.text = result.formattedAddress;
      });
    }
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context)!;
    final address = _selectedAddress;
    if (address == null || address.latitiude == 0 || address.longitude == 0) {
      context.showErrorToast(l10n.please_select_valid_location);
      return;
    }
    // if (address.city.trim().isEmpty ||
    //     address.state.trim().isEmpty ||
    //     address.country.trim().isEmpty) {
    //   context.showErrorToast(l10n.please_choose_location_with_full_address);
    //   return;
    // }

    final params = SaveLocationParams(
      name: _nameController.text.trim(),
      address: _locationController.text.trim(),
      country: address.country.trim(),
      city: address.city.trim(),
      state: address.state.trim(),
      lat: address.latitiude,
      lng: address.longitude,
    );

    final notifier = ref.read(savedLocationsProvider.notifier);
    final success = widget.isEdit
        ? await notifier.updateLocation(
            locationId: widget.locationId ?? '',
            params: params,
          )
        : await notifier.saveLocation(params);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, widget.isEdit ? 'updated' : 'added');
    }
  }

  // Roothey Sajjan
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(savedLocationsProvider);

    return DraggableSheetWidget(
      heightFactor: 0.5,
      isButtonAvailable: false,
      expandOnFocusNodes: [_nameFocusNode],
      title: widget.isEdit ? l10n.edit_location : l10n.save_location,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // const SizedBox(height: AppSizes.p12),
              Text(
                l10n.name_this_location,
                style: context.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSizes.p8),
              AppTextField(
                focusNode: _nameFocusNode,
                controller: _nameController,
                hintText: l10n.enter_location_name,
                maxLength: 50,
                textInputAction: TextInputAction.next,
                onChanged: (val) => setState(() {}),
                validator: Validators.fullNameValidator,
              ),
              const SizedBox(height: AppSizes.p16),
              Text(l10n.location, style: context.textTheme.titleSmall),
              const SizedBox(height: AppSizes.p8),
              AppTextField(
                controller: _locationController,
                hintText: l10n.select_location,
                readOnly: true,
                onTap: _onPickLocation,
                prefixIcon: AppIcons.locationFill,
                validator: Validators.requiredFieldValidator,
              ),
              const SizedBox(height: AppSizes.p20),
              AppButton(
                text: widget.isEdit ? l10n.save : l10n.save_location,
                onPressed: (!state.isSaving && !state.isDeleting)
                    ? _onSave
                    : null,
                child: state.isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.appColors.button,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
