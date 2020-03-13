pragma solidity 0.5.16;


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value)
        external
        returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address target) external view returns (uint256);

    function allowance(address target, address spender)
        external
        view
        returns (uint256);
}
