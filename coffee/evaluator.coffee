
DEFAULT_FA = 12
DEFAULT_FS = 2
DEFAULT_FN = 0

class Context
    
    constructor: (@parent, @current) ->
        @current ?= new Hash()
        return
    
    get: (name) ->
        
        value = @current.get(name)
        return value if value? and value != false
        
        return @parent.get(name) if @parent?
        
        throw "unknown name `" + name + "'"
    
    set: (name, value) ->
        @current.set(name, value)
        return

class Iterator
    constructor: () -> return
    next: () -> throw 'not implemented'

class RangeIterator extends Iterator
    
    constructor: (@start, @increment, @end) -> return
    toString: () -> 'range(' + @start + ':' + @increment + ':' + @end + ')'
    
    next: () ->
        if not @current?
            @current = @start
            return @current
        
        @current += @increment
        @current = undefined if @current > @end
        
        return @current

class VectorIterator extends Iterator
    
    constructor: (@values) -> return
    toString: () -> 'vector([' + @values + '])'
    
    size: () -> @values.length
    
    next: () ->
        if not @current?
            @current = 0
        else
            @current += 1
        
        @current = undefined if @current >= @values.length
        return @values[@current]

class GeometryBase
    """ this class is a common base for all of the geometry classes """
    
    constructor: () -> return
    
    parseargs: (args, kwargs) ->
        """
        Match up arguments. 
        
        @args contains a list of unnamed arguments.
        @kwargs contains a list of nammed arguments.
        @prototype contains a list of expected arguments
        
        We expect @prototype to have all arguments without default value first, and the 
        ones with defaults last.
        
        We first match up all arguments in @prototype with the unnamed arguments in @args in 
        the order they appear in @prototype, making sure none of them also appear in @kwargs.
        Then we match up the arguments in @kwargs which can appear in arbitrary order. If there
        are less arguments provided than expected in @prototype, default values are used.
        """
        
        if (args.length + kwargs.size()) > @prototype.length
            throw 'too many arguments for function'
        
        validnames = ((if v instanceof Array then v[0] else v) for v in @prototype)
        #console.log @prototype
        for name in kwargs.keys()
            if name not in validnames
                throw 'argument ' +  name + ' is not a valid name for an argument of this function ' + validnames.join(', ')
        
        i = 0
        ret = new Hash()
        for expected in @prototype
            if expected instanceof Array
                [name, def] = expected
            else
                name = expected
                def = undefined
            
            if i < args.length
                if kwargs.get(name)?
                    throw 'argument ' + name + ' given implicitely as argument #' + i + ' but also specified by name'
                ret.set(name, args[i])
                i += 1
            else
                console.log @prototype
                console.log [kwargs.keys(), kwargs.values()]
                value = kwargs.get(name)
                if not value?
                    if def == undefined
                        throw 'argument ' +  name + ' does not have a default value'
                    value = def
                ret.set(name, value)
        
        @argshash = ret
        return
    
    formatargs: () ->
        
        args = []
        for name in @argshash.keys()
            args.push name + '=' + @argshash.get(name)
        
        return args.join(',')


# some basic functions
class Echo extends GeometryBase
    """ echo(`expr`) """
    
    constructor: (body, @args, kwargs) ->
        throw 'module cannot be instantiated with a body' if body?
        #@prototype = ['s']
        #@parseargs(args, kwargs)
        #@text = @argshash.get('s')
        
        if kwargs.size() > 0
            throw 'echo() cannot not take any named arguments'
        
        return
    
    toString: () -> 'echo(' + @args.join(',') + ')'

