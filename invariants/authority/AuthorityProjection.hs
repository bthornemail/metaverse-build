-- Capability: Authority-Projection
-- Authority: tetragrammatron-os
-- Justification: ../INVARIANT.md
-- Inputs: Identity, Trace
-- Outputs: ValidatedTrace or AuthorityViolation
-- Trace: yes

module AuthorityProjection
  ( AuthorityViolation(..)
  , Identity(..)
  , Trace(..)
  , ValidatedTrace
  , validateAuthority
  ) where

-- Opaque identity and trace wrappers (no constructors exported for ValidatedTrace)
newtype Identity = Identity { identityPrefix :: String }
  deriving (Eq, Show)

newtype Trace = Trace { tracePayload :: String }
  deriving (Eq, Show)

newtype ValidatedTrace = ValidatedTrace Trace

-- Minimal violation set (expand later)
data AuthorityViolation
  = InvalidSchemaPrefix
  | UnknownAuthority
  | CrossDomainEscalation
  deriving (Eq, Show)

-- Pure, total, lazy authority gate
validateAuthority
  :: Identity
  -> Trace
  -> Either AuthorityViolation ValidatedTrace
validateAuthority ident tr
  | not (schemaPrefixValid p) = Left InvalidSchemaPrefix
  | p == "unknown" = Left UnknownAuthority
  | p == "cross" = Left CrossDomainEscalation
  | otherwise = Right (ValidatedTrace tr)
  where
    p = identityPrefix ident

-- Placeholder semantic check: replace with real schema rule set later
schemaPrefixValid :: String -> Bool
schemaPrefixValid p = not (null p)
