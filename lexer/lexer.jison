
%{
if (typeof require !== 'undefined') {
    language = require("./language")
    Assignment = language.Assignment
    ModuleDefinition = language.ModuleDefinition
    FunctionDefinition = language.FunctionDefinition
    For = language.For
    IntersectionFor = language.IntersectionFor
    Assign = language.Assign
    IfElseStatement = language.IfElseStatement
    ModuleBody = language.ModuleBody
    ModuleInstantiation = language.ModuleInstantiation
    Expression = language.Expression
    Identifier = language.Identifier
    Dereference = language.Dereference
    Range = language.Range
    Vector = language.Vector
    Multiply = language.Multiply
    Divide = language.Divide
    Modulo = language.Modulo
    Plus = language.Plus
    Minus = language.Minus
    LessThan = language.LessThan
    LowerEqual = language.LowerEqual
    Equal = language.Equal
    NotEqual = language.NotEqual
    GreaterEqual = language.GreaterEqual
    MoreThan = language.MoreThan
    And = language.And
    Or = language.Or
    Negate = language.Negate
    UnaryMinus = language.UnaryMinus
    TernaryIf = language.TernaryIf
    Index = language.Index
    ArgumentList = language.ArgumentList
    ArgumentDeclaration = language.ArgumentDeclaration
    CallArgument = language.CallArgument
    CurlyBraces = language.CurlyBraces
}
%}

/* lexical grammar */
%lex
%%

