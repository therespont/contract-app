// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import {Cryptography} from "./crypto.sol";

contract Key {
    struct IssuerKeyStruct {
        bytes Issuer1;
    }

    struct IssuerAddressStruct {
        address Issuer1;
        address Issuer2;
    }

    bytes32 private Secret;

    IssuerKeyStruct private IssuerKey;
    IssuerAddressStruct private IssuerAddress;

    constructor(
        string memory _Key,
        bytes memory _IssuerKey1,
        address _IssuerAddress1,
        address _IssuerAddress2
    ) {
        Secret = bytes32(
            uint256(
                keccak256(
                    abi.encodePacked(
                        string.concat(
                            string(_IssuerKey1),
                            string(abi.encodePacked(_IssuerAddress1)),
                            _Key,
                            string(abi.encodePacked(_IssuerAddress2))
                        )
                    )
                )
            )
        );

        IssuerKey.Issuer1 = _IssuerKey1;

        IssuerAddress.Issuer1 = _IssuerAddress1;
        IssuerAddress.Issuer2 = _IssuerAddress2;
    }

    function Bytes(string memory _Text) public view returns (bytes memory) {
        require(
            IssuerAddress.Issuer1 == msg.sender ||
                IssuerAddress.Issuer2 == msg.sender,
            "You're not allowed to perform this action."
        );

        return Cryptography.Encrypt(_Text, Secret);
    }

    function Text(bytes memory _Bytes) public view returns (string memory){
        require(
            IssuerAddress.Issuer1 == msg.sender ||
                IssuerAddress.Issuer2 == msg.sender,
            "You're not allowed to perform this action."
        );

        return Cryptography.Decrypt(_Bytes, Secret);
    }
}
