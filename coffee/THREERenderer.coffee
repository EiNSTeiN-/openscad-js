

class THREERenderer

    constructor: (@scene, @params) ->
        
        @params ?= {}
        @params['default_color'] ?= new THREE.Color(0xff5566)
        
        @debug = yes
        
        return
    
    render: (node) ->
        return if not node?
        
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
                    # apply translation matrix to revert automatic centering of the object
                    geometry.applyMatrix(new THREE.Matrix4(
                        1,0,0, node.x / 2,
                        0,1,0, node.y / 2,
                        0,0,1, node.z / 2,
                        0,0,0, 1))
                
                console.log ['cube', geometry] if @debug
                return geometry
                
            when 'Cylinder'
                geometry = new THREE.CylinderGeometry(node.r2, node.r1, node.height)
                
                # rotate 90 degree around x axis for consistency with openscad
                angle = 90 * 0.0174532925
                geometry.applyMatrix(new THREE.Matrix4(
                    1,0,0, 0,
                    0,Math.cos(angle),-Math.sin(angle), 0,
                    0,Math.sin(angle),Math.cos(angle), 0,
                    0,0,0, 1))
                
                if not node.center
                    geometry.applyMatrix(new THREE.Matrix4(
                        1,0,0, 0,
                        0,1,0, 0,
                        0,0,1, node.height / 2,
                        0,0,0, 1))
                
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
                    #console.log ['child', child]
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
                return if not list?
                return list if not (list instanceof Array) or list.length <= 1
                list = list.compact()
                
                geometry = THREE.CSG.toCSG(list[0]);
                
                for child in list.slice(1)
                    csg = THREE.CSG.toCSG(child)
                    geometry = geometry.intersect(csg)
                
                geometry = THREE.CSG.fromCSG(geometry)
                
                console.log ['intersection', geometry] if @debug
                return geometry
            
            when 'Color'
                
                list = @render(node.body)
                return if not list?
                list = [list] if not (list instanceof Array)
                list = list.compact()
                
                console.log ['color', list] if @debug
                return list[0] if list.length == 1
                return list
            
            when 'MultMatrix'
                
                list = @render(node.body)
                return if not list?
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
            
            else
                throw 'Cannot render type "' + nodetype + '"'
        
        return
