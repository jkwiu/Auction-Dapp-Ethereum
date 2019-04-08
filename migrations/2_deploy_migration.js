const PictureAuction = artifacts.require("./PictureAuction.sol");

module.exports = function(deployer) {
  deployer.deploy(PictureAuction);
};
