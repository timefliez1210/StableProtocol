//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

interface IStable {
    //////////////////////////////
    //// View Functions
    //////////////////////////////
    function isWhitelisted(address _token) external view returns (bool);
    function getTotalBalance(address _asset) external view returns (uint256);
    function getUserBalance(address _user, address _asset) external view returns (uint256);
    function isLiquidatable(address _user) external view returns (bool);
    function getStableLendingHealthFactor() external view returns (uint256);
    function getSusdAddress() external view returns (address);
    function getHealthFactor(address _user) external view returns (uint256);

    //////////////////////////////
    //// State Changing Functions
    //////////////////////////////
    function deposit(address _asset, uint256 _amount) external;
    function withdraw(address _asset, uint256 _amount) external;
    function whitelistTokens(address _token) external;
    function mintStable(uint256 _amountToMint, uint256[] calldata _amountColleteral, address[] calldata _colleteral)
        external;
    function repayStable(uint256 _amount) external;
    function unlockColleteral(address _asset, uint256 _amount) external;
    function liquidatePosition(address _user) external;
    function donate(uint256 _amount) external;
}
