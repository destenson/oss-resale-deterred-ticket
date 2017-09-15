var LOCAL_STORAGE = {};

var _prefix = 'inhibit-resale-token.v0.';

var _promoterKey = _prefix + 'promoter';
var _promoterIDKey = _prefix + 'promoter-id';
var _salesAgentKey = _prefix + 'sales-agent';
var _salesAgentIDKey = _prefix + 'sales-agent-id';
var _usersKey = _prefix + 'users';
var _attractionsDBKey = _prefix + 'local.promoter.db.attractions';
var _entryAccountsDBKey = _prefix + 'local.venue.db.entry-accounts';
var _entryHistoryDBKey = _prefix + 'local.venue.db.entry-history';

LOCAL_STORAGE.getPromoterAccount = function () {
    var serializedAccount = localStorage.getItem(_promoterKey);
    return serializedAccount ? ethClient.Account.deserialize(serializedAccount) : null;
};
LOCAL_STORAGE.setPromoterAccount = function (_account) {
    localStorage.setItem(_promoterKey, _account.serialize());
};

LOCAL_STORAGE.getPromoterID = function () {
    return localStorage.getItem(_promoterIDKey);
};
LOCAL_STORAGE.setPromoterID = function (_id) {
    localStorage.setItem(_promoterIDKey, _id);
};

LOCAL_STORAGE.getSalesAgentAccount = function () {
    var serializedAccount = localStorage.getItem(_salesAgentKey);
    return serializedAccount ? ethClient.Account.deserialize(serializedAccount) : null;
};
LOCAL_STORAGE.setSalesAgentAccount = function (_account) {
    localStorage.setItem(_salesAgentKey, _account.serialize());
};

LOCAL_STORAGE.getUserAccounts = function () {
    var serialUsers = JSON.parse(localStorage.getItem(_usersKey));
    serialUsers = serialUsers ? serialUsers : [];
    var users = [];
    for (var i = 0; i < serialUsers.length; i++) {
        users.push(ethClient.Account.deserialize(serialUsers[i]));
    }
    return users;
};
LOCAL_STORAGE.getUserAccount = function (i) {
    var serialUsers = JSON.parse(localStorage.getItem(_usersKey));
    return ethClient.Account.deserialize(serialUsers[i]);
};
LOCAL_STORAGE.addUserAccount = function (_account) {
    var serialUsers = JSON.parse(localStorage.getItem(_usersKey));
    serialUsers = serialUsers ? serialUsers : [];
    serialUsers.push(_account.serialize());
    localStorage.setItem(_usersKey, JSON.stringify(serialUsers));
};
LOCAL_STORAGE.getUserAccountWithAddress = function (address) {
    var serialUsers = JSON.parse(localStorage.getItem(_usersKey));
    serialUsers = serialUsers ? serialUsers : [];
    var users = [];
    for (var i = 0; i < serialUsers.length; i++) {
        var account = ethClient.Account.deserialize(serialUsers[i]);
        if (account.getAddress() == address) {
            return account;
        }
    }
    return null;
};

LOCAL_STORAGE.getSalesAgentID = function () {
    return localStorage.getItem(_salesAgentIDKey);
};
LOCAL_STORAGE.setSalesAgentID = function (_id) {
    localStorage.setItem(_salesAgentIDKey, _id);
};

LOCAL_STORAGE.getAttractionsDB = function () {
    var a = JSON.parse(localStorage.getItem(_attractionsDBKey));
    return a ? a: [];
};
LOCAL_STORAGE.setAttractionsDB = function (_jsonValue) {
    localStorage.setItem(_attractionsDBKey, JSON.stringify(_jsonValue));
};

LOCAL_STORAGE.getEntryAccountsDB = function () {
    var db = localStorage.getItem(_entryAccountsDBKey);
    return db ? JSON.parse(db) : {};
};
LOCAL_STORAGE.setEntryAccountsDB = function (_jsonValue) {
    localStorage.setItem(_entryAccountsDBKey, JSON.stringify(_jsonValue));
};

LOCAL_STORAGE.getEntryHistoryDB = function () {
    var db = localStorage.getItem(_entryHistoryDBKey);
    return db ? JSON.parse(db) : {};
};
LOCAL_STORAGE.setEntryHistoryDB = function (_jsonValue) {
    localStorage.setItem(_entryHistoryDBKey, JSON.stringify(_jsonValue));
};
