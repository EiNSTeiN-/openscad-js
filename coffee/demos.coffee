
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
            
            console.log ['exception', e]
            console.log ['exception', e.stack]
            msg = e.toString()
            msg = msg.replace(/\n/g, '<br />')
            msg += '<br />'
            msg += e.stack
            
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
            
            console.log ['exception', e]
            console.log ['exception', e.stack]
            
            msg = e.toString()
            msg = msg.replace(/\n/g, '<br />')
            msg += '<br />'
            msg += e.stack
            
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
        
        @filetext = """
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
        
        @initeditor()
        
        @parser = new lexer.Parser()
        
        @width = 700
        @height = 480
    
        @zoom = 20
        @zoom_speed = 5
        
        @move_theta = 45
        @move_phi = 60
        @radius = 1600
        
        @initrenderer()
        
        @scene = new THREE.Scene()
        @initcamera()
        @initlights()
        @initgrid()
        @initcontrols()
        
        @select('#wireframe')[0].observe 'click', (e) => @update(e)
        @select('#submit')[0].observe 'click', (e) => @update(e)
        
        @update()
        @animate()
        
        return
    
    initeditor: () ->
        
        @editor_div = new Element('div', {id: 'editor', style: 'width: 490px; height: 480px;'})
        @select('#file-parent')[0].insert @editor_div
        @editor_div.update @filetext
        
        @editor = ace.edit(@editor_div)
        @editor.setTheme("ace/theme/dawn")
        @editor.getSession().setMode("ace/mode/scad")
        
        return
    
    initcontrols: () ->
        @select('#scene')[0].observe 'mousewheel', (e) => @mousewheel(e)
        
        @controls = new THREE.TrackballControls( @camera, @renderer.domElement )

        @controls.rotateSpeed = 1.0
        @controls.panSpeed = 0.2

        @controls.noZoom = false
        @controls.noPan = false

        @controls.staticMoving = true
        @controls.dynamicDampingFactor = 0.3
        
        @controls.keys = [ 65, 83, 68 ]
        return
    
    mousewheel: (e) ->
        
        console.log ['wheel', @zoom, e.wheelDelta]
        
        @zoom += (if e.wheelDelta > 0 then -@zoom_speed else @zoom_speed)
        @camera.fov = @zoom
        @camera.updateProjectionMatrix()
        
        @render()
        
        return
    
    initcamera: () ->
        @view_angle = 10
        @aspect = @width / @height
        @near = 1
        @far = 10000
        
        @camera = new THREE.PerspectiveCamera(@zoom, @aspect, @near, @far)
        @camera.position.y = -450;
        @camera.position.z = 400;
        
        @camera.lookAt(new THREE.Vector3(0, 0, 0));
        
        @scene.add(@camera)
        
        return
    
    initrenderer: () ->
    
        params = 
            clearColor: 0x00000000
            clearAlpha: 0
            antialias: true
        @renderer = new THREE.CanvasRenderer(params);
        @renderer.clear()
        @renderer.setSize(@width, @height);
        @renderer.shadowMapEnabled = true
        @renderer.shadowMapAutoUpdate = true
        
        @select('#scene')[0].insert @renderer.domElement
        @select('#scene')[0].setStyle
            backgroundColor: '#ffffff'
        
        return
    
    initlights: () ->
        ambientLight = new THREE.AmbientLight( 0x404040 )
        @scene.add( ambientLight )

        directionalLight = new THREE.DirectionalLight( 0xffffff )
        directionalLight.position.x = 1
        directionalLight.position.y = 1
        directionalLight.position.z = 0.75
        directionalLight.position.normalize()
        @scene.add( directionalLight )

        directionalLight = new THREE.DirectionalLight( 0x808080 )
        directionalLight.position.x = - 1
        directionalLight.position.y = 1
        directionalLight.position.z = - 0.75
        directionalLight.position.normalize()
        @scene.add( directionalLight )
        
        return
    
    initgrid: () ->
        @grid_size = 200
        @grid_spacing = 10
        
        geometry = new THREE.Geometry()
        geometry.vertices.push( new THREE.Vector3( -@grid_size/2, 0, 0 ) )
        geometry.vertices.push( new THREE.Vector3( @grid_size/2, 0, 0 ) )

        material = new THREE.LineBasicMaterial( { color: 0x000000, opacity: 0.4 } )

        for i in [0..20]

            line = new THREE.Line( geometry, material )
            line.position.y = (i * @grid_spacing) - (@grid_size / 2)
            @scene.add( line )

            line = new THREE.Line( geometry, material )
            line.position.x = (i * @grid_spacing) - (@grid_size / 2)
            line.rotation.z = 90 * Math.PI / 180
            @scene.add( line )

        
        return
    
    animate: () ->
        #console.log ['animate...', @animate]
        requestAnimationFrame(() => @animate())
        @render()
        return
    
    render: () ->
        @controls.update()
        @renderer.render(@scene, @camera)
        return
    
    update: () ->
        
        tree = @parser.parse @editor.getValue()
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
        
        @scene.add @mesh
        
        @select('#errors')[0].hide()
        @select('#scene')[0].show()
        
        @render()
        
        try
            x=1
        catch e
            
            @select('#scene')[0].hide()
            @select('#errors')[0].show()
            
            msg = e.toString()
            msg = msg.replace(/\n/g, '<br />')
            
            @select('#errors')[0].update('<pre>' + msg + '</pre>')
            
        
        return

Event.observe window, 'load', () ->
    o = new App()
    $('body').insert o
