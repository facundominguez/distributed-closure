{-# LANGUAGE StaticPointers #-}
{-# LANGUAGE TemplateHaskell #-}

-- | Utility Template Haskell macros.

module Control.Distributed.Closure.TH where

import           Control.Monad (replicateM)
import           Control.Distributed.Closure.Internal
import           Data.Constraint (Dict(..))
import qualified Language.Haskell.TH as TH
import           Numeric.Natural

-- | Abbreviation for @closure (static Dict)@. Example usage:
--
-- @
-- foo :: Closure (Dict (Num a)) -> ...
--
-- foo $cdict ...
-- @
cdict :: TH.ExpQ
cdict = cdictFrom 0

-- | Create a static dictionary from the given dictionaries. Example usage:
--
-- @
-- $cdictFrom 2 Dict Dict :: Closure (Static (Dict (Eq a, Show a)))
-- @
cdictFrom :: Natural -> TH.ExpQ
cdictFrom n0 = apply abstract [| closure (static $(staticFun n0)) |] n0
  where
    staticFun 0 = [| Dict |]
    staticFun n = [| \Dict -> $(staticFun (n - 1)) |]
    apply k f n = do
        names <- replicateM (fromIntegral n) (TH.newName "x")
        k names (foldl (\acc x -> [| $acc `cap` $(TH.varE x) |]) f names)
    abstract [] expr = expr
    abstract (nm:names) expr = [| \ $(TH.varP nm) -> $(abstract names expr) |]
