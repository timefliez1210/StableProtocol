# Aderyn Analysis Report

This report was generated by [Aderyn](https://github.com/Cyfrin/aderyn), a static analysis tool built by [Cyfrin](https://cyfrin.io), a blockchain security company. This report is not a substitute for manual audit or security review. It should not be relied upon for any purpose other than to assist in the identification of potential security vulnerabilities.
# Table of Contents

- [Summary](#summary)
  - [Files Summary](#files-summary)
  - [Files Details](#files-details)
  - [Issue Summary](#issue-summary)
- [Low Issues](#low-issues)
  - [L-1: Centralization Risk for trusted owners](#l-1-centralization-risk-for-trusted-owners)
  - [L-2: `public` functions not used internally could be marked `external`](#l-2-public-functions-not-used-internally-could-be-marked-external)
  - [L-3: Define and use `constant` variables instead of using literals](#l-3-define-and-use-constant-variables-instead-of-using-literals)
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
| Total nSLOC | 283 |


## Files Details

| Filepath | nSLOC |
| --- | --- |
| src/Stable.sol | 62 |
| src/Utils.sol | 47 |
| src/mocks/MockOracle.sol | 6 |
| src/modules/StableLending.sol | 157 |
| src/tokens/StableUSD.sol | 11 |
| **Total** | **283** |


## Issue Summary

| Category | No. of Issues |
| --- | --- |
| High | 0 |
| Low | 13 |


# Low Issues

## L-1: Centralization Risk for trusted owners

Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

<details><summary>3 Found Instances</summary>


- Found in src/Stable.sol [Line: 88](src/Stable.sol#L88)

	```solidity
	    function whitelistTokens(address _token) external onlyOwner {
	```

- Found in src/tokens/StableUSD.sol [Line: 10](src/tokens/StableUSD.sol#L10)

	```solidity
	contract StableUSD is ERC20, ERC20Burnable, Ownable, ERC20Permit {
	```

- Found in src/tokens/StableUSD.sol [Line: 13](src/tokens/StableUSD.sol#L13)

	```solidity
	    function mint(address to, uint256 amount) public onlyOwner {
	```

</details>



## L-2: `public` functions not used internally could be marked `external`

Instead of marking a function as `public`, consider marking it as `external` if it is not used internally.

<details><summary>1 Found Instances</summary>


- Found in src/tokens/StableUSD.sol [Line: 13](src/tokens/StableUSD.sol#L13)

	```solidity
	    function mint(address to, uint256 amount) public onlyOwner {
	```

</details>



## L-3: Define and use `constant` variables instead of using literals

If the same constant literal value is used multiple times, create a constant state variable and reference it throughout the contract.

<details><summary>2 Found Instances</summary>


- Found in src/modules/StableLending.sol [Line: 80](src/modules/StableLending.sol#L80)

	```solidity
	        if (healthFactor < 100) {
	```

- Found in src/modules/StableLending.sol [Line: 129](src/modules/StableLending.sol#L129)

	```solidity
	        if (healthFactor > 100) {
	```

</details>



## L-4: Modifiers invoked only once can be shoe-horned into the function



<details><summary>1 Found Instances</summary>


- Found in src/Utils.sol [Line: 37](src/Utils.sol#L37)

	```solidity
	    modifier onlyOwner() {
	```

</details>



## L-5: Contract still has TODOs

Contract contains comments with TODOS

<details><summary>1 Found Instances</summary>


- Found in src/modules/StableLending.sol [Line: 22](src/modules/StableLending.sol#L22)

	```solidity
	abstract contract StableLending is Utils {
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

<details><summary>5 Found Instances</summary>


- Found in src/modules/StableLending.sol [Line: 75](src/modules/StableLending.sol#L75)

	```solidity
	        for (uint256 i; i < _colleteral.length; i++) {
	```

- Found in src/modules/StableLending.sol [Line: 152](src/modules/StableLending.sol#L152)

	```solidity
	            for (uint256 i; i < s_depositedColleteralsByUser[_user].length; i++) {
	```

- Found in src/modules/StableLending.sol [Line: 198](src/modules/StableLending.sol#L198)

	```solidity
	        for (uint256 i; i < allowlist.length; i++) {
	```

- Found in src/modules/StableLending.sol [Line: 214](src/modules/StableLending.sol#L214)

	```solidity
	        for (uint256 i; i < s_depositedColleteralsByUser[_user].length; i++) {
	```

- Found in src/modules/StableLending.sol [Line: 225](src/modules/StableLending.sol#L225)

	```solidity
	        for (uint256 i = 0; i < _colleteral.length; i++) {
	```

</details>



## L-8: Uninitialized local variables.

Initialize all the variables. If a variable is meant to be initialized to zero, explicitly set it to zero to improve code readability.

<details><summary>3 Found Instances</summary>


- Found in src/modules/StableLending.sol [Line: 75](src/modules/StableLending.sol#L75)

	```solidity
	        for (uint256 i; i < _colleteral.length; i++) {
	```

- Found in src/modules/StableLending.sol [Line: 198](src/modules/StableLending.sol#L198)

	```solidity
	        for (uint256 i; i < allowlist.length; i++) {
	```

- Found in src/modules/StableLending.sol [Line: 214](src/modules/StableLending.sol#L214)

	```solidity
	        for (uint256 i; i < s_depositedColleteralsByUser[_user].length; i++) {
	```

</details>



## L-9: Loop condition contains `state_variable.length` that could be cached outside.

Cache the lengths of storage arrays if they are used and not modified in for loops.

<details><summary>1 Found Instances</summary>


- Found in src/modules/StableLending.sol [Line: 198](src/modules/StableLending.sol#L198)

	```solidity
	        for (uint256 i; i < allowlist.length; i++) {
	```

</details>



## L-10: Costly operations inside loops.

Invoking `SSTORE`operations in loops may lead to Out-of-gas errors. Use a local variable to hold the loop computation result.

<details><summary>2 Found Instances</summary>


- Found in src/modules/StableLending.sol [Line: 83](src/modules/StableLending.sol#L83)

	```solidity
	        for (uint256 i; i < _colleteral.length; i++) {
	```

- Found in src/modules/StableLending.sol [Line: 152](src/modules/StableLending.sol#L152)

	```solidity
	            for (uint256 i; i < s_depositedColleteralsByUser[_user].length; i++) {
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

<details><summary>7 Found Instances</summary>


- Found in src/Stable.sol [Line: 39](src/Stable.sol#L39)

	```solidity
	    function deposit(address _asset, uint256 _amount) external payable {
	```

- Found in src/Stable.sol [Line: 62](src/Stable.sol#L62)

	```solidity
	    function withdraw(address _asset, uint256 _amount) external nonReentrant {
	```

- Found in src/Stable.sol [Line: 88](src/Stable.sol#L88)

	```solidity
	    function whitelistTokens(address _token) external onlyOwner {
	```

- Found in src/modules/StableLending.sol [Line: 71](src/modules/StableLending.sol#L71)

	```solidity
	    function mintStable(uint256 _amountToMint, uint256[] calldata _amountColleteral, address[] calldata _colleteral)
	```

- Found in src/modules/StableLending.sol [Line: 97](src/modules/StableLending.sol#L97)

	```solidity
	    function repayStable(uint256 _amount) external {
	```

- Found in src/modules/StableLending.sol [Line: 116](src/modules/StableLending.sol#L116)

	```solidity
	    function unlockColleteral(address _asset, uint256 _amount) external nonReentrant {
	```

- Found in src/modules/StableLending.sol [Line: 145](src/modules/StableLending.sol#L145)

	```solidity
	    function liquidatePosition(address _user) external nonReentrant {
	```

</details>



## L-13: State variable could be declared immutable

State variables that are should be declared immutable to save gas. Add the `immutable` attribute to state variables that are only changed in the constructor

<details><summary>1 Found Instances</summary>


- Found in src/Utils.sol [Line: 26](src/Utils.sol#L26)

	```solidity
	    address owner;
	```

</details>



