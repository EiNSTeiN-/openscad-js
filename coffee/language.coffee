

class Assignment
    """
    `identifier` = `expr` ;
    """
    
    constructor: (@identifier, @expression) ->
        return
    
    pprint: () -> return @identifier.pprint() + ' = ' + @expression.pprint() + ';'
    dump: () -> return '<assignment id=' + @identifier.dump() + ' value=' + @expression.dump() + '>'

class ModuleDefinition
    """
    module `identifier` ( `arguments` ) `body`
    """
    
    constructor: (@parent, @identifier, @arguments, @body) ->
        @arguments ?= new ArgumentList()
        return
    
    pprint: () -> return 'module ' + @identifier.pprint() + @arguments.pprint() + (if @body? then ' ' + @body.pprint() else ';')
    dump: () -> return '<module id=' + @identifier.dump() + ' args=' + @arguments.dump() + '>\n   ' + @body.dump().split('\n').join('\n   ') + '\n</module>'

class FunctionDefinition
    """
    function `identifier` ( `arguments` ) = `expr` ;
    """

    constructor: (@identifier, @arguments, @body) ->
        
        return
    
    pprint: () -> return 'function ' + @identifier.pprint() + @arguments.pprint() + ' = ' + @body.pprint() + ';'
    dump: () -> return '<function id=' + @identifier.dump() + ' args=' + @arguments.dump() + ' expr=' + @body.dump() + '>'

class For
    """
    for ( `arguments` ) `expr` ;
    """

    constructor: (@arguments, @body) -> return
    
    pprint: () -> return 'for(' + @arguments.pprint() + ') ' + @body.pprint()
    dump: () -> return '<for args=' + @arguments.dump() + '>\n' + @body.dump().split('\n').join('\n   ') + '\n</for>'

class IntersectionFor
    """
    intersection_for ( `arguments` ) `expr` ;
    """

    constructor: (@arguments, @body) -> return
    
    pprint: () -> return 'intersection_for ' + @arguments.pprint() + ' ' + @body.pprint()
    dump: () -> return '<intersection_for args=' + @arguments.dump() + '>\n' + @body.dump().split('\n').join('\n   ') + '\n</for>'

class Assign
    """
    assign ( `arguments` ) `body` ;
    """

    constructor: (@arguments, @body) ->
        
        return
    
    pprint: () -> return 'assign' + @arguments.pprint() + ' ' + @body.pprint() + ';'
    dump: () -> return '<assign args=' + @arguments.dump() + ' expr=' + @body.dump() + '>'

class IfElseStatement
    """
    if ( `condition` ) 
        `body`
    [ else
        `else_body` ]
    """

    constructor: (@condition, @body) ->
        @else_body = null
        return
    
    pprint: () ->
        s = 'if(' + @condition.pprint() + ') ' + @body.pprint()
        if @else_body
            s += ' else ' + @else_body.pprint()
        return s
    
    dump: () ->
        s = '<if cond=' + @condition.dump() + '>\n'
        s += '   ' + @body.dump().split('\n').join('\n   ')
        if @else_children
            s += '\n<else>\n   ' + @else_body.dump().split('\n').join('\n   ')
        s += '</if>'
        return s

class ModuleBody
    
    constructor: () ->
        @children = []
        return
    
    pprint: () -> return (c.pprint() for c in @children).join('\n').split('\n').join('\n')
    dump: () -> return '<module>\n   ' + (c.dump() for c in @children).join('\n').split('\n').join('\n   ') + '\n</module>'

class ModuleInstantiation
    """
    `identifier` ( `arguments` ) `body`
    """
    
    constructor: (@identifier, @arguments) ->
        @arguments ?= new ArgumentList()
        @body = null
        @tag_root = false
        @tag_highlight = false
        @tag_background = false
        return
    
    tags: () ->
        s = ''
        s += '!' if @tag_root
        s += '#' if @tag_highlight
        s += '%' if @tag_background
        return s
    
    pprint: () -> return @tags() + @identifier.pprint() + @arguments.pprint() + (if @body then ' ' + @body.pprint() else ';')
    dump: () -> return '<module-inst tags=' + @tags() + ' id=' + @identifier.dump() + ' args=' + @arguments.dump() + '>\n   ' + (if @body then @body.dump() else '') + '\n</module-inst>'

class Identifier
    """
    Any identifier name
    """

    constructor: (@name) -> return
    
    pprint: () -> return @name
    dump: () -> return '<identifier name=' + @name + '>'

class Dereference
    """
    Dereferences a property of an expression
    """

    constructor: (@expression, @identifier) -> return
    
    pprint: () -> return @expression.pprint() + '.' + @identifier.pprint()
    dump: () -> return '<dereference expr=' + @expression.dump() + ' identifier=' + @identifier.dump() + '>'

class Range
    """
    A range of expression [`start`, `end`] or [`start`, `increment`, `end`]
    """

    constructor: (@start, @increment, @end) -> return
    
    pprint: () -> return '[' + @start.pprint() + (if @increment? then (':' + @increment.pprint()) else '') + ':' + @end.pprint() + ']'
    dump: () -> return '<range start=' + @start + ' increment=' + @increment + ' end=' + @end + '>'

class Vector
    """
    A vector like [`first`, `second`, `third`, ...]
    """

    constructor: () ->
        @children = []
        return
    
    pprint: () -> return '[' + (c.pprint() for c in @children).join(', ') + ']'
    dump: () -> return '<vector>\n   ' + (c.dump() for c in @children).join('\n').split('\n').join('\n   ') + '\n</vector>'

