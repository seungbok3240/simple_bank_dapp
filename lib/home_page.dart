import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:web_socket_channel/io.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String rpcUrl = "HTTP://10.0.2.2:7545";
  final String wsUrl = "ws://10.0.2.2:7545/";
  final String privateKey = "85fe18161d7c996eba05a8595d4b0400592d751ae71ea3ead3975152303da1b8";

  var balance = 0;
  late String selectedBalance;

  late Client httpClient;
  late Web3Client ethClient;

  @override
  void initState() {
    initialSetup();
    super.initState();
  }

  Future<void> initialSetup() async {
    httpClient = Client();
    ethClient = Web3Client(rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(wsUrl).cast<String>();
    });

    await getCredentials();
    await getDeployedContract();
    await getContractFunctions();
  }


  late Credentials credentials;
  late EthereumAddress myAddress;

  Future<void> getCredentials() async {
    credentials = EthPrivateKey.fromHex(privateKey);
    myAddress = await credentials.extractAddress();
  }

  late String abi;
  late EthereumAddress contractAddress;

  Future<void> getDeployedContract() async {
    String abiString = await rootBundle.loadString('assets/json/Bank.json');
    var abiJson = jsonDecode(abiString);
    abi = jsonEncode(abiJson['abi']);

    contractAddress =
        EthereumAddress.fromHex(abiJson['networks']['5777']['address']);
  }

  late DeployedContract contract;
  late ContractFunction getBalance, deposit, withdraw;

  Future<void> getContractFunctions() async {
    contract = DeployedContract(
        ContractAbi.fromJson(abi, "Bank"), contractAddress);

    getBalance = contract.function('getBalance');
    deposit = contract.function('deposit');
    withdraw = contract.function('withdraw');
  }

  Future<List<dynamic>> readContract(
      ContractFunction functionName,
      List<dynamic> functionArgs,
      ) async {
    var queryResult = await ethClient.call(
      contract: contract,
      function: functionName,
      params: functionArgs,
    );

    return queryResult;
  }

  Future<void> writeContract(
      ContractFunction functionName,
      List<dynamic> functionArgs,
      ) async {
    await ethClient.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: functionName,
        parameters: functionArgs,
      ),
    );
  }


  PreferredSizeWidget _appbarWidget() {
    return AppBar(
      title: const Text('Simple Dapp'),
    );
  }

  Widget _bodyWidget() {
    return Center(
      child: Column(
        children: <Widget>[
          const Text('My Coin', style: TextStyle(
            fontSize: 30,
          ),),
          Text('Balance  ' + balance.toString(), style: TextStyle(
            fontSize: 20,
          ),),
          Padding(
            padding: const EdgeInsets.fromLTRB(50.0, 0, 50.0, 20.0),
            child: TextField(
              onChanged: (value) {
                selectedBalance = value;
              },
              decoration: const InputDecoration(
                hintText: "Set Balance",
              ),
            ),
          ),
          const SizedBox(height: 20,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              GestureDetector(
                onTap: () async {
                  await writeContract(deposit, [BigInt.from(int.parse(selectedBalance))]);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text('Deposit Success'),
                      content: Text(selectedBalance.toString() + ' Deposit success'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'OK'),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(7),
                  child: const Text('입금'),
                  color: Colors.green,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await writeContract(withdraw, [BigInt.from(int.parse(selectedBalance))]);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text('Withdraw Success'),
                      content: Text(selectedBalance.toString() + ' Withdraw success'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'OK'),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(7),
                  child: const Text('출금'),
                  color: Colors.red,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  var result = await readContract(getBalance, []);
                  setState(() {
                    balance = int.parse(result[0].toString());
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(7),
                  child: const Text('새로고침'),
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appbarWidget(),
      body: _bodyWidget(),
    );
  }
}
