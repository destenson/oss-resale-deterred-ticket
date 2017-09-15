var preparePromoters = function(callback) {

    var promoterAccount = LOCAL_STORAGE.getPromoterAccount();
    var promoterID = LOCAL_STORAGE.getPromoterID();
    var salesAgentAccount = LOCAL_STORAGE.getSalesAgentAccount();
    var salesAgentID = LOCAL_STORAGE.getSalesAgentID();
    if (!promoterAccount || !promoterID || !salesAgentAccount || !salesAgentID) {

        DEMO_UTIL.confirmDialog(
            demoMsg('common.dialog.err-no-promoter.title'),
            demoMsg('common.dialog.err-no-promoter.msg'),
            function() {

                DEMO_UTIL.startLoad();
                $(this).dialog("close");

                registerAccount(promoterAccount, function(promoterAccount) {
                    registerAccount(salesAgentAccount, function(salesAgentAccount) {
                        var promoterId = DEMO_UTIL.createRandomId(32);
                        var salesAgentId = DEMO_UTIL.createRandomId(32);
                        createOrganization(promoterAccount, promoterId, function(err) {
                            if (err) {
                                console.error(err);
                                return callback();
                            }
                            createOrganization(salesAgentAccount, salesAgentId, function(err) {
                                if (err) {
                                    console.error(err);
                                    return callback();
                                }
                                LOCAL_STORAGE.setPromoterAccount(promoterAccount);
                                LOCAL_STORAGE.setSalesAgentAccount(salesAgentAccount);
                                LOCAL_STORAGE.setPromoterID(promoterId);
                                LOCAL_STORAGE.setSalesAgentID(salesAgentId);
                                DEMO_UTIL.stopLoad();
                                callback();
                            })
                        })
                    });
                });
            },
            function() {
                window.location.href = './index.html';
            }
        );
        return;
    }
    callback();
};

var createOrganization = function(account, key, callback) {
    var nonce, sign;
    var contract = ETH_UTIL.getContract(account);
    contract.call('', 'ProxyController', 'getOrganizationsNonce', [ORGANIZATIONS, account.getAddress()], PROXY_CONTROLLER_ABI, function(err, res) {
        if (err) return callback(err);
        console.log(res);
        nonce = res[0].toString(10);
        account.sign('', ethClient.utils.hashBySolidityType(['address', 'bytes32', 'bytes32', 'uint'], [ORGANIZATIONS, 'createOrganizationWithSign', key, nonce]), function(err, res) {
            if (err) return callback(err);
            console.log(res);
            sign = res;
            contract.sendTransaction('', 'ProxyController', 'createOrganization', [ORGANIZATIONS, key, nonce, sign], PROXY_CONTROLLER_ABI, function(err, res) {
                if (err) return callback(err);
                console.log(res);
                var txHash = res;
                var getTransactionReceipt = function(txHash, cb) {
                    contract.getTransactionReceipt(txHash, function(err, res) {
                        if (err) cb(err);
                        else if (res) addMember(account, key, account.getAddress(), cb);
                        else setTimeout(function() { getTransactionReceipt(txHash, cb); }, 5000);
                    });
                }
                getTransactionReceipt(txHash, callback);
            });
        });
    });
}

var addMember = function(admin, key, member, callback) {
    var nonce, sign;
    var contract = ETH_UTIL.getContract(admin);
    contract.call('', 'ProxyController', 'getOrganizationsNonce', [ORGANIZATIONS, member], PROXY_CONTROLLER_ABI, function(err, res) {
        if (err) return callback(err);
        console.log(res);
        nonce = res[0].toString(10);
        admin.sign('', ethClient.utils.hashBySolidityType(['address', 'bytes32', 'address', 'uint'], [ORGANIZATIONS, 'addMemberWithSign', member, nonce]), function(err, res) {
            if (err) return callback(err);
            console.log(res);
            sign = res;
            contract.sendTransaction('', 'ProxyController', 'addOrganizationMember', [ORGANIZATIONS, member, nonce, sign], PROXY_CONTROLLER_ABI, function(err, res) {
                if (err) return callback(err);
                console.log(res);
                callback();
            });
        });
    });
}

var registerAccount = function(account, callback) {
    if (account) {
        callback(account);
        return;
    }
    ETH_UTIL.generateNewAccount(function(_newAccount) {
        callback(_newAccount);
    });
};

var prepareEvent = function(callback) {

    var attractions = LOCAL_STORAGE.getAttractionsDB();
    if (attractions.length == 0) {

        DEMO_UTIL.confirmDialog(
            demoMsg('common.dialog.err-no-event.title'),
            demoMsg('common.dialog.err-no-event.msg'),
            function() {
                window.location.href = './event.html';
            },
            function() {
                window.location.href = './index.html';
            }
        );
        return;
    }
    callback();
};

var prepareUsers = function(callback) {

    var userAccounts = LOCAL_STORAGE.getUserAccounts();
    if (userAccounts.length == 0) {

        DEMO_UTIL.confirmDialog(
            demoMsg('common.dialog.err-no-user.title'),
            demoMsg('common.dialog.err-no-user.msg'),
            function() {

                DEMO_UTIL.startLoad();
                $(this).dialog("close");

                ETH_UTIL.generateNewAccount(function(user0) {
                    ETH_UTIL.generateNewAccount(function(user1) {
                        ETH_UTIL.generateNewAccount(function(user2) {
                            LOCAL_STORAGE.addUserAccount(user0);
                            LOCAL_STORAGE.addUserAccount(user1);
                            LOCAL_STORAGE.addUserAccount(user2);
                            DEMO_UTIL.stopLoad();
                            callback();
                        });
                    });
                });
            },
            function() {
                window.location.href = './index.html';
            }
        );
        return;
    }
    callback();
};