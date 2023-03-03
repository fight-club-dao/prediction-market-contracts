// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./dev/functions/FunctionsClient.sol";
// import "@chainlink/contracts/src/v0.8/dev/functions/FunctionsClient.sol"; // Once published
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

/**
 * @title Functions Consumer contract
 * @notice This contract is a demonstration of using Functions.
 * @notice NOT FOR PRODUCTION USE
 */
contract FunctionsConsumer is FunctionsClient, ConfirmedOwner {
  using Functions for Functions.Request;

  bytes32 public latestRequestId;
  bytes public latestResponse;
  bytes public latestError;
  uint256 public latestMatchResults;
  string private s_source;
  bytes private s_secrets;
  Functions.Location private s_secretsLocation;
  uint64 private s_subscriptionId;
  uint32 private s_gasLimit;
  address public pmManager;

  event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);

  /**
   * @notice Executes once when a contract is created to initialize state variables
   *
   * @param oracle - The FunctionsOracle contract
   */
  constructor(address oracle) FunctionsClient(oracle) ConfirmedOwner(msg.sender) {

  }

  function setPMManager(address _pmManager) external { //todo: add require for that only owner
    pmManager = _pmManager;
  }


  /**
   * @notice Send a simple request
   *
   * @param args List of arguments accessible from within the source code
   */
  function requestMatchResults(
    string[] calldata args
  ) public returns (bytes32) { //todo add only pmManager
    Functions.Request memory req;
    req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, s_source);
    if (s_secrets.length > 0) {
      if (s_secretsLocation == Functions.Location.Inline) {
        req.addInlineSecrets(s_secrets);
      } else {
        req.addRemoteSecrets(s_secrets);
      }
    }
    if (args.length > 0) req.addArgs(args);

    bytes32 assignedReqID = sendRequest(req, s_subscriptionId, s_gasLimit);
    latestRequestId = assignedReqID;
    return assignedReqID;
  }

  /**
   * @notice Store static variables regarding request
   *
   * @param _source JavaScript source code
   * @param _secrets Encrypted secrets payload
   * @param _subscriptionId Billing ID
   */
  function storeRequestDataOnChain(
    string calldata _source,
    bytes calldata _secrets,
    Functions.Location _secretsLocation,
    uint64 _subscriptionId,
    uint32 _gasLimit
  ) public onlyOwner{
    s_source = _source;
    s_secrets = _secrets;
    s_secretsLocation = _secretsLocation;
    s_subscriptionId = _subscriptionId;
    s_gasLimit = _gasLimit;
  }
  /**
   * @notice Send a simple request
   *
   * @param source JavaScript source code
   * @param secrets Encrypted secrets payload
   * @param args List of arguments accessible from within the source code
   * @param subscriptionId Billing ID
   */
  function executeRequest(
    string calldata source,
    bytes calldata secrets,
    Functions.Location secretsLocation,
    string[] calldata args,
    uint64 subscriptionId,
    uint32 gasLimit
  ) public onlyOwner returns (bytes32) {
    s_source = source;
    s_secrets = secrets;
    s_secretsLocation = secretsLocation;
    s_subscriptionId = subscriptionId;
    s_gasLimit = gasLimit;
    Functions.Request memory req;
    req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, source);
    if (secrets.length > 0) {
      if (secretsLocation == Functions.Location.Inline) {
        req.addInlineSecrets(secrets);
      } else {
        req.addRemoteSecrets(secrets);
      }
    }
    if (args.length > 0) req.addArgs(args);

    bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit);
    latestRequestId = assignedReqID;
    return assignedReqID;
  }

  /**
   * @notice Callback that is invoked once the DON has resolved the request or hit an error
   *
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) internal override {
    latestResponse = response;
    latestError = err;
    latestMatchResults = uint256(bytes32(latestResponse));
    emit OCRResponse(requestId, response, err);
  }

  /**
   * @notice Allows the Functions oracle address to be updated
   *
   * @param oracle New oracle address
   */
  function updateOracleAddress(address oracle) public onlyOwner {
    setOracle(oracle);
  }

  function addSimulatedRequestId(address oracleAddress, bytes32 requestId) public onlyOwner {
    addExternalRequest(oracleAddress, requestId);
  }

  function getMatchResults(uint256 _matchId) public view returns(uint256){
    require(_matchId == latestMatchResults / 10, "latest results are not for this match");
    return( latestMatchResults % 10);
  }

}
