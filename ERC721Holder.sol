pragma solidity ^0.4.24;

import "./ERC721TokenReceiver.sol";


contract ERC721Holder is ERC721TokenReceiver {
  function onERC721Received(address, uint256, bytes) public returns(bytes4) {
    return ERC721_RECEIVED;
  }
}
