// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract RewardToken is ERC20, Ownable2Step {

    address public swapperContract;

    error Not_Swapper_Contract();
    error Zero_Address();

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender) {}

    function mint(
        address _recipient,
        uint256 _amount
    ) external {
        onlySwapperContract(msg.sender);
        isZeroAddress(_recipient);
        _mint(_recipient, _amount);
    }

    function burn(
        address _account,
        uint256 _amount
    ) external {
        onlySwapperContract(msg.sender);
        isZeroAddress(_account);
        _burn(_account, _amount);
    }

    function updateSwapperContract(
        address _swapperContract
    ) external onlyOwner {
        swapperContract = _swapperContract;
    }

    function onlySwapperContract(address _address) internal view {
        if(_address != swapperContract) {
            revert Not_Swapper_Contract();
        }
    }

    function isZeroAddress(address _address) internal pure {
        if(_address == address(0)) {
            revert Zero_Address();
        }
    }
}