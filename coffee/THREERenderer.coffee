

class THREERenderer

    constructor: (@scene, @material_parameters) ->
    
        @material_parameters ?= {}
        @material_parameters['color'] ?= new THREE.Color(0xff5566)
        @material_parameters['vertexColors'] ?= new THREE.Color(0xffffff)
        @material_parameters['refractionRatio'] ?= 0.1
    
        @debug = yes
        
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
                    vertex.y = vector.values[2]
                    vertex.z = vector.values[1]
                    
                    geometry.vertices.push(vertex)
                
                for vector in triangles
                    vertex = new THREE.Face3();
                    vertex.a = vector.values[0]
                    vertex.b = vector.values[1]
                    vertex.c = vector.values[2]
                    
                    geometry.faces.push( vertex )
                
                #geometry.colors = colors;
                
                geometry.computeCentroids();
                geometry.mergeVertices();
                
                console.log ['polyhedron', geometry] if @debug
                return geometry
                
            when 'Sphere'
                geometry = new THREE.SphereGeometry(node.r)
                console.log ['sphere', geometry] if @debug
                return geometry
                
            when 'Cube'
                geometry = new THREE.CubeGeometry(node.x, node.z, node.y)
                
                if not node.center
                    # apply translation matrix to center the object
                    geometry.applyMatrix(new THREE.Matrix4(
                        1,0,0, node.x / 2,
                        0,1,0, node.z / 2,
                        0,0,1, node.y / 2,
                        0,0,0, 1))
                
                console.log ['cube', geometry] if @debug
                return geometry
                
            when 'Cylinder'
                geometry = new THREE.CylinderGeometry(node.r2, node.r1, node.height)
                
                material = new THREE.MeshBasicMaterial(@material_parameters)
                mesh = new THREE.Mesh(geometry, material)
                
                if not node.center
                    mesh.position.y += node.height / 2
                
                console.log ['cylinder', geometry] if @debug
                return mesh
                
            when 'Objects'
                list = (@render(obj) for obj in node.objects)
                console.log ['objects', geometry] if @debug
                return list.compact()
            
            when 'Union'
                
                list = @render(node.body)
                return if not list?
                
                list = [list] if not (list instanceof Array)
                list = list.compact()
                
                """
                union = THREE.CSG.toCSG(list[0]);
                
                for child in list.slice(1)
                    csg = THREE.CSG.toCSG(child)
                    union = union.union(csg)
                
                geometry = THREE.CSG.fromCSG(union)
                material = new THREE.MeshBasicMaterial(@material_parameters)
                
                mesh = new THREE.Mesh(geometry, material)
                
                console.log ['union', geometry] if @debug
                return mesh"""
                
                geometry = new THREE.Geometry()
                material = new THREE.MeshBasicMaterial(@material_parameters)
                
                mesh = new THREE.Mesh(geometry, material)
                
                #console.log list
                
                mesh.add(child) for child in list
                
                console.log ['union', geometry] if @debug
                return mesh
            
            when 'Difference'
                
                #var cube = THREE.CSG.toCSG(new THREE.CubeGeometry( 2, 2, 2 ));
                #var sphere = THREE.CSG.toCSG(new THREE.SphereGeometry(1.4, 16, 16));
                #var geometry = THREE.CSG.fromCSG( sphere.subtract(cube) );
                #var mesh = new THREE.Mesh(geometry, new THREE.MeshNormalMaterial());
                
                geometry = new THREE.ExtrudeGeometry()
                material = new THREE.MeshBasicMaterial(@material_parameters)
                
                mesh = new THREE.Mesh(geometry, material)
                
                #console.log list
                
                mesh.add(child) for child in list
                
                console.log ['difference', geometry] if @debug
                return mesh
                
                
                list = @render(node.body)
                return list if not (list instanceof Array) or list.length <= 1
                list = list.compact()
                
                diff = THREE.CSG.toCSG(list[0]);
                
                for child in list.slice(1)
                    csg = THREE.CSG.toCSG(child)
                    diff = diff.subtract(csg)
                
                geometry = THREE.CSG.fromCSG(diff)
                material = new THREE.MeshBasicMaterial(@material_parameters)
                
                mesh = new THREE.Mesh(geometry, material)
                
                #console.log ['difference', mesh]
                console.log ['difference', geometry] if @debug
                return mesh
            
            when 'Intersection'
                
                #var cube = THREE.CSG.toCSG(new THREE.CubeGeometry( 2, 2, 2 ));
                #var sphere = THREE.CSG.toCSG(new THREE.SphereGeometry(1.4, 16, 16));
                #var geometry = THREE.CSG.fromCSG( sphere.subtract(cube) );
                #var mesh = new THREE.Mesh(geometry, new THREE.MeshNormalMaterial());
                
                list = @render(node.body)
                return list if not (list instanceof Array) or list.length <= 1
                list = list.compact()
                
                geometry = THREE.CSG.toCSG(list[0]);
                
                for child in list.slice(1)
                    csg = THREE.CSG.toCSG(child)
                    geometry = geometry.intersect(csg)
                
                geometry = THREE.CSG.fromCSG(geometry)
                material = new THREE.MeshBasicMaterial(@material_parameters)
                
                mesh = new THREE.Mesh(geometry, material)
                
                console.log ['intersection', geometry] if @debug
                return mesh
            
            when 'Translate'
                
                list = @render(node.body)
                list = [list] if not (list instanceof Array)
                list = list.compact()
                
                geometry = new THREE.Geometry()
                material = new THREE.MeshBasicMaterial(@material_parameters)
                
                mesh = new THREE.Mesh(geometry, material)
                
                mesh.add(child) for child in list
                
                mesh.position.x += node.x
                mesh.position.y += node.z
                mesh.position.z -= node.y
                
                console.log ['translate', geometry] if @debug
                return mesh
            
            when 'Scale'
                
                list = @render(node.body)
                list = [list] if not (list instanceof Array)
                list = list.compact()
                
                geometry = new THREE.Geometry()
                material = new THREE.MeshBasicMaterial(@material_parameters)
                
                mesh = new THREE.Mesh(geometry, material)
                
                console.log list
                
                mesh.add(child) for child in list
                
                mesh.scale.x = node.x
                mesh.scale.y = node.z
                mesh.scale.z = node.y
                
                console.log ['scale', geometry] if @debug
                return mesh
            
            when 'Rotate'
                
                #console.log ['rotate', node.body]
                list = @render(node.body)
                list = [list] if not (list instanceof Array)
                list = list.compact()
                
                
                geometry = new THREE.Geometry()
                material = new THREE.MeshBasicMaterial(@material_parameters)
                
                mesh = new THREE.Mesh(geometry, material)
                
                console.log list
                
                mesh.add(child) for child in list
                
                mesh.rotation.x += (node.degree * node.x) * 0.0174532925
                mesh.rotation.y += (node.degree * node.z) * 0.0174532925
                mesh.rotation.z -= (node.degree * node.y) * 0.0174532925
                
                console.log ['rotate', geometry] if @debug
                return mesh
            else
                throw 'Cannot render type "' + nodetype + '"'
        
        return
