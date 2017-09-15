pragma solidity ^0.4.8;

import './Organizations.sol';

contract Attraction {

    struct Ticket {
        bool exist;
        uint seatCount;
        address admissionAddress;
        bytes32 salesAgentKey;
    }

    address public handler = msg.sender;

    Organizations public organizations;

    bool public onSale;
    bytes32 public promoterKey;
    mapping (bytes32 => bool) public salesAgentKeys;
    mapping (bytes32 => Ticket) public tickets; // ticketKey => Ticket
    mapping (address => bytes32[]) public addressTicketKeys; // admissionAddress => ticketKeys
    address[] public admissionAddresses;

    // nonce for each account
    mapping(address => uint) public nonces;

    // nonce for each ticket for high throughput ticket registration
    // ticketKey => nonce
    mapping(bytes32 => uint) public ticketNonces;

    enum SaleEventStatus {
        Sellable,
        Unsellable
    }

    enum ChangeSalesAgentAction {
        Add,
        Remove
    }

    enum TicketAction {
        Create,
        Remove,
        SetSeatCount,
        SetAdmissionAddress
    }

    event SaleEvent(SaleEventStatus saleEventStatus);
    event SetPromoterEvent(bytes32 key);
    event ChangeSalesAgentEvent(bytes32 key, ChangeSalesAgentAction action);
    event TicketEvent(TicketAction ticketAction, bytes32 indexed ticketKey, bytes32 indexed salesAgentKey, address seller, uint seatCount, address indexed addr);

    /* ----------- modifiers ----------------- */

    modifier onlyByHandler() {
        assert(msg.sender == handler);
        _;
    }

    modifier onlyByPromoterMember(address _addr) {
        bytes32 organizationKey = organizations.memberOrganizationKeys(_addr);
        assert(organizationKey == promoterKey && organizations.isMember(_addr) && organizations.isActive(organizationKey));
        _;
    }

    modifier onlyBySalesMember(address _addr) {
        bytes32 organizationKey = organizations.memberOrganizationKeys(_addr);
        assert(salesAgentKeys[organizationKey] && organizations.isMember(_addr) && organizations.isActive(organizationKey));
        _;
    }

    /* ----------- constructor ----------------- */

    function Attraction(Organizations _organizations, bytes32 _promoterKey, bytes32 _salesAgentKey) {
        organizations = _organizations;
        promoterKey = _promoterKey;
        salesAgentKeys[_salesAgentKey] = true;
        onSale = true;
        SetPromoterEvent(_promoterKey);
        ChangeSalesAgentEvent(_salesAgentKey, ChangeSalesAgentAction.Add);
        SaleEvent(SaleEventStatus.Sellable);
    }

    function kill() onlyByHandler {
        suicide(handler);
    }

    /* ----------- method----------------- */

    /**
     * change sales status by promoter member
     */
    function changeSaleStatus(bool _onSale) returns (bool) {
        return changeSaleStatusPrivate(msg.sender, _onSale);
    }

    function changeSaleStatusWithSign(bool _onSale, uint _nonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('changeSaleStatusWithSign');
        hash = sha3(hash, _onSale);
        hash = sha3(hash, _nonce);
        address from = recoverAddress(hash, _sign);

        if (_nonce != nonces[from]) return false;
        nonces[from]++;

        return changeSaleStatusPrivate(from, _onSale);
    }

    function changeSaleStatusPrivate(address _from, bool _onSale) onlyByPromoterMember(_from) private returns (bool) {
        if (onSale == _onSale) return false;
        SaleEvent(_onSale ? SaleEventStatus.Sellable : SaleEventStatus.Unsellable);
        onSale = _onSale;
        return true;
    }

    /**
     * change promoter by promoter member
     */
    function setPromoterKey(bytes32 _promoterKey) returns (bool) {
        return setPromoterKeyPrivate(msg.sender, _promoterKey);
    }

    function setPromoterKeyWithSign(bytes32 _promoterKey, uint _nonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('setPromoterKeyWithSign');
        hash = sha3(hash, _promoterKey);
        hash = sha3(hash, _nonce);
        address from = recoverAddress(hash, _sign);

        if (_nonce != nonces[from]) return false;
        nonces[from]++;

        return setPromoterKeyPrivate(from, _promoterKey);
    }

    function setPromoterKeyPrivate(address _from, bytes32 _promoterKey) onlyByPromoterMember(_from) private returns (bool) {
        if (promoterKey == _promoterKey || !organizations.isActive(_promoterKey)) return false;
        SetPromoterEvent(_promoterKey);
        promoterKey = _promoterKey;
        return true;
    }

    /**
     * add sales agent by promoter member
     */
    function addSalesAgent(bytes32 _salesAgentKey) returns (bool) {
        return addSalesAgentPrivate(msg.sender, _salesAgentKey);
    }

    function addSalesAgentWithSign(bytes32 _salesAgentKey, uint _nonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('addSalesAgentWithSign');
        hash = sha3(hash, _salesAgentKey);
        hash = sha3(hash, _nonce);
        address from = recoverAddress(hash, _sign);

        if (_nonce != nonces[from]) return false;
        nonces[from]++;

        return addSalesAgentPrivate(from, _salesAgentKey);
    }

    function addSalesAgentPrivate(address _from, bytes32 _salesAgentKey) onlyByPromoterMember(_from) returns (bool) {
        if (salesAgentKeys[_salesAgentKey]) return false;
        salesAgentKeys[_salesAgentKey] = true;
        ChangeSalesAgentEvent(_salesAgentKey, ChangeSalesAgentAction.Add);
        return true;
    }

    /**
     * remove sales agent by promoter member
     */
    function removeSalesAgent(bytes32 _salesAgentKey) returns (bool) {
        return removeSalesAgentPrivate(msg.sender, _salesAgentKey);
    }

    function removeSalesAgentWithSign(bytes32 _salesAgentKey, uint _nonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('removeSalesAgentWithSign');
        hash = sha3(hash, _salesAgentKey);
        hash = sha3(hash, _nonce);
        address from = recoverAddress(hash, _sign);

        if (_nonce != nonces[from]) return false;
        nonces[from]++;

        return removeSalesAgentPrivate(from, _salesAgentKey);
    }

    function removeSalesAgentPrivate(address _from, bytes32 _salesAgentKey) onlyByPromoterMember(_from) returns (bool) {
        if (!salesAgentKeys[_salesAgentKey]) return false;
        salesAgentKeys[_salesAgentKey] = false;
        ChangeSalesAgentEvent(_salesAgentKey, ChangeSalesAgentAction.Remove);
        return true;
    }


    /**
     * create ticket by sales agent member
     */
    function createTicket(bytes32 _ticketKey, uint _seatCount, address _admissionAddress) returns (bool) {
        return createTicketPrivate(msg.sender, _ticketKey, _seatCount, _admissionAddress);
    }

    function createTicketWithSign(bytes32 _ticketKey, uint _seatCount, address _admissionAddress, uint _ticketNonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('createTicketWithSign');
        hash = sha3(hash, _ticketKey);
        hash = sha3(hash, _seatCount);
        hash = sha3(hash, _admissionAddress);
        hash = sha3(hash, _ticketNonce);
        address from = recoverAddress(hash, _sign);

        if (_ticketNonce != ticketNonces[_ticketKey]) return false;
        ticketNonces[_ticketKey]++;

        return createTicketPrivate(from, _ticketKey, _seatCount, _admissionAddress);
    }

    function createTicketPrivate(address _from, bytes32 _ticketKey, uint _seatCount, address _admissionAddress) onlyBySalesMember(_from) private returns (bool) {
        bytes32 salesAgentKey = organizations.memberOrganizationKeys(_from);
        if (!onSale || tickets[_ticketKey].exist) return false;
        TicketEvent(TicketAction.Create, _ticketKey, salesAgentKey, _from, _seatCount, _admissionAddress);
        tickets[_ticketKey] = Ticket({ exist:true, admissionAddress: _admissionAddress, seatCount: _seatCount, salesAgentKey: salesAgentKey });
        if (_admissionAddress != 0) addAdmissionAddress(_ticketKey, _admissionAddress);
        return true;
    }

    /**
     * remove ticket by sales agent member
     */
    function removeTicket(bytes32 _ticketKey) returns (bool) {
        return removeTicketPrivate(msg.sender, _ticketKey);
    }

    function removeTicketWithSign(bytes32 _ticketKey, uint _ticketNonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('removeTicketWithSign');
        hash = sha3(hash, _ticketKey);
        hash = sha3(hash, _ticketNonce);
        address from = recoverAddress(hash, _sign);

        if (_ticketNonce != ticketNonces[_ticketKey]) return false;
        ticketNonces[_ticketKey]++;

        return removeTicketPrivate(from, _ticketKey);
    }

    function removeTicketPrivate(address _from, bytes32 _ticketKey) onlyBySalesMember(_from) private returns (bool) {
        bytes32 salesAgentKey = organizations.memberOrganizationKeys(_from);
        if (!onSale || !tickets[_ticketKey].exist || !isSeller(_ticketKey, salesAgentKey)) return false;
        TicketEvent(TicketAction.Remove, _ticketKey, salesAgentKey, _from, tickets[_ticketKey].seatCount, tickets[_ticketKey].admissionAddress);
        if (tickets[_ticketKey].admissionAddress != 0) removeAdmissionAddress(_ticketKey, tickets[_ticketKey].admissionAddress);
        tickets[_ticketKey].admissionAddress = 0;
        tickets[_ticketKey].seatCount = 0;
        tickets[_ticketKey].salesAgentKey = 0;
        return true;
    }

    /**
     * set seat count by sales agent member
     */
    function setSeatCount(bytes32 _ticketKey, uint _seatCount) returns (bool) {
        return setSeatCountPrivate(msg.sender, _ticketKey, _seatCount);
    }

    function setSeatCountWithSign(bytes32 _ticketKey, uint _seatCount, uint _ticketNonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('setSeatCountWithSign');
        hash = sha3(hash, _ticketKey);
        hash = sha3(hash, _seatCount);
        hash = sha3(hash, _ticketNonce);
        address from = recoverAddress(hash, _sign);

        if (_ticketNonce != ticketNonces[_ticketKey]) return false;
        ticketNonces[_ticketKey]++;

        return setSeatCountPrivate(from, _ticketKey, _seatCount);
    }

    function setSeatCountPrivate(address _from, bytes32 _ticketKey, uint _seatCount) onlyBySalesMember(_from) private returns (bool) {
        bytes32 salesAgentKey = organizations.memberOrganizationKeys(_from);
        if (!onSale || !tickets[_ticketKey].exist || !isSeller(_ticketKey, salesAgentKey)) return false;
        TicketEvent(TicketAction.SetSeatCount, _ticketKey, salesAgentKey, _from, tickets[_ticketKey].seatCount, tickets[_ticketKey].admissionAddress);
        tickets[_ticketKey].seatCount = _seatCount;
        return true;
    }

    /**
     * set admission address by sales agent member
     */
    function setAdmissionAddress(bytes32 _ticketKey, address _address) returns (bool) {
        return setAdmissionAddressPrivate(msg.sender, _ticketKey, _address);
    }

    function setAdmissionAddressWithSign(bytes32 _ticketKey, address _address, uint _ticketNonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('setAdmissionAddressWithSign');
        hash = sha3(hash, _ticketKey);
        hash = sha3(hash, _address);
        hash = sha3(hash, _ticketNonce);
        address from = recoverAddress(hash, _sign);

        if (_ticketNonce != ticketNonces[_ticketKey]) return false;
        ticketNonces[_ticketKey]++;

        return setAdmissionAddressPrivate(from, _ticketKey, _address);
    }

    function setAdmissionAddressPrivate(address _from, bytes32 _ticketKey, address _address) onlyBySalesMember(_from) private returns (bool) {
        bytes32 salesAgentKey = organizations.memberOrganizationKeys(_from);
        address removed = tickets[_ticketKey].admissionAddress;
        if (!onSale || !tickets[_ticketKey].exist || !isSeller(_ticketKey, salesAgentKey) || removed == _address) return false;
        TicketEvent(TicketAction.SetAdmissionAddress, _ticketKey, salesAgentKey, _from, tickets[_ticketKey].seatCount, _address);
        tickets[_ticketKey].admissionAddress = _address;
        if (_address != 0) addAdmissionAddress(_ticketKey, _address);
        if (removed != 0) removeAdmissionAddress(_ticketKey, removed);
        return true;
    }

    function addAdmissionAddress(bytes32 _ticketKey, address _address) private {
        if (addressTicketKeys[_address].length == 0) {
            admissionAddresses.push(_address);
        }
        addressTicketKeys[_address].push(_ticketKey);
    }

    function removeAdmissionAddress(bytes32 _ticketKey, address _address) private {
        for (uint i = 0; i < addressTicketKeys[_address].length; i++) {
            if (addressTicketKeys[_address][i] == _ticketKey) {
                addressTicketKeys[_address][i] = addressTicketKeys[_address][addressTicketKeys[_address].length - 1];
                addressTicketKeys[_address].length--;
                if (addressTicketKeys[_address].length == 0) {
                    for (uint j = 0; j < admissionAddresses.length; j++) {
                        if (admissionAddresses[j] == _address) {
                            admissionAddresses[j] = admissionAddresses[admissionAddresses.length - 1];
                            admissionAddresses.length--;
                            break;
                        }
                    }
                }
                break;
            }
        }
    }

    /* ----------- other----------------- */

    function getAddressAndSeatCount(uint _offset, uint _limit) constant returns (address[], uint[]) {
        assert (_limit <= 10000 && _offset <= admissionAddresses.length);
        uint count = (_offset + _limit) > admissionAddresses.length ? admissionAddresses.length - _offset : _limit;
        address[] memory addr = new address[](count);
        uint[] memory seatCount = new uint[](count);
        for (uint i = 0; i < count; i++) {
            addr[i] = admissionAddresses[_offset + i];
            seatCount[i] = getOwnSeatCount(addr[i]);
        }
        return (addr, seatCount);
    }

    function isSeller(bytes32 _ticketKey, bytes32 _saleAgentKey) constant returns (bool) {
        return tickets[_ticketKey].salesAgentKey == _saleAgentKey;
    }

    function ownTicket(address _address, bytes32 _ticketKey) constant returns (bool) {
        return tickets[_ticketKey].exist && tickets[_ticketKey].admissionAddress == _address;
    }

    function getOwnSeatCount(address _address) constant returns (uint c) {
        for (uint i = 0; i < addressTicketKeys[_address].length; i++) {
            c += tickets[addressTicketKeys[_address][i]].seatCount;
        }
    }

    function getAddressTicketKeysLength(address _address) constant returns (uint) {
        return addressTicketKeys[_address].length;
    }

    function getAdmissionAddressesLength() constant returns (uint) {
        return admissionAddresses.length;
    }

    function getAdmissionAddress(uint _index) constant returns (address) {
        return admissionAddresses[_index];
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
