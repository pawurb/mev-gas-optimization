// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// based on https://github.com/CodeForcer/foundry-yul/blob/main/test/lib/YulDeployer.sol

import "forge-std/Test.sol";

contract BytecodeDeployer is Test {
    ///@notice Compiles a Yul contract and returns the address that the contract was deployeod to
    ///@notice If deployment fails, an error will be thrown
    ///@param fileName - The file name of the a file with bytecode under bytecode dir without .hex in the end. "/bytecode/Test.hex" -> "Test"
    ///@return deployedAddress - The address that the contract was deployed to
    function deployContract(string memory fileName) public returns (address) {
        string memory bashCommand = string.concat(
            'cast abi-encode "f(bytes)" $(cat bytecode/',
            string.concat(fileName, ".hex | tail -n 1)")
        );

        string[] memory inputs = new string[](3);
        inputs[0] = "bash";
        inputs[1] = "-c";
        inputs[2] = bashCommand;

        bytes memory bytecode = abi.decode(vm.ffi(inputs), (bytes));

        ///@notice deploy the bytecode with the create instruction
        address deployedAddress;
        vm.broadcast();
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        ///@notice check that the deployment was successful
        require(
            deployedAddress != address(0),
            "BytecodeDeployer could not deploy contract"
        );

        ///@notice return the address that the contract was deployed to
        return deployedAddress;
    }
}
