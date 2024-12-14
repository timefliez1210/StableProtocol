# Aderyn Analysis Report

This report was generated by [Aderyn](https://github.com/Cyfrin/aderyn), a static analysis tool built by [Cyfrin](https://cyfrin.io), a blockchain security company. This report is not a substitute for manual audit or security review. It should not be relied upon for any purpose other than to assist in the identification of potential security vulnerabilities.
# Table of Contents

- [Summary](#summary)
  - [Files Summary](#files-summary)
  - [Files Details](#files-details)
  - [Issue Summary](#issue-summary)
- [Low Issues](#low-issues)
  - [L-1: Centralization Risk for trusted owners](#l-1-centralization-risk-for-trusted-owners)
  - [L-2: Unsafe ERC20 Operations should not be used](#l-2-unsafe-erc20-operations-should-not-be-used)
  - [L-3: `public` functions not used internally could be marked `external`](#l-3-public-functions-not-used-internally-could-be-marked-external)
  - [L-4: Modifiers invoked only once can be shoe-horned into the function](#l-4-modifiers-invoked-only-once-can-be-shoe-horned-into-the-function)
  - [L-5: Contract still has TODOs](#l-5-contract-still-has-todos)
  - [L-6: Unused Custom Error](#l-6-unused-custom-error)
  - [L-7: Loop contains `require`/`revert` statements](#l-7-loop-contains-requirerevert-statements)
  - [L-8: Uninitialized local variables.](#l-8-uninitialized-local-variables)
  - [L-9: Loop condition contains `state_variable.length` that could be cached outside.](#l-9-loop-condition-contains-statevariablelength-that-could-be-cached-outside)
  - [L-10: Costly operations inside loops.](#l-10-costly-operations-inside-loops)
  - [L-11: Unused Imports](#l-11-unused-imports)
  - [L-12: State variable changes but no event is emitted.](#l-12-state-variable-changes-but-no-event-is-emitted)
  - [L-13: State variable could be declared immutable](#l-13-state-variable-could-be-declared-immutable)


# Summary

## Files Summary

| Key | Value |
| --- | --- |
| .sol Files | 5 |
| Total nSLOC | 228 |


## Files Details

| Filepath | nSLOC |
| --- | --- |
| src/Stable.sol | 62 |
| src/Utils.sol | 41 |
| src/mocks/MockOracle.sol | 6 |
| src/modules/Lending.sol | 104 |
| src/tokens/StableUSD.sol | 15 |
| **Total** | **228** |


## Issue Summary

| Category | No. of Issues |
| --- | --- |
| High | 0 |
| Low | 13 |


# Low Issues

## L-1: Centralization Risk for trusted owners

Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

<details><summary>3 Found Instances</summary>


- Found in src/Stable.sol [Line: 80](src/Stable.sol#L80)

	```solidity
	    function whitelistTokens(address _token) external onlyOwner {
	```

- Found in src/tokens/StableUSD.sol [Line: 10](src/tokens/StableUSD.sol#L10)

	```solidity
	contract StableUSD is ERC20, ERC20Burnable, Ownable, ERC20Permit {
	```

- Found in src/tokens/StableUSD.sol [Line: 17](src/tokens/StableUSD.sol#L17)

	```solidity
	    function mint(address to, uint256 amount) public onlyOwner {
	```

</details>



## L-2: Unsafe ERC20 Operations should not be used

ERC20 functions may not behave as expected. For example: return values are not always meaningful. It is recommended to use OpenZeppelin's SafeERC20 library.

<details><summary>1 Found Instances</summary>


- Found in src/modules/Lending.sol [Line: 74](src/modules/Lending.sol#L74)

	```solidity
	                    IERC20(allowlist[i]).transfer(msg.sender, amountToSend);
	```

</details>



## L-3: `public` functions not used internally could be marked `external`

Instead of marking a function as `public`, consider marking it as `external` if it is not used internally.

<details><summary>4 Found Instances</summary>


- Found in src/Stable.sol [Line: 88](src/Stable.sol#L88)

	```solidity
	    function isWhitelisted(address _token) public view returns (bool) {
	```

- Found in src/Stable.sol [Line: 92](src/Stable.sol#L92)

	```solidity
	    function getTotalBalance(address _asset) public view returns (uint256) {
	```

- Found in src/Stable.sol [Line: 96](src/Stable.sol#L96)

	```solidity
	    function getUserBalance(address _user, address _asset) public view returns (uint256) {
	```

- Found in src/tokens/StableUSD.sol [Line: 17](src/tokens/StableUSD.sol#L17)

	```solidity
	    function mint(address to, uint256 amount) public onlyOwner {
	```

</details>



## L-4: Modifiers invoked only once can be shoe-horned into the function



<details><summary>1 Found Instances</summary>


- Found in src/Utils.sol [Line: 26](src/Utils.sol#L26)

	```solidity
	    modifier onlyOwner() {
	```

</details>



## L-5: Contract still has TODOs

Contract contains comments with TODOS

<details><summary>2 Found Instances</summary>


- Found in src/Utils.sol [Line: 7](src/Utils.sol#L7)

	```solidity
	abstract contract Utils is MockOracle {
	```

- Found in src/modules/Lending.sol [Line: 12](src/modules/Lending.sol#L12)

	```solidity
	abstract contract Lending is Utils {
	```

</details>



## L-6: Unused Custom Error

it is recommended that the definition be removed when custom error is unused

<details><summary>1 Found Instances</summary>


- Found in src/Stable.sol [Line: 23](src/Stable.sol#L23)

	```solidity
	    error StopDoingWeirdStuff();
	```

</details>



## L-7: Loop contains `require`/`revert` statements

Avoid `require` / `revert` statements in a loop because a single bad item can cause the whole transaction to fail. It's better to forgive on fail and return failed elements post processing of the loop

<details><summary>2 Found Instances</summary>


- Found in src/modules/Lending.sol [Line: 85](src/modules/Lending.sol#L85)

	```solidity
	        for(uint256 i; i < allowlist.length; i++) {
	```

- Found in src/modules/Lending.sol [Line: 96](src/modules/Lending.sol#L96)

	```solidity
	        for(uint256 i = 0; i < _colleteral.length; i++) {
	```

</details>



## L-8: Uninitialized local variables.

Initialize all the variables. If a variable is meant to be initialized to zero, explicitly set it to zero to improve code readability.

<details><summary>1 Found Instances</summary>


- Found in src/modules/Lending.sol [Line: 85](src/modules/Lending.sol#L85)

	```solidity
	        for(uint256 i; i < allowlist.length; i++) {
	```

</details>



## L-9: Loop condition contains `state_variable.length` that could be cached outside.

Cache the lengths of storage arrays if they are used and not modified in for loops.

<details><summary>2 Found Instances</summary>


- Found in src/modules/Lending.sol [Line: 68](src/modules/Lending.sol#L68)

	```solidity
	            for(uint256 i; i < allowlist.length; i++){
	```

- Found in src/modules/Lending.sol [Line: 85](src/modules/Lending.sol#L85)

	```solidity
	        for(uint256 i; i < allowlist.length; i++) {
	```

</details>



## L-10: Costly operations inside loops.

Invoking `SSTORE`operations in loops may lead to Out-of-gas errors. Use a local variable to hold the loop computation result.

<details><summary>2 Found Instances</summary>


- Found in src/modules/Lending.sol [Line: 68](src/modules/Lending.sol#L68)

	```solidity
	            for(uint256 i; i < allowlist.length; i++){
	```

- Found in src/modules/Lending.sol [Line: 121](src/modules/Lending.sol#L121)

	```solidity
	        for(uint256 i = 0; i < _colleteral.length; i++) {
	```

</details>



## L-11: Unused Imports

Redundant import statement. Consider removing it.

<details><summary>1 Found Instances</summary>


- Found in src/Stable.sol [Line: 9](src/Stable.sol#L9)

	```solidity
	import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
	```

</details>



## L-12: State variable changes but no event is emitted.

State variable changes in this function but no event is emitted.

<details><summary>6 Found Instances</summary>


- Found in src/Stable.sol [Line: 38](src/Stable.sol#L38)

	```solidity
	    function deposit(address _asset, uint256 _amount) external payable {
	```

- Found in src/Stable.sol [Line: 54](src/Stable.sol#L54)

	```solidity
	    function withdraw(address _asset, uint256 _amount) external nonReentrant {
	```

- Found in src/Stable.sol [Line: 80](src/Stable.sol#L80)

	```solidity
	    function whitelistTokens(address _token) external onlyOwner {
	```

- Found in src/modules/Lending.sol [Line: 31](src/modules/Lending.sol#L31)

	```solidity
	    function mintStable(uint256 _amount, address[] calldata _colleteral) external {
	```

- Found in src/modules/Lending.sol [Line: 46](src/modules/Lending.sol#L46)

	```solidity
	    function repayStable(uint256 _amount) external {
	```

- Found in src/modules/Lending.sol [Line: 59](src/modules/Lending.sol#L59)

	```solidity
	    function liquidatePosition(address _user) external nonReentrant {
	```

</details>



## L-13: State variable could be declared immutable

State variables that are should be declared immutable to save gas. Add the `immutable` attribute to state variables that are only changed in the constructor

<details><summary>1 Found Instances</summary>


- Found in src/Utils.sol [Line: 12](src/Utils.sol#L12)

	```solidity
	    address owner;
	```

</details>


