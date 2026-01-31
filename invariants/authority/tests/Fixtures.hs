module Fixtures
  ( identValid
  , identInvalid
  , identUnknown
  , identCross
  , traceMinimal
  ) where

import AuthorityProjection

identValid :: Identity
identValid = Identity "valid"

identInvalid :: Identity
identInvalid = Identity ""

identUnknown :: Identity
identUnknown = Identity "unknown"

identCross :: Identity
identCross = Identity "cross"

traceMinimal :: Trace
traceMinimal = Trace "trace"
