import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/settings/domain/entities/saved_location_entity.dart';
import 'package:ride_app/features/settings/presentation/providers/saved_locations_provider.dart';
import 'package:ride_app/features/settings/presentation/states/saved_locations_state.dart';
import 'package:ride_app/features/settings/presentation/widgets/saved_location_card.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/models/selected_location.dart';
import 'package:ride_app/shared/shared.dart';

import '../../../../shared/widgets/custom_dialogue.dart';
import 'add_to_location_sheet.dart';

class SavedLocationsScreen extends ConsumerStatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  ConsumerState<SavedLocationsScreen> createState() =>
      _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends ConsumerState<SavedLocationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(savedLocationsProvider.notifier).fetchSavedLocations();
    });
  }

  void _handleEdit(SavedLocationEntity location) {
    _openEditLocationSheet(location);
  }

  Future<void> _handleDelete(SavedLocationEntity location) async {
    final l10n = AppLocalizations.of(context)!;
    final isConfirmed =
        await showDialog(
          context: context,
          builder: (dialogContext) => GradientSideDialog(
            title: l10n.delete_location,
            subtitle: l10n.delete_location_confirmation,
            // imagePath: AppIcons.danger,
            icon: Icons.warning,
            iconColor: AppColors.error,
            buttons: [
              AppButton(
                text: l10n.cancel,
                fontColor: context.brightness == Brightness.light
                    ? context.appColors.textPrimary
                    : context.appColors.brand,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                backgroundColor: context.appColors.lightButton,
              ),
              AppButton(
                text: l10n.confirm,
                fontColor: AppColors.darkBackground,
                backgroundColor: context.appColors.brand,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                // color: Colors.red,
              ),
            ],
          ),
        ) ??
        false;

    if (!isConfirmed || !mounted) return;

    final success = await ref
        .read(savedLocationsProvider.notifier)
        .deleteLocation(location.id);
    if (!mounted) return;
    if (!mounted) return;
    if (success) {
      context.showSuccessToast(l10n.location_deleted_successfully);
    }
  }

  Future<void> _openAddLocationSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddLocationSheet(),
    );

    if (!mounted) return;
    if (result == 'added') {
      await showDialog(
        context: context,
        builder: (_) => GradientSideDialog(
          title: context.l10n.location_updated,
          subtitle: context.l10n.location_subtitle,
          imagePath: AppIcons.tick,
        ),
      );
    }
  }

  Future<void> _openEditLocationSheet(SavedLocationEntity location) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddLocationSheet(
        isEdit: true,
        locationId: location.id,
        locationName: location.name,
        locationAddress: location.formattedAddress,
        initialAddress: Address(
          latitiude: location.lat,
          longitude: location.lng,
          country: location.country,
          state: location.state,
          city: location.city,
          zipCode: '',
          countryCode: '',
          formattedAddress: location.formattedAddress,
        ),
      ),
    );

    if (!mounted) return;
    if (result == 'updated') {
      await showDialog(
        context: context,
        builder: (_) => GradientSideDialog(
          title: context.l10n.location_updated,
          subtitle: context.l10n.location_subtitle,
          icon: Icons.check_circle,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final state = ref.watch(savedLocationsProvider);

    ref.listen(savedLocationsProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        context.showErrorToast(next.errorMessage!);
      }
    });

    return AppScaffold(
      scrollable: false,
      whichBackground: ScaffoldBackgroundType.doubleShadow,
      appBar: AppBar(
        title: Text(l10n.saved_locations)
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            ),
        centerTitle: true,
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: _buildContent(context, state, l10n)),
          if (state.isReordering)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (state.locations.isNotEmpty)
            Positioned(
                  right: 20,
                  bottom: 30,
                  child: FloatingActionButton(
                    onPressed: state.isSaving ? null : _openAddLocationSheet,
                    backgroundColor: colors.brand,
                    shape: const CircleBorder(),
                    child: Icon(
                      Icons.add,
                      color: context.appColors.textPrimary,
                      size: 32,
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SavedLocationsState state,
    AppLocalizations l10n,
  ) {
    if (state.status == SavedLocationsStatus.loading &&
        state.locations.isEmpty) {
      return const AppLoadingWidget();
    }

    if (state.status == SavedLocationsStatus.error && state.locations.isEmpty) {
      return AppErrorWidget(
        message: state.errorMessage ?? context.l10n.something_went_wrong,
        onRetry: () =>
            ref.read(savedLocationsProvider.notifier).fetchSavedLocations(),
      );
    }

    if (state.locations.isEmpty) {
      return AppEmptyWidget(
            message: l10n.no_saved_locations_found,
            icon: Icons.location_off_outlined,
            action: AppButton(
              text: context.l10n.add_location,
              onPressed: _openAddLocationSheet,
              width: 180,
            ),
          )
          .animate()
          .fadeIn(duration: 400.ms)
          .scale(begin: const Offset(0.90, 0.90));
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: AppSizes.p16, bottom: 100),
      itemCount: state.locations.length,
      onReorder: (oldIndex, newIndex) async {
        await ref
            .read(savedLocationsProvider.notifier)
            .reorderLocation(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final location = state.locations[index];

        return Padding(
          key: ValueKey(location.id),
          padding: const EdgeInsets.only(bottom: AppSizes.p12),
          child:
              SavedLocationCard(
                    locationName: location.name.capitalised,
                    address: location.formattedAddress,
                    onEdit: () => _handleEdit(location),
                    onDelete: () => _handleDelete(location),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.90, 0.90)),
        );
      },
    );
  }
}
