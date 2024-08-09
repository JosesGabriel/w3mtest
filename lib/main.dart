import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final W3MService w3mService = W3MService(
    enableEmail: true,
    projectId: 'd322dd83295c25ee111f449fdf162f1b',
    metadata: const PairingMetadata(
      name: 'W3MTest',
      description: 'W3MTest',
      url: 'https://github.com/JosesGabriel/w3mtest',
      icons: <String>[
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d1/Identicon.svg/1200px-Identicon.svg.png',
      ],
      redirect: Redirect(
        universal: 'https://github.com/JosesGabriel/w3mtest',
        native: 'https://github.com/JosesGabriel/w3mtest',
      ),
    ),
    includedWalletIds: <String>{
      'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // metamask
    },
  );

  Future<DeployedContract> get deployedGreeterContract async {
    const String abiDirectory = 'lib/contracts/staging/greeter.abi.json';
    const String contractAddress = '0x0e10e90f67C67c2cB9DD5071674FDCfb7853a6F5';
    final String contractABI = await rootBundle.loadString(abiDirectory);

    final DeployedContract contract = DeployedContract(
      ContractAbi.fromJson(contractABI, 'Greeter'),
      EthereumAddress.fromHex(contractAddress),
    );

    return contract;
  }

  @override
  void initState() {
    super.initState();
    initializeW3M();
  }

  Future<void> initializeW3M() async {
    try {
      // await w3mService.selectChain(
      //   W3MChainInfo(
      //     chainName: 'Ethereum Sepolia Testnet',
      //     chainId: '11155111',
      //     namespace: 'eip155:11155111',
      //     tokenName: 'ETH',
      //     rpcUrl: 'https://sepolia.drpc.org',
      //   ),
      // );
      await w3mService.init();
      log('Initialized!');
    } catch (e) {
      print('---Instantiate Error---');
      print(e);
    }
  }

  Future<void> read() async {
    try {
      final List<dynamic> contractData = await w3mService.requestReadContract(
        deployedContract: await deployedGreeterContract,
        functionName: 'greet',
      );
      print('----Contract Data----');
      print(contractData);
    } catch (e, s) {
      print('---Read Error---');
      print(e);
      print('---Stack Trace---');
      print(s);
    }
  }

  Future<void> write() async {
    final List<String> accounts =
        w3mService.session?.getAccounts() ?? <String>[];

    if (accounts.isNotEmpty) {
      final String sender = accounts.first.split(':').last;

      w3mService.launchConnectedWallet();

      await w3mService.requestWriteContract(
        chainId: 'eip155:11155111',
        topic: w3mService.session?.topic ?? '',
        deployedContract: await deployedGreeterContract,
        functionName: 'setGreeting',
        parameters: <String>['Update this greeting!'],
        method: 'setGreeting',
        transaction: Transaction(
          from: EthereumAddress.fromHex(sender),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            W3MConnectWalletButton(
              context: context,
              service: w3mService,
            ),
            ElevatedButton(onPressed: read, child: const Text('Read')),
            ElevatedButton(onPressed: write, child: const Text('Write'))
          ],
        ),
      ),
    );
  }
}
