const web3 = require('web3');
const solc = require("solc");
const { BN, toWei } = require('web3-utils');
const { Transaction } = require('@ethereumjs/tx');
const { Common, Chain, Hardfork } = require('@ethereumjs/common');
const { VM } = require('@ethereumjs/vm');
const { Account, Address, privateToAddress, toBuffer } = require('ethereumjs-util');
const keythereum = require("keythereum");
const privateKey = keythereum.create({ keyBytes: 32, ivBytes: 16 }).privateKey;
const senderAddress = Address.fromPrivateKey(privateKey);
const common = new Common({ chain: Chain.Mainnet, hardfork: Hardfork.London });
const vm = new VM({ common });

async function main() {
    const contractCode = `
        pragma solidity ^0.8.0;

        contract PrimeFactorizationGame {
            address public owner;

            struct Number {
                uint256 value;
                uint256 prize;
                bool claimed;
            }

            Number[20] public numbers;

            event PrizeClaimed(address claimant, uint256 amount);

            constructor() {
                owner = msg.sender;
                // Initialization
                numbers[0] = Number(2, 0.5 ether, false);
                numbers[1] = Number(3, 0.5 ether, false);
                numbers[2] = Number(5, 1 ether, false);
                numbers[3] = Number(7, 1.5 ether, false);
                numbers[4] = Number(11, 2 ether, false);
                numbers[5] = Number(13, 2.5 ether, false);
                numbers[6] = Number(17, 3 ether, false);
                numbers[7] = Number(19, 3.5 ether, false);
                numbers[8] = Number(23, 4 ether, false);
                numbers[9] = Number(29, 4.5 ether, false);
                numbers[10] = Number(31, 5 ether, false);
                numbers[11] = Number(37, 5.5 ether, false);
                numbers[12] = Number(41, 6 ether, false);
                numbers[13] = Number(43, 6.5 ether, false);
                numbers[14] = Number(47, 7 ether, false);
                numbers[15] = Number(53, 7.5 ether, false);
                numbers[16] = Number(59, 8 ether, false);
                numbers[17] = Number(61, 8.5 ether, false);
                numbers[18] = Number(67, 9 ether, false);
                numbers[19] = Number(71, 9.5 ether, false);
            }

            function claimPrize(uint256 numberIndex, uint256[] calldata factors) external {
                require(numberIndex < numbers.length, "Invalid number index.");
                Number storage number = numbers[numberIndex];
                require(!number.claimed, "Prize already claimed.");
                require(isValidFactorization(number.value, factors), "Invalid or non-prime factorization.");
                
                (bool success, ) = msg.sender.call{value: number.prize}("");
                require(success, "Failed to send Ether");
                number.claimed = true;
                emit PrizeClaimed(msg.sender, number.prize);
            }

            function isValidFactorization(uint256 number, uint256[] calldata factors) internal pure returns (bool) {
                uint256 product = 1;
                for (uint256 i = 0; i < factors.length; i++) {
                    if (!isPrime(factors[i]) || product * factors[i] > number) {
                        return false;
                    }
                    product *= factors[i];
                }
                return product == number;
            }

            function isPrime(uint256 _number) internal pure returns (bool) {
                if (_number < 2) return false;
                for (uint256 i = 2; i * i <= _number; i++) {
                    if (_number % i == 0) return false;
                }
                return true;
            }
            
            // Function to add funds to the contract. Only the owner can add funds.
            function deposit() external payable {
                require(msg.value > 0, "Deposit must be more than 0.");
            }

            // Withdraw function for extracting funds. Only the owner can withdraw.
            function withdraw(uint256 amount) external {
                require(amount <= address(this).balance, "Insufficient funds.");
                (bool success, ) = owner.call{value: amount}("");
                require(success, "Failed to send Ether.");
            }
        }
    `;

    // Compile the contract
    const input = {
        language: 'Solidity',
        sources: {
            'PrimeFactorizationGame.sol': {
                content: contractCode,
            },
        },
        settings: {
            outputSelection: {
                '*': {
                    '*': ['abi', 'evm.bytecode'],
                },
            },
        },
    };

    const output = JSON.parse(solc.compile(JSON.stringify(input)));

    const abi = output.contracts['PrimeFactorizationGame.sol']['PrimeFactorizationGame'].abi;
    const bytecode = output.contracts['PrimeFactorizationGame.sol']['PrimeFactorizationGame'].evm.bytecode.object;

    const account = Account.fromAccountData({
      nonce: new BN(0),
      balance: new BN(10000000000), // initial balance
    });
    await vm.stateManager.putAccount(address, account);
    const retrievedAccount = await vm.stateManager.getAccount(address);

    // Deploy the contract
    const nonce = await vm.stateManager.getAccountNonce(senderAddress);
    const deployTxData = {
        data: `0x${bytecode}`,
        gasLimit: 1000000,
        gasPrice: toWei('20', 'gwei'),
        nonce: retrievedAccount.nonce.toNumber(),
    };

    const tx = Transaction.fromTxData(deployTxData, { common }).sign(privateKey);
    const receipt = await vm.runTx({ tx });

    const contractAddress = receipt.receipt.contractAddress;

    console.log('Contract deployed at:', contractAddress.toString());

    // Initialize the contract with 1000 ETH
    const depositTxData = {
        to: contractAddress,
        value: toWei('1000', 'ether'),
        gasLimit: 21000,
        gasPrice: toWei('20', 'gwei'),
        nonce: nonce.addn(1).toNumber(),
    };

    const depositTx = Transaction.fromTxData(depositTxData, { common }).sign(privateKey);
    await vm.runTx({ tx: depositTx });

    console.log('1000 ETH sent to contract:', contractAddress.toString());

    // Assume the contract is initialized successfully, now claim rewards
    for (let i = 0; i < 20; i++) {
        const claimPrizeData = web3.eth.abi.encodeFunctionCall(abi.find((f) => f.name === 'claimPrize'), [
            i,
            [numbers[i].value], // Prime factors of prime is the number itself.
        ]);

        const claimTxData = {
            to: contractAddress,
            data: claimPrizeData,
            gasLimit: 1000000,
            gasPrice: toWei('20', 'gwei'),
            nonce: nonce.addn(2 + i).toNumber(),
        };

        const claimTx = Transaction.fromTxData(claimTxData, { common }).sign(privateKey);
        await vm.runTx({ tx: claimTx });

        console.log(`Prize for number ${numbers[i].value} claimed.`);
    }
}

main().catch(console.error);
