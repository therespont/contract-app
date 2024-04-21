// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";

contract Forwarder is ERC2771Forwarder {
    address private contractSigner;

    constructor(string memory name, address signer) ERC2771Forwarder(name) {
        contractSigner = signer;
    }

    function execute(ForwardRequestData calldata request)
        public
        payable
        virtual
        override
    {
        require(msg.sender == contractSigner);

        return super.execute(request);
    }

    function executeBatch(
        ForwardRequestData[] calldata request,
        address payable refundReceiver
    ) public payable virtual override {
        require(msg.sender == contractSigner);

        return super.executeBatch(request, refundReceiver);
    }

    function verify(ForwardRequestData calldata request)
        public
        view
        virtual
        override
        returns (bool)
    {
        require(msg.sender == contractSigner);

        return super.verify(request);
    }
}
