module Main ( main ) where

import Test.Framework ( defaultMain, testGroup, Test )
-- import Test.Framework.Providers.HUnit
import Test.Framework.Providers.QuickCheck2 ( testProperty )
-- import Test.HUnit hiding ( Test, test)
import Test.QuickCheck

import Control.Monad ( replicateM )
import qualified Data.Foldable as F
import Data.Maybe ( isNothing )
import qualified Data.Set as S

import qualified Data.Graph.Inductive as FGL
import qualified Data.Graph.Haggle as HGL
import qualified Data.Graph.Haggle.VertexLabelAdapter as HGL
import qualified Data.Graph.Haggle.SimpleBiDigraph as HGL

-- import Debug.Trace
-- debug = flip trace

type BaseGraph = FGL.Gr Int ()
type TestGraph = HGL.VertexLabeledGraph HGL.SimpleBiDigraph Int

data GraphPair = GP [(Int, Int)] BaseGraph TestGraph

instance Arbitrary GraphPair where
  arbitrary = sized mkGraphPair

instance Show GraphPair where
  show (GP es _ _) = show es

newtype NodeId = NID Int
  deriving (Show)
instance Arbitrary NodeId where
  arbitrary = sized mkNodeId
    where
      mkNodeId n = do
        i <- choose (0, n)
        return (NID i)

mkGraphPair :: Int -> Gen GraphPair
mkGraphPair sz = do
  nEdges <- choose (2, 2 * sz)
  srcs <- replicateM nEdges (choose (0, sz))
  dsts <- replicateM nEdges (choose (0, sz))
  let edges = unique $ zip srcs dsts
      nids = unique (srcs ++ dsts)
      ns = zip nids nids
      bg = FGL.mkGraph ns (map (\(s, d) -> (s, d, ())) edges)
      tg = HGL.fromEdgeList HGL.newMSimpleBiDigraph edges
  return $! GP edges bg tg

main :: IO ()
main = defaultMain tests

tests :: [Test]
tests = [ testProperty "prop_sameVertexCount" prop_sameVertexCount
        , testProperty "prop_sameEdgeCount" prop_sameEdgeCount
        , testProperty "prop_sameSuccessorsAtLabel" prop_sameSuccessorsAtLabel
        , testProperty "prop_samePredecessorsAtLabel" prop_samePredecessorsAtLabel
        ]

prop_sameVertexCount :: GraphPair -> Bool
prop_sameVertexCount (GP _ bg tg) =
  length (FGL.nodes bg) == length (HGL.vertices tg)

prop_sameEdgeCount :: GraphPair -> Bool
prop_sameEdgeCount (GP _ bg tg) =
  length (FGL.edges bg) == length (HGL.edges tg)

prop_sameSuccessorsAtLabel :: (NodeId, GraphPair) -> Bool
prop_sameSuccessorsAtLabel (NID nid, GP _ bg tg)
  | not (FGL.gelem nid bg) && isNothing (vertexFromLabel tg nid) = True
  | otherwise = bss == tss
  where
    bss = S.fromList $ fmap Just $ FGL.suc bg nid
    ts = maybe [] (map (HGL.vertexLabel tg) . HGL.successors tg) (vertexFromLabel tg nid)
    tss = S.fromList ts

prop_samePredecessorsAtLabel :: (NodeId, GraphPair) -> Bool
prop_samePredecessorsAtLabel (NID nid, GP _ bg tg)
  | not (FGL.gelem nid bg) && isNothing (vertexFromLabel tg nid) = True
  | otherwise = bss == tss
  where
    bss = S.fromList $ fmap Just $ FGL.pre bg nid
    ts = maybe [] (map (HGL.vertexLabel tg) . HGL.predecessors tg) (vertexFromLabel tg nid)
    tss = S.fromList ts

-- Helpers

vertexFromLabel :: TestGraph -> Int -> Maybe HGL.Vertex
vertexFromLabel g lbl = F.find labelMatch (HGL.vertices g)
  where
    labelMatch v = Just lbl == (HGL.vertexLabel g v)

unique :: (Ord a) => [a] -> [a]
unique = S.toList . S.fromList
