module Main where

import AuthorityProjection
import Fixtures

assert :: String -> Bool -> IO ()
assert name ok =
  putStrLn $ (if ok then "PASS " else "FAIL ") ++ name

assertEq :: (Eq a, Show a) => String -> a -> a -> IO ()
assertEq name expected actual =
  assert (name ++ " expected=" ++ show expected ++ " actual=" ++ show actual)
         (expected == actual)

main :: IO ()
main = do
  assertEq "Invalid schema prefix" (Left InvalidSchemaPrefix)
    (validateAuthority identInvalid traceMinimal)

  assertEq "Unknown authority" (Left UnknownAuthority)
    (validateAuthority identUnknown traceMinimal)

  assertEq "Cross-domain escalation" (Left CrossDomainEscalation)
    (validateAuthority identCross traceMinimal)

  case validateAuthority identValid traceMinimal of
    Left v  -> assert "Happy path" False
    Right _ -> assert "Happy path" True
