import 'package:flutter/widgets.dart';
import 'package:ride_app/shared/widgets/select_ride_card.dart';

class HorizontalImageSelector<T> extends StatelessWidget {
  final List<T> items;
  final String? selectedId; // 👈 store only id
  final String Function(T) idBuilder; // 👈 extract id
  final String Function(T) labelBuilder;
  final String Function(T) imageBuilder;
  // final String Function(T) subTitleBuilder;
  final ValueChanged<T> onChanged;
  final bool isUpdating;

  const HorizontalImageSelector({
    super.key,
    required this.items,
    required this.selectedId,
    required this.idBuilder,
    required this.labelBuilder,
    required this.imageBuilder,
    // required this.subTitleBuilder,
    required this.onChanged,
    this.isUpdating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: SelectableImageCard(
                label: labelBuilder(items[i]),
                imagePath: imageBuilder(items[i]),
                isSelected: selectedId == idBuilder(items[i]),
                isDisabled: isUpdating,
                onTap: () => onChanged(items[i]),
              ),
            ),
            if (i != items.length - 1)
              const SizedBox(width: 12), // 👈 space between cards
          ],
        ],
      ),
    );

    //  SizedBox(
    //   height: context.screenWidth * 0.35,
    //   child: ListView.separated(
    //     scrollDirection: Axis.horizontal,
    //     itemCount: items.length,
    //     padding: const EdgeInsets.symmetric(horizontal: 16),
    //     separatorBuilder: (_, _) => const SizedBox(width: 10),
    //     itemBuilder: (context, index) {
    //       final item = items[index];
    //       final itemId = idBuilder(item);

    //       return SelectableImageCard(
    //         label: labelBuilder(item),
    //         imagePath: imageBuilder(item),
    //         isSelected: selectedId == itemId,
    //         isDisabled: isUpdating,
    //         onTap: () => onChanged(item),
    //       );
    //     },
    //   ),
    // );
  }
}
