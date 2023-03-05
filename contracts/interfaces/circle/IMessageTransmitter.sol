
interface IMessageTransmitter{
    function receiveMessage(bytes calldata message, bytes calldata attestation)
    external
    returns (bool success);
}
