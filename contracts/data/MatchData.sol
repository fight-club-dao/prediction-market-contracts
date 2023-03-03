// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;



/// @notice Mock ERC20 contract for testing purposes
contract MatchData {

    mapping(uint256 => uint256) public MatchIdResults;

    constructor(
    ) public {

    }

    function pushMatchResults(uint256 match_id, uint256 match_results) public {
        MatchIdResults[match_id] = match_results;
    }




}