# transofrmations
class Rotate extends GeometryBase
    """
    rotate(a = deg)
    rotate(a = deg, v = [x, y, z])
    rotate(a=[x_deg,y_deg,z_deg])
    """
    constructor: (@body, args, kwargs) ->
        @prototype = ['degree', ['vector', null]]
        @parseargs(args, kwargs)
        
        @degree = @argshash.get('degree')
        @vector = @argshash.get('vector')
        
        if @degree instanceof VectorIterator and not b?
            [@degree, @vector] = [1, @degree]
        
        if not @vector?
            # when only a degree is specified and no vector, the rotation is around the z axis
            @vector = new VectorIterator([0,0,1])
        
        if not (@vector instanceof VectorIterator) or @vector.values.length != 3
            throw "rotation() takes a 3-value vector as argument (got: " + @vector.toString() + ")"
        
        @x = @vector.values[0]
        @y = @vector.values[1]
        @z = @vector.values[2]
        
        return
    
    toString: () -> return 'rotate(' + @formatargs() + '){' + @body.toString() + '}'

class Scale extends GeometryBase
    """
    scale(v = [x, y, z])
    """
    constructor: (@body, args, kwargs) ->
        @prototype = ['vector']
        @parseargs(args, kwargs)
        
        @vector = @argshash.get('vector')
        
        if not (@vector instanceof VectorIterator) or @vector.values.length != 3
            throw "scale() takes a 3-value vector as argument (got: " + @vector.toString() + ")"
        
        @x = @vector.values[0]
        @y = @vector.values[1]
        @z = @vector.values[2]
        
        return
    
    toString: () -> return 'scale(' + @formatargs() + '){' + @body.toString() + '}'

class MultMatrix extends GeometryBase
    """
    multmatrix([[a1, b1, c1, d1], [a2, b2, c2, d2], [a3, b3, c3, d3], [a4, b4, c4, d4]])
    """
    constructor: (@body, args, kwargs) ->
        @prototype = ['m']
        @parseargs(args, kwargs)
        
        @matrix = @argshash.get('m')
        
        if not (@matrix instanceof VectorIterator) or @matrix.size() != 4
            throw "multmatrix() takes a 4x4 matrix as argument"
        
        @n1 = @matrix.values[0]
        @n2 = @matrix.values[1]
        @n3 = @matrix.values[2]
        @n4 = @matrix.values[3]
        
        if not (@n1 instanceof VectorIterator) or @n1.size() != 4
            throw "multmatrix() takes a 4x4 matrix as argument"
        if not (@n2 instanceof VectorIterator) or @n2.size() != 4
            throw "multmatrix() takes a 4x4 matrix as argument"
        if not (@n3 instanceof VectorIterator) or @n3.size() != 4
            throw "multmatrix() takes a 4x4 matrix as argument"
        if not (@n4 instanceof VectorIterator) or @n4.size() != 4
            throw "multmatrix() takes a 4x4 matrix as argument"
        
        @n11 = @n1.values[0]
        @n12 = @n1.values[1]
        @n13 = @n1.values[2]
        @n14 = @n1.values[3]
        
        @n21 = @n2.values[0]
        @n22 = @n2.values[1]
        @n23 = @n2.values[2]
        @n24 = @n2.values[3]
        
        @n31 = @n3.values[0]
        @n32 = @n3.values[1]
        @n33 = @n3.values[2]
        @n34 = @n3.values[3]
        
        @n41 = @n4.values[0]
        @n42 = @n4.values[1]
        @n43 = @n4.values[2]
        @n44 = @n4.values[3]
        
        return
    
    toString: () -> return 'scale(' + @formatargs() + '){' + @body.toString() + '}'

class Mirror extends GeometryBase
    """
    mirror(v = [x, y, z])
    """
    constructor: (@body, args, kwargs) ->
        @prototype = ['vector']
        @parseargs(args, kwargs)
        
        @vector = @argshash.get('vector')
        
        if not (@vector instanceof VectorIterator) or @vector.values.length != 3
            throw "mirror() takes a 3-value vector as argument (got: " + @vector.toString() + ")"
        
        @x = @vector.values[0]
        @y = @vector.values[1]
        @z = @vector.values[2]
        
        return
    
    toString: () -> return 'mirror(' + @formatargs() + '){' + @body.toString() + '}'

