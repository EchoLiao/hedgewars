module PascalParser where

import Text.Parsec.Expr
import Text.Parsec.Char
import Text.Parsec.Token
import Text.Parsec.Language
import Text.Parsec.Prim
import Text.Parsec.Combinator
import Text.Parsec.String
import Control.Monad
import Data.Char

data PascalUnit =
    Program Identifier Implementation
    | Unit Identifier Interface Implementation (Maybe Initialize) (Maybe Finalize)
    deriving Show
data Interface = Interface Uses TypesAndVars
    deriving Show
data Implementation = Implementation Uses TypesAndVars
    deriving Show
data Identifier = Identifier String
    deriving Show
data TypesAndVars = TypesAndVars [TypeVarDeclaration]
    deriving Show
data TypeVarDeclaration = TypeDeclaration Identifier TypeDecl
    | VarDeclaration Bool ([Identifier], TypeDecl) (Maybe InitExpression)
    | FunctionDeclaration Identifier TypeDecl (Maybe Phrase)
    deriving Show
data TypeDecl = SimpleType Identifier
    | RangeType Range
    | Sequence [Identifier]
    | ArrayDecl Range TypeDecl
    | RecordType [TypeVarDeclaration]
    | PointerTo TypeDecl
    | String
    | UnknownType
    deriving Show
data Range = Range Identifier
           | RangeFromTo Expression Expression
    deriving Show
data Initialize = Initialize String
    deriving Show
data Finalize = Finalize String
    deriving Show
data Uses = Uses [Identifier]
    deriving Show
data Phrase = ProcCall Identifier [Expression]
        | IfThenElse Expression Phrase (Maybe Phrase)
        | WhileCycle Expression Phrase
        | RepeatCycle Expression [Phrase]
        | ForCycle Identifier Expression Expression Phrase
        | WithBlock Reference Phrase
        | Phrases [Phrase]
        | SwitchCase Expression [(Expression, Phrase)] (Maybe Phrase)
        | Assignment Reference Expression
    deriving Show
data Expression = Expression String
    | PrefixOp String Expression
    | PostfixOp String Expression
    | BinOp String Expression Expression
    | StringLiteral String
    | CharCode String
    | NumberLiteral String
    | FloatLiteral String
    | HexNumber String
    | Reference Reference
    | Null
    deriving Show
data Reference = ArrayElement [Expression] Reference
    | FunCall [Expression] Reference
    | BuiltInFunCall [Expression] Reference
    | SimpleReference Identifier
    | Dereference Reference
    | RecordField Reference Reference
    | Address Reference
    deriving Show
data InitExpression = InitBinOp String InitExpression InitExpression
    | InitPrefixOp String InitExpression
    | InitReference Identifier
    | InitArray [InitExpression]
    | InitRecord [(Identifier, InitExpression)]
    | InitFloat String
    | InitNumber String
    | InitHexNumber String
    | InitString String
    | InitChar String
    | InitNull
    deriving Show

    
pascalLanguageDef
    = emptyDef
    { commentStart   = "(*"
    , commentEnd     = "*)"
    , commentLine    = "//"
    , nestedComments = False
    , identStart     = letter <|> oneOf "_"
    , identLetter    = alphaNum <|> oneOf "_."
    , reservedNames  = [
            "begin", "end", "program", "unit", "interface"
            , "implementation", "and", "or", "xor", "shl"
            , "shr", "while", "do", "repeat", "until", "case", "of"
            , "type", "var", "const", "out", "array", "packed"
            , "procedure", "function", "with", "for", "to"
            , "downto", "div", "mod", "record", "set", "nil"
            , "string", "shortstring"--, "succ", "pred", "low"
            --, "high"
            ]
    , reservedOpNames= [] 
    , caseSensitive  = False   
    }
    
pas = patch $ makeTokenParser pascalLanguageDef
    where
    patch tp = tp {stringLiteral = sl}
    sl = do
        (char '\'')
        s <- (many $ noneOf "'")
        (char '\'')
        ss <- many $ do
            (char '\'')
            s' <- (many $ noneOf "'")
            (char '\'')
            return $ '\'' : s'
        comments    
        return $ concat (s:ss)
    
comments = do
    spaces
    skipMany $ do
        comment
        spaces

pascalUnit = do
    comments
    u <- choice [program, unit]
    comments
    return u

