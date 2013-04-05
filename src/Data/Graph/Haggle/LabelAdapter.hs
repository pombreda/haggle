module Data.Graph.Haggle.LabelAdapter (
  -- * Types
  LabeledMGraph,
  LabeledGraph,
  -- * Mutable Graph API
  newLabeledGraph,
  newSizedLabeledGraph,
  addLabeledVertex,
  addLabeledEdge,
  getVertexLabel,
  getEdgeLabel,
  getSuccessors,
  getOutEdges,
  countVertices,
  countEdges,
  getPredecessors,
  getInEdges,
  freeze,
  -- * Immutable Graph API
  edgeLabel,
  vertexLabel,
  fromEdgeList,
  ) where

import Data.Graph.Haggle.Internal.Adapter