class Translate extends GeometryBase
    constructor: (@body, args, kwargs) ->
        @prototype = ['convexity']
        @parseargs(args, kwargs)
        
        @convexity = @argshash.get('convexity')
        
        if @convexity instanceof VectorIterator and @convexity.values.length == 3
            @x = @convexity.values[0]
            @y = @convexity.values[1]
            @z = @convexity.values[2]
        else
            throw "parameter `convexity' of translate() should evaluate to a 3-value vector or a number (got: " + @convexity.toString() + ")"
        return
    
    toString: () -> return 'translate(' + @formatargs() + '){' + @body.toString() + '}'


class Difference extends GeometryBase
    constructor: (@body) -> return
    toString: () -> return 'difference(){' + @body.toString() + '}'

class Union extends GeometryBase
    constructor: (@body) -> return
    toString: () -> 'union(){' + @body.toString() + '}'

class Intersection extends GeometryBase
    constructor: (@body) -> return
    toString: () -> 'intersection(){' + @body.toString() + '}'

class Objects extends GeometryBase
    constructor: (@objects) -> return
    toString: () ->
        return (obj.toString() for obj in @objects).join(',')

class Render extends GeometryBase
    constructor: (@body, args, kwargs) ->
        @prototype = ['convexity']
        @parseargs(args, kwargs)
        
        @convexity = @argshash['convexity']
        return
    
    toString: () -> return ('render(' + @formatargs() + '){' + @body.toString() + '}')

class Polyhedron extends GeometryBase
    constructor: (body, args, kwargs) ->
        throw 'module cannot be instantiated with a body' if body?
        
        @prototype = ['points', 'triangles']
        @parseargs(args, kwargs)
        
        @points = @argshash.get('points')
        @triangles = @argshash.get('triangles')
        return
    
    toString: () ->
        return 'polyhedron(' + @formatargs() + ')'

class Sphere extends GeometryBase
    constructor: (body, args, kwargs) ->
        throw 'module cannot be instantiated with a body' if body?
        
        @prototype = ['r', ['$fa', DEFAULT_FA], ['$fs', DEFAULT_FS], ['$fn', DEFAULT_FN]]
        @parseargs(args, kwargs)
        
        @r = @argshash.get('r')
        @center = @argshash.get('center')
        
        return
    
    toString: () ->
        return 'sphere(' + @formatargs() + ')'

class Cylinder extends GeometryBase
    constructor: (body, args, kwargs) ->
        throw 'module cannot be instantiated with a body' if body?
        
        @prototype = [['h', 1], ['r', null], ['r1', null], ['r2', null], ['center', false], ['$fn', DEFAULT_FN], ['$fa', DEFAULT_FA], ['$fs', DEFAULT_FS]]
        @parseargs(args, kwargs)
        
        @height = @argshash.get('h')
        
        r = @argshash.get('r')
        if r != null
            @r1 = r
            @r2 = r
        else
            @r1 = @argshash.get('r1')
            @r2 = @argshash.get('r2')
            if @r1 == null and @r2 == null
                @r1 = 1
                @r2 = 1
            else if @r1 == null or @r2 == null
                throw 'either "r" or "r1"/"r2" must be specified for cylinder()'
        
        @center = @argshash.get('center')
        
        return
    
    toString: () ->
        return 'cylinder(' + @formatargs() + ')'

class Cube extends GeometryBase
    constructor: (body, args, kwargs) ->
        throw 'module cannot be instantiated with a body' if body?
        
        @prototype = ['size', ['center', false]]
        @parseargs(args, kwargs)
        
        @size = @argshash.get('size')
        
        if typeof @size == 'number'
            @x = @size
            @y = @size
            @z = @size
        else if @size instanceof VectorIterator and @size.values.length == 3
            @x = @size.values[0]
            @y = @size.values[1]
            @z = @size.values[2]
        else
            throw "parameter `size' of cube() should evaluate to a 3-value vector or a number (got: " + @size.toString() + ")"
        
        @center = @argshash.get('center')
        
        return
    
    toString: () ->
        return 'cube(' + @formatargs() + ')'

