const AttractionHandler = artifacts.require('./AttractionHandler.sol'),
    Organizations = artifacts.require('./Organizations.sol');

module.exports = function(deployer, network, accounts) {
    deployer.deploy(AttractionHandler, Organizations.address);
}