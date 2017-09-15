pragma solidity ^0.4.8;

import '../../gmo/contracts/VersionLogic.sol';
import './ProxyController.sol';
import './Organizations.sol';
import './Attraction.sol';
import './AttractionHandler.sol';

contract ProxyControllerLogic_v1 is VersionLogic, ProxyController {
    function ProxyControllerLogic_v1(ContractNameService _cns) VersionLogic (_cns, CONTRACT_NAME) {}

    /* ----------- proxy of Organizations function ----------------- */

    function createOrganization(address _organizationsAddress, bytes32 _organizationKey, uint _nonce, bytes _clientSign) {
        assert(Organizations(_organizationsAddress).createOrganizationWithSign(_organizationKey, _nonce, _clientSign));
    }

    function changeOrganizationActivation(address _organizationsAddress, uint _nonce, bytes _clientSign) {
        assert(Organizations(_organizationsAddress).changeActivationWithSign(_nonce, _clientSign));
    }

    function addOrganizationAdmin(address _organizationsAddress, address _addr, uint _nonce, bytes _clientSign) {
        assert(Organizations(_organizationsAddress).addAdminWithSign(_addr, _nonce, _clientSign));
    }

    function removeOrganizationAdmin(address _organizationsAddress, address _addr, uint _nonce, bytes _clientSign) {
        assert(Organizations(_organizationsAddress).removeAdminWithSign(_addr, _nonce, _clientSign));
    }

    function addOrganizationMember(address _organizationsAddress, address _addr, uint _nonce, bytes _clientSign) {
        assert(Organizations(_organizationsAddress).addMemberWithSign(_addr, _nonce, _clientSign));
    }

    function removeOrganizationMember(address _organizationsAddress, address _addr, uint _nonce, bytes _clientSign) {
        assert(Organizations(_organizationsAddress).removeMemberWithSign(_addr, _nonce, _clientSign));
    }

    function getOrganizationsNonce(address _organizationsAddress, address _addr) constant returns (uint) {
        return Organizations(_organizationsAddress).nonces(_addr);
    }

    function getOrganizationStatus(address _organizationsAddress, bytes32 _organizationKey) constant returns (bool created, bool active, uint adminCount) {
        return Organizations(_organizationsAddress).organizations(_organizationKey);
    }

    function isOrganizationAdmin(address _organizationsAddress, address _addr) constant returns (bool) {
        return Organizations(_organizationsAddress).isAdmin(_addr);
    }

    function isOrganizationMember(address _organizationsAddress, address _addr) constant returns (bool) {
        return Organizations(_organizationsAddress).isMember(_addr);
    }

    /* ----------- proxy of AttractionHandler function ----------------- */

    function createAttraction(address _attractionHandlerAddress, bytes32 _attractionKey, bytes32 _salesAgentKey, uint _nonce, bytes _clientSign) {
        assert(AttractionHandler(_attractionHandlerAddress).createAttractionWithSign(_attractionKey, _salesAgentKey, _nonce, _clientSign));
    }

    function removeAttraction(address _attractionHandlerAddress, bytes32 _attractionKey, uint _nonce, bytes _clientSign) {
        assert(AttractionHandler(_attractionHandlerAddress).removeAttractionWithSign(_attractionKey, _nonce, _clientSign));
    }

    function getAttractionAddress(address _attractionHandlerAddress, bytes32 _attractionKey) constant returns (address) {
        return AttractionHandler(_attractionHandlerAddress).attractions(_attractionKey);
    }

    function getAttractionHandlerNonce(address _attractionHandlerAddress, address _addr) constant returns (uint) {
        return AttractionHandler(_attractionHandlerAddress).nonces(_addr);
    }


    /* ----------- proxy of Attraction function ----------------- */

    function changeAttractionSaleStatus(address _attractionAddress, bool _onSale, uint _nonce, bytes _clientSign) {
        assert(Attraction(_attractionAddress).changeSaleStatusWithSign(_onSale, _nonce, _clientSign));
    }

    function setAttractionPromoter(address _attractionAddress, bytes32 _promoterKey, uint _nonce, bytes _clientSign) {
        assert(Attraction(_attractionAddress).setPromoterKeyWithSign(_promoterKey, _nonce, _clientSign));
    }

    function addAttractionSalesAgent(address _attractionAddress, bytes32 _salesAgentKey, uint _nonce, bytes _clientSign) {
        assert(Attraction(_attractionAddress).addSalesAgentWithSign(_salesAgentKey, _nonce, _clientSign));
    }

    function removeAttractionSalesAgent(address _attractionAddress, bytes32 _salesAgentKey, uint _nonce, bytes _clientSign) {
        assert(Attraction(_attractionAddress).removeSalesAgentWithSign(_salesAgentKey, _nonce, _clientSign));
    }

    function createAttractionTicket(address _attractionAddress, bytes32 _ticketKey, uint _seatCount, address _admissionAddress, uint _ticketNonce, bytes _clientSign) {
        assert(Attraction(_attractionAddress).createTicketWithSign(_ticketKey, _seatCount, _admissionAddress, _ticketNonce, _clientSign));
    }

    function removeAttractionTicket(address _attractionAddress, bytes32 _ticketKey, uint _ticketNonce, bytes _clientSign) {
        assert(Attraction(_attractionAddress).removeTicketWithSign(_ticketKey, _ticketNonce, _clientSign));
    }

    function setAttractionSeatCount(address _attractionAddress, bytes32 _ticketKey, uint _seatCount, uint _ticketNonce, bytes _clientSign) {
        assert(Attraction(_attractionAddress).setSeatCountWithSign(_ticketKey, _seatCount, _ticketNonce, _clientSign));
    }

    function setAttractionAdmisionAddress(address _attractionAddress, bytes32 _ticketKey, address _admissionAddress, uint _ticketNonce, bytes _clientSign) {
        assert(Attraction(_attractionAddress).setAdmissionAddressWithSign(_ticketKey, _admissionAddress, _ticketNonce, _clientSign));
    }

    function getAttractionNonce(address _attractionAddress, address _addr) constant returns (uint) {
        return Attraction(_attractionAddress).nonces(_addr);
    }

    function getAttractionTicketNonce(address _attractionAddress, bytes32 _ticketKey) constant returns (uint) {
        return Attraction(_attractionAddress).ticketNonces(_ticketKey);
    }

    function getAttractionAdmissionAddressesLength(address _attractionAddress) constant returns (uint) {
        return Attraction(_attractionAddress).getAdmissionAddressesLength();
    }

    function getAttractionAdmissionAddress(address _attractionAddress, uint _index) constant returns (address) {
        return Attraction(_attractionAddress).getAdmissionAddress(_index);
    }

    function getAttractionOwnSeatCount(address _attractionAddress, address _addr) constant returns (uint) {
        return Attraction(_attractionAddress).getOwnSeatCount(_addr);
    }

    function getAttractionTicket(address _attractionAddress, bytes32 _ticketKey) constant returns (bool exist, uint seatCount, address admissionAddress, bytes32 salesAgentKey) {
        return Attraction(_attractionAddress).tickets(_ticketKey);
    }

    function getAttractionAddressTicketKeysLength(address _attractionAddress, address _addr) constant returns (uint) {
        return Attraction(_attractionAddress).getAddressTicketKeysLength(_addr);
    }

    function getAttractionAddressTicketKey(address _attractionAddress, address _addr, uint _index) constant returns (bytes32) {
        return Attraction(_attractionAddress).addressTicketKeys(_addr, _index);
    }

    function isAttractionSellable(address _attractionAddress) constant returns (bool) {
        return Attraction(_attractionAddress).onSale();
    }

    function getAttractionPromoterKey(address _attractionAddress) constant returns (bytes32) {
        return Attraction(_attractionAddress).promoterKey();
    }

    function isAttractionSalesAgent(address _attractionAddress, bytes32 _salesAgentKey) constant returns (bool) {
        return Attraction(_attractionAddress).salesAgentKeys(_salesAgentKey);
    }
}
