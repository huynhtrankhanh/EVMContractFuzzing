const solc = require('solc');
const crypto = require('crypto');
const generateHMAC = (() => {
    const key = crypto.randomBytes(32).toString('hex'); // Generate a random key

    return function(input) {
        const hmac = crypto.createHmac('sha256', key);
        hmac.update(input);
        return 'H' + hmac.digest('hex');
    };
})();
const hashArray = x => generateHMAC(JSON.stringify(x));

// Dummy array of Solidity contract strings
const contracts = [
  `
  // SPDX-License-Identifier: 0BSD
  pragma solidity ^0.8.0;

  contract ContractA {
      function foo() public pure returns (string memory) {
          return "foo";
      }
  }
  `,
  `
  // SPDX-License-Identifier: 0BSD
  pragma solidity ^0.8.0;

  contract ContractB {
      function bar() public pure returns (string memory) {
          return "bar";
      }
  }
  `,
];

// Create input format required by solc compiler
const input = {
  language: 'Solidity',
  sources: contracts.reduce((acc, contract, index) => {
    acc[`Contract${index}.sol`] = { content: contract };
    return acc;
  }, {}),
  settings: {
    outputSelection: {
      '*': {
        '*': ['*']
      }
    }
  }
};

// Compile contracts
const output = JSON.parse(solc.compile(JSON.stringify(input)));

// error handling
if (output.errors) {
  output.errors.forEach(err => {
    console.error(err.formattedMessage);
  });
  throw new Error("Compilation failed");
}

// Extract contract names
const contractNames = Object.keys(output.contracts);

// Generate mega contract
let megaContract = `
pragma solidity ^0.8.0;

contract MegaContract {
`;

// Add each contract as a member
contractNames.forEach(name => {
  for (const baseName of Object.keys(output.contracts[name]))
    megaContract += `  ${baseName} public ${generateHMAC(baseName)};\n`;
});

// Constructor to instantiate each contract
megaContract += `
  constructor() {
`;

contractNames.forEach(name => {
  for (const baseName of Object.keys(output.contracts[name]))
    megaContract += `    ${generateHMAC(baseName)} = new ${baseName}();\n`;
});

megaContract += `  }\n`;

// Append methods from each contract
contractNames.forEach(name => {
  for (const baseName of Object.keys(output.contracts[name])) {
    const contractOutput = output.contracts[name][baseName].abi;

    contractOutput.forEach(item => {
      if (item.type === 'function') {
        const signature = `${hashArray([baseName, item.name])}(` + item.inputs.map((input, idx) => `${input.type} arg${idx}`).join(', ') + `)`;
        const params = item.inputs.map((_, idx) => generateHMAC(`arg${idx}`)).join(', ');
        const returnType = item.outputs.length > 0 ? item.outputs[0].type : 'void';

        megaContract += `
  function ${signature} public ${returnType !== 'void' ? `returns (${returnType})` : ''} {
    return ${generateHMAC(baseName)}.${item.name}(${params});
  }\n`;
      }
    });
  }
});

megaContract += `
}
`;

// Log the generated mega contract
console.log(megaContract);
