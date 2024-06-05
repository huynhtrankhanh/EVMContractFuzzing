#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
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

// Read contract files from command-line arguments
const filePaths = process.argv.slice(2);
const contracts = filePaths.map(filePath => fs.readFileSync(filePath, 'utf8'));

// Create input format required by solc compiler
const input = {
    language: 'Solidity',
    sources: filePaths.reduce((acc, filePath, index) => {
        acc[path.basename(filePath)] = { content: contracts[index] };
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

// Helper function to resolve imports
function findImports(importPath) {
    try {
        const resolvedPath = path.resolve(importPath);
        const source = fs.readFileSync(resolvedPath, 'utf8');
        return { contents: source };
    } catch (e) {
        return { error: 'File not found' };
    }
}

// Compile contracts
const output = JSON.parse(solc.compile(JSON.stringify(input), { import: findImports }));

// Error handling
if (output.errors) {
    output.errors.forEach(err => {
        console.error(err.formattedMessage);
    });
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
                const isPayable = item.stateMutability === 'payable' ? ' payable' : '';

                const signature = `${hashArray([baseName, item.name])}(` + item.inputs.map((input, idx) => `${input.type} arg${idx}`).join(', ') + `)${isPayable}`;
                
                const params = item.inputs.map((_, idx) => generateHMAC(`arg${idx}`)).join(', ');

                const returnType = item.outputs.length > 0 ? item.outputs.map(output => output.type).join(', ') : 'void';

                megaContract += `
  function ${signature} public ${isPayable} ${returnType !== 'void' ? `returns (${returnType})` : ''} {
    `;

                if (returnType !== 'void') {
                    megaContract += `return `;
                }

                megaContract += `${generateHMAC(baseName)}.${item.name}(${params}`;

                if (isPayable.length > 0) {
                    megaContract += `).value(msg.value`;
                }

                megaContract += `);\n  }\n`;
            }
        });
    }
});

megaContract += `
}
`;

// Log the generated mega contract
console.log(megaContract);
