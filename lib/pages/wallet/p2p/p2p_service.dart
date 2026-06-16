import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:openim_common/openim_common.dart';
import 'package:web3dart/web3dart.dart';
import '../../../services/wallet/chain_config.dart';
import 'p2p_models.dart';

const _contractAddress = '0x06F97e0FB5c5aA8CAD545dA83357b02e84D8965B';
const _chainKey        = 'bsc_testnet';

const _escrowAbi = '''[
  {"inputs":[{"name":"token","type":"address"},{"name":"amount","type":"uint256"},{"name":"fiatAmount","type":"uint256"},{"name":"fiatCurrency","type":"string"},{"name":"payMethod","type":"string"},{"name":"lockTimeout","type":"uint256"}],"name":"createOrder","outputs":[{"name":"orderId","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"name":"orderId","type":"uint256"}],"name":"takeOrder","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"name":"orderId","type":"uint256"}],"name":"markPaid","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"name":"orderId","type":"uint256"}],"name":"confirmRelease","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"name":"orderId","type":"uint256"}],"name":"cancelOpenOrder","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"name":"orderId","type":"uint256"}],"name":"cancelExpiredLock","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"name":"orderId","type":"uint256"}],"name":"raiseDispute","outputs":[],"stateMutability":"nonpayable","type":"function"}
]''';

const _approveAbi = '''[
  {"inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}
]''';

class P2PService {
  static String get _base => Config.appAuthUrl;

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'token': DataSp.chatToken ?? '',
      };

  // ── REST API ──────────────────────────────────────────────────────────────

  static Future<List<P2POrder>> fetchOpen({int limit = 20, int offset = 0}) async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/p2p/orders?limit=$limit&offset=$offset'),
        headers: _headers(),
      );
      if (resp.statusCode != 200) return [];
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = body['data'] as List? ?? [];
      return list.map((e) => P2POrder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<P2POrder>> fetchMySelling(String address) async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/p2p/my/selling?address=${address.toLowerCase()}'),
        headers: _headers(),
      );
      if (resp.statusCode != 200) return [];
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = body['data'] as List? ?? [];
      return list.map((e) => P2POrder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<P2POrder>> fetchMyBuying(String address) async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/p2p/my/buying?address=${address.toLowerCase()}'),
        headers: _headers(),
      );
      if (resp.statusCode != 200) return [];
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = body['data'] as List? ?? [];
      return list.map((e) => P2POrder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Contract calls ────────────────────────────────────────────────────────

  // Tries each RPC in order, returns first that responds.
  static Future<T> _rpc<T>(Future<T> Function(Web3Client) fn) async {
    final rpcs = chains[_chainKey]!.rpcs;
    Object? last;
    for (final url in rpcs) {
      try {
        return await fn(Web3Client(url, http.Client()));
      } catch (e) {
        last = e;
      }
    }
    throw last!;
  }

  static DeployedContract _escrow() => DeployedContract(
        ContractAbi.fromJson(_escrowAbi, 'P2PEscrow'),
        EthereumAddress.fromHex(_contractAddress),
      );

  static Future<String> approveUsdt({
    required EthPrivateKey key,
    required BigInt amount,
    required String usdtContract,
  }) =>
      _rpc((c) async {
        final contract = DeployedContract(
          ContractAbi.fromJson(_approveAbi, 'ERC20'),
          EthereumAddress.fromHex(usdtContract),
        );
        final fn = contract.function('approve');
        final tx = Transaction.callContract(
          contract: contract,
          function: fn,
          parameters: [EthereumAddress.fromHex(_contractAddress), amount],
          gasPrice: await c.getGasPrice(),
          maxGas: 80000,
        );
        return c.sendTransaction(key, tx, chainId: chains[_chainKey]!.chainId);
      });

  static Future<String> createOrder({
    required EthPrivateKey key,
    required String usdtContract,
    required BigInt amount,
    required int fiatAmount,
    required String payMethod,
    int lockMinutes = 30,
  }) =>
      _rpc((c) async {
        final escrow = _escrow();
        final fn = escrow.function('createOrder');
        final tx = Transaction.callContract(
          contract: escrow,
          function: fn,
          parameters: [
            EthereumAddress.fromHex(usdtContract),
            amount,
            BigInt.from(fiatAmount),
            'CNY',
            payMethod,
            BigInt.from(lockMinutes * 60),
          ],
          gasPrice: await c.getGasPrice(),
          maxGas: 300000,
        );
        return c.sendTransaction(key, tx, chainId: chains[_chainKey]!.chainId);
      });

  static Future<String> _simpleCall(EthPrivateKey key, String fnName, BigInt orderId) =>
      _rpc((c) async {
        final escrow = _escrow();
        final fn = escrow.function(fnName);
        final tx = Transaction.callContract(
          contract: escrow,
          function: fn,
          parameters: [orderId],
          gasPrice: await c.getGasPrice(),
          maxGas: 120000,
        );
        return c.sendTransaction(key, tx, chainId: chains[_chainKey]!.chainId);
      });

  static Future<String> takeOrder(EthPrivateKey key, int orderId) =>
      _simpleCall(key, 'takeOrder', BigInt.from(orderId));

  static Future<String> markPaid(EthPrivateKey key, int orderId) =>
      _simpleCall(key, 'markPaid', BigInt.from(orderId));

  static Future<String> confirmRelease(EthPrivateKey key, int orderId) =>
      _simpleCall(key, 'confirmRelease', BigInt.from(orderId));

  static Future<String> cancelOpenOrder(EthPrivateKey key, int orderId) =>
      _simpleCall(key, 'cancelOpenOrder', BigInt.from(orderId));

  static Future<String> raiseDispute(EthPrivateKey key, int orderId) =>
      _simpleCall(key, 'raiseDispute', BigInt.from(orderId));
}
