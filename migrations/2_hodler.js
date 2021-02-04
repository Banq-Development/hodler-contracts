const HodlerFactory = artifacts.require("HodlerFactory");

module.exports = function (deployer) {
  deployer.deploy(HodlerFactory);
};