comment = choice [
        char '{' >> manyTill anyChar (try $ char '}')
        , (try $ string "(*") >> manyTill anyChar (try $ string "*)")
        , (try $ string "//") >> manyTill anyChar (try newline)
        ]

iD = do
    i <- liftM Identifier (identifier pas)
    comments
    return i
        
unit = do
    string "unit" >> comments
    name <- iD
    semi pas
    comments
    int <- interface
    impl <- implementation
    comments
    return $ Unit name int impl Nothing Nothing

    
reference = buildExpressionParser table term <?> "reference"
    where
    term = comments >> choice [
        parens pas (reference >>= postfixes) >>= postfixes
        , char '@' >> reference >>= postfixes >>= return . Address
        , liftM SimpleReference iD >>= postfixes 
        ] <?> "simple reference"

    table = [ 
            [Infix (try (char '.' >> notFollowedBy (char '.')) >> return RecordField) AssocLeft]
        ]
    
    postfixes r = many postfix >>= return . foldl fp r
    postfix = choice [
            parens pas (option [] parameters) >>= return . FunCall
          , char '^' >> return Dereference
          , (brackets pas) (commaSep1 pas $ expression) >>= return . ArrayElement
        ]
    fp r f = f r

    
varsDecl1 = varsParser sepEndBy1    
varsDecl = varsParser sepEndBy
varsParser m endsWithSemi = do
    vs <- m (aVarDecl endsWithSemi) (semi pas)
    return vs

aVarDecl endsWithSemi = do
    when (not endsWithSemi) $
        optional $ choice [
            try $ string "var"
            , try $ string "const"
            , try $ string "out"
            ]
    comments
    ids <- do
        i <- (commaSep1 pas) $ (try iD <?> "variable declaration")
        char ':'
        return i
    comments
    t <- typeDecl <?> "variable type declaration"
    comments
    init <- option Nothing $ do
        char '='
        comments
        e <- initExpression
        comments
        return (Just e)
    return $ VarDeclaration False (ids, t) init


constsDecl = do
    vs <- many1 (try (aConstDecl >>= \i -> semi pas >> return i) >>= \i -> comments >> return i)
    comments
    return vs
    where
    aConstDecl = do
        comments
        i <- iD <?> "const declaration"
        optional $ do
            char ':'
            comments
            t <- typeDecl
            return ()
        char '='
        comments
        e <- initExpression
        comments
        return $ VarDeclaration False ([i], UnknownType) (Just e)
        
typeDecl = choice [
    char '^' >> typeDecl >>= return . PointerTo
    , try (string "shortstring") >> return String
    , arrayDecl
    , recordDecl
    , sequenceDecl >>= return . Sequence
    , try (identifier pas) >>= return . SimpleType . Identifier
    , rangeDecl >>= return . RangeType
    ] <?> "type declaration"
    where
    arrayDecl = do
        try $ string "array"
        comments
        char '['
        r <- rangeDecl
        char ']'
        comments
        string "of"
        comments
        t <- typeDecl
        return $ ArrayDecl r t
    recordDecl = do
        optional $ (try $ string "packed") >> comments
        try $ string "record"
        comments
        vs <- varsDecl True
        string "end"
        return $ RecordType vs
    sequenceDecl = (parens pas) $ (commaSep pas) iD

typesDecl = many (aTypeDecl >>= \t -> comments >> return t)
    where
    aTypeDecl = do
        i <- try $ do
            i <- iD <?> "type declaration"
            comments
            char '='
            return i
        comments
        t <- typeDecl
        comments
        semi pas
        comments
        return $ TypeDeclaration i t
        
rangeDecl = choice [
    try $ rangeft
    , iD >>= return . Range
    ] <?> "range declaration"
    where
    rangeft = do
    e1 <- expression
    string ".."
    e2 <- expression
    return $ RangeFromTo e1 e2
    
