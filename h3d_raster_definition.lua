error('You cannot include this file')

--- @class H3DRaster
local raster = {}


--- Draw geometry with the raster
--- @param geometry number[] the geometry buffer 
--- @param matrix H3DMatrix the rotation matrix
--- @return H3DRaster raster
function raster.drawGeometry(geometry, matrix)
	return raster
end


--- Fill the specified layer with a value
--- @param name string the name of the layer
--- @param value number the value to fill with
--- @return H3DRaster raster
function raster.set_layer(name, value)
	return raster
end


--- Returns the layer with the specified name
--- @param name string the layer name
--- @return number[][]? layer the data of the layer
function raster.get_layer(name)
	return nil
end


--- Update the dimensions of the raster
--- @param width integer the width of the buffer
--- @param height integer the height of the buffer
--- @return H3DRaster raster
function raster.set_size(width, height)
	return raster
end


--- Set the near plane of the raster
--- @param near number the near clipping value
--- @return H3DRaster raster
function raster.set_near(near)
	return raster
end


--- Change if geometry should be face culled or not
--- @param enable boolean if culling should be enabled or not
--- @return H3DRaster raster
function raster.set_face_culling(enable)
	return raster
end


--- Change the currently loaded texture
--- @param texture any a texture object
--- @return H3DRaster raster
function raster.set_texture(texture)
	TEXTURE = texture
	return raster
end


--- Returns some information about the raster
--- @return table data
function raster.get_raster_info()
	return {}
end
