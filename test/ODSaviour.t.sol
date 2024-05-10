// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IOracleRelayer} from '@opendollar/interfaces/IOracleRelayer.sol';
import {IDelayedOracle} from '@opendollar/interfaces/oracles/IDelayedOracle.sol';
import {IBaseOracle} from '@opendollar/interfaces/oracles/IBaseOracle.sol';
import {ODSaviour} from '../src/contracts/ODSaviour.sol';
import {ISAFESaviour} from '../src/interfaces/ISAFESaviour.sol';
import {IODSaviour} from '../src/interfaces/IODSaviour.sol';
import {SetUp} from './SetUp.sol';
import {Assertions} from '@libraries/Assertions.sol';

contract ODSaviourSetUp is SetUp {
  ODSaviour public saviour;
  address public saviourTreasury = _mockContract('saviourTreasury');
  address public protocolGovernor = _mockContract('protocolGovernor');
  address public oracleRelayer = _mockContract('oracleRelayer');
  IODSaviour.SaviourInit public saviourInit;

  function setUp() public override {
    super.setUp();
    vm.startPrank(deployer);
    bytes32[] memory _cTypes = new bytes32[](1);
    _cTypes[0] = ARB;
    address[] memory _tokens = new address[](1);
    _tokens[0] = address(collateralToken);

    saviourInit = IODSaviour.SaviourInit({
      saviourTreasury: saviourTreasury,
      protocolGovernor: protocolGovernor,
      vault721: address(vault721),
      oracleRelayer: oracleRelayer,
      collateralJoinFactory: address(collateralJoinFactory),
      cTypes: _cTypes,
      saviourTokens: _tokens,
      liquidatorReward: 0
    });

    saviour = new ODSaviour(saviourInit);

    IOracleRelayer.OracleRelayerCollateralParams memory oracleCParams = IOracleRelayer.OracleRelayerCollateralParams({
      oracle: IDelayedOracle(address(1)),
      safetyCRatio: 1.25e27,
      liquidationCRatio: 1.2e27
    });

    vm.mockCall(
      oracleRelayer, abi.encodeWithSelector(IOracleRelayer.cParams.selector, bytes32(0)), abi.encode(oracleCParams)
    );
    vm.mockCall(address(1), abi.encodeWithSelector(IBaseOracle.read.selector), abi.encode(1 ether));
    liquidationEngine.connectSAFESaviour(address(saviour));
    vm.stopPrank();
  }
}

contract UnitODSaviourDeployment is ODSaviourSetUp {
  function test_Set_LiquidationEngine() public view {
    assertEq(address(saviour.liquidationEngine()), address(liquidationEngine));
  }

  function test_Set_SaviourTreasury() public view {
    assertEq(address(saviour.saviourTreasury()), address(saviourTreasury));
  }

  function test_Set_SaviourTreasury_RevertNullAddress() public {
    saviourInit.saviourTreasury = address(0);
    vm.expectRevert(Assertions.NullAddress.selector);
    saviour = new ODSaviour(saviourInit);
  }

  function test_Set_ProtocolGovernor() public view {
    assertEq(address(saviour.protocolGovernor()), address(protocolGovernor));
  }

  function test_Set_ProtocolGovernor_RevertNullAddress() public {
    saviourInit.protocolGovernor = address(0);
    vm.expectRevert(Assertions.NullAddress.selector);
    saviour = new ODSaviour(saviourInit);
  }

  function test_Set_Vault721() public view {
    assertEq(address(saviour.vault721()), address(vault721));
  }

  function test_Set_Vault721_RevertNullAddress() public {
    saviourInit.vault721 = address(0);
    vm.expectRevert(Assertions.NullAddress.selector);
    saviour = new ODSaviour(saviourInit);
  }

  function test_Set_OracleRelayer() public view {
    assertEq(address(saviour.oracleRelayer()), address(oracleRelayer));
  }

  function test_Set_OracleRelayer_RevertNullAddress() public {
    saviourInit.oracleRelayer = address(0);
    vm.expectRevert(Assertions.NullAddress.selector);
    saviour = new ODSaviour(saviourInit);
  }

  function test_Set_SafeManager() public view {
    assertEq(address(saviour.safeManager()), address(safeManager));
  }

  function test_Set_SafeEngine() public view {
    assertEq(address(saviour.safeEngine()), address(safeEngine));
  }

  function test_Set_CollateralJoinFactory() public view {
    assertEq(address(saviour.collateralJoinFactory()), address(collateralJoinFactory));
  }

  function test_Set_CollateralJoinFactory_RevertNullAddress() public {
    saviourInit.collateralJoinFactory = address(0);
    vm.expectRevert(Assertions.NullAddress.selector);
    saviour = new ODSaviour(saviourInit);
  }

  function test_Set_LiquidatorReward() public view {
    assertEq(saviour.liquidatorReward(), 0);
  }

  function test_Set_SaviourTokens() public view {
    assertEq(saviour.cType(ARB), address(collateralToken));
  }

  function test_Set_SaviourTokens_Revert_LengthMismatch() public {
    bytes32[] memory _mismatchTypes = new bytes32[](2);
    saviourInit.cTypes = _mismatchTypes;
    vm.expectRevert(IODSaviour.LengthMismatch.selector);
    saviour = new ODSaviour(saviourInit);
  }

  function test_Set_SaviourTokens_Revert_NullAddress() public {
    address[] memory _nullToken = new address[](1);
    _nullToken[0] = address(0);

    saviourInit.saviourTokens = _nullToken;
    vm.expectRevert(Assertions.NullAddress.selector);
    saviour = new ODSaviour(saviourInit);
  }
}
