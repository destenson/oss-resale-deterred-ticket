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
    var attraction = $('#attraction').val();
    var userAddress = $('#user').val();
    if ('' == attraction || '' == userAddress) {
        $('#ticket-list-area').css('display', 'none');
    } else {
        refreshTicket();
    }
};

var refreshTicket = function() {
    if (DEMO_UTIL.isLoading()) return;
    if (!DEMO_UTIL.startLoad()) return;

    $('#ticket-list-area').css('display', 'none');

    $('#ticket-list').empty();
    $('#ticket-list').append($('#ticket-row-title-template div:first').clone(true));

    var userAccount = LOCAL_STORAGE.getUserAccountWithAddress($('#user').val());
    var attractionId = $('#attraction').val();

    var contract = ETH_UTIL.getContract(userAccount);
    var ticketKeys, seatCounts;
    contract.call('', 'ProxyController', 'getTicketsByAdmissionAddress', [ATTRACTION_HANDLER, attractionId, userAccount.getAddress()], PROXY_CONTROLLER_ABI, function(err, res) {
        if (err) {
            console.error(err);
            return;
        }
        console.log(res);
        ticketKeys = res[0];
        seatCounts = res[2];

        ticketKeys.forEach(function(key, index) {
            addTicketRow({ key: ETH_UTIL.toUtf8(key), seatCount: seatCounts[index].toString(10) });
        });
        DEMO_UTIL.stopLoad();
        if (ticketKeys.length > 0) {
            $('#ticket-list-area').css('display', 'block');
        } else {
            DEMO_UTIL.okDialog(
                demoMsg('ticket.dialog.err-no-ticket.title'),
                demoMsg('ticket.dialog.err-no-ticket.msg')
            );
        }
    });
};

var addTicketRow = function(ticket) {
    var key = ticket.key;
    var row = $('#ticket-row-template div:first').clone(true);
    row.find('div[name="key"]').html(key);
    row.find('input[name="key"]').val(key);
    var seatCount = row.find('select[name="seat-count"]');
    seatCount.empty();
    seatCount.append($('<option>').val('1').text('1'));
    seatCount.append($('<option>').val('2').text('2'));
    seatCount.append($('<option>').val('3').text('3'));
    seatCount.append($('<option>').val('4').text('4'));
    seatCount.append($('<option>').val('5').text('5'));
    seatCount.append($('<option>').val('6').text('6'));
    seatCount.append($('<option>').val('7').text('7'));
    seatCount.append($('<option>').val('8').text('8'));
    seatCount.append($('<option>').val('9').text('9'));
    seatCount.append($('<option>').val('10').text('10'));
    setTicketSeatCount(row, ticket.seatCount);
    $('#ticket-list').append(row);
};

var setTicketSeatCount = function(row, seatCount) {
    row.find('input[name="current-seat-count"]').html(seatCount);
    row.find('select[name="seat-count"]').val(seatCount);
};

var changeSeatCount = function(obj) {
    if (DEMO_UTIL.isLoading()) return;
    if (!DEMO_UTIL.startLoad()) return;
    var attractionId = $('#attraction').val();
    var row = $(obj.closest('div[name="ticket-row"]'));
    var ticketKey = row.find('input[name="key"]').val();
    var seatCount = row.find('select[name="seat-count"]').val();
    var currentSeatCount = row.find('input[name="current-seat-count"]').val();

    if (seatCount == currentSeatCount) {
        DEMO_UTIL.okDialog(
            demoMsg('common.dialog.err-required.title'),
            demoMsg('common.dialog.err-required.msg')
        );
        return;
    }

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
        salesAgentAccount.sign('', ethClient.utils.hashBySolidityType(['address', 'bytes32', 'bytes32', 'uint', 'uint'], [attractionAddress, 'setSeatCountWithSign', ticketKey, seatCount, nonce]), function(err, res) {
            if (err) {
                console.error(err);
                return;
            }
            console.log(res);
            sign = res;
            contract.sendTransaction('', 'ProxyController', 'setAttrSeatCount', [attractionAddress, ticketKey, seatCount, nonce, sign], PROXY_CONTROLLER_ABI, function(err, res) {
                if (err) {
                    console.error(err);
                    return;
                }
                console.log(res);
                setTicketSeatCount(row, seatCount);
                DEMO_UTIL.stopLoad();
            });
        });
    });
};

var cancelTicket = function(obj) {
    if (DEMO_UTIL.isLoading()) return;
    if (!DEMO_UTIL.startLoad()) return;
    var attractionId = $('#attraction').val();
    var row = $(obj.closest('div[name="ticket-row"]'));
    var ticketKey = row.find('input[name="key"]').val();

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
        salesAgentAccount.sign('', ethClient.utils.hashBySolidityType(['address', 'bytes32', 'bytes32', 'uint'], [attractionAddress, 'removeTicketWithSign', ticketKey, nonce]), function(err, res) {
            if (err) {
                console.error(err);
                return;
            }
            console.log(res);
            sign = res;
            contract.sendTransaction('', 'ProxyController', 'removeAttrTicket', [attractionAddress, ticketKey, nonce, sign], PROXY_CONTROLLER_ABI, function(err, res) {
                if (err) {
                    console.error(err);
                    return;
                }
                console.log(res);
                row.remove();
                DEMO_UTIL.stopLoad();
            });
        });
    });
};
