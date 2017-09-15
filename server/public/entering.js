$(document).ready(function() {

    prepareEvent(function() {
        prepareUsers(function() {
            refreshPage();
        });
    });
});

var refreshPage = function() {
    var attraction = $('#attraction');
    attraction.empty();
    attraction.append($('<option>').val("").text(demoMsg('common.content.select')));
    var attractions = LOCAL_STORAGE.getAttractionsDB();
    for (var i = 0; i < attractions.length; i++) {
        attraction.append($('<option>').val(attractions[i].key).text(attractions[i].name + ' (' + attractions[i].key + ')'));
    }

    var user = $('#user');
    user.empty();
    user.append($('<option>').val("").text(demoMsg('common.content.select')));
    var userAccounts = LOCAL_STORAGE.getUserAccounts();
    for (var i = 0; i < userAccounts.length; i++) {
        user.append($('<option>').val(userAccounts[i].getAddress()).text(userAccounts[i].getAddress()));
    }
};

var changeValues = function() {
    $('#user-area').css('display', 'none');
    $('#qr-area').css('display', 'none');
};

var changeUser = function() {
    $('#qr-area').css('display', 'none');
};

var prepareEntering = function() {
    if (DEMO_UTIL.isLoading()) return;
    if (!DEMO_UTIL.startLoad()) return;

    var attractionId = $('#attraction').val();
    if ('' == attractionId) {
        DEMO_UTIL.okDialog(
            demoMsg('common.dialog.err-required.title'),
            demoMsg('common.dialog.err-required.msg')
        );
        return DEMO_UTIL.stopLoad();
    }

    var contract = ETH_UTIL.getContract(LOCAL_STORAGE.getSalesAgentAccount());
    var onSale;
    contract.call('', 'ProxyController', 'isAttrSellable', [ATTRACTION_HANDLER, attractionId], PROXY_CONTROLLER_ABI, function(err, res) {
        if (err) {
            console.error(err);
            alert('error');
            return;
        }
        console.log(res);
        onSale = res[0];
        if (onSale) {
            DEMO_UTIL.stopLoad();
            DEMO_UTIL.confirmDialog(
                demoMsg('entering.dialog.warning-on-sale.title'),
                demoMsg('entering.dialog.warning-on-sale.msg'),
                function() {
                    DEMO_UTIL.startLoad();
                    loadEntryUsers(attractionId);
                    $(this).dialog("close");
                }
            );
            return;
        } else {
            loadEntryUsers(attractionId);
        }
    });
};

var loadEntryUsers = function(attractionId) {
    var contract = ETH_UTIL.getContract(LOCAL_STORAGE.getSalesAgentAccount());
    var offset = 0;
    var limit = 10;
    contract.call('', 'ProxyController', 'getAttrAdmissionsAndSeatCounts', [ATTRACTION_HANDLER, attractionId, offset, limit], PROXY_CONTROLLER_ABI, function(err, res) {
        if (err) {
            console.error(err);
            alert('error');
            return;
        }
        console.log(res);
        var admissions = res[0];
        var seatCounts = res[1];
        var entryUsers = {};
        admissions.forEach(function(admission, index) {
            entryUsers[admission] = seatCounts[index].toString(10);
        })
        LOCAL_STORAGE.setEntryAccountsDB(entryUsers);
        LOCAL_STORAGE.setEntryHistoryDB({});
        DEMO_UTIL.stopLoad();
        $('#user-area').css('display', 'block');
    });
};

var showQr = function() {
    var userAddress = $('#user').val();
    if ('' == userAddress) {
        DEMO_UTIL.okDialog(
            demoMsg('common.dialog.warning-on-sale.title'),
            demoMsg('common.dialog.warning-on-sale.msg')
        );
        return;
    }

    var userAccount = LOCAL_STORAGE.getUserAccountWithAddress(userAddress);
    var timeInMillis = Date.now();
    var attractionId = $('#attraction').val();

    var userSign;
    userAccount.sign(
        '',
        ethClient.utils.hashBySolidityType(
            ['bytes32', 'uint'], [attractionId, timeInMillis]
        ),
        function(err, res) {
            if (err) {
                console.error(err);
                alert('error');
                return;
            }
            console.log(res);
            userSign = res;

            var qrContent = {
                eventId: attractionId,
                timeInMillis: timeInMillis,
                sign: userSign
            };
            $('#qrcode').empty();
            var qrValue = JSON.stringify(qrContent);
            $('#qrcode').qrcode(qrValue);
            $('#qrcode-content').val(qrValue);
            qrContent['sign'] = qrContent.sign.substring(0, 32) + '...';
            $('#qrcode-content-view').html(JSON.stringify(qrContent, null, '    '));
            $('#qrcode-drawing-time').html(moment(timeInMillis).format('YYYY-MM-DD HH:mm:ss'));
            $('#qr-area').css('display', 'block');
        }
    );
};

var entry = function() {

    var qr = JSON.parse($('#qrcode-content').val());
    var hash = ethClient.utils.hashBySolidityType(
        ['bytes32', 'uint'], [qr.eventId, qr.timeInMillis]
    );
    var userAddress = ethClient.utils.recoverAddress(hash, qr.sign);
    console.log(userAddress);
    var entryDB = LOCAL_STORAGE.getEntryAccountsDB();
    if (!entryDB[userAddress]) {
        DEMO_UTIL.okDialog(
            demoMsg('entering.dialog.err-no-auth.title'),
            demoMsg('entering.dialog.err-no-auth.msg')
        );
        return;
    }

    var historyDB = LOCAL_STORAGE.getEntryHistoryDB();
    if (historyDB[userAddress] && historyDB[userAddress] >= entryDB[userAddress]) {
        DEMO_UTIL.okDialog(
            demoMsg('entering.dialog.err-used.title'),
            demoMsg('entering.dialog.err-used.msg')
        );
        return;
    }

    var timeDiffMillis = Date.now() - qr.timeInMillis;
    var tenMin = 10 * 60 * 1000;
    if (timeDiffMillis < -tenMin || tenMin < timeDiffMillis) {
        DEMO_UTIL.okDialog(
            demoMsg('entering.dialog.err-timeout.title'),
            demoMsg('entering.dialog.err-timeout.msg')
        );
        return;
    }

    var entryCount = entryDB[userAddress];
    if (historyDB[userAddress]) {
        entryCount = historyDB[userAddress] - entryDB[userAddress];
    }

    historyDB[userAddress] = entryDB[userAddress];
    LOCAL_STORAGE.setEntryHistoryDB(historyDB);

    DEMO_UTIL.okDialog(
        demoMsg('entering.dialog.entried.title'),
        demoMsg('entering.dialog.entried.msg').replace("%0", entryCount.toString())
    );
};