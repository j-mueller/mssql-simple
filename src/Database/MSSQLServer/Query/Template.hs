{-# OPTIONS_HADDOCK hide #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE TemplateHaskell #-}

module Database.MSSQLServer.Query.Template ( rowTupleQ
                                           , resultSetTupleQ
                                           , rpcResponseSetTupleQ
                                           , rpcOutputSetTupleQ
                                           , rpcResultSetTupleQ
                                           , rpcQuerySetTupleQ
                                           , rpcParamSetTupleQ
                                           ) where

import Data.Monoid((<>))
import Database.Tds.Message
import Language.Haskell.TH
import Data.List (foldl')



rowTupleQ :: Int -> Q Dec
rowTupleQ n = return $ rowTuple n

rowTuple :: Int -> Dec
rowTuple n =
#if MIN_VERSION_template_haskell(2,11,0)
  InstanceD Nothing
#else
  InstanceD
#endif
#if MIN_VERSION_template_haskell(2,10,0)
  (map (\i ->AppT (ConT ''Data) (VarT (mkName $ "a" <> show i))) [1..n])
#else
  (map (\i ->ClassP ''Data [(VarT (mkName $ "a" <> show i))]) [1..n])
#endif
  (AppT (ConT (mkName "Row")) (foldl' (\x i -> AppT x (VarT (mkName ("a" <> show i)))) (TupleT n) [1..n]))
  [FunD (mkName "fromListOfRawBytes")
    [ Clause
      [ ListP (map (\i ->VarP (mkName $ "m" <> show i)) [1..n])
      , ListP (map (\i ->VarP (mkName $ "b" <> show i)) [1..n])
      ]
#if MIN_VERSION_template_haskell(2,16,0)
      (NormalB (TupE (map (\i ->Just $ VarE (mkName $ "d" <> show i)) [1..n]) ))
#else
      (NormalB (TupE (map (\i ->VarE (mkName $ "d" <> show i)) [1..n]) ))
#endif
      (map d [1..n])
    , Clause [WildP,WildP] (NormalB (AppE
                                      (VarE 'error)
                                      (LitE (StringL ("fromListOfRawBytes: List length must be " <> show n)))
                                    )
                           ) []
    ]
  ]
  where
    d :: Int -> Dec
    d i = ValD (BangP (VarP (mkName $ "d" <> show i)))
      (NormalB (AppE
                 (AppE (VarE 'fromRawBytes)
                   (AppE (VarE (mkName "mcdTypeInfo")) (VarE (mkName $ "m" <> show i)))
                 )
                 (VarE (mkName $ "b" <> show i))
               )
      ) []



resultSetTupleQ :: Int -> Q Dec
resultSetTupleQ n = return $ resultSetTuple n

resultSetTuple :: Int -> Dec
resultSetTuple n =
#if MIN_VERSION_template_haskell(2,11,0)
  InstanceD Nothing
#else
  InstanceD
#endif
#if MIN_VERSION_template_haskell(2,10,0)
  (map (\i->AppT (ConT (mkName "Result")) (VarT (mkName $ "a" <> (show i)))) [1..n])
#else
  (map (\i ->ClassP (mkName "Result") [(VarT (mkName $ "a" <> show i))]) [1..n])
#endif
  (AppT (ConT (mkName "ResultSet")) (foldl' (\x i -> AppT x (VarT (mkName ("a" <> show i)))) (TupleT n) [1..n]))
  [ValD (VarP (mkName "resultSetParser"))
    (NormalB (DoE
#if MIN_VERSION_template_haskell(2,17,0)
               Nothing
#endif
               (
                 (flip map [1..n] $ \i ->
                     BindS
                     (BangP (VarP (mkName $ "r" <> show i )))
                     (SigE
                      (AppE (VarE (mkName "resultParser")) (if i==n then (ConE 'True) else (ConE 'False)) )
                      (ForallT
#if MIN_VERSION_template_haskell(2,17,0)
                        [PlainTV (mkName $ "a" <> show i) SpecifiedSpec]
#else
                        [PlainTV (mkName $ "a" <> show i)]
#endif
#if MIN_VERSION_template_haskell(2,10,0)
                        [AppT (ConT (mkName "Result")) (VarT (mkName $ "a" <> show i))]
#else
                        [ClassP (mkName "Result") [VarT (mkName $ "a" <> show i)]]
#endif
                        (AppT (ConT (mkName "Parser'")) (VarT (mkName $ "a" <> show i)))
                      )
                     )
                 )
                 <>
#if MIN_VERSION_template_haskell(2,16,0)
                 [(NoBindS (AppE (VarE 'return) (TupE (map (\i->Just $ VarE (mkName $ "r" <> show i)) [1..n]) )) )]
#else
                 [(NoBindS (AppE (VarE 'return) (TupE (map (\i->VarE (mkName $ "r" <> show i)) [1..n]) )) )]
#endif
               )
             )
    ) []
  ]



rpcResponseSetTupleQ :: Int -> Q Dec
rpcResponseSetTupleQ n = return $ rpcResponseSetTuple n

rpcResponseSetTuple :: Int -> Dec
rpcResponseSetTuple n =
#if MIN_VERSION_template_haskell(2,11,0)
  InstanceD Nothing
#else
  InstanceD
#endif
#if MIN_VERSION_template_haskell(2,10,0)
  (concatMap (\i->[AppT (ConT (mkName "RpcOutputSet")) (VarT (mkName $ "a" <> show i))
                  ,AppT (ConT (mkName "RpcResultSet")) (VarT (mkName $ "b" <> show i))
                  ]) [1..n])
#else
  (concatMap (\i->[ClassP (mkName "RpcOutputSet") [(VarT (mkName $ "a" <> show i))]
                  ,ClassP (mkName "RpcResultSet") [(VarT (mkName $ "b" <> show i))]
                  ]) [1..n])
#endif
  (AppT (ConT (mkName "RpcResponseSet"))
   (foldl' (\x i -> AppT x (AppT (AppT (ConT (mkName "RpcResponse")) (VarT (mkName ("a" <> show i)))) (VarT (mkName ("b" <> show i)) )) ) (TupleT n) [1..n]))
  [ValD (VarP (mkName "rpcResponseSetParser"))
    (NormalB (DoE
#if MIN_VERSION_template_haskell(2,17,0)
               Nothing
#endif
               (
                 (flip map [1..n] $ \i ->
                     BindS
                     (BangP (VarP (mkName $ "r" <> show i )))
                     (AppE (VarE (mkName "rpcResponseParser")) (if i==n then (ConE 'True) else (ConE 'False)))
                 )
                 <>
#if MIN_VERSION_template_haskell(2,16,0)
                 [(NoBindS (AppE (VarE 'return) (TupE (map (\i->Just $ VarE (mkName $ "r" <> show i)) [1..n]) )) )]
#else
                 [(NoBindS (AppE (VarE 'return) (TupE (map (\i->VarE (mkName $ "r" <> show i)) [1..n]) )) )]
#endif
               )
             )
    ) []
  ]



rpcOutputSetTupleQ :: Int -> Q Dec
rpcOutputSetTupleQ n = return $ rpcOutputSetTuple n

rpcOutputSetTuple :: Int -> Dec
rpcOutputSetTuple n =
#if MIN_VERSION_template_haskell(2,11,0)
  InstanceD Nothing
#else
  InstanceD
#endif
#if MIN_VERSION_template_haskell(2,10,0)
  (map (\i ->AppT (ConT ''Data) (VarT (mkName $ "a" <> show i))) [1..n])
#else
  (map (\i ->ClassP ''Data [(VarT (mkName $ "a" <> show i))]) [1..n])
#endif
  (AppT
    (ConT (mkName "RpcOutputSet"))
    (foldl' (\x i -> AppT x (VarT (mkName ("a" <> show i)))) (TupleT n) [1..n])
  )
  [FunD (mkName "fromReturnValues")
   [Clause
     [ListP (map (\i ->VarP (mkName $ "r" <> show i)) [1..n])]
#if MIN_VERSION_template_haskell(2,16,0)
     (NormalB (TupE (map (\i ->Just $ VarE (mkName $ "d" <> show i)) [1..n])))
#else
     (NormalB (TupE (map (\i ->VarE (mkName $ "d" <> show i)) [1..n])))
#endif

     (map (\i->ValD (BangP (VarP (mkName $ "d" <> show i)))
               (NormalB (AppE
                         (AppE
                           (VarE (mkName "fromRawBytes"))
                           (AppE (VarE (mkName "rvTypeInfo")) (VarE (mkName $ "r" <> show i)))
                         )
                         (AppE (VarE (mkName "rvRawBytes")) (VarE (mkName $ "r" <> show i))))
               ) []
          ) [1..n]
     )
   ,Clause [WildP] (NormalB (AppE (VarE 'error) (LitE (StringL $ "fromReturnValues: List length must be " <> show n)))) []
   ]
  ]



rpcResultSetTupleQ :: Int -> Q Dec
rpcResultSetTupleQ n = return $ rpcResultSetTuple n

rpcResultSetTuple :: Int -> Dec
rpcResultSetTuple n =
#if MIN_VERSION_template_haskell(2,11,0)
  InstanceD Nothing
#else
  InstanceD
#endif
#if MIN_VERSION_template_haskell(2,10,0)
  (map (\i->AppT (ConT (mkName "RpcResult")) (VarT (mkName $ "a" <> (show i)))) [1..n])
#else
  (map (\i ->ClassP (mkName "RpcResult") [(VarT (mkName $ "a" <> show i))]) [1..n])
#endif
  (AppT (ConT (mkName "RpcResultSet")) (foldl' (\x i -> AppT x (VarT (mkName ("a" <> show i)))) (TupleT n) [1..n]))
  [ValD (VarP (mkName "rpcResultSetParser"))
    (NormalB (DoE
#if MIN_VERSION_template_haskell(2,17,0)
               Nothing
#endif
               (
                 (flip map [1..n] $ \i ->
                     BindS
                     (BangP (VarP (mkName $ "r" <> show i )))
                     (SigE (VarE (mkName "rpcResultParser"))
                      (ForallT
#if MIN_VERSION_template_haskell(2,17,0)
                        [PlainTV (mkName $ "a" <> show i) SpecifiedSpec]
#else
                        [PlainTV (mkName $ "a" <> show i)]
#endif
#if MIN_VERSION_template_haskell(2,10,0)
                        [AppT (ConT (mkName "RpcResult")) (VarT (mkName $ "a" <> show i))]
#else
                        [ClassP (mkName "RpcResult") [VarT (mkName $ "a" <> show i)]]
#endif
                        (AppT (ConT (mkName "Parser'")) (VarT (mkName $ "a" <> show i)))
                      )
                     )
                 )
                 <>
#if MIN_VERSION_template_haskell(2,16,0)
                 [(NoBindS (AppE (VarE 'return) (TupE (map (\i->Just $ VarE (mkName $ "r" <> show i)) [1..n]) )) )]
#else
                 [(NoBindS (AppE (VarE 'return) (TupE (map (\i->VarE (mkName $ "r" <> show i)) [1..n]) )) )]
#endif
               )
             )
    ) []
  ]



rpcQuerySetTupleQ :: Int -> Q Dec
rpcQuerySetTupleQ n = return $ rpcQuerySetTuple n

rpcQuerySetTuple :: Int -> Dec
rpcQuerySetTuple n =
#if MIN_VERSION_template_haskell(2,11,0)
  InstanceD Nothing
#else
  InstanceD
#endif
#if MIN_VERSION_template_haskell(2,10,0)
  (concatMap (\i->[AppT (ConT (mkName "RpcQueryId")) (VarT (mkName $ "a" <> show i))
                  ,AppT (ConT (mkName "RpcParamSet")) (VarT (mkName $ "b" <> show i))
                  ]) [1..n])
#else
  (concatMap (\i->[ClassP (mkName "RpcQueryId") [(VarT (mkName $ "a" <> show i))]
                  ,ClassP (mkName "RpcParamSet") [(VarT (mkName $ "b" <> show i))]
                  ]) [1..n])
#endif
  (AppT (ConT (mkName "RpcQuerySet"))
    (foldl' (\x i -> AppT x (AppT (AppT (ConT (mkName "RpcQuery")) (VarT (mkName ("a" <> show i)))) (VarT (mkName ("b" <> show i)) )) ) (TupleT n) [1..n]))
  [FunD (mkName "toRpcRequest")
   [Clause
    [TupP
     (map (\i->ConP (mkName "RpcQuery") [VarP (mkName $ "a" <> show i),VarP (mkName $ "b" <> show i)]) [1..n])
    ]
    (NormalB (AppE
               (ConE (mkName "RpcRequest"))
               (ListE (map (\i->VarE (mkName $ "r" <> show i)) [1..n]))))
    (map (\i->ValD (BangP (VarP (mkName $ "r" <> show i)))
           (NormalB (AppE (AppE (VarE (mkName "toRpcReqBatch"))
                            (VarE (mkName $ "a" <> show i))) (VarE (mkName $ "b" <> show i)))) []) [1..n])
   ]
  ]



rpcParamSetTupleQ :: Int -> Q Dec
rpcParamSetTupleQ n = return $ rpcParamSetTuple n

rpcParamSetTuple :: Int -> Dec
rpcParamSetTuple n =
#if MIN_VERSION_template_haskell(2,11,0)
  InstanceD Nothing
#else
  InstanceD
#endif
#if MIN_VERSION_template_haskell(2,10,0)
  (map (\i ->AppT (ConT ''Data) (VarT (mkName $ "a" <> show i))) [1..n])
#else
  (map (\i ->ClassP ''Data [(VarT (mkName $ "a" <> show i))]) [1..n])
#endif
  (AppT (ConT (mkName "RpcParamSet")) (foldl' (\x i -> AppT x (AppT (ConT (mkName "RpcParam")) (VarT (mkName ("a" <> show i))) ) ) (TupleT n) [1..n]))
  [FunD (mkName "toRpcReqBatchParams")
   [Clause
    [TupP (map (\i->VarP (mkName $ "d" <> show i)) [1..n])]
    (NormalB (ListE (map (\i ->VarE (mkName $ "p" <> show i)) [1..n]) ))
    (map (\i->ValD (BangP (VarP (mkName $ "p" <> show i)))
              (NormalB (AppE (VarE (mkName "rpcReqBatchParam")) (VarE (mkName $ "d" <> show i)))) []) [1..n])
   ]
  ]



