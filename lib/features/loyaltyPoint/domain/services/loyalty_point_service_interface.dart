
abstract class LoyaltyPointServiceInterface {
  Future<dynamic> getList({int? offset = 1, String? filterBy, DateTime? startDate, DateTime? endDate, List<String>? transactionTypes});
  Future<dynamic> convertPointToCurrency(int point);
}