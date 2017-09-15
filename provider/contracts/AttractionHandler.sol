pragma solidity ^0.4.8;

import './Organizations.sol';
import './Attraction.sol';

contract AttractionHandler {

    Organizations public organizations;
    mapping (bytes32 => Attraction) public attractions; // attractionKey => Attraction

    // nonce for each account
    mapping(address => uint) public nonces;

    enum AttractionAction {
        Create,
        Remove
    }

    event AttractionEvent(bytes32 promoterKey, address indexed from, bytes32 indexed attractionKey, AttractionAction indexed action);

    /* ----------- modifiers ----------------- */

    modifier onlyByMember(address _addr) {
        bytes32 organizationKey = organizations.memberOrganizationKeys(_addr);
        assert(organizations.isMember(_addr) && organizations.isActive(organizationKey));
        _;
    }

    /* ----------- constructor ----------------- */

    function AttractionHandler(address _organizations) {
        organizations = Organizations(_organizations);
    }

    /* ----------- methods----------------- */

    function createAttraction(bytes32 _attractionKey, bytes32 _salesAgentKey) returns(bool) {
        return createAttractionPrivate(msg.sender, _attractionKey, _salesAgentKey);
    }

    function createAttractionWithSign(bytes32 _attractionKey, bytes32 _salesAgentKey, uint _nonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('createAttractionWithSign');
        hash = sha3(hash, _attractionKey);
        hash = sha3(hash, _salesAgentKey);
        hash = sha3(hash, _nonce);
        address from = recoverAddress(hash, _sign);

        if (_nonce != nonces[from]) return false;
        nonces[from]++;

        return createAttractionPrivate(from, _attractionKey, _salesAgentKey);
    }

    function createAttractionPrivate(address _from, bytes32 _attractionKey, bytes32 _salesAgentKey) onlyByMember(_from) private returns (bool) {
        bytes32 promoterKey = organizations.memberOrganizationKeys(_from);
        if (address(attractions[_attractionKey]) != 0) return false;
        AttractionEvent(promoterKey, _from, _attractionKey, AttractionAction.Create);
        attractions[_attractionKey] = new Attraction(organizations, promoterKey, _salesAgentKey);
        return true;
    }

    function removeAttraction(bytes32 _attractionKey) returns(bool) {
        return removeAttractionPrivate(msg.sender, _attractionKey);
    }

    function removeAttractionWithSign(bytes32 _attractionKey, uint _nonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('removeAttractionWithSign');
        hash = sha3(hash, _attractionKey);
        hash = sha3(hash, _nonce);
        address from = recoverAddress(hash, _sign);

        if (_nonce != nonces[from]) return false;
        nonces[from]++;

        return removeAttractionPrivate(from, _attractionKey);
    }

    function removeAttractionPrivate(address _from, bytes32 _attractionKey) onlyByMember(_from) private returns (bool) {
        if (address(attractions[_attractionKey]) == 0) return false;
        bytes32 promoterKeyByFrom = organizations.memberOrganizationKeys(_from);
        bytes32 promoterKeyByAttraction = attractions[_attractionKey].promoterKey();
        if (promoterKeyByAttraction == 0 || promoterKeyByFrom != promoterKeyByAttraction) return false;
        AttractionEvent(promoterKeyByFrom, _from, _attractionKey, AttractionAction.Remove);
        attractions[_attractionKey].kill();
        return true;
    }

    /* ----------- recover address ----------------- */

    function calcEnvHash(bytes32 _functionName) constant returns (bytes32 hash) {
        hash = sha3(this);
        hash = sha3(hash, _functionName);
    }

    function recoverAddress(bytes32 _hash, bytes _sign) constant returns (address recoverdAddr) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assert(_sign.length == 65);

        assembly {
            r := mload(add(_sign, 32))
            s := mload(add(_sign, 64))
            v := byte(0, mload(add(_sign, 96)))
        }

        if (v < 27) v += 27;
        assert(v == 27 || v == 28);

        recoverdAddr = ecrecover(_hash, v, r, s);
        assert(recoverdAddr != 0);
    }

}
