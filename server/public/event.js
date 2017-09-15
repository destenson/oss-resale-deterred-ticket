$(document).ready(function() {

    if ("ja" == localStorage.getItem('_lang')) {
        $(".flatpickr-datetime").flatpickr({ enableTime: true, locale: "ja" });
    } else {
        $(".flatpickr-datetime").flatpickr({ enableTime: true });
    }

    preparePromoters(function() {
        refreshPage();
    });
});

var refreshPage = function() {
    $('#attraction-name').val('');
    $('#attraction-datetime').val('');

    var attractions = LOCAL_STORAGE.getAttractionsDB();
    for (var i = 0; i < attractions.length; i++) {
        var attraction = attractions[i];
        addAttractionRow(attraction, true);
    }
};

var addAttractionRow = function(attraction, refresh, defaultSalesStatus) {
    var key = attraction.key;
    var name = attraction.name;
    var datetime = attraction.datetime;
    var row = $('#attraction-row-template div:first').clone(true);
    row.find('div[name="key"]').html(key);
    row.find('input[name="key"]').val(key);
    row.find('div[name="name"]').html(name);
    row.find('div[name="datetime"]').html(datetime);
    if (refresh) {
        refreshAttractionStatusUntilReflected(row, key, false);
    } else {
        setAttractionStatus(row, defaultSalesStatus);
    }
    $('#attraction-list').append(row);
};

var refreshAttractionStatus = function(row, key, callback) {
    var contract = ETH_UTIL.getContract(LOCAL_STORAGE.getPromoterAccount());
    var salesStatus, attractionAddress;
    contract.call('', 'ProxyController', 'isAttrSellable', [ATTRACTION_HANDLER, key], PROXY_CONTROLLER_ABI, function(err, res) {
        if (err) {
            console.error(err);
            if (callback) {
                callback(salesStatus, err);
            }
            return;
        }
        console.log(res);
        salesStatus = res[0];
        setAttractionStatus(row, salesStatus);
        if (callback) {
            callback(salesStatus);
        }
    });
};

var MAX_RETRY = 3;
var RETRY_INTERVAL = 3000;
var refreshAttractionStatusUntilReflected = function(
    row, key,
    changeSalesStatus) {
    var oldSalesStatus = row.find('input[name="sales-status"]').val();
    refreshAttractionStatusWithRetry(
        row, key, 0,
        changeSalesStatus, oldSalesStatus);
};
var refreshAttractionStatusWithRetry = function(
    row, key, currenRetryCount,
    changeSalesStatus, oldSalesStatus) {

    refreshAttractionStatus(row, key, function(salesStatus, err) {
        if (currenRetryCount >= MAX_RETRY) {
            if (err) {
                alert('failed to get event status check console.');
            }
            return;
        }
        if (!err && (!changeSalesStatus || oldSalesStatus != salesStatus.toString())) {
            return;
        }

        setTimeout(
            function() {
                currenRetryCount++;
                console.log('retry : ' + currenRetryCount);
                refreshAttractionStatusWithRetry(
                    row, key, currenRetryCount,
                    changeSalesStatus, oldSalesStatus);
            }, RETRY_INTERVAL);
    });
};

var setAttractionStatus = function(row, salesStatus) {
    row.find('div[name="sales-status"]').html(salesStatus ? demoMsg('common.content.on-sale') : demoMsg('common.content.off-sale'));
    row.find('input[name="sales-status"]').val(salesStatus);
};

var changeSalesStatus = function(obj) {
    if (DEMO_UTIL.isLoading()) return;
    if (!DEMO_UTIL.startLoad()) return;
    var row = $(obj.closest('div[name="attraction-row"]'));
    var key = row.find('input[name="key"]').val();
    var salesStatus = row.find('input[name="sales-status"]').val() === 'true';
    var promoterAccount = LOCAL_STORAGE.getPromoterAccount();
    var contract = ETH_UTIL.getContract(promoterAccount);

    var attractionAddress, nonce, sign;
    contract.call('', 'ProxyController', 'getAttrAddressAndNonce', [ATTRACTION_HANDLER, key, promoterAccount.getAddress()], PROXY_CONTROLLER_ABI, function(err, res) {
        if (err) {
            console.error(err);
            alert('error');
            return;
        }
        console.log(res);
        attractionAddress = res[0];
        nonce = res[1].toString(10);
        promoterAccount.sign('', ethClient.utils.hashBySolidityType(['address', 'bytes32', 'bool', 'uint'], [attractionAddress, 'changeSaleStatusWithSign', !salesStatus, nonce]), function(err, res) {
            if (err) {
                console.error(err);
                alert('error');
                return;
            }
            console.log(res);
            sign = res;
            contract.sendTransaction('', 'ProxyController', 'changeAttrSaleStatus', [attractionAddress, !salesStatus, nonce, sign], PROXY_CONTROLLER_ABI, function(err, res) {
                if (err) {
                    console.error(err);
                    alert('error');
                    return;
                }
                console.log(res);
                refreshAttractionStatusUntilReflected(row, key, true);
                DEMO_UTIL.stopLoad();
            });
        });
    })
};

/* create attraction */
var createAttraction = function() {
    if (DEMO_UTIL.isLoading()) return;
    if (!DEMO_UTIL.startLoad()) return;

    var name = $('#attraction-name').val().trim();
    var datetime = $('#attraction-datetime').val().trim();

    // validate(very simple for DEMO)
    if (!name || !datetime) {
        DEMO_UTIL.okDialog(
            demoMsg('common.dialog.err-required.title'),
            demoMsg('common.dialog.err-required.msg')
        );
        return DEMO_UTIL.stopLoad();
    }

    var key = DEMO_UTIL.createRandomId(32);
    var promoterAccount = LOCAL_STORAGE.getPromoterAccount();
    var salesAgentId = LOCAL_STORAGE.getSalesAgentID();
    var contract = ETH_UTIL.getContract(promoterAccount);

    var nonce, sign;
    contract.call('', 'ProxyController', 'getAttractionHandlerNonce', [ATTRACTION_HANDLER, promoterAccount.getAddress()], PROXY_CONTROLLER_ABI, function(err, res) {
        if (err) {
            console.error(err);
            return;
        }
        console.log(res);
        nonce = res[0].toString(10);
        promoterAccount.sign('', ethClient.utils.hashBySolidityType(['address', 'bytes32', 'bytes32', 'bytes32', 'uint'], [ATTRACTION_HANDLER, 'createAttractionWithSign', key, salesAgentId, nonce]), function(err, res) {
            if (err) {
                console.error(err);
                return;
            }
            console.log(res);
            sign = res;
            contract.sendTransaction('', 'ProxyController', 'createAttraction', [ATTRACTION_HANDLER, key, salesAgentId, nonce, sign], PROXY_CONTROLLER_ABI, function(err, res) {
                if (err) {
                    console.error(err);
                    return;
                }
                console.log(res);
                var attractions = LOCAL_STORAGE.getAttractionsDB();
                var attraction = { key: key, name: name, datetime: datetime };
                attractions.push(attraction);
                LOCAL_STORAGE.setAttractionsDB(attractions);
                addAttractionRow(attraction, false, true);
                $('#attraction-name').val("");
                $('#attraction-datetime').val("");
                DEMO_UTIL.stopLoad();
            });
        });
    });
};
