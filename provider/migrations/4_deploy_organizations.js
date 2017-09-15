const Organizations = artifacts.require('./Organizations.sol');

module.exports = function(deployer, network, accounts) {
    deployer.deploy(Organizations);
}