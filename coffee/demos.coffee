
class App
    # New photo instance freshly uploaded to the server.
    
    constructor: (options) ->
        @self = new Element('div', options)
        Object.extend(@self, App.prototype)
        @self.init()
        return @self
    
    init: () ->
        
        t = """
        <div>
            <div style="float: left; width: 800px; height: 20px; border: 1px #808080 solid; padding: 4px;">
                demos:&nbsp;
                <a href="#demo/lexer" id="lexer">lexer</a>
                <a href="#demo/evaluator" id="evaluator">evaluator</a>
                <a href="#demo/3render" id="3render">THREE render</a>
            </div>
            <div id="demo" style="float: left; border: 0px #808080 solid; padding: 4px;">
                
            </div>
        </div>
        """
        
        data = {}
        
        @insert new Template(t).evaluate(data)
        
        @select('#lexer')[0].observe 'click', (e) => @show_demo(LexerDemo)
        @select('#evaluator')[0].observe 'click', (e) => @show_demo(EvaluatorDemo)
        @select('#3render')[0].observe 'click', (e) => @show_demo(THREERenderDemo)
        
        demo = @anchor_demo()
        demo = 'lexer' if not demo?
        if demo?
            @show_demo(LexerDemo) if demo == 'lexer'
            @show_demo(EvaluatorDemo) if demo == 'evaluator'
            @show_demo(THREERenderDemo) if demo == '3render'
        
        return
    
    anchor_demo: () ->
        
        demo = document.location.href.match(/#demo\/(.+)/i)
        
        if demo and demo.length >= 2
            return demo[1]
        
        return
    
    cleanup: () ->
        @select('#demo')[0].update ''
    
    show_demo: (ctor) ->
        
        @cleanup()
        
        @demo = new ctor()
        @select('#demo')[0].insert @demo
        
        return

class LexerDemo
    # New photo instance freshly uploaded to the server.
    
    constructor: (options) ->
        @self = new Element('div', options)
        Object.extend(@self, LexerDemo.prototype)
        @self.init()
        return @self
    
    init: () ->
        
        file = """
for(i = [ [ 0,  0,  0],
           [10, 12, 10],
           [20, 24, 20],
           [30, 36, 30],
           [20, 48, 40],
           [10, 60, 50] ])
{
    translate(i)
    cube([50, 15, 10], center = true);
}
        """
        
        t = """
        <div>
            <div style="float: left; width: 500px; height: 500px; border: 0px #808080 solid; padding: 4px;">
                <textarea id="file" style="width: 496px; height: 480px;">#{file}</textarea>
                <input id="submit" type="button" value="OK" />
                <input type="radio" id="displaystyle" name="displaystyle" value="pprint" checked="checked" /> Pretty printed
                <input type="radio" id="displaystyle" name="displaystyle" value="dump" /> Formatted
            </div>
            <textarea id="output" style="float: left; width: 700px; height: 500px; margin: 4px;"></textarea>
            <div id="errors" style="overflow: auto; width: 700px; height: 500px; color: red;"></div>
        </div>
        """
        
        data = {}
        
        @insert new Template(t).evaluate(data)
        
        @parser = new lexer.Parser()
        
        @select('#submit')[0].observe 'click', (e) => @update(e)
        for el in @select('#displaystyle')
            el.observe 'click', (e) => @update(e)
        
        @update()
        
        return
    
    update: () ->
        
        try
            text = @parser.parse @select('#file')[0].value
            
            style = (x.value for x in @select('#displaystyle') when x.checked)[0]
            if style == 'pprint'
                output = text.pprint()
            else
                output = text.dump()
            
            
            @select('#errors')[0].hide()
            @select('#output')[0].show()
            
            @select('#output')[0].value = output
        catch e
            
            @select('#output')[0].hide()
            @select('#errors')[0].show()
            
            msg = e.toString()
            msg = msg.replace(/\n/g, '<br />')
            
            @select('#errors')[0].update('<pre>' + msg + '</pre>')
        
        return

class EvaluatorDemo
    # New photo instance freshly uploaded to the server.
    
    constructor: (options) ->
        @self = new Element('div', options)
        Object.extend(@self, EvaluatorDemo.prototype)
        @self.init()
        return @self
    
    init: () ->
        
        file = """
for(i = [ [ 0,  0,  0],
           [10, 12, 10],
           [20, 24, 20],
           [30, 36, 30],
           [20, 48, 40],
           [10, 60, 50] ])
{
    translate(i)
    cube([50, 15, 10], center = true);
}
        """
        
        t = """
        <div>
            <div style="float: left; width: 500px; height: 500px; border: 0px #808080 solid; padding: 4px;">
                <textarea id="file" style="width: 496px; height: 480px;">#{file}</textarea>
                <input id="submit" type="button" value="OK" />
            </div>
            <textarea id="output" style="float: left; width: 700px; height: 500px; margin: 4px;"></textarea>
            <div id="errors" style="overflow: auto; width: 700px; height: 500px; color: red;"></div>
        </div>
        """
        
        data = {}
        
        @insert new Template(t).evaluate(data)
        
        @parser = new lexer.Parser()
        
        @select('#errors')[0].hide()
        @select('#submit')[0].observe 'click', (e) => @update(e)
        
        @update()
        
        return
    
    update: () ->
        
        try
            text = @parser.parse @select('#file')[0].value
        
            evaluator = new OpenSCADEvaluator(text)
            
            root_ctx = new Context()
            evaluator.register_builtins(root_ctx)
            
            s = evaluator.evaluate(root_ctx)
            
            @select('#errors')[0].hide()
            @select('#output')[0].show()
            
            @select('#output')[0].value = s
        catch e
            
            @select('#output')[0].hide()
            @select('#errors')[0].show()
            
            msg = e.toString()
            msg = msg.replace(/\n/g, '<br />')
            
            @select('#errors')[0].update('<pre>' + msg + '</pre>')
            
        
        return


class THREERenderDemo
    # New photo instance freshly uploaded to the server.
    
    constructor: (options) ->
        @self = new Element('div', options)
        Object.extend(@self, THREERenderDemo.prototype)
        @self.init()
        return @self
    
    init: () ->
        
        filetext = """
spool_diameter = 40;
spool_height = 90;
shell_width = 1.2;

difference() {
    union() {
        cylinder(r=spool_diameter/2, h = spool_height, center=true);
        translate([0,0,(spool_height/2)-1]) cylinder(r1=spool_diameter/2, r2=(spool_diameter/2)+2, h=2, center=true);
    }
    cylinder(r=(spool_diameter/2)-shell_width, h = spool_height+2, center=true);

    for(i = [0,90])
        rotate([0,0,i]) translate([0,0,14]) cube([2,spool_diameter+4,spool_height-14], center=true);
}

difference() {
    translate([0,0,-spool_height/2])
        cube([spool_diameter+4, spool_diameter+4, 4], center=true);
    
    for(holes = [0, 90]) {
        rotate([0, 0, holes])
            for(i = [(spool_diameter/2)-8,-((spool_diameter/2)-8)])
                translate([i,0,-spool_height/2]) cylinder(r = 4/2, h=5, center=true);
    }
}
        """
        filetext="""
for(i = [ [ 0,  0,  0],
           [10, 12, 10],
           [20, 24, 20],
           [30, 36, 30],
           [20, 48, 40],
           [10, 60, 50] ])
{
    translate(i)
    cube([50, 15, 10], center = true);
}"""
        
        t = """
        <div>
            <div style="float: left; width: 500px; height: 500px; border: 0px #808080 solid; padding: 4px;">
                <div id="file-parent"></div>
                <input id="submit" type="button" value="OK" />
            </div>
            <div id="scene" style="float: left; width: 700px; height: 480px; border: 1px #808080 solid; margin: 4px;"></div>
            <div id="errors" style="overflow: auto; width: 700px; height: 480px; color: red;"></div>
            <div style="margin: 4px;">
                <span id="zoom">Current zoom: </span>
                <input type="checkbox" id="wireframe" /> Wireframe
            </div>
        </div>
        """
        
        data = {}
        
        @insert new Template(t).evaluate(data)
        
        @editor = new TextEditor({id: 'editor', style: 'width: 490px; height: 480px;'})
        @select('#file-parent')[0].insert @editor
        @editor.update filetext
            
        @initial_zoom = 100
        @zoom_increment = 25
        
        @initscene()
        @animate()
        
        @parser = new lexer.Parser()
        
        @select('#wireframe')[0].observe 'click', (e) => @update(e)
        @select('#submit')[0].observe 'click', (e) => @update(e)
        sceneelement = @select('#scene')[0]
        sceneelement.observe 'mousewheel', (e) => @mousewheel(e)
        @select('#scene')[0].observe 'mousedown', (e) => @move_start(e)
        @select('#scene')[0].observe 'mouseup', (e) => @move_end(e)
        
        @camera_vector = new THREE.Vector3();
        @camera_vector.x = 0
        @camera_vector.y = 0
        @camera_vector.z = 0
        @camera.lookAt(@camera_vector)
        
        @update()
        
        return
    
    
    move_start: (e) ->
        
        #.rotation.y += ( targetRotation - parent.rotation.y ) * 0.05;
        
        
        return
    
    move_end: (e) ->
    
        
        return
    
    mousewheel: (e) ->
        @camera.position.z += if e.wheelDelta > 0 then @zoom_increment else -@zoom_increment;
        
        @select('#zoom')[0].update 'Current zoom: ' + @camera.position.z
        
        e.stop()
        return
    
    initscene: () ->
        
        #@camera_vector = new THREE.Vector3(45, 45, 45)
        
        @camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 1, 10000 );
        @camera.position.z = @initial_zoom;
        
        
        @select('#zoom')[0].update 'Current zoom: ' + @camera.position.z
        
        @scene = new THREE.Scene();
        
        @renderer = new THREE.CanvasRenderer();
        @renderer.setSize(780, 468);
        
        @select('#scene')[0].insert @renderer.domElement
        
        return
    
    update: () ->
        
        @scene = new THREE.Scene()
        
        tree = @parser.parse @select('#editor')[0].text
        
        evaluator = new OpenSCADEvaluator(tree)
        
        root_ctx = new Context()
        evaluator.register_builtins(root_ctx)
        
        s = evaluator.evaluate(root_ctx)
        
        params = 
            wireframe: @select('#wireframe')[0].checked
            opacity: 0.7
            color: new THREE.Color(0xcc0000)
            vertexColors: new THREE.Color(0)
            wireframeLinewidth: 2
        
        threerender = new THREERenderer(@scene)
        @geometry = threerender.render(s)
        
        console.log ['geometry', @geometry]
        
        material = new THREE.MeshBasicMaterial(params)
        @mesh = new THREE.Mesh(@geometry, material)
                
        #console.log @mesh
        
        @add_axis()
        
        @scene.add @mesh
        
        @select('#errors')[0].hide()
        @select('#scene')[0].show()
        
        @renderer.render(@scene, @camera)
        #@select('#scene')[0].update(s)
        try
            x=1
        catch e
            
            @select('#scene')[0].hide()
            @select('#errors')[0].show()
            
            msg = e.toString()
            msg = msg.replace(/\n/g, '<br />')
            
            @select('#errors')[0].update('<pre>' + msg + '</pre>')
            
        
        return
    
    add_axis: () ->
        
        geometry = new THREE.Geometry()
        geometry.vertices.push new THREE.Vector3(-50,0,0)
        geometry.vertices.push new THREE.Vector3(50,0,0)
        line = new THREE.Line( geometry, new THREE.LineBasicMaterial({ color: 0, opacity: 0.8 }))
        @mesh.add line
        
        font = {
                size: 4,
                height: 1,
                curveSegments: 2,
                font: "helvetiker"
            }
        
        geometry = new THREE.TextGeometry("x", font)
        mesh = new THREE.Mesh(geometry, new THREE.MeshBasicMaterial({color: 0}))
        mesh.position = new THREE.Vector3(55,0,0)
        mesh.rotation = new THREE.Vector3(0.1,0.1,0.1)
        @mesh.add mesh
        
        geometry = new THREE.Geometry();
        geometry.vertices.push new THREE.Vector3(0,-50,0)
        geometry.vertices.push new THREE.Vector3(0,50,0)
        line = new THREE.Line( geometry, new THREE.LineBasicMaterial({ color: 0, opacity: 1 }))
        @mesh.add line
        
        geometry = new THREE.TextGeometry("y", font)
        mesh = new THREE.Mesh(geometry, new THREE.MeshBasicMaterial({color: 0}))
        mesh.position = new THREE.Vector3(0,55,0)
        mesh.rotation = new THREE.Vector3(0.1,0.1,0.1)
        @mesh.add mesh
        
        geometry = new THREE.Geometry();
        geometry.vertices.push new THREE.Vector3(0,0,-50)
        geometry.vertices.push new THREE.Vector3(0,0,50)
        line = new THREE.Line( geometry, new THREE.LineBasicMaterial({ color: 0, opacity: 0.8 }))
        @mesh.add line
        
        geometry = new THREE.TextGeometry("z", font)
        mesh = new THREE.Mesh(geometry, new THREE.MeshBasicMaterial({color: 0}))
        mesh.position = new THREE.Vector3(0,0,55)
        @mesh.add mesh
        
        return
    
    animate: () ->
        
        # note: three.js includes requestAnimationFrame shim
        requestAnimationFrame( () => @animate() );
        
        if @mesh?
            #@mesh.rotation.x = (20 * 0.0174532925);
            #@mesh.rotation.y = (-20 * 0.0174532925);
        
            @camera.position.z = 80
            @camera.position.y = -65
            @camera.position.x = 50
            #@camera.position.z = 100
            
            @camera.rotation.y = (0 * 0.0174532925)
            @camera.rotation.x = (45 * 0.0174532925)
            @camera.rotation.z = (0 * 0.0174532925)
            
            @camera_vector.x = 0
            @camera_vector.y = 0
            @camera_vector.z = 0
            #@camera.lookAt(@camera_vector)
            
            @mesh.rotation.z += -0.01;
            
            #@camera.position.z = 100;
            #@camera.position.z = 500;
        
            #@mesh.rotation.y = (45 * 0.0174532925);
            #@mesh.rotation.x += 0.01;
            #@mesh.rotation.y += 0.02;
        
        @renderer.render( @scene, @camera );
        
        return

Event.observe window, 'load', () ->
    o = new App()
    $('body').insert o
