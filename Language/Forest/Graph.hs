{-# LANGUAGE ScopedTypeVariables #-}
{-
** *********************************************************************
*                                                                      *
*              This software is part of the pads package               *
*           Copyright (c) 2005-2011 AT&T Knowledge Ventures            *
*                      and is licensed under the                       *
*                        Common Public License                         *
*                      by AT&T Knowledge Ventures                      *
*                                                                      *
*                A copy of the License is available at                 *
*                    www.padsproj.org/License.html                     *
*                                                                      *
*  This program contains certain software code or other information    *
*  ("AT&T Software") proprietary to AT&T Corp. ("AT&T").  The AT&T     *
*  Software is provided to you "AS IS". YOU ASSUME TOTAL RESPONSIBILITY*
*  AND RISK FOR USE OF THE AT&T SOFTWARE. AT&T DOES NOT MAKE, AND      *
*  EXPRESSLY DISCLAIMS, ANY EXPRESS OR IMPLIED WARRANTIES OF ANY KIND  *
*  WHATSOEVER, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF*
*  MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE, WARRANTIES OF  *
*  TITLE OR NON-INFRINGEMENT.  (c) AT&T Corp.  All rights              *
*  reserved.  AT&T is a registered trademark of AT&T Corp.             *
*                                                                      *
*                   Network Services Research Center                   *
*                          AT&T Labs Research                          *
*                           Florham Park NJ                            *
*                                                                      *
*              Kathleen Fisher <kfisher@research.att.com>              *
*                                                                      *
************************************************************************
-}

module Language.Forest.Graph where

import Language.Forest.Forestc
import Data.Graph.Inductive.Graph
import qualified Data.Graph.Inductive.PatriciaTree as MG
import Data.GraphViz
import System.FilePath.Posix
import Data.Map 
import Data.List

type NodeTy = Forest_md
type EdgeLabel = ()

type ForestGraphParams = GraphvizParams NodeTy EdgeLabel () NodeTy
defaultGraphVizParams :: ForestGraphParams  = Params
  { isDirected = True
  , globalAttributes = [GraphAttrs [Ordering "out", RankDir FromLeft]]
  , clusterBy = N
  , clusterID = const Nothing
  , fmtCluster = const []
  , fmtNode =  displayNodes
  , fmtEdge =  const []
  }

displayNodes :: LNode Forest_md -> Attributes
displayNodes (n,fmd) = 
  let fInfo = fileInfo fmd
      full = fullpath fInfo
      name = takeFileName full
      shape = case kind fInfo of 
               DirectoryK -> [Shape BoxShape]
               BinaryK  -> [PenWidth 2.0]
               AsciiK   -> []
               otherwise -> []
      symLink = if isSymLink fInfo
                 then [Style [SItem Dashed []]]
                 else []
      color = if numErrors fmd > 0
                then [Color[myred]]
                else []
  in [FontName "Courier", mkLabel name] ++ color ++ shape ++ symLink

mdToPDF :: ForestMD md => md -> FilePath -> IO(Maybe String)
mdToPDF md filePath = mdToPDFWithParams defaultGraphVizParams md filePath 

mdToPDFWithParams :: ForestMD md => ForestGraphParams -> md -> FilePath -> IO(Maybe String)
mdToPDFWithParams params md filePath = do
  { let dg = toDotGraphWithParams params md
  ; result <- runGraphviz dg Pdf filePath
  ; case result of 
      Left s -> return (Just s)
      Right fp -> return Nothing
  }

toDotGraph md = toDotGraphWithParams defaultGraphVizParams md 

toDotGraphWithParams params md = let
  (nodes,edges) = getNodesAndEdgesMD md
  g = myMkGraph nodes edges
  dg = graphToDot params g
  in dg

getNodesAndEdgesMD md = 
  let allpaths = Data.List.nub(listMDNonEmptyFiles md)
      fileNames = Prelude.map (fullpath . fileInfo) allpaths
      idMap = Data.Map.fromList (zip fileNames [0..])
  in getNodesAndEdges idMap allpaths ([], [])

getNodesAndEdges idMap []        (nodes, edges) = (nodes, edges)
getNodesAndEdges idMap (finfo:finfos) (nodes, edges) = 
   let f = fullpath(fileInfo finfo)
       f_id = idMap ! f
       node = (f_id,finfo)
       parent = takeDirectory f
       new_edges = case Data.Map.lookup parent idMap of
                    Just parent_id -> [(parent_id, f_id, ())]
                    Nothing -> []
   in getNodesAndEdges idMap finfos (node:nodes, new_edges++edges)

myMkGraph :: [LNode NodeTy] -> [LEdge EdgeLabel] -> MG.Gr NodeTy EdgeLabel
myMkGraph = mkGraph

mkLabel s = Label (StrLabel s)
myred = X11Color Red
