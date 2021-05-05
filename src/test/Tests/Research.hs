module Tests.Research (researchTests) where

import Test.Tasty (TestTree, testGroup)

import Common (testContract, testContractV, testContract', solved)
import Echidna.Solidity (solcV)

researchTests :: TestTree
researchTests = testGroup "Research-based Integration Testing"
  [ testContract "research/harvey_foo.sol" Nothing
      [ ("echidna_assert failed",     solved "echidna_assert") ]
  , testContract "research/harvey_baz.sol" Nothing
      [ ("echidna_all_states failed", solved "echidna_all_states") ]
  , testContractV "research/ilf_crowdsale.sol" (Just (\v -> v >= solcV (0,5,0) && v < solcV (0,6,0))) (Just "research/ilf_crowdsale.yaml")
      [ ("echidna_assert failed", solved "ASSERTION withdraw") ]
  , testContract' "research/solcfuzz_funwithnumbers.sol" (Just "VerifyFunWithNumbers") (Just (< solcV (0,6,0))) (Just "research/solcfuzz_funwithnumbers.yaml") True
      [ ("echidna_assert failed", solved "ASSERTION sellTokens"),
        ("echidna_assert failed", solved "ASSERTION buyTokens")
      ]
  ]