class Expression
    """
    Any basic type value: bool, string, number.
    """

    constructor: (@value) -> return
    
    pprint: () -> return @value
    dump: () -> return '<expression value=' + @value + '>'

class Multiply

    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' * ' + @right.pprint()
    dump: () -> return '<multiply>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</multiply>'

class Divide

    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' / ' + @right.pprint()
    dump: () -> return '<divide>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</divide>'

class Modulo

    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' % ' + @right.pprint()
    dump: () -> return '<modulo>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</modulo>'

class Plus

    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' + ' + @right.pprint()
    dump: () -> return '<plus>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</plus>'

class Minus

    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' - ' + @right.pprint()
    dump: () -> return '<minus>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</minus>'

class LessThan
    """ Evaluates to a boolean expression which is true if `left` is less than `right` """
    
    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' < ' + @right.pprint()
    dump: () -> return '<less-than>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</less-than>'

class LowerEqual
    """ Evaluates to a boolean expression which is true if `left` is less or equal than `right` """

    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' <= ' + @right.pprint()
    dump: () -> return '<lower-or-equal>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</lower-or-equal>'

class Equal
    """ Evaluates to a boolean expression which is true if `left` is equal to `right` """

    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' == ' + @right.pprint()
    dump: () -> return '<equals>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</equals>'

class NotEqual

    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' != ' + @right.pprint()
    dump: () -> return '<not-equal>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</not-equal>'

class GreaterEqual

    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' >= ' + @right.pprint()
    dump: () -> return '<greater-or-equal>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</greater-or-equal>'

class MoreThan

    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' > ' + @right.pprint()
    dump: () -> return '<more-than>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</more-than>'

class And

    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' && ' + @right.pprint()
    dump: () -> return '<and>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</and>'

class Or

    constructor: (@left, @right) -> return
    
    pprint: () -> return @left.pprint() + ' || ' + @right.pprint()
    dump: () -> return '<or>\n   ' + @left.dump() + '\n   ' + @right.dump() + '</or>'

class Negate

    constructor: (@expression) -> return
    
    pprint: () -> return '!' + @expression.pprint()
    dump: () -> return '<not>' + @expression.dump() + '</not>'

class UnaryMinus

    constructor: (@expression) -> return
    
    pprint: () -> return '-' + @expression.pprint()
    dump: () -> return '<unary-minus>' + @expression.dump() + '</unary-minus>'

class TernaryIf

    constructor: (@condition, @true_expression, @false_expression) -> return
    
    pprint: () -> return @condition.pprint() + '?' + @true_expression.pprint() + ':' + @false_expression
    dump: () -> return '<ternary-if cond=' + @condition.dump() + '>\n   ' + @true_expression.dump() + '<else>\n   ' + @false_expression.dump() '</ternary-if>'

class Index

    constructor: (@expression, @index) -> return
    
    pprint: () -> return @expression.pprint() + '[' + @index.pprint() + ']'
    dump: () -> return '<index expression=' + @expression.dump() + ' index=' + @index.dump() + '>'

class ArgumentList

    constructor: () ->
        @args = []
        return
    
    pprint: () -> return '(' + (c.pprint() for c in @args).join(', ') + ')'
    dump: () -> return '(' + (c.dump() for c in @args).join(', ') + ')'

class ArgumentDeclaration

    constructor: (@identifier, @default) ->
        return
    
    pprint: () -> return @identifier.pprint() + (if @default then ' = ' + @default.pprint() else '')
    dump: () -> return '<arg-decl id=' + @identifier.dump() + ' default=' + (if @default then @default.dump() else 'none') + '>'

class CallArgument

    constructor: (@identifier, @value) ->
        return
    
    pprint: () -> return (if @identifier then @identifier.pprint() + ' = ' else '') + @value.pprint()
    dump: () -> return '<arg' + (if @identifier then ' id=' + @identifier.dump() else '') + ' value=' + @value.dump() + '>'

class CurlyBraces

    constructor: (@children) ->
        @children ?= []
        return
    
    pprint: () -> return '{\n   ' + (c.pprint() for c in @children).join('\n').split('\n').join('\n   ') + '\n}'
    dump: () ->
        return '<curly-braces>\n   ' + (c.dump() for c in @children).join('\n').split('\n').join('\n   ') + '\n</curly-braces>'

if module?
    module.exports =
        Assignment: Assignment,
        ModuleDefinition: ModuleDefinition,
        FunctionDefinition: FunctionDefinition,
        For: For,
        IntersectionFor: IntersectionFor,
        Assign: Assign,
        IfElseStatement: IfElseStatement,
        ModuleBody: ModuleBody,
        ModuleInstantiation: ModuleInstantiation,
        Expression: Expression,
        Identifier: Identifier,
        Dereference: Dereference,
        Range: Range,
        Vector: Vector,
        Multiply: Multiply,
        Divide: Divide,
        Modulo: Modulo,
        Plus: Plus,
        Minus: Minus,
        LessThan: LessThan,
        LowerEqual: LowerEqual,
        Equal: Equal,
        NotEqual: NotEqual,
        GreaterEqual: GreaterEqual,
        MoreThan: MoreThan,
        And: And,
        Or: Or,
        Negate: Negate,
        UnaryMinus: UnaryMinus,
        TernaryIf: TernaryIf,
        Index: Index,
        Call: Call,
        ArgumentList: ArgumentList,
        ArgumentDeclaration: ArgumentDeclaration,
        CallArgument: CallArgument,
        CurlyBraces: CurlyBraces,
  
