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

var changeValue = function() {
    $('#qr-area').css('display', 'none');
};

var onetimeKeyTicket;
var purchase = function() {
    var attractionId = $('#attraction').val();
    var seatCount = $('#seat-count').val();

    if ("" == attractionId) {
        DEMO_UTIL.okDialog(
            demoMsg('common.dialog.err-required.title'),
            demoMsg('common.dialog.err-required.msg')
        );
        return;
    }

    var onetimeKey = DEMO_UTIL.createRandomId(32);
    onetimeKeyTicket = {};
    onetimeKeyTicket[onetimeKey] = {ticket:DEMO_UTIL.createRandomId(16), used:false};
    var qrContent = {
        eventId: attractionId,
        seatCount: seatCount,
        onetimeKey: onetimeKey
    };
    $('#qrcode').empty();
    $('#qrcode').qrcode(JSON.stringify(qrContent));
    $('#qr-content').html(JSON.stringify(qrContent, null, '    '));
    $('#qr-area').css('display', 'block');
};

var saveTicket = function() {
    var userAddress = $('#user').val();
    if ("" == userAddress) {
        DEMO_UTIL.okDialog(
            demoMsg('common.dialog.err-required.title'),
            demoMsg('common.dialog.err-required.msg')
        );
        return;
    }

    if (DEMO_UTIL.isLoading()) return;
    if (!DEMO_UTIL.startLoad()) return;

    var userAccount = LOCAL_STORAGE.getUserAccountWithAddress(userAddress);
    var qrContent = JSON.parse($('#qr-content').html());
    var attractionId = qrContent.eventId;
    var seatCount = qrContent.seatCount;
    var onetimeKey = qrContent.onetimeKey;

    var userSign;
    userAccount.sign(
        '',
        ethClient.utils.hashBySolidityType(
            ['bytes32', 'uint', 'bytes32'], [attractionId, seatCount, onetimeKey]
        ),
        function(err, res) {
            if (err) {
                console.error(err);
                alert('error');
                return DEMO_UTIL.stopLoad();
            }
            console.log(res);
            userSign = res;

            // Send attractionId, onetimeKey, userSign from client side to server side at this point.
            // And the following processing should be done on the server side.

            if (!onetimeKeyTicket[onetimeKey]) {
                DEMO_UTIL.okDialog(
                    demoMsg('purchase.dialog.err-onetime-unmatch.title'),
                    demoMsg('purchase.dialog.err-onetime-unmatch.msg')
                );
                return DEMO_UTIL.stopLoad();
            }
            if (onetimeKeyTicket[onetimeKey].used) {
                DEMO_UTIL.okDialog(
                    demoMsg('purchase.dialog.err-onetime-used.title'),
                    demoMsg('purchase.dialog.err-onetime-used.msg')
                );
                return DEMO_UTIL.stopLoad();
            }
            var hash = ethClient.utils.hashBySolidityType(
                ['bytes32', 'uint', 'bytes32'], [attractionId, seatCount, onetimeKey]
            );
            var userAddress = ethClient.utils.recoverAddress(hash, userSign);
            console.log(userAddress);
            var ticketKey = onetimeKeyTicket[onetimeKey].ticket;

            var salesAgentAccount = LOCAL_STORAGE.getSalesAgentAccount();
            var contract = ETH_UTIL.getContract(salesAgentAccount);
            var attractionAddress, nonce, sign;
            contract.call('', 'ProxyController', 'getAttrAddressAndTicketNonce', [ATTRACTION_HANDLER, attractionId, ticketKey], PROXY_CONTROLLER_ABI, function(err, res) {
                if (err) {
                    console.error(err);
                    return;
                }
                console.log(res);
                attractionAddress = res[0];
                nonce = res[1].toString(10);
                salesAgentAccount.sign('', ethClient.utils.hashBySolidityType(['address', 'bytes32', 'bytes32', 'uint', 'address', 'uint'], [attractionAddress, 'createTicketWithSign', ticketKey, seatCount, userAddress, nonce]), function(err, res) {
                    if (err) {
                        console.error(err);
                        return;
                    }
                    console.log(res);
                    sign = res;
                    contract.sendTransaction('', 'ProxyController', 'createAttrTicket', [attractionAddress, ticketKey, seatCount, userAddress, nonce, sign], PROXY_CONTROLLER_ABI, function(err, res) {
                        if (err) {
                            console.error(err);
                            return;
                        }
                        onetimeKeyTicket[onetimeKey].used = true;
                        console.log(res);
                        DEMO_UTIL.stopLoad();
                        if (onetimeKeyTicket[onetimeKey].used) {
                            DEMO_UTIL.okDialog(
                                demoMsg('purchase.dialog.complete.title'),
                                demoMsg('purchase.dialog.complete.msg')
                            );
                            return DEMO_UTIL.stopLoad();
                        }
                    });
                });
            })
        }
    );
};
