-- 4x3 matrix

local h3d_matrix = {}

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
---
--- @return table self
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

function h3d_matrix:translate(x, y, z)
	self.m30 = self.m00 * x + self.m10 * y + self.m20 * z + self.m30
	self.m31 = self.m01 * x + self.m11 * y + self.m21 * z + self.m31
	self.m32 = self.m02 * x + self.m12 * y + self.m22 * z + self.m32
	return self
end

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

function h3d_matrix:rotateX(dest, angle)
	return self:rotateAroundAxis(dest, angle, 1, 0, 0)
end

function h3d_matrix:rotateY(dest, angle)
	return self:rotateAroundAxis(dest, angle, 0, 1, 0)
end

function h3d_matrix:rotateZ(dest, angle)
	return self:rotateAroundAxis(dest, angle, 0, 0, 1)
end

function h3d_matrix:rotateXYZ(angleY, angleX, angleZ)
	local sinX = math.sin(math.rad(angleX))
	local cosX = math.cos(math.rad(angleX))
	local sinY = math.sin(math.rad(angleY))
	local cosY = math.cos(math.rad(angleY))
	local sinZ = math.sin(math.rad(angleZ))
	local cosZ = math.cos(math.rad(angleZ))
	local m_sinX = -sinX
	local m_sinY = -sinY
	local m_sinZ = -sinZ

	-- rotateX
	local nm10 = self.m10 * cosX   + self.m20 * sinX
	local nm11 = self.m11 * cosX   + self.m21 * sinX
	local nm12 = self.m12 * cosX   + self.m22 * sinX
	local nm20 = self.m10 * m_sinX + self.m20 * cosX
	local nm21 = self.m11 * m_sinX + self.m21 * cosX
	local nm22 = self.m12 * m_sinX + self.m22 * cosX

	-- rotateY
	local nm00 = self.m00 * cosY + nm20 * m_sinY
	local nm01 = self.m01 * cosY + nm21 * m_sinY
	local nm02 = self.m02 * cosY + nm22 * m_sinY
	self.m20   = self.m00 * sinY + nm20 * cosY
	self.m21   = self.m01 * sinY + nm21 * cosY
	self.m22 =   self.m02 * sinY + nm22 * cosY

	-- rotateZ
	self.m00 = nm00 * cosZ + nm10 * sinZ
	self.m01 = nm01 * cosZ + nm11 * sinZ
	self.m02 = nm02 * cosZ + nm12 * sinZ
	self.m10 = nm00 * m_sinZ + nm10 * cosZ
	self.m11 = nm01 * m_sinZ + nm11 * cosZ
	self.m12 = nm02 * m_sinZ + nm12 * cosZ

	self.m30 = self.m30
	self.m31 = self.m31
	self.m32 = self.m32
	return self
end

--- Rotate around the X axis (1, 0, 0)
--- @param angle integer how many degrees to rotate
function h3d_matrix:rotateLocalX(angle)
	local sin = math.sin(math.rad(angle))
	local cos = math.cos(math.rad(angle))
	local nm01 = cos * self.m01 - sin * self.m02
	local nm02 = sin * self.m01 + cos * self.m02
	local nm11 = cos * self.m11 - sin * self.m12
	local nm12 = sin * self.m11 + cos * self.m12
	local nm21 = cos * self.m21 - sin * self.m22
	local nm22 = sin * self.m21 + cos * self.m22
	local nm31 = cos * self.m31 - sin * self.m32
	local nm32 = sin * self.m31 + cos * self.m32
	self.m01 = nm01
	self.m02 = nm02
	self.m11 = nm11
	self.m12 = nm12
	self.m21 = nm21
	self.m22 = nm22
	self.m31 = nm31
	self.m32 = nm32
	return self
end

--- Rotate around the Y axis (0, 1, 0)
--- @param angle integer how many degrees to rotate
function h3d_matrix:rotateLocalY(angle)
	local sin = math.sin(math.rad(angle))
	local cos = math.cos(math.rad(angle))
	local nm00 =  cos * self.m00 + sin * self.m02
	local nm02 = -sin * self.m00 + cos * self.m02
	local nm10 =  cos * self.m10 + sin * self.m12
	local nm12 = -sin * self.m10 + cos * self.m12
	local nm20 =  cos * self.m20 + sin * self.m22
	local nm22 = -sin * self.m20 + cos * self.m22
	local nm30 =  cos * self.m30 + sin * self.m32
	local nm32 = -sin * self.m30 + cos * self.m32
	self.m00 = nm00
	self.m02 = nm02
	self.m10 = nm10
	self.m12 = nm12
	self.m20 = nm20
	self.m22 = nm22
	self.m30 = nm30
	self.m32 = nm32
	return self
end

--- Rotate around the Z axis (0, 0, 1)
--- @param angle integer how many degrees to rotate
function h3d_matrix:rotateLocalZ(angle)
	local sin = math.sin(math.rad(angle))
	local cos = math.cos(math.rad(angle))
	local nm00 = cos * self.m00 - sin * self.m01
	local nm01 = sin * self.m00 + cos * self.m01
	local nm10 = cos * self.m10 - sin * self.m11
	local nm11 = sin * self.m10 + cos * self.m11
	local nm20 = cos * self.m20 - sin * self.m21
	local nm21 = sin * self.m20 + cos * self.m21
	local nm30 = cos * self.m30 - sin * self.m31
	local nm31 = sin * self.m30 + cos * self.m31
	self.m00 = nm00
	self.m01 = nm01
	self.m10 = nm10
	self.m11 = nm11
	self.m20 = nm20
	self.m21 = nm21
	self.m30 = nm30
	self.m31 = nm31
	return self
end

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

function h3d_matrix:setPerspective(fovy, aspect, zNear, zFar)
	local h = math.tan(math.rad(fovy) * 0.5)
	self.m00 = 1.0 / (h * aspect)
	self.m11 = 1.0 / h
	local farInf  = zFar == math.huge
	local nearInf = zNear == math.huge
	if farInf then
		self.m22 = 1e-6 - 1.0
		self.m32 = (1e-6 - 2.0) * zNear
	elseif nearInf then
		self.m22 = 1.0 - 1e-6
		self.m32 = (2.0 - 1e-6) * zFar
	else
		self.m22 = (zFar + zNear) / (zNear - zFar)
		self.m32 = (zFar + zFar) * zFar / (zNear - zFar)
	end
	self.m23 = -1
	return self
end



function h3d_matrix:rotateLocalXYZ(angleX, angleY, angleZ)
	return self
		:rotateLocalY(angleY)
		:rotateLocalX(angleX)
		:rotateLocalZ(angleZ)
end

function h3d_matrix:transfer(x, y, z)
	local nx = self.m00 * x + self.m10 * y + self.m20 * z + self.m30
	local ny = self.m01 * x + self.m11 * y + self.m21 * z + self.m31
	local nz = self.m02 * x + self.m12 * y + self.m22 * z + self.m32
	return nx, ny, nz
end

return h3d_matrix
