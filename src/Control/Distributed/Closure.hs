-- | Serializable closures for distributed programming. This package builds
-- a "remotable closure" abstraction on top of
-- <https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/glasgow_exts.html#static-pointers static pointers>.
-- See
-- <https://ocharles.org.uk/blog/guest-posts/2014-12-23-static-pointers.html this blog post>
-- for a longer introduction.

{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE ExplicitNamespaces #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE StaticPointers #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
#if __GLASGOW_HASKELL__ >= 800
{-# LANGUAGE UndecidableSuperClasses #-}
#endif

module Control.Distributed.Closure
  ( Serializable
    -- * Closures
  , Closure
  , closure
  , unclosure
  , cpure
  , cap
  , cmap
  , cduplicate
    -- * Special closures
  , WrappedArrowClosure(..)
  , type (/->)
    -- * Closure dictionaries
    -- $static-dicts
  , Dict(..)
  , Static(..)
  ) where

import Control.Distributed.Closure.Internal
import Data.Binary (Binary)
import Data.Constraint (Dict(..))
import Data.Typeable (Typeable)

-- $static-dicts
--
-- A 'Dict' reifies a constraint in the form of a first class value. The 'Dict'
-- type is not serializable: how do you serialize the constraint that values of
-- this type carry? Whereas, for any constraint @c@, a value of type @'Closure'
-- ('Dict' c)@ /can/ be serialized and sent over the wire, just like any
-- 'Closure'. A /static dictionary/ for some constraint @c@ is a value of type
-- @'Closure' ('Dict' c)@.

-- | It's often useful to create a static dictionary on-the-fly given any
-- constraint. Morally, all type class constraints have associated static
-- dictionaries, since these are either global values or simple combinations
-- thereof. But GHC doesn't yet know how to invent a static dictionary on-demand
-- yet given any type class constraint, so we'll have to do it manually for the
-- time being. By defining instances of this type class manually, or via
-- 'Control.Distributed.Closure.TH.withStatic' if it becomes too tedious.
class c => Static c where
  closureDict :: Closure (Dict c)

instance (Static c1, Static c2, Typeable c1, Typeable c2, (c1, c2)) => Static (c1, c2) where
  closureDict = static pairDict `cap` closureDict `cap` closureDict

-- Needs to be defined at top-level for GHC <8.4 compat.
pairDict :: Dict c1 -> Dict c2 -> Dict (c1, c2)
pairDict Dict Dict = Dict

-- | A newtype-wrapper useful for defining instances of classes indexed by
-- higher-kinded types.
newtype WrappedArrowClosure a b = WrapArrowClosure
  { unwrapClosureArrow :: Closure (a -> b)
  } deriving (Binary)

infixr 0 /->
type (/->) = WrappedArrowClosure
