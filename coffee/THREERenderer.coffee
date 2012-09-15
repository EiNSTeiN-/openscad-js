

class THREERenderer

    constructor: (@scene, @material_parameters) ->
    
        @material_parameters ?= {}
        @material_parameters['color'] ?= new THREE.Color(0xff5566)
        @material_parameters['vertexColors'] ?= new THREE.Color(0)
        @material_parameters['refractionRatio'] ?= 5
        @material_parameters['wireframeLinewidth'] ?= 2
    
        @debug = yes
        
        return

    apply_rotation_matrix: (geometry, angles) ->
        
        if angles.x? and angles.x > 0
            angle = angles.x * 0.0174532925
            geometry.applyMatrix(new THREE.Matrix4(
                1,0,0, 0,
                0,Math.cos(angle),-Math.sin(angle), 0,
                0,Math.sin(angle),Math.cos(angle), 0,
                0,0,0, 1))
        
        if angles.y? and angles.y > 0
            angle = angles.y * 0.0174532925
            geometry.applyMatrix(new THREE.Matrix4(
                Math.cos(angle), 0, Math.sin(angle), 0,
                0,1,0, 0,
                -Math.sin(angle),0,Math.cos(angle), 0,
                0,0,0, 1))
        
        if angles.z? and angles.z > 0
            angle = angles.z * 0.0174532925
            geometry.applyMatrix(new THREE.Matrix4(
                Math.cos(angle),-Math.sin(angle), 0, 0,
                Math.sin(angle),Math.cos(angle), 0, 0,
                0, 0, 1, 0,
                0,0,0, 1))
        
        return
    
    apply_translation_matrix: (geometry, positions) ->
    
        x = positions.x
        x ?= 0
        
        y = positions.y
        y ?= 0
        
        z = positions.z
        z ?= 0
        
        geometry.applyMatrix(new THREE.Matrix4(
            1,0,0, x,
            0,1,0, y,
            0,0,1, z,
            0,0,0, 1))
        
        return
    
    render: (node) ->
        
        
        nodetype = node.constructor.name
        switch nodetype
            when 'Echo'
                console.log node.args.join()
                return
            
            when 'Polyhedron'
                geometry = new THREE.Geometry()
                
                # node.points is a VectorIterator containing more VectorIterator
                points = node.points.values
                triangles = node.triangles.values
                
                for vector in points
                    vertex = new THREE.Vector3();
                    vertex.x = vector.values[0]
                    vertex.y = vector.values[1]
                    vertex.z = vector.values[2]
                    
                    geometry.vertices.push(vertex)
                
                for vector in triangles
                    vertex = new THREE.Face3();
                    vertex.a = vector.values[0]
                    vertex.b = vector.values[1]
                    vertex.c = vector.values[2]
                    
                    geometry.faces.push( vertex )
                
                geometry.computeCentroids();
                geometry.mergeVertices();
                
                console.log ['polyhedron', geometry] if @debug
                return geometry
                
            when 'Sphere'
                geometry = new THREE.SphereGeometry(node.r)
                console.log ['sphere', geometry] if @debug
                return geometry
                
            when 'Cube'
                geometry = new THREE.CubeGeometry(node.x, node.y, node.z)
                
                if not node.center
                    # apply translation matrix to avoid centering the object
                    @apply_translation_matrix(geometry, {x: node.x / 2, y: node.y / 2, z: node.z / 2})
                
                console.log ['cube', geometry] if @debug
                return geometry
                
            when 'Cylinder'
                geometry = new THREE.CylinderGeometry(node.r2, node.r1, node.height)
                
                @apply_rotation_matrix(geometry, {x: 90})
                
                if not node.center
                    @apply_translation_matrix(geometry, {z: node.height/2})
                
                console.log ['cylinder', geometry] if @debug
                return geometry
                
            when 'Objects'
                list = (@render(obj) for obj in node.objects)
                list = list.compact()
                console.log ['objects', list] if @debug
                return list[0] if list.length == 1
                return list
            
            when 'Union'
                
                list = @render(node.body)
                return if not list?
                return list if not (list instanceof Array) or list.length <= 1
                list = list.compact()
                
                union = THREE.CSG.toCSG(list[0]);
                
                for child in list.slice(1)
                    csg = THREE.CSG.toCSG(child)
                    union = union.union(csg)
                
                geometry = THREE.CSG.fromCSG(union)
                
                console.log ['union', geometry] if @debug
                return geometry
            
            when 'Difference'
                
                list = @render(node.body)
                return if not list?
                return list if not (list instanceof Array) or list.length <= 1
                list = list.compact()
                
                diff = THREE.CSG.toCSG(list[0]);
                
                for child in list.slice(1)
                    csg = THREE.CSG.toCSG(child)
                    diff = diff.subtract(csg)
                
                geometry = THREE.CSG.fromCSG(diff)
                
                console.log ['difference', geometry] if @debug
                return geometry
            
            when 'Intersection'
                
                list = @render(node.body)
                return list if not (list instanceof Array) or list.length <= 1
                list = list.compact()
                
                geometry = THREE.CSG.toCSG(list[0]);
                
                for child in list.slice(1)
                    csg = THREE.CSG.toCSG(child)
                    geometry = geometry.intersect(csg)
                
                geometry = THREE.CSG.fromCSG(geometry)
                
                console.log ['intersection', geometry] if @debug
                return geometry
            
            when 'Translate'
                
                list = @render(node.body)
                list = [list] if not (list instanceof Array)
                list = list.compact()
                
                for geometry in list
                    @apply_translation_matrix(geometry, {x: node.x, y: node.y, z: node.z})
                
                console.log ['translate', list] if @debug
                return list[0] if list.length == 1
                return list
            
            when 'Scale'
                
                list = @render(node.body)
                list = [list] if not (list instanceof Array)
                list = list.compact()
                
                #for child in list
                    #@apply_scale_matrix(child, {x: node.x, y: node.y, z: node.z})
                
                console.log ['scale', list] if @debug
                return list[0] if list.length == 1
                return list
            
            when 'MultMatrix'
                
                list = @render(node.body)
                list = [list] if not (list instanceof Array)
                list = list.compact()
                
                for child in list
                    child.applyMatrix(new THREE.Matrix4(node.n11, node.n12, node.n13, node.n14,
                                                    node.n21, node.n22, node.n23, node.n24,
                                                    node.n31, node.n32, node.n33, node.n34,
                                                    node.n41, node.n42, node.n43, node.n44))
                
                console.log ['multmatrix', list] if @debug
                return list[0] if list.length == 1
                return list
            
            when 'Rotate'
                
                #console.log ['rotate', node.body]
                list = @render(node.body)
                list = [list] if not (list instanceof Array)
                list = list.compact()
                
                for child in list
                    @apply_rotation_matrix(child, {x: node.degree * node.x, y: node.degree * node.y, z: node.degree * node.z})
                
                console.log ['rotate', list] if @debug
                return list[0] if list.length == 1
                return list
            else
                throw 'Cannot render type "' + nodetype + '"'
        
        return
