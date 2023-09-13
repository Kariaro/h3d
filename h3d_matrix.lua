--- @class H3DMatrix
local h3d_matrix = {}

--- Construct a new 4x3 matrix
--- @return H3DMatrix
function h3d_matrix:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	self.m00 = 1
	self.m01 = 0
	self.m02 = 0
	self.m10 = 0
	self.m11 = 1
	self.m12 = 0
	self.m20 = 0
	self.m21 = 0
	self.m22 = 1
	self.m30 = 0
	self.m31 = 0
	self.m32 = 0
	return o
end

function h3d_matrix:__tostring()
	local pattern =
		'Matrix[\n' ..
			'%.4f, %.4f, %.4f, %.4f,\n' ..
			'%.4f, %.4f, %.4f, %.4f,\n' ..
			'%.4f, %.4f, %.4f, %.4f\n' ..
		']'

	return string.format(pattern,
		self.m00, self.m10, self.m20, self.m30,
		self.m01, self.m11, self.m21, self.m31,
		self.m02, self.m12, self.m22, self.m32
	)
end

--- Transform this into the identity matrix
--- @return H3DMatrix self
function h3d_matrix:identity()
	self.m00 = 1
	self.m01 = 0
	self.m02 = 0
	self.m10 = 0
	self.m11 = 1
	self.m12 = 0
	self.m20 = 0
	self.m21 = 0
	self.m22 = 1
	self.m30 = 0
	self.m31 = 0
	self.m32 = 0
	return self
end


--- Create the invert of this matrix
--- @param dest H3DMatrix? the destination matrix
--- @return H3DMatrix matrix the destination matrix
function h3d_matrix:invert(dest)
	dest = dest or h3d_matrix:new()
	local m11m00, m10m01, m10m02 = self.m00 * self.m11, self.m01 * self.m10, self.m02 * self.m10
	local m12m00, m12m01, m11m02 = self.m00 * self.m12, self.m01 * self.m12, self.m02 * self.m11
	local m10m22, m10m21, m11m22 = self.m10 * self.m22, self.m10 * self.m21, self.m11 * self.m22
	local m11m20, m12m21, m12m20 = self.m11 * self.m20, self.m12 * self.m21, self.m12 * self.m20
	local m20m02, m20m01, m21m02 = self.m20 * self.m02, self.m20 * self.m01, self.m21 * self.m02
	local m21m00, m22m01, m22m00 = self.m21 * self.m00, self.m22 * self.m01, self.m22 * self.m00
	local s = 1.0 / ((m11m00 - m10m01) * self.m22 + (m10m02 - m12m00) * self.m21 + (m12m01 - m11m02) * self.m20)
	local nm00 = (m11m22 - m12m21) * s
	local nm01 = (m21m02 - m22m01) * s
	local nm02 = (m12m01 - m11m02) * s
	local nm10 = (m12m20 - m10m22) * s
	local nm11 = (m22m00 - m20m02) * s
	local nm12 = (m10m02 - m12m00) * s
	local nm20 = (m10m21 - m11m20) * s
	local nm21 = (m20m01 - m21m00) * s
	local nm22 = (m11m00 - m10m01) * s
	local nm30 = (m10m22 * self.m31 - m10m21 * self.m32 + m11m20 * self.m32 - m11m22 * self.m30 + m12m21 * self.m30 - m12m20 * self.m31) * s
	local nm31 = (m20m02 * self.m31 - m20m01 * self.m32 + m21m00 * self.m32 - m21m02 * self.m30 + m22m01 * self.m30 - m22m00 * self.m31) * s
	local nm32 = (m11m02 * self.m30 - m12m01 * self.m30 + m12m00 * self.m31 - m10m02 * self.m31 + m10m01 * self.m32 - m11m00 * self.m32) * s
	dest.m00 = nm00
	dest.m01 = nm01
	dest.m02 = nm02
	dest.m10 = nm10
	dest.m11 = nm11
	dest.m12 = nm12
	dest.m20 = nm20
	dest.m21 = nm21
	dest.m22 = nm22
	dest.m30 = nm30
	dest.m31 = nm31
	dest.m32 = nm32
	return dest
end


--- Translate this matrix locally
--- @param x number the x translation
--- @param y number the y translation
--- @param z number the z translation
--- @return H3DMatrix self
function h3d_matrix:translate(x, y, z)
	self.m30 = self.m00 * x + self.m10 * y + self.m20 * z + self.m30
	self.m31 = self.m01 * x + self.m11 * y + self.m21 * z + self.m31
	self.m32 = self.m02 * x + self.m12 * y + self.m22 * z + self.m32
	return self
end


--- Scale this matrix locally
--- @param x number the x scale
--- @param y number the y scale
--- @param z number the z scale
--- @return H3DMatrix self
function h3d_matrix:scale(x, y, z)
	self.m00 = self.m00 * x
	self.m01 = self.m01 * y
	self.m02 = self.m02 * z
	self.m10 = self.m10 * x
	self.m11 = self.m11 * y
	self.m12 = self.m12 * z
	self.m20 = self.m20 * x
	self.m21 = self.m21 * y
	self.m22 = self.m22 * z
	self.m30 = self.m30 * x
	self.m31 = self.m31 * y
	self.m32 = self.m32 * z
	return self
