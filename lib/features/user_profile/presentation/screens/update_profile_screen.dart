import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_entity.dart';
import 'package:ride_app/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:ride_app/features/user_profile/presentation/states/user_states.dart';
import 'package:ride_app/shared/widgets/loader.dart';

import '../../../../shared/location_component/location_models/address_details.dart';
import '../../../../shared/location_component/location_ui/address_search_field.dart';
import '../../../../shared/shared.dart';
import '../../../../shared/widgets/date_of_birth_picker_sheet.dart';
import '../../../../shared/widgets/image_picker_field.dart';
import '../../../../shared/widgets/phone_number_field.dart';

class UpdateProfileScreen extends ConsumerStatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  ConsumerState<UpdateProfileScreen> createState() =>
      _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends ConsumerState<UpdateProfileScreen> {
  final _firstNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? imagePath;
  bool _isProfileImageRemoved = false;
  bool _isCityStateReadOnly = true;
  final CustomLoader loader = CustomLoader();

  /// Normalized calendar date from picker or profile `dob`.
  DateTime? _dobDate;

  @override
  void initState() {
    super.initState();

    // Pre-fill user data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).profile;
      if (profile != null) {
        _firstNameController.text = profile.user.firstName;
        _lastNameController.text = profile.user.lastName;
        _emailController.text = profile.user.email;
        _phoneController.text = profile.user.phone.toUSPhoneFormat();
        imagePath = profile.user.profilePicture;
        _isProfileImageRemoved = false;
        _seedAddressFields(profile.user);
        _seedDobFields(profile.user);
      }

      ref.read(userProfileProvider.notifier).getProfile();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
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

  void _seedAddressFields(UserEntity user) {
    _addressController.text = user.address;
    if (user.city != null && user.city!.isNotEmpty) {
      _cityController.text = user.city!;
    }
    if (user.state != null && user.state!.isNotEmpty) {
      _stateController.text = user.state!;
    }

    if ((user.city == null || user.city!.isEmpty) ||
        (user.state == null || user.state!.isEmpty)) {
      _isCityStateReadOnly = false;
      _onAddressDetailsFetched(
        AddressDetails(
          latitude: 0,
          longitude: 0,
          city: user.city ?? '',
          state: user.state ?? '',
          country: '',
          zipCode: '',
        ),
      );
    } else {
      _isCityStateReadOnly = true;
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
    final currentProfile = ref.read(userProfileProvider).profile;
    if (currentProfile != null &&
        _addressController.text.trim() == currentProfile.user.address.trim()) {
      _seedAddressFields(currentProfile.user);
    } else if (_addressController.text.trim().isNotEmpty) {
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

  void _seedDobFields(UserEntity user) {
    final d = user.dob;
    if (d != null) {
      final utc = d.toUtc();
      _dobDate = DateTime(utc.year, utc.month, utc.day);
      _dobController.text = DateFormat.yMd(
        Localizations.localeOf(context).toString(),
      ).format(_dobDate!);
    } else {
      _dobDate = null;
      _dobController.clear();
    }
  }

  bool _dobMatchesUser(UserEntity user, DateTime? picked) {
    final server = user.dob;
    if (server == null && picked == null) return true;
    if (server == null || picked == null) return false;
    final su = server.toUtc();
    return su.year == picked.year &&
        su.month == picked.month &&
        su.day == picked.day;
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

  void handleProfileImage(String? path) {
    setState(() {
      imagePath = path;
      _isProfileImageRemoved = path == null;
    });
  }

  void handleUpdate() {
    FocusScope.of(context).unfocus();

    final currentProfile = ref.read(userProfileProvider).profile;
    if (currentProfile == null) {
      context.showToast(context.l10n.profile_data_not_loaded);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final updatedFirstName = _firstNameController.text.trim();
    final updatedLastName = _lastNameController.text.trim();
    final updatedEmail = _emailController.text.trim();
    final updatedAddress = _addressController.text.trim();

    final updatedCity = _cityController.text.trim().isEmpty
        ? currentProfile.user.city
        : _cityController.text.trim();

    final updatedState = _stateController.text.trim().isEmpty
        ? currentProfile.user.state
        : _stateController.text.trim();

    final hasNewLocalImage =
        imagePath != null && !imagePath!.startsWith('http');
    final updatedFile = hasNewLocalImage ? File(imagePath!) : null;
    final hasRemovedExistingImage =
        _isProfileImageRemoved &&
        (currentProfile.user.profilePicture?.isNotEmpty ?? false);

    final dobUnchanged = _dobMatchesUser(currentProfile.user, _dobDate);

    // Nothing changed
    if (updatedFirstName == currentProfile.user.firstName &&
        updatedLastName == currentProfile.user.lastName &&
        updatedEmail == currentProfile.user.email &&
        updatedAddress == currentProfile.user.address &&
        updatedCity == currentProfile.user.city &&
        updatedState == currentProfile.user.state &&
        updatedFile == null &&
        !hasRemovedExistingImage &&
        dobUnchanged) {
      context.showToast(context.l10n.no_changes_to_update);
      return;
    }

    final params = UpdateProfileParams(
      firstName: updatedFirstName,
      lastName: updatedLastName,
      email: updatedEmail,
      address: updatedAddress,
      city: updatedCity,
      state: updatedState,
      file: updatedFile,
      removeProfilePicture: hasRemovedExistingImage,
      dob: _dobDate,
    );

    ref.read(userProfileProvider.notifier).updateProfile(params);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(userProfileProvider);
    final user = state.profile?.user;
    final colors = context.appColors;

    ref.listen<UserProfileState>(userProfileProvider, (previous, next) {
      if (previous?.profile == null && next.profile != null && mounted) {
        final p = next.profile!;
        _firstNameController.text = p.user.firstName;
        _lastNameController.text = p.user.lastName;
        _emailController.text = p.user.email;
        _phoneController.text = p.user.phone.toUSPhoneFormat();
        imagePath = p.user.profilePicture;
        _isProfileImageRemoved = false;
        _seedAddressFields(p.user);
        _seedDobFields(p.user);
        setState(() {});
      }

      // Loading
      if (next.status == UserProfileStatus.loading) {
        loader.showLoader(context);
      } else {
        loader.hideLoader();
      }

      // Error
      if (next.status == UserProfileStatus.error && next.message != null) {
        context.showErrorToast(next.message!);
      }

      // Success
      if (previous?.profile != next.profile &&
          next.status == UserProfileStatus.success &&
          next.action == UserProfileAction.updateProfile) {
        context.showToast(context.l10n.profile_updated_success);
        Navigator.pop(context);
      }
    });

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.update_profile)),
      scrollable: true,
      child: user == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Image
                  ImagePickerField(
                    isPickup: true,
                    radius: 40,
                    type: ImagePickerFieldType.profileImage,
                    labelText: l10n.upload_profile_picture,
                    subText: l10n.optional,
                    filePath:
                        (imagePath != null && !imagePath!.startsWith('http'))
                        ? imagePath
                        : null,
                    imagePath: _isProfileImageRemoved
                        ? null
                        : (imagePath != null && imagePath!.startsWith('http'))
                        ? imagePath
                        : user.profilePicture,
                    onPicTap: handleProfileImage,
                  ),
                  const SizedBox(height: AppSizes.p16),

                  Text(
                    context.l10n.first_name,
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSizes.p8),
                  AppTextField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    hintText: context.l10n.enter_first_name,
                    maxLength: 15,
                    // maxlines: 2,
                    keyboardType: TextInputType.name,
                    inputFormatters: [
                      // Allows only a-z and A-Z characters
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                    ],
                    validator: Validators.requiredFieldValidator,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSizes.p16),
                  Text(
                    context.l10n.last_name,
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSizes.p8),
                  AppTextField(
                    controller: _lastNameController,
                    maxLength: 15,
                    // maxlines: 2,
                    textCapitalization: TextCapitalization.words,
                    hintText: context.l10n.enter_last_name,
                    keyboardType: TextInputType.name,
                    inputFormatters: [
                      // Allows only a-z and A-Z characters
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                    ],
                    validator: Validators.requiredFieldValidator,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: AppSizes.p16),
                  // Email
                  Text(l10n.email_address, style: context.textTheme.titleSmall),
                  const SizedBox(height: AppSizes.p8),
                  AppTextField(
                    controller: _emailController,
                    hintText: l10n.enter_email,
                    maxLength: 254,
                    validator: Validators.emailValidator,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: AppSizes.p16),
                  Text(l10n.address, style: context.textTheme.titleSmall),
                  const SizedBox(height: AppSizes.p8),
                  AddressSearchField(
                    searchFieldId: 'profile_edit.address',
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
                          // validator: Validators.stateValidator,
                          textInputAction: TextInputAction.next,
                        ),
                      ),

                      const SizedBox(width: AppSizes.p16),

                      Expanded(
                        child: AppTextField(
                          controller: _stateController,
                          labelText: context.l10n.state,
                          maxlines: 1,
                          readOnly: _isCityStateReadOnly,
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

                  // const SizedBox(height: AppSizes.p16),
                  // Text(context.l10n.state, style: context.textTheme.titleSmall),
                  // const SizedBox(height: AppSizes.p8),
                  // AppTextField(
                  //   controller: _stateController,
                  //   readOnly: true,
                  //   hintText: context.l10n.state,
                  //   textInputAction: TextInputAction.next,
                  // ),
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
                  // Phone (readonly)
                  Text(l10n.phone_number, style: context.textTheme.titleSmall),
                  const SizedBox(height: AppSizes.p8),
                  PhoneNumberField(
                    controller: _phoneController,
                    enabled: false,
                    hintText: l10n.add_phone_number,
                  ),

                  const SizedBox(height: AppSizes.p24),
                  AppButton(text: l10n.update_profile, onPressed: handleUpdate),
                  const SizedBox(height: AppSizes.p16),
                ],
              ),
            ),
    );
  }
}
