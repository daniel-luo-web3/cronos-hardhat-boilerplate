// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyERC20} from "../contracts/MyERC20.sol";

/**
 * @title MyERC20Test
 * @dev Forge-style unit tests for MyERC20 contract
 * 
 * Run tests with:
 * npx hardhat test solidity
 * npx hardhat test solidity test/MyERC20.t.sol
 */
contract MyERC20Test is Test {
    MyERC20 public token;
    
    address public owner;
    address public controller;
    address public minter;
    address public user1;
    address public user2;
    
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 1e18;
    
    // Events to test
    event Transfer(address indexed from, address indexed to, uint256 value);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event Paused(address account);
    event Unpaused(address account);
    
    function setUp() public {
        // Setup test accounts
        owner = address(this);
        controller = makeAddr("controller");
        minter = makeAddr("minter");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Deploy token
        token = new MyERC20("Test Token", "TST");
    }
    
    /*//////////////////////////////////////////////////////////////
                        DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_InitialState() public view {
        assertEq(token.name(), "Test Token", "Name should be Test Token");
        assertEq(token.symbol(), "TST", "Symbol should be TST");
        assertEq(token.decimals(), 18, "Decimals should be 18");
        assertEq(token.totalSupply(), INITIAL_SUPPLY, "Total supply should match");
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY, "Owner should have initial supply");
    }
    
    function test_InitialRoles() public view {
        bytes32 defaultAdminRole = token.DEFAULT_ADMIN_ROLE();
        bytes32 controllerRole = token.CONTROLLER_ROLE();
        bytes32 minterRole = token.MINTER_ROLE();
        
        assertTrue(token.hasRole(defaultAdminRole, owner), "Owner should have DEFAULT_ADMIN_ROLE");
        assertTrue(token.hasRole(controllerRole, owner), "Owner should have CONTROLLER_ROLE");
        assertTrue(token.hasRole(minterRole, owner), "Owner should have MINTER_ROLE");
    }
    
    /*//////////////////////////////////////////////////////////////
                        MINTING TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_Mint() public {
        uint256 mintAmount = 1000 * 1e18;
        uint256 initialBalance = token.balanceOf(user1);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user1, mintAmount);
        
        token.mint(user1, mintAmount);
        
        assertEq(token.balanceOf(user1), initialBalance + mintAmount, "Balance should increase");
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount, "Total supply should increase");
    }
    
    function test_MintMultiple() public {
        uint256 amount1 = 100 * 1e18;
        uint256 amount2 = 200 * 1e18;
        
        token.mint(user1, amount1);
        token.mint(user2, amount2);
        
        assertEq(token.balanceOf(user1), amount1);
        assertEq(token.balanceOf(user2), amount2);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + amount1 + amount2);
    }
    
    function testFuzz_Mint(address to, uint256 amount) public {
        // Bound inputs
        vm.assume(to != address(0));
        amount = bound(amount, 0, type(uint96).max); // Reasonable upper bound
        
        uint256 initialBalance = token.balanceOf(to);
        uint256 initialSupply = token.totalSupply();
        
        token.mint(to, amount);
        
        assertEq(token.balanceOf(to), initialBalance + amount);
        assertEq(token.totalSupply(), initialSupply + amount);
    }
    
    function test_RevertWhen_MintWithoutRole() public {
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user2, 1000 * 1e18);
    }
    
    function test_MintWithMinterRole() public {
        // Grant MINTER_ROLE to minter address
        bytes32 minterRole = token.MINTER_ROLE();
        token.grantRole(minterRole, minter);
        
        // Minter should be able to mint
        vm.prank(minter);
        token.mint(user1, 1000 * 1e18);
        
        assertEq(token.balanceOf(user1), 1000 * 1e18);
    }
    
    /*//////////////////////////////////////////////////////////////
                        BURNING TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_Burn() public {
        uint256 burnAmount = 100 * 1e18;
        uint256 initialBalance = token.balanceOf(owner);
        uint256 initialSupply = token.totalSupply();
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), burnAmount);
        
        token.burn(burnAmount);
        
        assertEq(token.balanceOf(owner), initialBalance - burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);
    }
    
    function test_BurnFrom() public {
        uint256 burnAmount = 100 * 1e18;
        
        // Transfer some tokens to user1
        token.transfer(user1, 1000 * 1e18);
        
        // User1 approves owner to burn
        vm.prank(user1);
        token.approve(owner, burnAmount);
        
        uint256 initialBalance = token.balanceOf(user1);
        
        // Owner burns from user1
        token.burnFrom(user1, burnAmount);
        
        assertEq(token.balanceOf(user1), initialBalance - burnAmount);
    }
    
    function testFuzz_Burn(uint256 burnAmount) public {
        burnAmount = bound(burnAmount, 0, token.balanceOf(owner));
        
        uint256 initialBalance = token.balanceOf(owner);
        uint256 initialSupply = token.totalSupply();
        
        token.burn(burnAmount);
        
        assertEq(token.balanceOf(owner), initialBalance - burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);
    }
    
    function test_RevertWhen_BurnExceedsBalance() public {
        uint256 balance = token.balanceOf(user1);
        
        vm.prank(user1);
        vm.expectRevert();
        token.burn(balance + 1);
    }
    
    /*//////////////////////////////////////////////////////////////
                        PAUSE/UNPAUSE TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_Pause() public {
        assertFalse(token.paused(), "Token should not be paused initially");
        
        vm.expectEmit(true, false, false, false);
        emit Paused(owner);
        
        token.pause();
        
        assertTrue(token.paused(), "Token should be paused");
    }
    
    function test_Unpause() public {
        token.pause();
        assertTrue(token.paused());
        
        vm.expectEmit(true, false, false, false);
        emit Unpaused(owner);
        
        token.unpause();
        
        assertFalse(token.paused(), "Token should be unpaused");
    }
    
    function test_RevertWhen_TransferWhilePaused() public {
        token.pause();
        
        vm.expectRevert();
        token.transfer(user1, 100 * 1e18);
    }
    
    function test_RevertWhen_PauseWithoutRole() public {
        vm.prank(user1);
        vm.expectRevert();
        token.pause();
    }
    
    function test_PauseWithControllerRole() public {
        // Grant CONTROLLER_ROLE to controller address
        bytes32 controllerRole = token.CONTROLLER_ROLE();
        token.grantRole(controllerRole, controller);
        
        // Controller should be able to pause
        vm.prank(controller);
        token.pause();
        
        assertTrue(token.paused());
    }
    
    /*//////////////////////////////////////////////////////////////
                        TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_Transfer() public {
        uint256 transferAmount = 1000 * 1e18;
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user1, transferAmount);
        
        token.transfer(user1, transferAmount);
        
        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
    }
    
    function test_TransferFrom() public {
        uint256 transferAmount = 1000 * 1e18;
        
        // Owner approves user1 to spend
        token.approve(user1, transferAmount);
        
        // User1 transfers from owner to user2
        vm.prank(user1);
        token.transferFrom(owner, user2, transferAmount);
        
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
    }
    
    function testFuzz_Transfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        amount = bound(amount, 0, token.balanceOf(owner));
        
        uint256 initialBalanceOwner = token.balanceOf(owner);
        uint256 initialBalanceTo = token.balanceOf(to);
        
        token.transfer(to, amount);
        
        if (to == owner) {
            assertEq(token.balanceOf(owner), initialBalanceOwner);
        } else {
            assertEq(token.balanceOf(owner), initialBalanceOwner - amount);
            assertEq(token.balanceOf(to), initialBalanceTo + amount);
        }
    }
    
    function test_RevertWhen_TransferExceedsBalance() public {
        uint256 balance = token.balanceOf(owner);
        
        vm.expectRevert();
        token.transfer(user1, balance + 1);
    }
    
    function test_RevertWhen_TransferToZeroAddress() public {
        vm.expectRevert();
        token.transfer(address(0), 100 * 1e18);
    }
    
    /*//////////////////////////////////////////////////////////////
                        APPROVAL TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_Approve() public {
        uint256 approveAmount = 1000 * 1e18;
        
        token.approve(user1, approveAmount);
        
        assertEq(token.allowance(owner, user1), approveAmount);
    }
    
    function testFuzz_Approve(address spender, uint256 amount) public {
        vm.assume(spender != address(0));
        
        token.approve(spender, amount);
        
        assertEq(token.allowance(owner, spender), amount);
    }
    
    /*//////////////////////////////////////////////////////////////
                        ACCESS CONTROL TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_GrantRole() public {
        bytes32 minterRole = token.MINTER_ROLE();
        
        assertFalse(token.hasRole(minterRole, user1));
        
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(minterRole, user1, owner);
        
        token.grantRole(minterRole, user1);
        
        assertTrue(token.hasRole(minterRole, user1));
    }
    
    function test_RevokeRole() public {
        bytes32 minterRole = token.MINTER_ROLE();
        
        token.grantRole(minterRole, user1);
        assertTrue(token.hasRole(minterRole, user1));
        
        token.revokeRole(minterRole, user1);
        
        assertFalse(token.hasRole(minterRole, user1));
    }
    
    function test_RevertWhen_GrantRoleWithoutAdmin() public {
        bytes32 minterRole = token.MINTER_ROLE();
        
        vm.prank(user1);
        vm.expectRevert();
        token.grantRole(minterRole, user2);
    }
    
    function test_GetRoleFunctions() public view {
        bytes32 controllerRole = token.getControllerRole();
        bytes32 minterRole = token.getMinterRole();
        
        assertEq(controllerRole, token.CONTROLLER_ROLE());
        assertEq(minterRole, token.MINTER_ROLE());
    }
    
    /*//////////////////////////////////////////////////////////////
                        PERMIT TESTS (EIP-2612)
    //////////////////////////////////////////////////////////////*/
    
    function test_Permit() public {
        uint256 privateKey = 0xA11CE;
        address alice = vm.addr(privateKey);
        
        // Mint some tokens to alice
        token.mint(alice, 1000 * 1e18);
        
        uint256 nonce = token.nonces(alice);
        uint256 deadline = block.timestamp + 1 hours;
        uint256 amount = 100 * 1e18;
        
        // Create permit signature
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                alice,
                user1,
                amount,
                nonce,
                deadline
            )
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                structHash
            )
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        // Execute permit
        token.permit(alice, user1, amount, deadline, v, r, s);
        
        assertEq(token.allowance(alice, user1), amount);
        assertEq(token.nonces(alice), nonce + 1);
    }
    
    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_CompleteWorkflow() public {
        // 1. Initial state
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        
        // 2. Transfer to user1
        token.transfer(user1, 1000 * 1e18);
        assertEq(token.balanceOf(user1), 1000 * 1e18);
        
        // 3. Grant MINTER_ROLE to minter
        token.grantRole(token.MINTER_ROLE(), minter);
        
        // 4. Minter mints to user2
        vm.prank(minter);
        token.mint(user2, 500 * 1e18);
        assertEq(token.balanceOf(user2), 500 * 1e18);
        
        // 5. User1 burns some tokens
        vm.prank(user1);
        token.burn(100 * 1e18);
        assertEq(token.balanceOf(user1), 900 * 1e18);
        
        // 6. Pause token
        token.pause();
        
        // 7. Transfers should fail when paused
        vm.expectRevert();
        token.transfer(user1, 100 * 1e18);
        
        // 8. Unpause
        token.unpause();
        
        // 9. Transfers should work again
        token.transfer(user1, 100 * 1e18);
        assertEq(token.balanceOf(user1), 1000 * 1e18);
    }
    
    /*//////////////////////////////////////////////////////////////
                        EDGE CASES
    //////////////////////////////////////////////////////////////*/
    
    function test_TransferToSelf() public {
        uint256 initialBalance = token.balanceOf(owner);
        
        token.transfer(owner, 100 * 1e18);
        
        assertEq(token.balanceOf(owner), initialBalance);
    }
    
    function test_MintZeroAmount() public {
        uint256 initialBalance = token.balanceOf(user1);
        
        token.mint(user1, 0);
        
        assertEq(token.balanceOf(user1), initialBalance);
    }
    
    function test_BurnZeroAmount() public {
        uint256 initialBalance = token.balanceOf(owner);
        
        token.burn(0);
        
        assertEq(token.balanceOf(owner), initialBalance);
    }
}

