pragma solidity ^0.4.24;

import "./interfaces/ERC20Token.sol";
import "./utils/Unimplemented.sol";
import "./utils/IterableSet.sol";
import "./utils/Owned.sol";

contract Ticker is Owned, Unimplemented {
    using IterableSet for IterableSet.Set;
    
    ERC20Token public denominatingAsset;

    mapping(address => PriceData[]) history;
    mapping(address => OraclePermissions) oracles;

    struct PriceData {
        uint price;
        uint timestamp;
        address oracle;
    }

    struct OraclePermissions {
        bool isOracle;
        bool isUniversal;
        IterableSet.Set allowed;
        IterableSet.Set disallowed;
    }

    constructor() 
        Owned(msg.sender)
    {}

    function isOracle(address oracle) 
        external
        returns (bool)
    {
        return oracles[oracle].isOracle;
    }

    function isUniversalOracle(address oracle)
        external
        returns (bool)
    {
        return oracles[oracle].isUniversal;
    }

    function isOracleFor(address oracle, ERC20Token token)
        public
        returns (bool)
    {
        OraclePermissions storage permissions = oracles[oracle];
        return (
            permissions.isOracle && // Implies sets are initialised.
            !permissions.disallowed.contains(token) &&
            ( permissions.isUniversal || permissions.allowed.contains(token) )
        );
    }

    function addOracle(address oracle)
        external
        onlyOwner
    {
        require(!oracles[oracle].isOracle, "Is already an oracle.");

        OraclePermissions storage permissions = oracles[oracle];
        permissions.isOracle = true;
        permissions.allowed.initialise();
        permissions.disallowed.initialise();
    }

    function removeOracle(address oracle)
        external
        onlyOwner
    {
        // Empty and de-initialise sets.
        unimplemented();
    }

    function updatePrices(ERC20Token[] tokens, uint[] prices)
        external
    {
        unimplemented();
    }
    
    function historyLength(ERC20Token token)
        public
        returns (uint)
    {
        return history[token].length;
    }

    function latestPriceData(ERC20Token token)
        public
        returns (uint price, uint timestamp, address oracle)
    {
        PriceData[] storage tokenHistory = history[token];
        PriceData latest = tokenHistory[tokenHistory.length - 1];
        return (latest.price, latest.timestamp, latest.oracle);
    }

    function price(ERC20Token token)
        public
        returns (uint)
    {
        PriceData[] storage tokenHistory = history[token];
        return tokenHistory[tokenHistory.length - 1].price;
    }

    function value(ERC20Token token, uint quantity) 
        public
        returns (uint)
    {
        unimplemented();
    }

    function rate(ERC20Token quote, ERC20Token base)
        public
        returns (uint)
    {
        unimplemented();
    }

}