// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyERC721} from "../contracts/MyERC721.sol";

/**
 * @title MyERC721Test
 * @dev Forge-style unit tests for MyERC721 (ERC721) contract
 *
 * Run tests with:
 * npx hardhat test solidity
 * npx hardhat test solidity test/MyERC721.t.sol
 */
contract MyERC721Test is Test {
    MyERC721 public nft;

    address public owner;
    address public controller;
    address public minter;
    address public user1;
    address public user2;

    string constant TOKEN_URI_1 = "ipfs://QmTest1";
    string constant TOKEN_URI_2 = "ipfs://QmTest2";
    string constant TOKEN_URI_3 = "ipfs://QmTest3";

    // Events to test
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event Paused(address account);
    event Unpaused(address account);

    function setUp() public {
        // Setup test accounts
        owner = address(this);
        controller = makeAddr("controller");
        minter = makeAddr("minter");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy NFT contract
        nft = new MyERC721();
    }

    /*//////////////////////////////////////////////////////////////
                        DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_InitialState() public view {
        assertEq(nft.name(), "MyToken", "Name should be MyToken");
        assertEq(nft.symbol(), "MTK", "Symbol should be MTK");
        assertEq(nft.owner(), owner, "Owner should be deployer");
    }

    function test_InitialRoles() public view {
        bytes32 defaultAdminRole = nft.DEFAULT_ADMIN_ROLE();
        bytes32 controllerRole = nft.CONTROLLER_ROLE();
        bytes32 minterRole = nft.MINTER_ROLE();

        assertTrue(
            nft.hasRole(defaultAdminRole, owner),
            "Owner should have DEFAULT_ADMIN_ROLE"
        );
        assertTrue(
            nft.hasRole(controllerRole, owner),
            "Owner should have CONTROLLER_ROLE"
        );
        assertTrue(
            nft.hasRole(minterRole, owner),
            "Owner should have MINTER_ROLE"
        );
    }

    function test_SupportsInterface() public view {
        // ERC721 interface id: 0x80ac58cd
        assertTrue(nft.supportsInterface(0x80ac58cd), "Should support ERC721");

        // ERC721Metadata interface id: 0x5b5e139f
        assertTrue(
            nft.supportsInterface(0x5b5e139f),
            "Should support ERC721Metadata"
        );

        // AccessControl interface id: 0x7965db0b
        assertTrue(
            nft.supportsInterface(0x7965db0b),
            "Should support AccessControl"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        MINTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SafeMint() public {
        vm.expectEmit(true, true, true, false);
        emit Transfer(address(0), user1, 0);

        nft.safeMint(user1, TOKEN_URI_1);

        assertEq(nft.ownerOf(0), user1, "User1 should own token 0");
        assertEq(nft.balanceOf(user1), 1, "User1 should have 1 token");
        assertEq(nft.tokenURI(0), TOKEN_URI_1, "Token URI should match");
    }

    function test_SafeMintMultiple() public {
        nft.safeMint(user1, TOKEN_URI_1);
        nft.safeMint(user1, TOKEN_URI_2);
        nft.safeMint(user2, TOKEN_URI_3);

        assertEq(nft.balanceOf(user1), 2, "User1 should have 2 tokens");
        assertEq(nft.balanceOf(user2), 1, "User2 should have 1 token");
        assertEq(nft.ownerOf(0), user1);
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user2);
    }

    function test_SafeMintIncrementsTokenId() public {
        nft.safeMint(user1, TOKEN_URI_1);
        nft.safeMint(user1, TOKEN_URI_2);
        nft.safeMint(user1, TOKEN_URI_3);

        assertEq(nft.ownerOf(0), user1);
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user1);
    }

    function test_SafeMintWithDifferentURIs() public {
        nft.safeMint(user1, TOKEN_URI_1);
        nft.safeMint(user1, TOKEN_URI_2);

        assertEq(nft.tokenURI(0), TOKEN_URI_1);
        assertEq(nft.tokenURI(1), TOKEN_URI_2);
        assertNotEq(nft.tokenURI(0), nft.tokenURI(1));
    }

    function testFuzz_SafeMint(address to, string memory uri) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0); // Not a contract
        vm.assume(bytes(uri).length > 0 && bytes(uri).length < 1000);

        uint256 initialBalance = nft.balanceOf(to);

        nft.safeMint(to, uri);

        assertEq(nft.balanceOf(to), initialBalance + 1);
        assertEq(nft.ownerOf(0), to);
        assertEq(nft.tokenURI(0), uri);
    }

    function test_RevertWhen_MintWithoutRole() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.safeMint(user2, TOKEN_URI_1);
    }

    function test_SafeMintWithMinterRole() public {
        // Grant MINTER_ROLE to minter
        bytes32 minterRole = nft.MINTER_ROLE();
        nft.grantRole(minterRole, minter);

        // Minter should be able to mint
        vm.prank(minter);
        nft.safeMint(user1, TOKEN_URI_1);

        assertEq(nft.ownerOf(0), user1);
    }

    function test_RevertWhen_MintToZeroAddress() public {
        vm.expectRevert();
        nft.safeMint(address(0), TOKEN_URI_1);
    }

    /*//////////////////////////////////////////////////////////////
                        BURNING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Burn() public {
        nft.safeMint(user1, TOKEN_URI_1);
        assertEq(nft.balanceOf(user1), 1);

        vm.expectEmit(true, true, true, false);
        emit Transfer(user1, address(0), 0);

        vm.prank(user1);
        nft.burn(0);

        assertEq(nft.balanceOf(user1), 0);

        // Should revert when querying burned token
        vm.expectRevert();
        nft.ownerOf(0);
    }

    function test_BurnMultiple() public {
        nft.safeMint(user1, TOKEN_URI_1);
        nft.safeMint(user1, TOKEN_URI_2);
        nft.safeMint(user1, TOKEN_URI_3);

        assertEq(nft.balanceOf(user1), 3);

        vm.startPrank(user1);
        nft.burn(0);
        nft.burn(1);
        vm.stopPrank();

        assertEq(nft.balanceOf(user1), 1);
    }

    function test_BurnByApproved() public {
        nft.safeMint(user1, TOKEN_URI_1);

        // User1 approves user2 to manage the token
        vm.prank(user1);
        nft.approve(user2, 0);

        // User2 can burn the token
        vm.prank(user2);
        nft.burn(0);

        assertEq(nft.balanceOf(user1), 0);
    }

    function test_BurnByOperator() public {
        nft.safeMint(user1, TOKEN_URI_1);

        // User1 sets user2 as operator
        vm.prank(user1);
        nft.setApprovalForAll(user2, true);

        // User2 can burn the token
        vm.prank(user2);
        nft.burn(0);

        assertEq(nft.balanceOf(user1), 0);
    }

    function test_RevertWhen_BurnWithoutPermission() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.prank(user2);
        vm.expectRevert();
        nft.burn(0);
    }

    function test_RevertWhen_BurnNonexistentToken() public {
        vm.expectRevert();
        nft.burn(999);
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE/UNPAUSE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Pause() public {
        assertFalse(nft.paused(), "NFT should not be paused initially");

        vm.expectEmit(true, false, false, false);
        emit Paused(owner);

        nft.pause();

        assertTrue(nft.paused(), "NFT should be paused");
    }

    function test_Unpause() public {
        nft.pause();
        assertTrue(nft.paused());

        vm.expectEmit(true, false, false, false);
        emit Unpaused(owner);

        nft.unpause();

        assertFalse(nft.paused(), "NFT should be unpaused");
    }

    function test_RevertWhen_TransferWhilePaused() public {
        nft.safeMint(user1, TOKEN_URI_1);
        nft.pause();

        vm.prank(user1);
        vm.expectRevert();
        nft.transferFrom(user1, user2, 0);
    }

    function test_RevertWhen_MintWhilePaused() public {
        nft.pause();

        vm.expectRevert();
        nft.safeMint(user1, TOKEN_URI_1);
    }

    function test_RevertWhen_PauseWithoutRole() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.pause();
    }

    function test_PauseWithControllerRole() public {
        // Grant CONTROLLER_ROLE to controller
        bytes32 controllerRole = nft.CONTROLLER_ROLE();
        nft.grantRole(controllerRole, controller);

        // Controller should be able to pause
        vm.prank(controller);
        nft.pause();

        assertTrue(nft.paused());
    }

    /*//////////////////////////////////////////////////////////////
                        TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TransferFrom() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.expectEmit(true, true, true, false);
        emit Transfer(user1, user2, 0);

        vm.prank(user1);
        nft.transferFrom(user1, user2, 0);

        assertEq(nft.ownerOf(0), user2);
        assertEq(nft.balanceOf(user1), 0);
        assertEq(nft.balanceOf(user2), 1);
    }

    function test_SafeTransferFrom() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.prank(user1);
        nft.safeTransferFrom(user1, user2, 0);

        assertEq(nft.ownerOf(0), user2);
    }

    function test_SafeTransferFromWithData() public {
        nft.safeMint(user1, TOKEN_URI_1);

        bytes memory data = "test data";

        vm.prank(user1);
        nft.safeTransferFrom(user1, user2, 0, data);

        assertEq(nft.ownerOf(0), user2);
    }

    function test_TransferByApproved() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.prank(user1);
        nft.approve(user2, 0);

        vm.prank(user2);
        nft.transferFrom(user1, controller, 0);

        assertEq(nft.ownerOf(0), controller);
    }

    function test_TransferByOperator() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.prank(user1);
        nft.setApprovalForAll(user2, true);

        vm.prank(user2);
        nft.transferFrom(user1, controller, 0);

        assertEq(nft.ownerOf(0), controller);
    }

    function testFuzz_Transfer(address to) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(to != user1);

        nft.safeMint(user1, TOKEN_URI_1);

        vm.prank(user1);
        nft.transferFrom(user1, to, 0);

        assertEq(nft.ownerOf(0), to);
        assertEq(nft.balanceOf(to), 1);
    }

    function test_RevertWhen_TransferWithoutPermission() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.prank(user2);
        vm.expectRevert();
        nft.transferFrom(user1, user2, 0);
    }

    function test_RevertWhen_TransferNonexistentToken() public {
        vm.expectRevert();
        nft.transferFrom(user1, user2, 999);
    }

    function test_RevertWhen_TransferToZeroAddress() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.prank(user1);
        vm.expectRevert();
        nft.transferFrom(user1, address(0), 0);
    }

    /*//////////////////////////////////////////////////////////////
                        APPROVAL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Approve() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.expectEmit(true, true, true, false);
        emit Approval(user1, user2, 0);

        vm.prank(user1);
        nft.approve(user2, 0);

        assertEq(nft.getApproved(0), user2);
    }

    function test_ApprovalClearedAfterTransfer() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.prank(user1);
        nft.approve(user2, 0);

        vm.prank(user1);
        nft.transferFrom(user1, controller, 0);

        assertEq(nft.getApproved(0), address(0), "Approval should be cleared");
    }

    function test_SetApprovalForAll() public {
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(user1, user2, true);

        vm.prank(user1);
        nft.setApprovalForAll(user2, true);

        assertTrue(nft.isApprovedForAll(user1, user2));
    }

    function test_RevokeApprovalForAll() public {
        vm.prank(user1);
        nft.setApprovalForAll(user2, true);

        vm.prank(user1);
        nft.setApprovalForAll(user2, false);

        assertFalse(nft.isApprovedForAll(user1, user2));
    }

    function test_RevertWhen_ApproveNonexistentToken() public {
        vm.expectRevert();
        nft.approve(user2, 999);
    }

    function test_RevertWhen_ApproveWithoutPermission() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.prank(user2);
        vm.expectRevert();
        nft.approve(controller, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        TOKEN URI TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TokenURI() public {
        nft.safeMint(user1, TOKEN_URI_1);

        assertEq(nft.tokenURI(0), TOKEN_URI_1);
    }

    function test_TokenURIDifferentTokens() public {
        nft.safeMint(user1, TOKEN_URI_1);
        nft.safeMint(user1, TOKEN_URI_2);
        nft.safeMint(user1, TOKEN_URI_3);

        assertEq(nft.tokenURI(0), TOKEN_URI_1);
        assertEq(nft.tokenURI(1), TOKEN_URI_2);
        assertEq(nft.tokenURI(2), TOKEN_URI_3);
    }

    function test_RevertWhen_QueryURIOfNonexistentToken() public {
        vm.expectRevert();
        nft.tokenURI(999);
    }

    function testFuzz_TokenURI(string memory uri) public {
        vm.assume(bytes(uri).length > 0 && bytes(uri).length < 1000);

        nft.safeMint(user1, uri);

        assertEq(nft.tokenURI(0), uri);
    }

    /*//////////////////////////////////////////////////////////////
                        ACCESS CONTROL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GrantRole() public {
        bytes32 minterRole = nft.MINTER_ROLE();

        assertFalse(nft.hasRole(minterRole, user1));

        vm.expectEmit(true, true, true, false);
        emit RoleGranted(minterRole, user1, owner);

        nft.grantRole(minterRole, user1);

        assertTrue(nft.hasRole(minterRole, user1));
    }

    function test_RevokeRole() public {
        bytes32 minterRole = nft.MINTER_ROLE();

        nft.grantRole(minterRole, user1);
        assertTrue(nft.hasRole(minterRole, user1));

        nft.revokeRole(minterRole, user1);

        assertFalse(nft.hasRole(minterRole, user1));
    }

    function test_RenounceRole() public {
        bytes32 minterRole = nft.MINTER_ROLE();

        nft.grantRole(minterRole, user1);

        vm.prank(user1);
        nft.renounceRole(minterRole, user1);

        assertFalse(nft.hasRole(minterRole, user1));
    }

    function test_RevertWhen_GrantRoleWithoutAdmin() public {
        bytes32 minterRole = nft.MINTER_ROLE();

        vm.prank(user1);
        vm.expectRevert();
        nft.grantRole(minterRole, user2);
    }

    /*//////////////////////////////////////////////////////////////
                        BALANCE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_BalanceOf() public {
        assertEq(nft.balanceOf(user1), 0);

        nft.safeMint(user1, TOKEN_URI_1);
        assertEq(nft.balanceOf(user1), 1);

        nft.safeMint(user1, TOKEN_URI_2);
        assertEq(nft.balanceOf(user1), 2);
    }

    function test_BalanceOfMultipleUsers() public {
        nft.safeMint(user1, TOKEN_URI_1);
        nft.safeMint(user1, TOKEN_URI_2);
        nft.safeMint(user2, TOKEN_URI_3);

        assertEq(nft.balanceOf(user1), 2);
        assertEq(nft.balanceOf(user2), 1);
        assertEq(nft.balanceOf(controller), 0);
    }

    function test_RevertWhen_BalanceOfZeroAddress() public {
        vm.expectRevert();
        nft.balanceOf(address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        OWNERSHIP TESTS
    //////////////////////////////////////////////////////////////*/

    function test_OwnerOf() public {
        nft.safeMint(user1, TOKEN_URI_1);

        assertEq(nft.ownerOf(0), user1);
    }

    function test_OwnerOfAfterTransfer() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.prank(user1);
        nft.transferFrom(user1, user2, 0);

        assertEq(nft.ownerOf(0), user2);
    }

    function test_RevertWhen_OwnerOfNonexistentToken() public {
        vm.expectRevert();
        nft.ownerOf(999);
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CompleteWorkflow() public {
        // 1. Mint tokens to user1
        nft.safeMint(user1, TOKEN_URI_1);
        nft.safeMint(user1, TOKEN_URI_2);
        assertEq(nft.balanceOf(user1), 2);

        // 2. Grant MINTER_ROLE to minter
        nft.grantRole(nft.MINTER_ROLE(), minter);

        // 3. Minter mints to user2
        vm.prank(minter);
        nft.safeMint(user2, TOKEN_URI_3);
        assertEq(nft.balanceOf(user2), 1);

        // 4. User1 transfers token to user2
        vm.prank(user1);
        nft.transferFrom(user1, user2, 0);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.balanceOf(user2), 2);

        // 5. User2 burns a token
        vm.prank(user2);
        nft.burn(0);
        assertEq(nft.balanceOf(user2), 1);

        // 6. Pause contract
        nft.pause();

        // 7. Transfers should fail when paused
        vm.prank(user1);
        vm.expectRevert();
        nft.transferFrom(user1, user2, 1);

        // 8. Unpause
        nft.unpause();

        // 9. Transfers should work again
        vm.prank(user1);
        nft.transferFrom(user1, user2, 1);
        assertEq(nft.ownerOf(1), user2);
    }

    function test_MintTransferBurnCycle() public {
        // Mint
        nft.safeMint(user1, TOKEN_URI_1);
        uint256 tokenId = 0;

        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(nft.balanceOf(user1), 1);

        // Transfer
        vm.prank(user1);
        nft.transferFrom(user1, user2, tokenId);

        assertEq(nft.ownerOf(tokenId), user2);
        assertEq(nft.balanceOf(user1), 0);
        assertEq(nft.balanceOf(user2), 1);

        // Burn
        vm.prank(user2);
        nft.burn(tokenId);

        assertEq(nft.balanceOf(user2), 0);

        vm.expectRevert();
        nft.ownerOf(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_ApproveToCurrentOwner() public {
        nft.safeMint(user1, TOKEN_URI_1);

        // ERC721 allows approving the current owner (it's a no-op)
        vm.prank(user1);
        nft.approve(user1, 0);

        // Approval should still be set (even though it's the owner)
        assertEq(nft.getApproved(0), user1);
    }

    function test_TransferToSelf() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.prank(user1);
        nft.transferFrom(user1, user1, 0);

        assertEq(nft.ownerOf(0), user1);
        assertEq(nft.balanceOf(user1), 1);
    }

    function test_MultipleApprovalsOverwritten() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.startPrank(user1);
        nft.approve(user2, 0);
        assertEq(nft.getApproved(0), user2);

        nft.approve(controller, 0);
        assertEq(nft.getApproved(0), controller);
        vm.stopPrank();
    }

    function test_BurnAfterApproval() public {
        nft.safeMint(user1, TOKEN_URI_1);

        vm.prank(user1);
        nft.approve(user2, 0);

        vm.prank(user1);
        nft.burn(0);

        // Token should not exist
        vm.expectRevert();
        nft.ownerOf(0);
    }
}
