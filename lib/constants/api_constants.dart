import 'package:investment_plan_app/services/bankdetails_service.dart';
import 'package:investment_plan_app/services/coin_service.dart';
import 'package:investment_plan_app/services/deposit_service.dart';
import 'package:investment_plan_app/services/investment_service.dart';
import 'package:investment_plan_app/services/referral_service.dart';
import 'package:investment_plan_app/services/transaction_service.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/services/withdrawal_service.dart';

const String API_BASE_URL = 'http://145.223.21.62:5021';

class ServiceLocator {
  static final UserApiService userService =
      UserApiService(baseUrl: API_BASE_URL);
  static final DepositService depositService =
      DepositService(baseUrl: API_BASE_URL);
  static final WithdrawalService withdrawalService =
      WithdrawalService(baseUrl: API_BASE_URL);
  static final InvestmentService investmentService =
      InvestmentService(baseUrl: API_BASE_URL);
  static final CoinService coinService = CoinService(baseUrl: API_BASE_URL);
  static final ReferralService referralService =
      ReferralService(baseUrl: API_BASE_URL);
  static final TransactionService transactionService =
      TransactionService(baseUrl: API_BASE_URL);
  static final BankDetailsService bankDetailsService =
      BankDetailsService(baseUrl: API_BASE_URL);
}
