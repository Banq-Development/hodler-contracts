// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;

import './Hodler.sol';

contract HodlerFactory {

    mapping(address => address[]) public hodler;
    mapping(address => uint256) public index;
    address[] public allHodlers;

    event Create(address hodler, address asset);
 
    function allHodlersLength() external view returns (uint) {
        return allHodlers.length;
    }

    function createHodler(address asset) public returns (address) {
        require(asset != address(0), "HodlerFactory: zero asset input");
        uint256 _index = index[asset];
        index[asset] += 1;
        if (_index > 0) {
            address previous = hodler[asset][_index - 1];
            Hodler _previous = Hodler(previous);
            bool started = _previous.started();
            require(started == true, "HodlerFactory: previous hodler did not start");
        }
        Hodler _hodler = new Hodler();
        _hodler.initialize(asset, 10**21, 80, 120);
        hodler[asset].push(address(_hodler));
        allHodlers.push(address(_hodler));
        Create(address(_hodler), asset);
        return address(_hodler);
    }
}
