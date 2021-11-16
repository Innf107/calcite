module Calcite.Driver where

import Calcite.Prelude
import Calcite.Types.AST

import Calcite.Lexer
import Calcite.Parser
import Calcite.Rename
import Calcite.Typecheck
import Calcite.Codegen

import Text.Parsec (parse, ParseError)

import Language.McFunction.Types

data CompilerError = LexicalError LexicalError
                   | ParseError ParseError
                   | RenameError RenameError
                   | TypeError TypeError
                   deriving (Show,Eq)    

lexAndParse :: Members '[Error CompilerError] r => Text -> Sem r [Decl 'Parsed]
lexAndParse code = do
    tokens <- mapError LexicalError $ lex code
    mapError ParseError $ fromEither $ parse module_ "" tokens

compileToRename :: Members '[Error CompilerError] r => Text -> Sem r [Decl 'Renamed]
compileToRename code = do
    ast <- lexAndParse code
    mapError RenameError $ rename (RenamerState mempty) ast
    
compileToTypecheck :: Members '[Error CompilerError] r => Text -> Sem r [Decl 'Typed]
compileToTypecheck code = do
    ast <- compileToRename code
    mapError TypeError $ evalState (TCState mempty) $ typecheck ast
    
compileToCodegen :: Members '[Error CompilerError] r => Text -> Sem r [CompiledModule]
compileToCodegen code = do
    ast <- compileToTypecheck code
    compile ast
