module FindBundled (findBundled, reportBundled, Bundles) where

import Control.Monad.RWS.Strict hiding (liftIO)
import Data.Maybe
import qualified Data.Map.Strict as M
import qualified Data.IntMap as I
import qualified Data.Set as S
import Environment (SortData(..))
import MMTypes
import Util

type Bundles = M.Map [Int] Int

bundle :: (Ord a) => [a] -> [Int]
bundle = go M.empty 0 where
  go m _ [] = []
  go m n (a:as) = case m M.!? a of
    Just i -> i : go m n as
    Nothing -> n : go (M.insert a n m) (n+1) as

type BundledReport = S.Set ((Label, Maybe [Int]), (Label, [Int]))
type FindBundledM = RWS () BundledReport (M.Map Label Bundles)

findBundled :: MMDatabase -> M.Map Label Bundles
findBundled db = fst $ execRWS (findBundled' db False) () M.empty

reportBundled :: MMDatabase -> M.Map Label Bundles -> BundledReport
reportBundled db m = snd $ execRWS (findBundled' db True) () m

findBundled' :: MMDatabase -> Bool -> FindBundledM ()
findBundled' db strict = mapM_ checkDecl (mDecls db) where
  pureArgs :: M.Map Label [Int]
  pureArgs = M.mapMaybe f (mStmts db) where
    f (Thm (hs, _) _ _ _) =
      case go hs 0 of { [] -> Nothing; l -> Just l } where
      go [] _ = []
      go ((b, _):ls) n = if b then n : go ls (n+1) else go ls (n+1)
    f _ = Nothing

  checkDecl :: Decl -> FindBundledM ()
  checkDecl (Stmt s) = case mStmts db M.! s of
    Thm fr _ _ (Just (_, p)) -> checkProof (s, Nothing) 0 (allDistinct fr) p
    _ -> return ()
  checkDecl _ = return ()

  allDistinct :: Frame -> I.IntMap Int
  allDistinct (hs, _) = go hs 0 0 I.empty where
    go [] _ _ m = m
    go ((True, _):ls) k i m = go ls (k+1) (i+1) (I.insert k i m)
    go ((False, _):ls) k i m = go ls (k+1) i m

  checkProof :: (Label, Maybe [Int]) -> Int -> I.IntMap Int -> Proof -> FindBundledM ()
  checkProof x k m = go where
    go (PSave p) = go p
    go (PThm t ps) = do
      mapM_ go ps
      mapM_ (\l ->
        let l' = (\n -> case ps !! n of
              PHyp _ i -> Left (m I.! i)
              PDummy i -> Right i) <$> l in
        unless (allUnique l') $ do
          let b = bundle l'
          m <- M.findWithDefault M.empty t <$> get
          if not strict || M.member b m then do
              modify $ M.insert t (M.alter (Just . maybe k (min k)) b m)
              case mStmts db M.! t of
                Thm fr _ _ (Just (_, p)) -> checkProof (t, Just b) (k+1) (I.fromList (zip l b)) p
                _ -> return ()
          else tell $ S.singleton (x, (t, b))
        ) (pureArgs M.!? t)
    go _ = return ()
