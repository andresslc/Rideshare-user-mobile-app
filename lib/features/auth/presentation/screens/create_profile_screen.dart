import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/core/services/location_service.dart';
import 'package:ride_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ride_app/features/auth/presentation/states/auth_state.dart';
import 'package:ride_app/shared/widgets/loader.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/location_component/location_models/address_details.dart';
import '../../../../shared/location_component/location_ui/address_search_field.dart';
import '../../../../shared/shared.dart';
import '../../../../shared/widgets/date_of_birth_picker_sheet.dart';
import '../../../../shared/widgets/image_picker_field.dart';
import '../../../../shared/widgets/phone_number_field.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final LocationService _locationService = locator<LocationService>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// Normalized calendar date (local); used for `CreateProfileParams.dob`.
  DateTime? _dobDate;

  final nameFocus = FocusNode();
  final addressFocus = FocusNode();
  final emailFocus = FocusNode();
  final phoneFocus = FocusNode();
  final descriptionFocus = FocusNode();
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  String? imagePath;
  bool _isCityStateReadOnly = true;
  CustomLoader loader = CustomLoader();

  @override
  void initState() {
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!.toUSPhoneFormat();
    }
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openWebUrl(ApiEndpoints.termsUrl);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openWebUrl(ApiEndpoints.privacyPolicyUrl);
    super.initState();
  }

  void handleProfileImage(String? path) {
    imagePath = path;
  }

  void _onAddressDetailsFetched(AddressDetails details) {
    if (details.isResolvedFromPlaces) {
      _cityController.text = details.city;
      _stateController.text = details.state;
      if (mounted) {
        setState(
          () => _isCityStateReadOnly =
              details.city.isNotEmpty && details.state.isNotEmpty,
        );
      }
      return;
    }
    final parts = _addressController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (details.city.isNotEmpty) {
      _cityController.text = details.city;
    } else if (parts.isNotEmpty) {
      if (parts.length >= 4) {
        _cityController.text = parts[parts.length - 3];
      } else if (parts.length == 3 || parts.length == 2) {
        _cityController.text = parts[0];
      }
    }

    if (details.state.isNotEmpty) {
      _stateController.text = details.state;
    } else if (parts.isNotEmpty) {
      if (parts.length >= 3) {
        _stateController.text = parts[parts.length - 2];
      } else if (parts.length == 2) {
        _stateController.text = parts[1];
      }
    }

    if (mounted) {
      setState(() {
        _isCityStateReadOnly =
            _cityController.text.isNotEmpty && _stateController.text.isNotEmpty;
      });
    }
  }

  void _onCustomAddressSelected(String customAddress) {
    if (mounted) {
      setState(() {
        _isCityStateReadOnly = false;
        _cityController.clear();
        _stateController.clear();
      });
    }
  }

  void _onAddressCleared() {
    if (mounted) {
      setState(() {
        _cityController.clear();
        _stateController.clear();
        _isCityStateReadOnly = false;
      });
    }
  }

  void _onAddressRestored() {
    if (_addressController.text.trim().isNotEmpty) {
      _onAddressDetailsFetched(
        AddressDetails(
          latitude: 0,
          longitude: 0,
          city: '',
          state: '',
          country: '',
          zipCode: '',
        ),
      );
    } else {
      if (mounted) {
        setState(() {
          _cityController.clear();
          _stateController.clear();
          _isCityStateReadOnly = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _privacyRecognizer.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final result = await showDateOfBirthPickerSheet(
      context,
      selectedDate: _dobDate,
    );
    if (result == null || !mounted) return;
    setState(() {
      _dobDate = result;
      _dobController.text = DateFormat.yMd(
        Localizations.localeOf(context).toString(),
      ).format(result);
    });
  }

  void handleTap() {
    FocusScope.of(context).unfocus();

    // if (imagePath?.isEmpty ?? true) {
    //   if (imagePath?.isEmpty ?? true) {
    //     context.showErrorToast(context.l10n.upload_profile_picture_required);
    //     return;
    //   }
    //   return;
    // }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rawNumber = _phoneController.text.trim();

    final String digitsOnly = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // if (digitsOnly.startsWith('1')) {
    //   digitsOnly = digitsOnly.substring(1);
    // }
    loader.showLoader(context);
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    ref
        .read(authProvider.notifier)
        .createProfile(
          CreateProfileParams(
            address: _addressController.text.trim(),
            city: _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
            state: _stateController.text.trim().isEmpty
                ? null
                : _stateController.text.trim(),
            file: imagePath != null ? File(imagePath!) : null,
            email: _emailController.text.trim(),
            firstName: firstName,
            lastName: lastName,
            phone: digitsOnly,
            role: '',
            countryCode: '1',
            dob: _dobDate!,
          ),
        );
  }

  Future<void> _handlePostProfileCreated() async {
    final bool isGranted = await _locationService.hasLocationPermission();
    if (!mounted) return;

    if (isGranted) {
      await _locationService.markLocationPromptShown();
      // ignore: use_build_context_synchronously
      context.goNamed(Routes.home.name);
      return;
    }

    await context.pushNamed(Routes.locationAccess.name);
  }

  Future<void> _openWebUrl(String url) async {
    final Uri uri = Uri.parse(url);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      context.showErrorToast('Unable to open link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    ref.listen<AuthState>(authProvider, (previous, next) {
      switch (next) {
        case AuthLoading():
          loader.showLoader(context);
          break;

        case AuthError(:final message):
          loader.hideLoader();
          context.showErrorToast(message);
          break;

        case ProfileCreated():
          loader.hideLoader();
          _handlePostProfileCreated();
          break;

        default:
          loader.hideLoader();
          break;
      }
    });
    return AppScaffold(
      scrollable: true,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
          child: Text.rich(
            TextSpan(
              text: l10n.by_registering,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              children: [
                const TextSpan(text: ' '),
                TextSpan(
                  text: l10n.terms_conditions,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.link),
                  recognizer: _termsRecognizer,
                ),
                TextSpan(
                  text: ' ${l10n.and} ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
                TextSpan(
                  text: l10n.privacy_policy,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.link),
                  recognizer: _privacyRecognizer,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSizes.p8),
            AuthHeader(
              title: l10n.create_profile,
              subtitle: l10n.signup_subtitle,
            ),
            const SizedBox(height: AppSizes.p24),

            ImagePickerField(
              isPickup: true,
              radius: 40,
              maxImageSizeInMB: 10,
              labelText: l10n.upload_profile_picture,
              subText: l10n.optional,
              onPicTap: handleProfileImage,
            ),

            const SizedBox(height: AppSizes.p16),
            Text(context.l10n.first_name, style: context.textTheme.titleSmall),
            const SizedBox(height: AppSizes.p8),
            AppTextField(
              controller: _firstNameController,
              hintText: context.l10n.enter_first_name,
              validator: Validators.requiredFieldValidator,
              maxLength: 15,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              inputFormatters: [
                // Allows only a-z and A-Z characters
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
              ],
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSizes.p16),
            Text(context.l10n.last_name, style: context.textTheme.titleSmall),
            const SizedBox(height: AppSizes.p8),

            AppTextField(
              controller: _lastNameController,
              hintText: context.l10n.enter_last_name,
              validator: Validators.requiredFieldValidator,
              maxLength: 15,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              inputFormatters: [
                // Allows only a-z and A-Z characters
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
              ],
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSizes.p16),
            Text(
              context.l10n.email_address,
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSizes.p8),
            AppTextField(
              controller: _emailController,
              hintText: context.l10n.enter_email,
              validator: Validators.emailValidator,
              keyboardType: TextInputType.emailAddress,
              maxLength: 254,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSizes.p16),
            Text(context.l10n.address, style: context.textTheme.titleSmall),
            const SizedBox(height: AppSizes.p8),
            AddressSearchField(
              searchFieldId: 'registration.address',
              controller: _addressController,
              onDetailsFetched: _onAddressDetailsFetched,
              onCustomAddressSelected: _onCustomAddressSelected,
              onAddressCleared: _onAddressCleared,
              onAddressRestored: _onAddressRestored,
              hintText: context.l10n.enter_address,
              validator: Validators.addressValidator,
            ),
            const SizedBox(height: AppSizes.p16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _cityController,
                    labelText: context.l10n.city,
                    maxlines: 1,
                    readOnly: _isCityStateReadOnly,
                    isGreishText: _isCityStateReadOnly,
                    hintText: context.l10n.enter_city,
                    maxLength: 28,
                    validator: Validators.requiredFieldValidator,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: AppSizes.p16),
                Expanded(
                  child: AppTextField(
                    controller: _stateController,
                    labelText: context.l10n.state,
                    readOnly: _isCityStateReadOnly,
                    maxlines: 1,
                    isGreishText: _isCityStateReadOnly,
                    hintText: context.l10n.enter_state,
                    maxLength: 28,
                    // validator: Validators.requiredFieldValidator,
                    validator: Validators.stateValidator,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p16),
            Text(l10n.date_of_birth, style: context.textTheme.titleSmall),
            const SizedBox(height: AppSizes.p8),
            AppTextField(
              controller: _dobController,
              readOnly: true,
              onTap: _pickDateOfBirth,
              hintText: l10n.select_date_of_birth,
              textInputAction: TextInputAction.next,
              suffixIcon: Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: colors.textSecondary,
              ),
              validator: Validators.dobValidator,
            ),

            const SizedBox(height: AppSizes.p16),
            Text(l10n.phone_number, style: context.textTheme.titleSmall),
            const SizedBox(height: AppSizes.p8),
            PhoneNumberField(
              controller: _phoneController,
              enabled: false,
              hintText: l10n.add_phone_number,
            ),
            const SizedBox(height: AppSizes.p24),
            AppButton(text: l10n.next, onPressed: handleTap),
            const SizedBox(height: AppSizes.p16),
          ],
        ),
      ),
    );
  }
}
