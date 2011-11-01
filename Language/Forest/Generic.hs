{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, ScopedTypeVariables, FlexibleContexts, FlexibleInstances #-}
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


module Language.Forest.Generic   where

import Data.Data
import Data.Generics
import Language.Pads.Generic
import Language.Forest.MetaData
import Data.Map hiding (map)
import Data.Set hiding (map)
import qualified Data.List as L

class (Data rep, ForestMD md) => Forest rep md | rep -> md  where
 load :: FilePath -> IO(rep, md)
 fdef :: rep
 fdef = myempty

class (Data rep, ForestMD md) => Forest1 arg rep md | rep -> md, rep->arg  where
 load1 :: arg -> FilePath -> IO(rep, md)
 fdef1 :: arg -> rep
 fdef1 = \s->myempty

class File rep md where
  fileLoad :: FilePath -> IO (rep, (Forest_md, md))

class File1 arg rep md where
  fileLoad1 :: arg -> FilePath -> IO (rep, (Forest_md, md))




listDirs :: (ForestMD md) => md -> [FilePath] 
listDirs md = map fullpath (listify (\(r::FileInfo) -> (kind r) `elem` [DirectoryK]) md)

listFiles :: (ForestMD md) => md -> [FilePath] 
listFiles md = map fullpath (listify (\(r::FileInfo) -> (kind r) `elem` [AsciiK, BinaryK]) md)

findFiles :: (ForestMD md) => md -> (FileInfo -> Bool) -> [FilePath]
findFiles md pred = map fullpath (listify pred md)

listNonEmptyFiles :: (ForestMD md) => md -> [FilePath] 
listNonEmptyFiles md = L.filter (\s->s/= "") (listFiles md)

listPaths :: (ForestMD md) => md -> [FilePath] 
listPaths md = map fullpath (listify (\(_::FileInfo) -> True) md)

listNonEmptyPaths :: (ForestMD md) => md -> [FilePath] 
listNonEmptyPaths md = map fullpath (listify (\(r::FileInfo) -> (fullpath r) /= "") md)

listInfoEmptyFiles :: Data.Data.Data a => a -> [FileInfo]
listInfoEmptyFiles md = listify (\(r::FileInfo) -> (fullpath r) == "") md

listInfoNonEmptyFiles :: Data.Data.Data a => a -> [FileInfo]
listInfoNonEmptyFiles md = listify (\(r::FileInfo) -> (fullpath r) /= "") md

listMDNonEmptyFiles :: Data.Data.Data a => a -> [Forest_md]
listMDNonEmptyFiles md = listify (\(r::Forest_md) -> (fullpath (fileInfo r)) /= "") md


mapInfoFiles :: Data.Data.Data a => a -> Map FilePath FileInfo
mapInfoFiles md = 
  let fileInfos = listInfoNonEmptyFiles md
      keyedInfos = map (\finfo -> (fullpath finfo, finfo)) fileInfos
  in  Data.Map.fromList keyedInfos


