class ChainConfig {
  final int chainId;
  final List<String> rpcs; // ordered by priority; fallback in sequence
  final String explorer;
  final String txExplorerBase; // base URL for tx explorer, e.g. "https://etherscan.io/tx/"
  final String symbol;
  final String name;
  final int decimals;
  final bool isTron;
  final bool isTestnet;
  final List<BuiltinToken> builtinTokens;

  const ChainConfig({
    required this.chainId,
    required this.rpcs,
    required this.explorer,
    required this.txExplorerBase,
    required this.symbol,
    required this.name,
    this.decimals = 18,
    this.isTron = false,
    this.isTestnet = false,
    this.builtinTokens = const [],
  });
}

class BuiltinToken {
  final String symbol;
  final String contractAddress;
  final int decimals;
  final String? coingeckoId;

  const BuiltinToken({
    required this.symbol,
    required this.contractAddress,
    required this.decimals,
    this.coingeckoId,
  });
}

const chains = <String, ChainConfig>{
  'eth': ChainConfig(
    chainId: 1,
    rpcs: [
      'https://cloudflare-eth.com',        // ~50 req/s, highly reliable
      'https://eth.llamarpc.com',           // ~25 req/s
      'https://rpc.ankr.com/eth',           // ~30 req/s
      'https://ethereum.publicnode.com',    // ~50 req/s
    ],
    explorer: 'https://api.etherscan.io/api',
    txExplorerBase: 'https://etherscan.io/tx/',
    symbol: 'ETH',
    name: 'Ethereum',
    decimals: 18,
    builtinTokens: [
      BuiltinToken(
        symbol: 'USDT',
        contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
        decimals: 6,
        coingeckoId: 'tether',
      ),
      BuiltinToken(
        symbol: 'USDC',
        contractAddress: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
        decimals: 6,
        coingeckoId: 'usd-coin',
      ),
    ],
  ),
  'bsc': ChainConfig(
    chainId: 56,
    rpcs: [
      'https://bsc-dataseed.binance.org',   // official
      'https://bsc-dataseed1.defibit.io',
      'https://rpc.ankr.com/bsc',
      'https://bsc.publicnode.com',
    ],
    explorer: 'https://api.bscscan.com/api',
    txExplorerBase: 'https://bscscan.com/tx/',
    symbol: 'BNB',
    name: 'BNB Chain',
    decimals: 18,
    builtinTokens: [
      BuiltinToken(
        symbol: 'USDT',
        contractAddress: '0x55d398326f99059fF775485246999027B3197955',
        decimals: 18,
        coingeckoId: 'tether',
      ),
      BuiltinToken(
        symbol: 'USDC',
        contractAddress: '0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d',
        decimals: 18,
        coingeckoId: 'usd-coin',
      ),
    ],
  ),
  'polygon': ChainConfig(
    chainId: 137,
    rpcs: [
      'https://polygon-rpc.com',            // official
      'https://polygon.llamarpc.com',
      'https://rpc.ankr.com/polygon',
      'https://polygon.publicnode.com',
    ],
    explorer: 'https://api.polygonscan.com/api',
    txExplorerBase: 'https://polygonscan.com/tx/',
    symbol: 'POL',
    name: 'Polygon',
    decimals: 18,
    builtinTokens: [
      BuiltinToken(
        symbol: 'USDT',
        contractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
        decimals: 6,
        coingeckoId: 'tether',
      ),
      BuiltinToken(
        symbol: 'USDC',
        contractAddress: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
        decimals: 6,
        coingeckoId: 'usd-coin',
      ),
    ],
  ),
  'arbitrum': ChainConfig(
    chainId: 42161,
    rpcs: [
      'https://arb1.arbitrum.io/rpc',       // official
      'https://rpc.ankr.com/arbitrum',
      'https://arbitrum.publicnode.com',
      'https://1rpc.io/arb',
    ],
    explorer: 'https://api.arbiscan.io/api',
    txExplorerBase: 'https://arbiscan.io/tx/',
    symbol: 'ETH',
    name: 'Arbitrum One',
    decimals: 18,
    builtinTokens: [
      BuiltinToken(
        symbol: 'USDT',
        contractAddress: '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9',
        decimals: 6,
        coingeckoId: 'tether',
      ),
      BuiltinToken(
        symbol: 'USDC',
        contractAddress: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',
        decimals: 6,
        coingeckoId: 'usd-coin',
      ),
    ],
  ),
  'optimism': ChainConfig(
    chainId: 10,
    rpcs: [
      'https://mainnet.optimism.io',        // official
      'https://rpc.ankr.com/optimism',
      'https://optimism.publicnode.com',
      'https://1rpc.io/op',
    ],
    explorer: 'https://api-optimistic.etherscan.io/api',
    txExplorerBase: 'https://optimistic.etherscan.io/tx/',
    symbol: 'ETH',
    name: 'Optimism',
    decimals: 18,
    builtinTokens: [
      BuiltinToken(
        symbol: 'USDT',
        contractAddress: '0x94b008aA00579c1307B0EF2c499aD98a8ce58e58',
        decimals: 6,
        coingeckoId: 'tether',
      ),
      BuiltinToken(
        symbol: 'USDC',
        contractAddress: '0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85',
        decimals: 6,
        coingeckoId: 'usd-coin',
      ),
    ],
  ),
  'tron': ChainConfig(
    chainId: 0,
    rpcs: [
      'https://api.trongrid.io',            // official TronGrid
      'https://api.tronstack.io',           // community fallback
    ],
    explorer: 'https://apilist.tronscanapi.com/api',
    txExplorerBase: 'https://tronscan.org/#/transaction/',
    symbol: 'TRX',
    name: 'TRON',
    decimals: 6,
    isTron: true,
    builtinTokens: [
      BuiltinToken(
        symbol: 'USDT',
        contractAddress: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
        decimals: 6,
        coingeckoId: 'tether',
      ),
    ],
  ),
  'bsc_testnet': ChainConfig(
    chainId: 97,
    rpcs: [
      'https://rpc.ankr.com/bsc_testnet_chapel', // supports eth_getLogs up to 10k blocks
      'https://data-seed-prebsc-1-s1.binance.org:8545',
      'https://data-seed-prebsc-2-s1.binance.org:8545',
      'https://bsc-testnet.publicnode.com',
    ],
    explorer: 'https://api-testnet.bscscan.com/api',
    txExplorerBase: 'https://testnet.bscscan.com/tx/',
    symbol: 'tBNB',
    name: 'BSC Testnet',
    decimals: 18,
    isTestnet: true,
    builtinTokens: [
      BuiltinToken(
        symbol: 'USDT',
        contractAddress: '0x337610d27c682E347C9cD60BD4b3b107C9d34dDd',
        decimals: 18,
      ),
    ],
  ),
  'eth_sepolia': ChainConfig(
    chainId: 11155111,
    rpcs: [
      'https://rpc.sepolia.org',
      'https://ethereum-sepolia.publicnode.com',
      'https://rpc.ankr.com/eth_sepolia',
    ],
    explorer: 'https://api-sepolia.etherscan.io/api',
    txExplorerBase: 'https://sepolia.etherscan.io/tx/',
    symbol: 'ETH',
    name: 'Sepolia',
    decimals: 18,
    isTestnet: true,
  ),
  'tron_shasta': ChainConfig(
    chainId: 0,
    rpcs: ['https://api.shasta.trongrid.io'],
    explorer: 'https://shasta.tronscanapi.com/api',
    txExplorerBase: 'https://shasta.tronscan.org/#/transaction/',
    symbol: 'TRX',
    name: 'Shasta Testnet',
    decimals: 6,
    isTron: true,
    isTestnet: true,
    builtinTokens: [
      BuiltinToken(
        symbol: 'USDT',
        contractAddress: 'TG3XXyExBkPp9nzdajDZsozEu4BkaSJozs',
        decimals: 6,
      ),
    ],
  ),
};

// Maps mainnet chain key → testnet equivalent
const testnetEquivalents = <String, String>{
  'eth': 'eth_sepolia',
  'bsc': 'bsc_testnet',
  'tron': 'tron_shasta',
};

const coinGeckoIds = <String, String>{
  'ETH': 'ethereum',
  'BNB': 'binancecoin',
  'tBNB': 'binancecoin',  // BSC testnet native — use BNB price for display
  'POL': 'matic-network',
  'TRX': 'tron',
  'BTC': 'bitcoin',
  'USDT': 'tether',
  'USDC': 'usd-coin',
};
