-- Capability: Authority-Projection
-- Authority: tetragrammatron-os
-- Justification: ../INVARIANT.md
-- Inputs: stdin trace payload + ID_PREFIX env
-- Outputs: passthrough trace if valid
-- Trace: yes

module Main where

import System.Environment (getEnv)
import System.IO (hGetContents, stdin, hPutStrLn, stderr)
import System.Exit (exitFailure)
import AuthorityProjection (Identity(..), Trace(..), validateAuthority, AuthorityViolation(..))

main :: IO ()
main = do
  prefix <- getEnv "ID_PREFIX"
  input <- hGetContents stdin
  case validateAuthority (Identity prefix) (Trace input) of
    Left v -> do
      hPutStrLn stderr ("HALT: " ++ show v)
      exitFailure
    Right _ -> putStr input
