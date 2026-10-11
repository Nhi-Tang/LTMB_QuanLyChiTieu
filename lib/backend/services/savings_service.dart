import '../database/db_helper.dart';
import '../models/savings_goal_model.dart';
import '../models/savings_transaction_model.dart';

class SavingsService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<SavingsGoalModel>> getSavingsGoals() async {
    return await _dbHelper.getSavingsGoals();
  }

  Future<int> insertSavingsGoal(SavingsGoalModel goal) async {
    return await _dbHelper.insertSavingsGoal(goal);
  }

  Future<int> updateSavingsGoal(SavingsGoalModel goal) async {
    return await _dbHelper.updateSavingsGoal(goal);
  }

  Future<int> deleteSavingsGoal(int goalId) async {
    return await _dbHelper.deleteSavingsGoal(goalId);
  }

  Future<List<SavingsTransactionModel>> getSavingsTransactions(int goalId) async {
    return await _dbHelper.getSavingsTransactions(goalId);
  }

  Future<int> addSavingsTransaction(SavingsTransactionModel tx) async {
    return await _dbHelper.addSavingsTransaction(tx);
  }
}
