// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Gnosis.sol";

library AddressUpgradeable {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}
abstract contract Initializable {
    uint8 private _initialized;
    bool private _initializing;
    event Initialized(uint8 version);
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}
interface IERC20Upgradeable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}
contract WalletRegistry is IProxyCreationCallback, OwnableUpgradeable {
    
    uint256 private constant MAX_OWNERS = 1;
    uint256 private constant MAX_THRESHOLD = 1;
    uint256 private constant TOKEN_PAYMENT = 10 ether; // 10 * 10 ** 18
    
    address public immutable masterCopy;
    address public immutable walletFactory;
    IERC20Upgradeable public immutable token;

    mapping (address => bool) public beneficiaries;

    // owner => wallet
    mapping (address => address) public wallets;

    constructor(
        address masterCopyAddress,
        address walletFactoryAddress, 
        address tokenAddress,
        address[] memory initialBeneficiaries
    ) {
        require(masterCopyAddress != address(0));
        require(walletFactoryAddress != address(0));

        masterCopy = masterCopyAddress;
        walletFactory = walletFactoryAddress;
        token = IERC20Upgradeable(tokenAddress);

        for (uint256 i = 0; i < initialBeneficiaries.length; i++) {
            addBeneficiary(initialBeneficiaries[i]);
        }
    }

    function addBeneficiary(address beneficiary) public onlyOwner {
        beneficiaries[beneficiary] = true;
    }

    function _removeBeneficiary(address beneficiary) private {
        beneficiaries[beneficiary] = false;
    }

    /**
     @notice Function executed when user creates a Gnosis Safe wallet via GnosisSafeProxyFactory::createProxyWithCallback
             setting the registry's address as the callback.
     */
    function proxyCreated(
        GnosisSafeProxy proxy,
        address singleton,
        bytes calldata initializer,
        uint256
    ) external override {
        // Make sure we have enough DVT to pay
        require(token.balanceOf(address(this)) >= TOKEN_PAYMENT, "Not enough funds to pay");

        address payable walletAddress = payable(proxy);

        // Ensure correct factory and master copy
        require(msg.sender == walletFactory, "Caller must be factory");
        require(singleton == masterCopy, "Fake mastercopy used");
        
        // Ensure initial calldata was a call to `GnosisSafe::setup`
        require(bytes4(initializer[:4]) == GnosisSafe.setup.selector, "Wrong initialization");

        // Ensure wallet initialization is the expected
        require(GnosisSafe(walletAddress).getThreshold() == MAX_THRESHOLD, "Invalid threshold");
        require(GnosisSafe(walletAddress).getOwners().length == MAX_OWNERS, "Invalid number of owners");       

        // Ensure the owner is a registered beneficiary
        address walletOwner = GnosisSafe(walletAddress).getOwners()[0];

        require(beneficiaries[walletOwner], "Owner is not registered as beneficiary");

        // Remove owner as beneficiary
        _removeBeneficiary(walletOwner);

        // Register the wallet under the owner's address
        wallets[walletOwner] = walletAddress;

        // Pay tokens to the newly created wallet
        token.transfer(walletAddress, TOKEN_PAYMENT);        
    }
}
