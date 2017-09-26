pragma solidity ^0.4.8;

contract Organizations {

    struct Organization {
        bool created;
        bool active;
        uint adminCount;
        mapping (address => bool) admins; // admin => bool
        mapping (address => bool) members; // member => bool
    }

    mapping (bytes32 => Organization) public organizations; // organizationKey => Organization
    mapping (address => bytes32) public adminOrganizationKeys; // adminAddress => OrganizationKey
    mapping (address => bytes32) public memberOrganizationKeys; // memberAddress => OrganizationKey

    // nonce for each account
    mapping(address => uint) public nonces;

    enum OrganizationAction {
        Create,
        Activate,
        Deactivate
    }

    enum AccountAction {
        Add,
        Remove
    }

    event OranizationEvent(bytes32 indexed _organizationKey, OrganizationAction action);
    event AdminEvent(bytes32 indexed _organizationKey, AccountAction action, address _address);
    event MemberEvent(bytes32 indexed _organizationKey, AccountAction action, address _address);

    /* ----------- modifiers ----------------- */

    modifier onlyByAdmin(address _addr) {
        assert(isAdmin(_addr));
        _;
    }


    /* ----------- methods ----------------- */

    function isAdmin(address _addr) constant returns (bool) {
        bytes32 organizationKey = adminOrganizationKeys[_addr];
        return organizationKey != 0 && organizations[organizationKey].admins[_addr];
    }

    function isMember(address _addr) constant returns (bool) {
        bytes32 organizationKey = memberOrganizationKeys[_addr];
        return organizationKey != 0 && organizations[organizationKey].members[_addr];
    }

    function isActive(bytes32 _organizationKey) constant returns (bool) {
        return organizations[_organizationKey].active;
    }

    function createOrganization(bytes32 _organizationKey) returns (bool) {
        return createOrganizationPrivate(msg.sender, _organizationKey);
    }

    function createOrganizationWithSign(bytes32 _organizationKey, uint _nonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('createOrganizationWithSign');
        hash = sha3(hash, _organizationKey);
        hash = sha3(hash, _nonce);
        address from = recoverAddress(hash, _sign);

        if (_nonce != nonces[from]) return false;
        nonces[from]++;

        return createOrganizationPrivate(from, _organizationKey);
    }

    function createOrganizationPrivate(address _from, bytes32 _organizationKey) private returns (bool) {
        if (organizations[_organizationKey].created) return false;
        OranizationEvent(_organizationKey, OrganizationAction.Create);
        AdminEvent(_organizationKey, AccountAction.Add, _from);
        organizations[_organizationKey] = Organization({created:true, active:true, adminCount:1});
        organizations[_organizationKey].admins[_from] = true;
        adminOrganizationKeys[_from] = _organizationKey;
        return true;
    }

    /**
     * change activate by admin
     */
    function changeActivation() returns (bool) {
        return changeActivationPrivate(msg.sender);
    }

    function changeActivationWithSign(uint _nonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('changeActivationWithSign');
        hash = sha3(hash, _nonce);
        address from = recoverAddress(hash, _sign);

        if (_nonce != nonces[from]) return false;
        nonces[from]++;

        return changeActivationPrivate(from);
    }

    function changeActivationPrivate(address _from) onlyByAdmin(_from) private returns (bool) {
        bytes32 organizationKey = adminOrganizationKeys[_from];
        if (organizationKey == 0) return false;
        bool changeTo = !organizations[organizationKey].active;
        OranizationEvent(organizationKey, (changeTo ? OrganizationAction.Activate : OrganizationAction.Deactivate));
        organizations[organizationKey].active = changeTo;
        return true;
    }

    /**
     * add admin by admin
     */
    function addAdmin(address _addr) returns (bool) {
        return addAdminPrivate(msg.sender, _addr);
    }

    function addAdminWithSign(address _addr, uint _nonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('addAdminWithSign');
        hash = sha3(hash, _addr);
        hash = sha3(hash, _nonce);
        address from = recoverAddress(hash, _sign);

        if (_nonce != nonces[from]) return false;
        nonces[from]++;

        return addAdminPrivate(from, _addr);
    }

    function addAdminPrivate(address _from, address _addr) onlyByAdmin( _from) private returns (bool) {
        bytes32 organizationKey = adminOrganizationKeys[_from];
        if (!organizations[organizationKey].created) return false;
        if (adminOrganizationKeys[_addr] != 0 && adminOrganizationKeys[_addr] != organizationKey) return false;
        if (memberOrganizationKeys[_addr] != 0 && memberOrganizationKeys[_addr] != organizationKey) return false;

        AdminEvent(organizationKey, AccountAction.Add, _addr);
        organizations[organizationKey].adminCount++;
        organizations[organizationKey].admins[_addr] = true;
        adminOrganizationKeys[_addr] = organizationKey;
        return true;
    }

    /**
     * remove admin by admin
     */
    function removeAdmin(address _addr) returns (bool) {
        return removeAdminPrivate(msg.sender, _addr);
    }

    function removeAdminWithSign(address _addr, uint _nonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('removeAdminWithSign');
        hash = sha3(hash, _addr);
        hash = sha3(hash, _nonce);
        address from = recoverAddress(hash, _sign);

        if (_nonce != nonces[from]) return false;
        nonces[from]++;

        return removeAdminPrivate(from, _addr);
    }

    function removeAdminPrivate(address _from, address _addr) onlyByAdmin(_from) private returns (bool) {
        bytes32 organizationKey = adminOrganizationKeys[_from];
        if (organizationKey == 0 || adminOrganizationKeys[_addr] == 0  || !organizations[organizationKey].created || organizations[organizationKey].adminCount == 1) return false;
        AdminEvent(organizationKey, AccountAction.Remove, _addr);
        organizations[organizationKey].adminCount--;
        organizations[organizationKey].admins[_addr] = false;
        // Because the account do not allow to become another admin or member.
        // adminOrganizationKeys[_addr] = 0;
        return true;
    }

    /**
     * add member by member
     */
    function addMember(address _addr) returns (bool) {
        return addMemberPrivate(msg.sender, _addr);
    }

    function addMemberWithSign(address _addr, uint _nonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('addMemberWithSign');
        hash = sha3(hash, _addr);
        hash = sha3(hash, _nonce);
        address from = recoverAddress(hash, _sign);

        if (_nonce != nonces[from]) return false;
        nonces[from]++;

        return addMemberPrivate(from, _addr);
    }

    function addMemberPrivate(address _from, address _addr) onlyByAdmin(_from) private returns (bool) {
        bytes32 organizationKey = adminOrganizationKeys[_from];
        if (!organizations[organizationKey].created) return false;
        if (adminOrganizationKeys[_addr] != 0 && adminOrganizationKeys[_addr] != organizationKey) return false;
        if (memberOrganizationKeys[_addr] != 0 && memberOrganizationKeys[_addr] != organizationKey) return false;

        MemberEvent(organizationKey, AccountAction.Add, _addr);
        organizations[organizationKey].members[_addr] = true;
        memberOrganizationKeys[_addr] = organizationKey;
        return true;
    }

    /**
     * remove member by admin
     */
    function removeMember(address _addr) returns (bool) {
        return removeMemberPrivate(msg.sender, _addr);
    }

    function removeMemberWithSign(address _addr, uint _nonce, bytes _sign) returns (bool) {
        bytes32 hash = calcEnvHash('removeMemberWithSign');
        hash = sha3(hash, _addr);
        hash = sha3(hash, _nonce);
        address from = recoverAddress(hash, _sign);

        if (_nonce != nonces[from]) return false;
        nonces[from]++;

        return removeMemberPrivate(from, _addr);
    }

    function removeMemberPrivate(address _from, address _addr) onlyByAdmin(_from) private returns (bool) {
        bytes32 organizationKey = adminOrganizationKeys[_from];
        if (organizationKey == 0 || memberOrganizationKeys[_addr] == 0 || !organizations[organizationKey].created) return false;
        MemberEvent(organizationKey, AccountAction.Remove, _addr);
        organizations[organizationKey].members[_addr] = false;
        // Because the account do not allow to become another admin or member.
        //memberOrganizationKeys[_addr] = 0;
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