typeVarDeclaration isImpl = (liftM concat . many . choice) [
    varSection,
    constSection,
    typeSection,
    funcDecl,
    procDecl
    ]
    where
    varSection = do
        try $ string "var"
        comments
        v <- varsDecl1 True
        comments
        return v

    constSection = do
        try $ string "const"
        comments
        c <- constsDecl
        comments
        return c

    typeSection = do
        try $ string "type"
        comments
        t <- typesDecl
        comments
        return t
        
    procDecl = do
        try $ string "procedure"
        comments
        i <- iD
        optional $ do
            char '('
            varsDecl False
            char ')'
        comments
        char ';'
        b <- if isImpl then
                do
                comments
                optional $ typeVarDeclaration True
                comments
                liftM Just functionBody
                else
                return Nothing
        comments
        return $ [FunctionDeclaration i UnknownType b]
        
    funcDecl = do
        try $ string "function"
        comments
        i <- iD
        optional $ do
            char '('
            varsDecl False
            char ')'
        comments
        char ':'
        comments
        ret <- typeDecl
        comments
        char ';'
        comments
        b <- if isImpl then
                do
                optional $ typeVarDeclaration True
                comments
                liftM Just functionBody
                else
                return Nothing
        return $ [FunctionDeclaration i ret b]

program = do
    string "program"
    comments
    name <- iD
    (char ';')
    comments
    impl <- implementation
    comments
    return $ Program name impl

interface = do
    string "interface"
    comments
    u <- uses
    comments
    tv <- typeVarDeclaration False
    comments
    return $ Interface u (TypesAndVars tv)

implementation = do
    string "implementation"
    comments
    u <- uses
    comments
    tv <- typeVarDeclaration True
    string "end."
    comments
    return $ Implementation u (TypesAndVars tv)

expression = buildExpressionParser table term <?> "expression"
    where
    term = comments >> choice [
        parens pas $ expression 
        , try $ integer pas >>= \i -> notFollowedBy (char '.') >> (return . NumberLiteral . show) i
        , try $ float pas >>= return . FloatLiteral . show
        , try $ integer pas >>= return . NumberLiteral . show
        , stringLiteral pas >>= return . StringLiteral
        , char '#' >> many digit >>= return . CharCode
        , char '$' >> many hexDigit >>= return . HexNumber
        , try $ string "nil" >> return Null
        , reference >>= return . Reference
        ] <?> "simple expression"

    table = [ 
          [  Infix (char '*' >> return (BinOp "*")) AssocLeft
           , Infix (char '/' >> return (BinOp "/")) AssocLeft
           , Infix (try (string "div") >> return (BinOp "div")) AssocLeft
           , Infix (try (string "mod") >> return (BinOp "mod")) AssocLeft
          ]
        , [  Infix (char '+' >> return (BinOp "+")) AssocLeft
           , Infix (char '-' >> return (BinOp "-")) AssocLeft
           , Prefix (char '-' >> return (PrefixOp "-"))
          ]
        , [  Infix (try (string "<>") >> return (BinOp "<>")) AssocNone
           , Infix (try (string "<=") >> return (BinOp "<=")) AssocNone
           , Infix (try (string ">=") >> return (BinOp ">=")) AssocNone
           , Infix (char '<' >> return (BinOp "<")) AssocNone
           , Infix (char '>' >> return (BinOp ">")) AssocNone
           , Infix (char '=' >> return (BinOp "=")) AssocNone
          ]
        , [  Infix (try $ string "and" >> return (BinOp "and")) AssocLeft
           , Infix (try $ string "or" >> return (BinOp "or")) AssocLeft
           , Infix (try $ string "xor" >> return (BinOp "xor")) AssocLeft
          ]
        , [  Infix (try $ string "shl" >> return (BinOp "shl")) AssocNone
           , Infix (try $ string "shr" >> return (BinOp "shr")) AssocNone
          ]
        , [Prefix (try (string "not") >> return (PrefixOp "not"))]
        ]
    
phrasesBlock = do
    try $ string "begin"
    comments
    p <- manyTill phrase (try $ string "end")
    comments
    return $ Phrases p
    
phrase = do
    o <- choice [
        phrasesBlock
        , ifBlock
        , whileCycle
        , repeatCycle
        , switchCase
        , withBlock
        , forCycle
        , (try $ reference >>= \r -> string ":=" >> return r) >>= \r -> expression >>= return . Assignment r
        , procCall
        ]
    optional $ char ';'
    comments
    return o

ifBlock = do
    try $ string "if"
    comments
    e <- expression
    comments
    string "then"
    comments
    o1 <- phrase
    comments
    o2 <- optionMaybe $ do
        try $ string "else"
        comments
        o <- phrase
        comments
        return o
    return $ IfThenElse e o1 o2

