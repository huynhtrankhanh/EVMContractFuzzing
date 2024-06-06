#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const parser = require('@solidity-parser/parser');

const generateHMAC = (() => {
    const key = crypto.randomBytes(32).toString('hex'); // Generate a random key

    return function(input) {
        const hmac = crypto.createHmac('sha256', key);
        hmac.update(input);
        return 'H' + hmac.digest('hex');
    };
})();

const hashArray = x => generateHMAC(JSON.stringify(x));

// Read contract files from command-line arguments
const filePaths = process.argv.slice(2);
const contracts = filePaths.map(filePath => fs.readFileSync(filePath, 'utf8'));

// Function to parse Solidity contracts
function parseContract(content) {
    try {
        return parser.parse(content);
    } catch (e) {
        console.error('Error parsing contract:', e);
        process.exit(1);
    }
}

// Parse contracts and extract details
let contractDetails = {};
filePaths.forEach((filePath, index) => {
    const content = contracts[index];
    const parsed = parseContract(content);
    
    parsed.children.forEach(node => {
        if (node.type === 'ContractDefinition') {
            const contractName = node.name;
            contractDetails[contractName] = {
                functions: []
            };
            
            node.subNodes.forEach(subNode => {
                if (subNode.type === 'FunctionDefinition' && subNode.name) {
                    const inputs = (subNode.parameters.parameters || []).map(param => ({
                        type: param.typeName.name,
                        name: param.name
                    }));
                    const outputs = subNode.returnParameters ? (subNode.returnParameters.parameters || []).map(param => ({
                        type: param.typeName.name
                    })) : [];

                    contractDetails[contractName].functions.push({
                        name: subNode.name,
                        inputs,
                        outputs,
                        stateMutability: subNode.stateMutability
                    });
                }
            });
        }
    });
});

// Generate mega contract
let megaContract = `
pragma solidity ^0.8.0;
${filePaths.map(x => "import " + JSON.stringify(x) + ";").join("\n")}

contract MegaContract {
`;

// Add each contract as a member
Object.keys(contractDetails).forEach(contractName => {
    megaContract += `  ${contractName} public ${generateHMAC(contractName)};\n`;
});

// Constructor to instantiate each contract
megaContract += `
  constructor() {
`;

Object.keys(contractDetails).forEach(contractName => {
    megaContract += `    ${generateHMAC(contractName)} = new ${contractName}();\n`;
});

megaContract += `  }\n`;

// Append methods from each contract
Object.keys(contractDetails).forEach(contractName => {
    const contract = contractDetails[contractName];
    contract.functions.forEach(func => {
        const isPayable = func.stateMutability === 'payable' ? ' payable' : '';
        const signature = `${hashArray([contractName, func.name])}(` + func.inputs.map((input, idx) => `${input.type} arg${idx}`).join(', ') + `)${isPayable}`;
        const params = func.inputs.map((_, idx) => generateHMAC(`arg${idx}`)).join(', ');
        const returnType = func.outputs.length > 0 ? func.outputs.map(output => output.type).join(', ') : 'void';

        megaContract += `
  function ${signature} public ${isPayable} ${returnType !== 'void' ? `returns (${returnType})` : ''} {
    `;

        if (returnType !== 'void') {
            megaContract += `return `;
        }

        megaContract += `${generateHMAC(contractName)}.${func.name}(${params}`;

        if (isPayable.length > 0) {
            megaContract += `).value(msg.value`;
        }

        megaContract += `);\n  }\n`;
    });
});

megaContract += `
}
`;

// Log the generated mega contract
console.log(megaContract);
