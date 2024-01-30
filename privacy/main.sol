// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Key} from "./key.sol";

contract Main {
    mapping(address => mapping(address => address[])) private Room;

    function GenerateKeyLocation(
        string memory _Key,
        address _AddressPair,
        bytes memory _IssuerKey
    ) public returns (address[] memory) {
        Key Deploy = new Key(_Key, _IssuerKey, msg.sender, _AddressPair);

        Room[msg.sender][_AddressPair].push(address(Deploy));
        Room[_AddressPair][msg.sender].push(address(Deploy));

        return Room[msg.sender][_AddressPair];
    }

    function GetKeyLocation(address _AddressPair)
        public
        view
        returns (address[] memory)
    {
        return Room[msg.sender][_AddressPair];
    }
}
