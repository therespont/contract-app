// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@opengsn/contracts/src/ERC2771Recipient.sol";
import {Key} from "./key.sol";

contract Main is ERC2771Recipient {
    address private contractOwner;
    mapping(address => mapping(address => address[])) private Room;

    event KeyGeneration(
        address indexed _AddressPair1,
        address indexed _AddressPair2
    );

    event trustedForwarder(address indexed _trustedForwarder);

    constructor(address _trustedForwarder) {
        contractOwner = msg.sender;
        _setTrustedForwarder(_trustedForwarder);
    }

    function getTrustedForwarder() public view override returns (address) {
        require(msg.sender == contractOwner);

        return super.getTrustedForwarder();
    }

    function setTrustedForwarder(address _trustedForwarder) public {
        require(msg.sender == contractOwner);

        emit trustedForwarder(_trustedForwarder);

        _setTrustedForwarder(_trustedForwarder);
    }

    function GenerateKeyLocation(
        string memory _Key,
        address _AddressPair,
        bytes memory _IssuerKey
    ) public returns (address[] memory) {
        Key Deploy = new Key(_Key, _IssuerKey, _msgSender(), _AddressPair);

        Room[_msgSender()][_AddressPair].push(address(Deploy));
        Room[_AddressPair][_msgSender()].push(address(Deploy));

        emit KeyGeneration(_msgSender(), _AddressPair);
        emit KeyGeneration(_AddressPair, _msgSender());

        return Room[_msgSender()][_AddressPair];
    }

    function GetKeyLocation(address _AddressPair)
        public
        view
        returns (address[] memory)
    {
        return Room[msg.sender][_AddressPair];
    }
}
