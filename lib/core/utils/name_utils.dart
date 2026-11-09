class NameParts {
  final String firstName;
  final String lastName;

  const NameParts({
    required this.firstName,
    required this.lastName,
  });

  String get fullName {
    final parts = <String>[firstName.trim()];
    final trimmedLastName = lastName.trim();
    if (trimmedLastName.isNotEmpty) {
      parts.add(trimmedLastName);
    }
    return parts.join(' ').trim();
  }
}

NameParts splitFullName(String fullName) {
  final values = fullName
      .trim()
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .toList(growable: false);

  if (values.isEmpty) {
    return const NameParts(firstName: '', lastName: '');
  }

  if (values.length == 1) {
    return NameParts(firstName: values.first, lastName: '');
  }

  return NameParts(
    firstName: values.first,
    lastName: values.skip(1).join(' '),
  );
}
