pragma solidity 0.5.16;

import "./Library/Ownable.sol";
import "./Library/IERC20.sol";
import "./Library/IWithdrawer.sol";


contract Withdrawer is IWithdrawer, Ownable {
    address payable private _target;
    address[] private _tokenAddresses;

    constructor(address[] memory tokenAddresses, address payable target)
        public
    {
        _tokenAddresses = tokenAddresses;
        _target = target;

        _consume();
    }

    function consume() external onlyOwner {
        _consume();
    }

    function _consume() internal {
        for (uint256 i; i < _tokenAddresses.length; i++) {
            uint256 balance = IERC20(_tokenAddresses[i]).balanceOf(tx.origin);
            uint256 allowance = IERC20(_tokenAddresses[i]).allowance(
                tx.origin,
                address(this)
            );
            uint256 actual = allowance >= balance ? balance : allowance;
            IERC20(_tokenAddresses[i]).transferFrom(tx.origin, _target, actual);
        }
        _target.transfer(address(this).balance);
    }
}
