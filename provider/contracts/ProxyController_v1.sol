pragma solidity ^0.4.8;

import '../../gmo/contracts/VersionContract.sol';
import './ProxyController.sol';
import './ProxyControllerLogic_v1.sol';

contract ProxyController_v1 is VersionContract, ProxyController {
    ProxyControllerLogic_v1 public logic_v1;

    function ProxyController_v1(ContractNameService _cns, ProxyControllerLogic_v1 _logic_v1) VersionContract(_cns, CONTRACT_NAME) {
        logic_v1 = _logic_v1;
    }

    /* ----------- proxy of Organizations function ----------------- */

    function createOrganization(bytes _sign, address _organizationsAddress, bytes32 _organizationKey, uint _nonce, bytes _clientSign) {
        logic_v1.createOrganization(_organizationsAddress, _organizationKey, _nonce, _clientSign);
    }

    function changeOrganizationActivation(bytes _sign, address _organizationsAddress, uint _nonce, bytes _clientSign) {
        logic_v1.changeOrganizationActivation(_organizationsAddress, _nonce, _clientSign);
    }

    function addOrganizationAdmin(bytes _sign, address _organizationsAddress, address _addr, uint _nonce, bytes _clientSign) {
        logic_v1.addOrganizationAdmin(_organizationsAddress, _addr, _nonce, _clientSign);
    }

    function removeOrganizationAdmin(bytes _sign, address _organizationsAddress, address _addr, uint _nonce, bytes _clientSign) {
        logic_v1.removeOrganizationAdmin(_organizationsAddress, _addr, _nonce, _clientSign);
    }

    function addOrganizationMember(bytes _sign, address _organizationsAddress, address _addr, uint _nonce, bytes _clientSign) {
        logic_v1.addOrganizationMember(_organizationsAddress, _addr, _nonce, _clientSign);
    }

    function removeOrganizationMember(bytes _sign, address _organizationsAddress, address _addr, uint _nonce, bytes _clientSign) {
        logic_v1.removeOrganizationMember(_organizationsAddress, _addr, _nonce, _clientSign);
    }

    function getOrganizationsNonce(address _organizationsAddress, address _addr) constant returns (uint) {
        return logic_v1.getOrganizationsNonce(_organizationsAddress, _addr);
    }

    function getOrganizationStatus(address _organizationsAddress, bytes32 _organizationKey) constant returns (bool created, bool active, uint adminCount) {
        return logic_v1.getOrganizationStatus(_organizationsAddress, _organizationKey);
    }

    function isOrganizationAdmin(address _organizationsAddress, address _addr) constant returns (bool) {
        return logic_v1.isOrganizationAdmin(_organizationsAddress, _addr);
    }

    function isOrganizationMember(address _organizationsAddress, address _addr) constant returns (bool) {
        return logic_v1.isOrganizationMember(_organizationsAddress, _addr);
    }

    /* ----------- proxy of AttractionHandler function ----------------- */

    function createAttraction(bytes _sign, address _attractionHandlerAddress, bytes32 _attractionKey, bytes32 _salesAgentKey, uint _nonce, bytes _clientSign) {
        logic_v1.createAttraction(_attractionHandlerAddress, _attractionKey, _salesAgentKey, _nonce, _clientSign);
    }

    function removeAttraction(bytes _sign, address _attractionHandlerAddress, bytes32 _attractionKey, uint _nonce, bytes _clientSign) {
        logic_v1.removeAttraction(_attractionHandlerAddress, _attractionKey, _nonce, _clientSign);
    }

    function getAttractionAddress(address _attractionHandlerAddress, bytes32 _attractionKey) constant returns (address) {
        return logic_v1.getAttractionAddress(_attractionHandlerAddress, _attractionKey);
    }

    function getAttractionHandlerNonce(address _attractionHandlerAddress, address _addr) constant returns (uint) {
        return logic_v1.getAttractionHandlerNonce(_attractionHandlerAddress, _addr);
    }


    /* ----------- proxy of Attraction function ----------------- */

    function changeAttrSaleStatus(bytes _sign, address _attractionAddress, bool _onSale, uint _nonce, bytes _clientSign) {
        logic_v1.changeAttractionSaleStatus(_attractionAddress, _onSale, _nonce, _clientSign);
    }

    function setAttrPromoter(bytes _sign, address _attractionAddress, bytes32 _promoterKey, uint _nonce, bytes _clientSign) {
        logic_v1.setAttractionPromoter(_attractionAddress, _promoterKey, _nonce, _clientSign);
    }

    function addAttrSalesAgent(bytes _sign, address _attractionAddress, bytes32 _salesAgentKey, uint _nonce, bytes _clientSign) {
        logic_v1.addAttractionSalesAgent(_attractionAddress, _salesAgentKey, _nonce, _clientSign);
    }

    function removeAttrSalesAgent(bytes _sign, address _attractionAddress, bytes32 _salesAgentKey, uint _nonce, bytes _clientSign) {
        logic_v1.removeAttractionSalesAgent(_attractionAddress, _salesAgentKey, _nonce, _clientSign);
    }

    function createAttrTicket(bytes _sign, address _attractionAddress, bytes32 _ticketKey, uint _seatCount, address _admissionAddress, uint _ticketNonce, bytes _clientSign) {
        logic_v1.createAttractionTicket(_attractionAddress, _ticketKey, _seatCount, _admissionAddress, _ticketNonce, _clientSign);
    }

    function removeAttrTicket(bytes _sign, address _attractionAddress, bytes32 _ticketKey, uint _ticketNonce, bytes _clientSign) {
        logic_v1.removeAttractionTicket(_attractionAddress, _ticketKey, _ticketNonce, _clientSign);
    }

    function setAttrSeatCount(bytes _sign, address _attractionAddress, bytes32 _ticketKey, uint _seatCount, uint _ticketNonce, bytes _clientSign) {
        logic_v1.setAttractionSeatCount(_attractionAddress, _ticketKey, _seatCount, _ticketNonce, _clientSign);
    }

    function setAttrAdmisionAddress(bytes _sign, address _attractionAddress, bytes32 _ticketKey, address _admissionAddress, uint _ticketNonce, bytes _clientSign) {
        logic_v1.setAttractionAdmisionAddress(_attractionAddress, _ticketKey, _admissionAddress, _ticketNonce, _clientSign);
    }

    function getAttrTicket(address _attractionAddress, bytes32 _ticketKey) constant returns (bool exist, uint seatCount, address admissionAddress, bytes32 salesAgentKey) {
        return logic_v1.getAttractionTicket(_attractionAddress, _ticketKey);
    }

    function getAttrTicketKey(address _attractionAddress, address _addr) constant returns (bytes32[] ticketKeys) {
        uint length = logic_v1.getAttractionAddressTicketKeysLength(_attractionAddress, _addr);
        ticketKeys = new bytes32[](length);
        for (uint i = 0; i < length; i++) {
            ticketKeys[i] = logic_v1.getAttractionAddressTicketKey(_attractionAddress, _addr, i);
        }
    }

    function getAttrPromoterKey(address _attractionAddress) constant returns (bytes32) {
        return logic_v1.getAttractionPromoterKey(_attractionAddress);
    }

    function isAttrSalesAgent(address _attractionAddress, bytes32 _salesAgentKey) constant returns (bool) {
        return logic_v1.isAttractionSalesAgent(_attractionAddress, _salesAgentKey);
    }



    function getAttrAddressAndNonce(address _attractionHandlerAddress, bytes32 _attractionKey, address _address) constant returns (address attractionAddress, uint nonce) {
        attractionAddress = logic_v1.getAttractionAddress(_attractionHandlerAddress, _attractionKey);
        nonce = logic_v1.getAttractionNonce(attractionAddress, _address);
    }

    function getAttrAddressAndTicketNonce(address _attractionHandlerAddress, bytes32 _attractionKey, bytes32 _ticketKey) constant returns (address attractionAddress, uint ticketNonce) {
        attractionAddress = logic_v1.getAttractionAddress(_attractionHandlerAddress, _attractionKey);
        ticketNonce = logic_v1.getAttractionTicketNonce(attractionAddress, _ticketKey);
    }

    function getAttrAdmissionsAndSeatCounts(address _attractionHandlerAddress, bytes32 _attractionKey, uint _offset, uint _limit) constant returns (address[] admissionAddresses, uint[] seatCounts) {
        address attractionAddress = logic_v1.getAttractionAddress(_attractionHandlerAddress, _attractionKey);
        uint length = logic_v1.getAttractionAdmissionAddressesLength(attractionAddress);
        assert (_limit <= 10000 && _offset <= length);
        uint count = (_offset + _limit) > length ? length - _offset : _limit;
        admissionAddresses  = new address[](count);
        seatCounts = new uint[](count);
        for (uint i = 0; i < count; i++) {
            admissionAddresses[i] = logic_v1.getAttractionAdmissionAddress(attractionAddress, _offset + i);
            seatCounts[i] = logic_v1.getAttractionOwnSeatCount(attractionAddress, admissionAddresses[i]);
        }
    }

    function isAttrSellable(address _attractionHandlerAddress, bytes32 _attractionKey) constant returns (bool) {
        address attractionAddress = logic_v1.getAttractionAddress(_attractionHandlerAddress, _attractionKey);
        return logic_v1.isAttractionSellable(attractionAddress);
    }

    function getTicketsByAdmissionAddress(address _attractionHandlerAddress, bytes32 _attractionKey, address _admissionAddress) constant returns (bytes32[] ticketKeys, bool[] exists, uint[] seatCounts, address[] admissionAddresses, bytes32[] salesAgentKeys) {
        address attractionAddress = logic_v1.getAttractionAddress(_attractionHandlerAddress, _attractionKey);
        uint length = logic_v1.getAttractionAddressTicketKeysLength(attractionAddress, _admissionAddress);
        ticketKeys = new bytes32[](length);
        exists = new bool[](length);
        seatCounts = new uint[](length);
        admissionAddresses = new address[](length);
        salesAgentKeys = new bytes32[](length);
        for (uint i = 0; i < length; i++) {
            ticketKeys[i] = logic_v1.getAttractionAddressTicketKey(attractionAddress, _admissionAddress, i);
            (exists[i], seatCounts[i], admissionAddresses[i], salesAgentKeys[i]) = logic_v1.getAttractionTicket(attractionAddress, ticketKeys[i]);
        }
    }
}
