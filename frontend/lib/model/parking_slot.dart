class ParkingSlot {
  final String id;
  final String name;
  final int is_available;
  final double ratePerHour;
  final List<String> supportedVehicleTypes;

  ParkingSlot({
    required this.id,
    required this.name,
    required this.is_available,
    required this.ratePerHour,
    required this.supportedVehicleTypes,
  });
}
