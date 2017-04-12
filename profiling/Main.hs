module Main where

import Prelude
import Bug
import qualified Hasql.Connection as A
import qualified Hasql.Connection.Session as B
import qualified Hasql.Connection.Session.Statement as C
import qualified Hasql.Connection.Session.Statement.Decoding as D
import qualified Hasql.Connection.Session.Statement.Encoding as E
import qualified Data.Vector as F


main =
  do
    Right connection <- A.acquire "localhost" Nothing "postgres" Nothing Nothing
    Right result <- A.use connection session
    return ()


-- * Sessions
-------------------------

session :: B.Session (List (List (Int64, Int64)))
session =
  B.batch $
  replicateM 3 $
  B.statement statementWithManyRowsInRevList ()


-- * Statements
-------------------------

statementWithSingleRow :: C.Statement () (Int64, Int64)
statementWithSingleRow =
  C.statement template encoder decoder True
  where
    template =
      "SELECT 1, 2"
    encoder =
      conquer
    decoder =
      {-# SCC "statementWithSingleRow/decoder" #-} 
      C.row row
      where
        row =
          tuple <$> C.column D.int8 <*> C.column D.int8
          where
            tuple !a !b =
              (a, b)

statementWithManyRows :: (C.RowDecoder (Int64, Int64) -> C.Decoder result) -> C.Statement () result
statementWithManyRows decoder =
  C.statement template encoder ({-# SCC "statementWithManyRows/decoder" #-} decoder rowDecoder) True
  where
    template =
      "SELECT generate_series(0,10000) as a, generate_series(10000,20000) as b"
    encoder =
      conquer
    rowDecoder =
      {-# SCC "statementWithManyRows/rowDecoder" #-} 
      tuple <$> C.column D.int8 <*> C.column D.int8
      where
        tuple !a !b =
          (a, b)

statementWithManyRowsInVector :: C.Statement () (Vector (Int64, Int64))
statementWithManyRowsInVector =
  statementWithManyRows C.rowVector

statementWithManyRowsInRevList :: C.Statement () (List (Int64, Int64))
statementWithManyRowsInRevList =
  statementWithManyRows C.rowRevList

statementWithManyRowsInList :: C.Statement () (List (Int64, Int64))
statementWithManyRowsInList =
  statementWithManyRows C.rowList