whileCycle = do
    try $ string "while"
    comments
    e <- expression
    comments
    string "do"
    comments
    o <- phrase
    return $ WhileCycle e o

withBlock = do
    try $ string "with"
    comments
    (r:rs) <- (commaSep1 pas) reference
    comments
    string "do"
    comments
    o <- phrase
    return $ WithBlock r (foldl (\ph r -> WithBlock r ph) o rs)
    
repeatCycle = do
    try $ string "repeat"
    comments
    o <- many phrase
    string "until"
    comments
    e <- expression
    comments
    return $ RepeatCycle e o

forCycle = do
    try $ string "for"
    comments
    i <- iD
    comments
    string ":="
    comments
    e1 <- expression
    comments
    choice [string "to", string "downto"]
    comments
    e2 <- expression
    comments
    string "do"
    comments
    p <- phrase
    comments
    return $ ForCycle i e1 e2 p
    
switchCase = do
    try $ string "case"
    comments
    e <- expression
    comments
    string "of"
    comments
    cs <- many1 aCase
    o2 <- optionMaybe $ do
        try $ string "else"
        comments
        o <- phrase
        comments
        return o
    string "end"
    return $ SwitchCase e cs o2
    where
    aCase = do
        e <- expression
        comments
        char ':'
        comments
        p <- phrase
        comments
        return (e, p)
    
procCall = do
    i <- iD
    p <- option [] $ (parens pas) parameters
    return $ ProcCall i p

parameters = (commaSep pas) expression <?> "parameters"
        
functionBody = do
    p <- phrasesBlock
    char ';'
    comments
    return p

uses = liftM Uses (option [] u)
    where
        u = do
            string "uses"
            comments
            u <- (iD >>= \i -> comments >> return i) `sepBy1` (char ',' >> comments)
            char ';'
            comments
            return u

initExpression = buildExpressionParser table term <?> "initialization expression"
    where
    term = comments >> choice [
        try $ parens pas (commaSep pas $ initExpression) >>= return . InitArray
        , parens pas (semiSep pas $ recField) >>= return . InitRecord
        , try $ integer pas >>= \i -> notFollowedBy (char '.') >> (return . InitNumber . show) i
        , try $ float pas >>= return . InitFloat . show
        , stringLiteral pas >>= return . InitString
        , char '#' >> many digit >>= return . InitChar
        , char '$' >> many hexDigit >>= return . InitHexNumber
        , try $ string "nil" >> return InitNull
        , iD >>= return . InitReference
        ]
        
    recField = do
        i <- iD
        spaces
        char ':'
        spaces
        e <- initExpression
        spaces
        return (i ,e)

    table = [ 
          [  Infix (char '*' >> return (InitBinOp "*")) AssocLeft
           , Infix (char '/' >> return (InitBinOp "/")) AssocLeft
           , Infix (try (string "div") >> return (InitBinOp "div")) AssocLeft
           , Infix (try (string "mod") >> return (InitBinOp "mod")) AssocLeft
          ]
        , [  Infix (char '+' >> return (InitBinOp "+")) AssocLeft
           , Infix (char '-' >> return (InitBinOp "-")) AssocLeft
           , Prefix (char '-' >> return (InitPrefixOp "-"))
          ]
        , [  Infix (try (string "<>") >> return (InitBinOp "<>")) AssocNone
           , Infix (try (string "<=") >> return (InitBinOp "<=")) AssocNone
           , Infix (try (string ">=") >> return (InitBinOp ">=")) AssocNone
           , Infix (char '<' >> return (InitBinOp "<")) AssocNone
           , Infix (char '>' >> return (InitBinOp ">")) AssocNone
           , Infix (char '=' >> return (InitBinOp "=")) AssocNone
          ]
        , [  Infix (try $ string "and" >> return (InitBinOp "and")) AssocLeft
           , Infix (try $ string "or" >> return (InitBinOp "or")) AssocLeft
           , Infix (try $ string "xor" >> return (InitBinOp "xor")) AssocLeft
          ]
        , [  Infix (try $ string "shl" >> return (InitBinOp "and")) AssocNone
           , Infix (try $ string "shr" >> return (InitBinOp "or")) AssocNone
          ]
        , [Prefix (try (string "not") >> return (InitPrefixOp "not"))]
        ]
    