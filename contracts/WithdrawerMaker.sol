pragma solidity 0.5.16;

import "./Library/Ownable.sol";
import "./Library/SafeMath.sol";
import "./Library/IWithdrawer.sol";
import "./Withdrawer.sol";


contract WithdrawerMaker is Ownable {
    using SafeMath for uint256;

    uint256 public nonce;
    address payable private _recipient;
    IWithdrawer[] private deployed;

    constructor(address payable recipient) public {
        _recipient = recipient;
    }

    function deploy(address[] memory tokenAddresses)
        public
        onlyOwner
        returns (address withdrawerInstance)
    {
        bytes memory initCode = abi.encodePacked(
            type(Withdrawer).creationCode,
            abi.encode(tokenAddresses, _recipient)
        );

        assembly {
            let encoded_data := add(0x20, initCode)
            let encoded_size := mload(initCode)
            let _nonce := sload(nonce_slot)
            withdrawerInstance := create2(
                callvalue,
                encoded_data,
                encoded_size,
                _nonce
            )

            if iszero(withdrawerInstance) {
                returndatacopy(0, 0, returndatasize)
                revert(0, returndatasize)
            }
        }

        deployed.push(IWithdrawer(withdrawerInstance));
        nonce = nonce.add(1);
    }

    function consumeWithOrder(uint256 order) public onlyOwner {
        require(
            deployed.length <= order,
            "WithdrawerMaker/Is-Not-Deployed-Withdrawer"
        );
        deployed[order].consume();
    }

    function calculateAddress(address[] memory tokenAddresses, uint256 order)
        public
        view
        returns (address target)
    {
        bytes memory initCode = abi.encodePacked(
            type(Withdrawer).creationCode,
            abi.encode(tokenAddresses, _recipient)
        );

        bytes32 initCodeHash = keccak256(initCode);

        target = address( // derive the target deployment address.
            uint160( // downcast to match the address type.
                uint256( // cast to uint to truncate upper digits.
                    keccak256( // compute CREATE2 hash using 4 inputs.
                        abi.encodePacked( // pack all inputs to the hash together.
                            bytes1(0xff), // pass in the control character.
                            address(this), // pass in the address of this contract.
                            order, // pass in the salt from above.
                            initCodeHash // pass in hash of contract creation code.
                        )
                    )
                )
            )
        );
    }
}