\s+                   /* skip whitespace */
\t+                   /* skip whitespace */
[0-9]*"."[0-9]+([Ee][+-]?[0-9]+)? return 'NUMBER'
[0-9]+"."[0-9]*([Ee][+-]?[0-9]+)? return 'NUMBER'
[0-9]+([Ee][+-]?[0-9]+)? return 'NUMBER'
"\""[^"]*"\""         return 'STRING'
"/*"(.|\n)*?"*/"           /* ignore comment */
"//"[^\n]*            /* ignore comment */
"<="                  return 'LE'
">="                  return 'GE'
"=="                  return 'EQ'
"!="                  return 'NE'
"&&"                  return 'AND'
"||"                  return 'OR'
"."                   return '.'
"("                   return "("
")"                   return ")"
"?"                   return "?"
":"                   return ":"
">"                   return ">"
"<"                   return "<"
";"                   return ";"
"="                   return "="
","                   return ","
"["                   return "["
"]"                   return "]"
"{"                   return "{"
"}"                   return "}"
"+"                   return "+"
"-"                   return "-"
"/"                   return "/"
"*"                   return "*"
"%"                   return "%"
"#"                   return "#"
"include"\s+"<"[0-9a-zA-Z_\.\/]+">" return 'INCLUDE'
"use"\s+"<"[0-9a-zA-Z_\.\/]+">" return 'USE'
"module"              return 'MODULE'
"function"            return 'FUNCTION'
"for"                 return 'FOR'
"intersection_for"    return 'INTERSECTION_FOR'
"assign"    return 'ASSIGN'
"if"                  return 'IF'
"else"                return 'ELSE'
"true"                return 'TRUE'
"false"               return 'FALSE'
"undef"               return 'UNDEF'
"$"?[a-zA-Z0-9_]+     return 'ID'
<<EOF>>               return 'EOF'
.                     return 'INVALID'

/lex

/* operator associations and precedence */


%token MODULE
%token FUNCTION
%token IF
%token ELSE

%token <text> ID
%token <text> STRING
%token <text> USE
%token <number> NUMBER

%token TRUE
%token FALSE
%token UNDEF

%token LE GE EQ NE AND OR

%right '?' ':'

%left OR
%left AND

%left '<' LE GE '>'
%left EQ NE

%left '!' '+' '-'
%left '*' '/' '%'
%left '[' ']'
%left '.'



%start root_module

%% /* language grammar */

use:
    USE { $$.children.push(Use($1)); } ; 

include:
    INCLUDE { $$.children.push(Include($1)); } ;

root_module :
    input {
        $$ = new ModuleBody();
        if($1 instanceof Array) {
            $$.children = $1;
        } else {
            $$.children = [$1];
        }
        return $$;
    } ;

input:
    /* empty */ |
    use input {
        if($2 instanceof Array) {
            $$ = $2;
            $$.unshift($1);
        } else {
            $$ = [$1];
        }
    } |
    include input {
        if($2 instanceof Array) {
            $$ = $2;
            $$.unshift($1);
        } else {
            $$ = [$1];
        }
    } |
    statement input {
        if($2 instanceof Array) {
            $$ = $2;
            $$.unshift($1);
        } else {
            $$ = [$1];
        }
    } |
    EOF ;

inner_input:
    /* empty */ |
    statement inner_input {
        if($2 instanceof Array) {
            $$ = $2;
            $$.unshift($1);
        } else {
            $$ = [$1];
        }
    } ;

statement:
    ';' |
    '{' inner_input '}' { $$ = new CurlyBraces($2); } |
    module_instantiation {
        if ($1) {
            $$ = $1;
        } else {
            $$ = null;
        }
    } |
    ID '=' expr ';' {
        $$ = new Assignment(new Identifier($1), $3);
    } |
    MODULE ID '(' arguments_decl optional_commas ')' statement {
        module = new ModuleDefinition($$, new Identifier($2), $4);
        
        module.body = $7;
        
        $$ = module;
    } |
    FUNCTION ID '(' arguments_decl optional_commas ')' '=' expr ';' {
        var func = new FunctionDefinition(new Identifier($2), $4, $8);
        $$ = func;
    } ;

for_statement:
    FOR '(' for_argument ')' children_instantiation {
        $$ = new For($3, $5);
    } |
    INTERSECTION_FOR '(' for_argument ')' children_instantiation {
        $$ = new IntersectionFor($3, $5);
    } ;

for_argument:
    ID '=' expr {
        $$ = new CallArgument(new Identifier($1), $3);
    } ;

module_instantiation:
    single_module_instantiation ';' {
        $$ = $1;
    } |
    single_module_instantiation children_instantiation {
        $$ = $1;
        $$.body = $2;
    } |
    ifelse_statement {
        $$ = $1;
    } |
    for_statement {
        $$ = $1;
    } |
    ASSIGN '(' arguments_call ')' children_instantiation {
        $$ = new Assign($3, $5);
    }    ;

ifelse_statement:
    if_statement {
        $$ = $1;
    } |
    if_statement ELSE children_instantiation {
        $$ = $1;
        $$.else_body = $3;
        delete $3;
    } ;

if_statement:
    IF '(' expr ')' children_instantiation {
        $$ = new IfElseStatement($3, $5);
    } ;

children_instantiation:
    module_instantiation {
        $$ = $1;
    } |
    '{' module_instantiation_list '}' {
        $$ = new CurlyBraces($2);
    } ;

module_instantiation_list:
    /* empty */ |
    module_instantiation_list module_instantiation {
        if($1 instanceof Array) {
            $$ = $1;
            $1.push($2);
        } else {
            $$ = [$2];
        }
    } ;

single_module_instantiation:
    ID '(' arguments_call ')' {
        $$ = new ModuleInstantiation(new Identifier($1), $3);
    } |
    '!' single_module_instantiation {
        $$ = $2;
        if ($$)
            $$.tag_root = true;
    } |
    '#' single_module_instantiation {
        $$ = $2;
        if ($$)
            $$.tag_highlight = true;
    } |
    '%' single_module_instantiation {
        $$ = $2;
        if ($$)
            $$.tag_background = true;
    } |
    '*' single_module_instantiation {
        $$ = null;
    };

expr:
    TRUE {
          $$ = new Expression(true);
    } |
    FALSE {
          $$ = new Expression(false);
    } |
    UNDEF {
          $$ = new Expression(undefined);
    } |
    ID {
        $$ = new Identifier($1);
    } |
    expr '.' ID {
        $$ = new Dereference($1, $3);
    } |
    STRING {
          $$ = new Expression($1.substring(1, $1.length-1));
    } |
    NUMBER {
          $$ = new Expression(Number($1));
    } |
    '[' expr ':' expr ']' {
        $$ = new Range($2, null, $4);
    } |
    '[' expr ':' expr ':' expr ']' {
        $$ = new Range($2, $4, $6);
    } |
    '[' optional_commas ']' {
          $$ = new Vector();
    } |
    '[' vector_expr optional_commas ']' {
        $$ = $2;
    } |
    expr '*' expr {
        $$ = new Multiply($1, $3);
    } |
    expr '/' expr {
        $$ = new Divide($1, $3);
    } |
    expr '%' expr {
        $$ = new Modulo($1, $3);
    } |
    expr '+' expr {
        $$ = new Plus($1, $3);
    } |
    expr '-' expr {
        $$ = new Minus($1, $3);
    } |
    expr '<' expr {
        $$ = new LessThan($1, $3);
    } |
    expr LE expr {
        $$ = new LowerEqual($1, $3);
    } |
    expr EQ expr {
        $$ = new Equal($1, $3);
    } |
    expr NE expr {
        $$ = new NotEqual($1, $3);
    } |
    expr GE expr {
        $$ = new GreaterEqual($1, $3);
    } |
    expr '>' expr {
        $$ = new MoreThan($1, $3);
    } |
    expr AND expr {
        $$ = new And($1, $3);
    } |
    expr OR expr {
        $$ = new Or($1, $3);
    } |
    '+' expr {
        $$ = $2;
    } |
    '-' expr {
        $$ = new UnaryMinus($2);
    } |
    '!' expr {
        $$ = new Negate($2);
    } |
    '(' expr ')' {
        $$ = $2;
    } |
    expr '?' expr ':' expr {
        $$ = new TernaryIf($1, $3, $5);
    } |
    expr '[' expr ']' {
        $$ = new Index($1, $3);
    } |
    ID '(' arguments_call ')' {
        $$ = new ModuleInstantiation(new Identifier($1), $3);
    } ;

optional_commas:
    ',' optional_commas | /* nothing */ ;

vector_expr:
    expr {
        $$ = new Vector();
        $$.children.push($1);
    } |
    vector_expr ',' optional_commas expr {
        $$ = $1;
        $$.children.push($4);
    } ;

arguments_decl:
    /* empty */ {
        $$ = new ArgumentList();
    } |
    argument_decl {
        $$ = new ArgumentList();
        $$.args.push($1);
    } |
    arguments_decl ',' optional_commas argument_decl {
        $$ = $1;
        $$.args.push($4);
    } ;

argument_decl:
    ID {
        $$ = new ArgumentDeclaration(new Identifier($1));
    } |
    ID '=' expr {
        $$ = new ArgumentDeclaration(new Identifier($1), $3);
    } ;

arguments_call:
    /* empty */ {
        $$ = new ArgumentList();
    } |
    argument_call {
        $$ = new ArgumentList();
        $$.args.push($1);
    } |
    arguments_call ',' optional_commas argument_call {
        $$ = $1;
        $$.args.push($4);
    } ;

argument_call:
    expr {
        $$ = new CallArgument(null, $1);
    } |
    ID '=' expr {
        $$ = new CallArgument(new Identifier($1), $3);
    } ;