end


--- Rotate this matrix locally around an axis
--- @param angle number the angle in degrees
--- @param x number the x component of the axis
--- @param y number the y component of the axis
--- @param z number the z component of the axis
--- @return H3DMatrix self
function h3d_matrix:rotate(angle, x, y, z)
	local s = math.sin(math.rad(angle))
	local c = math.cos(math.rad(angle))
	local C = 1.0 - c
	local xx, xy, xz = x * x, x * y, x * z
	local yy, yz = y * y, y * z
	local zz = z * z
	local rm00 = xx * C + c
	local rm01 = xy * C + z * s
	local rm02 = xz * C - y * s
	local rm10 = xy * C - z * s
	local rm11 = yy * C + c
	local rm12 = yz * C + x * s
	local rm20 = xz * C + y * s
	local rm21 = yz * C - x * s
	local rm22 = zz * C + c
	local nm00 = self.m00 * rm00 + self.m10 * rm01 + self.m20 * rm02
	local nm01 = self.m01 * rm00 + self.m11 * rm01 + self.m21 * rm02
	local nm02 = self.m02 * rm00 + self.m12 * rm01 + self.m22 * rm02
	local nm10 = self.m00 * rm10 + self.m10 * rm11 + self.m20 * rm12
	local nm11 = self.m01 * rm10 + self.m11 * rm11 + self.m21 * rm12
	local nm12 = self.m02 * rm10 + self.m12 * rm11 + self.m22 * rm12
	self.m20 = self.m00 * rm20 + self.m10 * rm21 + self.m20 * rm22
	self.m21 = self.m01 * rm20 + self.m11 * rm21 + self.m21 * rm22
	self.m22 = self.m02 * rm20 + self.m12 * rm21 + self.m22 * rm22
	self.m00 = nm00
	self.m01 = nm01
	self.m02 = nm02
	self.m10 = nm10
	self.m11 = nm11
	self.m12 = nm12
	return self
end


--- Rotate this matrix locally around the x axis
--- @param angle number the angle in degrees
--- @return H3DMatrix self
function h3d_matrix:rotateX(angle)
	return self:rotate(angle, 1, 0, 0)
end


--- Rotate this matrix locally around the y axis
--- @param angle number the angle in degrees
--- @return H3DMatrix self
function h3d_matrix:rotateY(angle)
	return self:rotate(angle, 0, 1, 0)
end


--- Rotate this matrix locally around the z axis
--- @param angle number the angle in degrees
--- @return H3DMatrix self
function h3d_matrix:rotateZ(angle)
	return self:rotate(angle, 0, 0, 1)
end


--- Apply perspective to this matrix
--- @param fovy number the angle of view vertically
--- @param aspect number the aspect ratio of the window
--- @param zNear number the near value
--- @param zFar number the far value
--- @return H3DMatrix self
function h3d_matrix:perspective(fovy, aspect, zNear, zFar)
	local h = math.tan(math.rad(fovy) * 0.5)
	local rm00 = 1.0 / (h * aspect)
	local rm11 = 1.0 / h
	local rm22
	local rm32
	local farInf  = zFar  == math.huge
	local nearInf = zNear == math.huge
	if farInf then
		rm22 = (1.0 - 1e-6)
		rm32 = (2.0 - 1e-6) * zNear
	elseif nearInf then
		rm22 = (1e-6 - 1.0)
		rm32 = (1e-6 - 2.0) * zFar
	else
		rm22 = (zFar + zNear) / (zFar - zNear)
		rm32 = (zFar + zFar ) * zNear / (zFar - zNear)
	end
	local nm20 = self.m20 * rm22 - self.m30
	local nm21 = self.m21 * rm22 - self.m31
	local nm22 = self.m22 * rm22 - self.m32
	self.m00 = self.m00 * rm00
	self.m01 = self.m01 * rm00
	self.m02 = self.m02 * rm00
	self.m10 = self.m10 * rm11
	self.m11 = self.m11 * rm11
	self.m12 = self.m12 * rm11
	self.m30 = self.m20 * rm32
	self.m31 = self.m21 * rm32
	self.m32 = self.m22 * rm32
	self.m20 = nm20
	self.m21 = nm21
	self.m22 = nm22
	return self
end


--- Translate a point using this matrix
--- @param x number the x coordinate
--- @param y number the y coordinate
--- @param z number the z coordinate
--- @return number x, number y, number z the translated point
function h3d_matrix:transfer(x, y, z)
	local nx = self.m00 * x + self.m10 * y + self.m20 * z + self.m30
	local ny = self.m01 * x + self.m11 * y + self.m21 * z + self.m31
	local nz = self.m02 * x + self.m12 * y + self.m22 * z + self.m32
	return nx, ny, nz
end

return h3d_matrix --$$REMOVE