class JsPassThrough
    constructor: (@fct) -> return
    passthrough: (self, args) -> @fct.apply(self, args)

class OpenSCADEvaluator
    """ this class walks through the language representation and builds the geometry representation """
    constructor: (@root_node) ->
        return
    
    evaluate: (ctx) ->
        return @walk(ctx, @root_node)
    
    register_builtins: (ctx) ->
        """ register the built-in modules in the current scope. """
        
        ctx.set 'echo', Echo
        
        ctx.set 'str', new JsPassThrough(() -> (arg.toString() for arg in arguments).join(''))
        ctx.set 'sign', new JsPassThrough((n) ->
            return 1.0 if n > 1
            return -1.0 if n < 1
            return 0)
        
        ctx.set 'abs', new JsPassThrough((n) -> Math.abs(n * Math.PI / 180))
        ctx.set 'acos', new JsPassThrough((n) -> Math.acos(n * Math.PI / 180))
        ctx.set 'asin', new JsPassThrough((n) -> Math.asin(n * Math.PI / 180) )
        ctx.set 'atan', new JsPassThrough((n) -> Math.atan(n * Math.PI / 180))
        ctx.set 'atan2', new JsPassThrough((n) -> Math.atan2(n * Math.PI / 180))
        ctx.set 'ceil', new JsPassThrough(Math.ceil)
        ctx.set 'cos', new JsPassThrough((n) -> Math.cos(n * Math.PI / 180))
        ctx.set 'exp', new JsPassThrough(Math.exp)
        ctx.set 'floor', new JsPassThrough(Math.floor)
        ctx.set 'ln', new JsPassThrough(Math.log)
        ctx.set 'len', new JsPassThrough((obj) ->
            if (obj instanceof VectorIterator)
                return obj.values.length
            if (typeof obj == 'string')
                return obj.length
            throw 'cannot get length of this object type')
        ctx.set 'max', new JsPassThrough(Math.max)
        ctx.set 'min', new JsPassThrough(Math.min)
        ctx.set 'pow', new JsPassThrough(Math.pow)
        ctx.set 'sin', new JsPassThrough((n) -> Math.sin(n * Math.PI / 180))
        ctx.set 'sqrt', new JsPassThrough(Math.sqrt)
        ctx.set 'tan', new JsPassThrough(Math.tan)
        ctx.set 'rands', new JsPassThrough((min_value, max_value, value_count, seed_value) =>
            new VectorIterator(((Math.random() * (max_value-min_value)) + min_value) for i in [0..value_count]))
        ctx.set 'round', new JsPassThrough(Math.round)
        
        ctx.set 'union', Union
        ctx.set 'difference', Difference
        ctx.set 'intersection', Intersection
        ctx.set 'rotate', Rotate
        ctx.set 'translate', Translate
        # TODO: ctx.set 'scale', Scale
        ctx.set 'multmatrix', MultMatrix
        # TODO: ctx.set 'mirror', Mirror
        # TODO: ctx.set 'color', Color
        # TODO: ctx.set 'polygon', Polygon
        # TODO: ctx.set 'linear_extrude', LinearExtrude
        ctx.set 'render', Render
        
        ctx.set 'polyhedron', Polyhedron
        ctx.set 'cube', Cube
        ctx.set 'sphere', Sphere
        ctx.set 'cylinder', Cylinder
        
    
    walk: (ctx, node) ->
        
        if not node?
            return
        
        nodetype = node.constructor.name
        switch nodetype
            when "Assignment"
                """ set the proper value in the current context. """
                
                id = node.identifier.name
                expr = @walk(ctx, node.expression)
                ctx.set(id, expr)
                return
            
            when "ModuleDefinition", "FunctionDefinition"
                """ store the node itself in the context to delegate its instanciation to whenever it is actually used """
                id = node.identifier.name
                ctx.set(id, node)
                return
            
            when "Assign"
                """ introduce the variables in the current context and continue evaluating the sub-blocks """
                
                [args, kwargs] = @walk(ctx, node.arguments)
                
                if args.length > 0
                    # FIXME: don't allow them in the language in the first place
                    throw 'assign() cannot make use of unnamed arguments'
                
                new_ctx = new Context(ctx, kwargs)
                    
                objects = []
                obj = @walk(new_ctx, node.body)
                return if not obj?
                
                if obj instanceof Array
                    objects = objects.concat(obj)
                else
                    objects.push obj
                
                return if objects.length == 0
                return objects[0] if objects.length == 1
                
                ret = new Union(new Objects(objects))
                
                return ret
            
            when "For", "IntersectionFor"
                """ unroll the loop and return the resulting list of objects """
                
                id = @walk(ctx, node.identifier)
                [variable, iterator] = @walk(ctx, node.arguments)
                
                if not (iterator instanceof Iterator)
                    throw 'for() loops take range or vector as argument (got ' + (iterator) + ')'
                
                new_ctx = new Context(ctx)
                
                objects = []
                while((value = iterator.next()) != undefined)
                    new_ctx.set(variable, value)
                    obj = @walk(new_ctx, node.body)
                    continue if not obj?
                    
                    if obj instanceof Array
                        objects = objects.concat(obj)
                    else
                        objects.push obj
                    
                
                ret = new Objects(objects)
                if nodetype == 'IntersectionFor'
                    ret = new Intersection(ret) 
                else
                    ret = new Union(ret)
                return ret
            
            when "IfElseStatement"
                
                condition = @walk(ctx, node.condition)
                if condition
                    return @walk(ctx, node.body)
                else if node.else_body?
                    return @walk(ctx, node.else_body)
                
                return
            
            when "ModuleBody", "CurlyBraces"
                """ the ModuleBody is implicitly a union, whereas CurlyBraces only imply a list of objects
                    
                    For proper scoping, we need to first evaluate any module, functions and assignments and
                    insert those in the current context. Then we can process other statements.
                """
                
                # process modules, functions and assignments
                for expr in node.children
                    if expr.constructor.name in ['ModuleDefinition', 'FunctionDefinition', 'Assignment']
                        @walk(ctx, expr)
                
                # get all the rest in the scope
                objects = []
                for expr in node.children
                    continue if expr.constructor.name in ['ModuleDefinition', 'FunctionDefinition', 'Assignment']
                    
                    obj = @walk(ctx, expr)
                    continue if not obj?
                    
                    if obj instanceof Array
                        objects = objects.concat(obj)
                    else
                        objects.push obj
                
                return undefined if objects.length == 0
                return objects[0] if objects.length == 1
                
                ret = new Objects(objects)
                ret = new Union(ret) if nodetype == 'ModuleBody'
                
                return ret
            
            when "ModuleInstantiation"
                """ there are two types of instantiations: the first type is all the built-in 
                    functions, the other type are the user-declared modules and functions.
                """
                
                ctor = @walk(ctx, node.identifier)
                
                if not ctor?
                    throw 'module or function "' + node.identifier.name + '" is not declared in this scope'
                
                if ctor.constructor.name in ['ModuleDefinition', 'FunctionDefinition']
                    """ the constructor is a module or function definition that is not yet evaluated """
                    b = new GeometryBase()
                    
                    if ctor.arguments?
                        [pargs, pkwargs] = @walk(ctx, ctor.arguments)
                        
                        b.prototype = pargs.concat([name, pkwargs.get(name)] for name in pkwargs.keys())
                    else
                        b.prototype = []
                    
                    [args, kwargs] = @walk(ctx, node.arguments)
                    b.parseargs(args, kwargs)
                    
                    # create a new context and introduce the current instanciation arguments into it
                    new_ctx = new Context(ctx, b.argshash)
                    m = @walk(new_ctx, ctor.body)
                    
                else
                    """ the constructor is one of our built-in geometry objects """
                    
                    if ctor instanceof JsPassThrough
                        
                        if node.body?
                            throw 'cannot instanciate ' + ctor.toString() + ' with a body'
                        
                        [args, kwargs] = @walk(ctx, node.arguments)
                        if kwargs.size() > 0
                            throw 'cannot use named arguments with function ' + ctor.toString()
                        
                        m = ctor.passthrough(@, args)
                    else
                        
                        [args, kwargs] = @walk(ctx, node.arguments)
                        body = @walk(ctx, node.body) if node.body?
                        
                        m = new ctor(body, args, kwargs)
                
                return m
            
            when "Identifier" then return ctx.get(node.name)
            when "Dereference" then return @dereference(ctx, @walk(ctx, node.expression), @walk(ctx, node.identifier))
            when "Range" then return new RangeIterator(@walk(ctx, node.start), (if node.increment? then @walk(ctx, node.increment) else 1), @walk(ctx, node.end))
            when "Vector" then return new VectorIterator(@walk(ctx, value) for value in node.children)
            when "Expression" then return node.value
            when "Multiply" then return @walk(ctx, node.left) * @walk(ctx, node.right)
            when "Divide" then return @walk(ctx, node.left) / @walk(ctx, node.right)
            when "Modulo" then return @walk(ctx, node.left) % @walk(ctx, node.right)
            when "Plus" then return @walk(ctx, node.left) + @walk(ctx, node.right)
            when "Minus" then return @walk(ctx, node.left) - @walk(ctx, node.right)
            when "LessThan" then return @walk(ctx, node.left) < @walk(ctx, node.right)
            when "LowerEqual" then return @walk(ctx, node.left) <= @walk(ctx, node.right)
            when "Equal" then return @walk(ctx, node.left) == @walk(ctx, node.right)
            when "NotEqual" then return @walk(ctx, node.left) != @walk(ctx, node.right)
            when "GreaterEqual" then return @walk(ctx, node.left) >= @walk(ctx, node.right)
            when "MoreThan" then return @walk(ctx, node.left) > @walk(ctx, node.right)
            when "And" then return @walk(ctx, node.left) and @walk(ctx, node.right)
            when "Or" then return @walk(ctx, node.left) or @walk(ctx, node.right)
            when "Negate" then return not @walk(ctx, node.expression)
            when "UnaryMinus" then return -@walk(ctx, node.expression)
            when "TernaryIf" then return (if @walk(ctx, node.condition) then @walk(ctx, node.true_expression) else @walk(ctx, node.false_expression))
            when "Index"
                idx = @walk(ctx, node.index)
                expr = @walk(ctx, node.expression)
                
                if expr instanceof VectorIterator
                    ret = expr.values[idx]
                else if typeof expr == 'string'
                    ret = expr[idx]
                else
                    throw 'cannot index this type of object'
                
                return ret
            #when "Call" then return @call(ctx, @walk(ctx, node.identifier), @walk(ctx, node.arguments))
            when "ArgumentList"
                """ An argument list can either be used in the context of a prototype declaration (module, function) or 
                    in the context of a function call (aka module instantiation). """
                args = []
                kwargs = new Hash()
                for arg in node.args
                    [k, v] = @walk(ctx, arg)
                    if k?
                        kwargs.set(k, v)
                    else
                        args.push v
                return [args, kwargs]
            when "ArgumentDeclaration"
                defaultvalue = @walk(ctx, node.defaultvalue)
                console.log ['arg-decl default value:', defaultvalue]
                return [node.identifier.name, defaultvalue]
            when "CallArgument" then return [(if node.identifier? then node.identifier.name else undefined), @walk(ctx, node.value)]
            else
                throw 'unknown language construct: ' + node.constructor.name
        
        return





