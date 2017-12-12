component = require("component")
modem = component.modem
computer = require("computer")
modem.open(4300)

local vector = {
  add = function( self, o )
    return new(
      self.x + o.x,
      self.y + o.y,
      self.z + o.z
    )
  end,
  sub = function( self, o )
    return new(
      self.x - o.x,
      self.y - o.y,
      self.z - o.z
    )
  end,
  mul = function( self, m )
    return new(
      self.x * m,
      self.y * m,
      self.z * m
    )
  end,
  div = function( self, m )
    return new(
      self.x / m,
      self.y / m,
      self.z / m
    )
  end,
  unm = function( self )
    return new(
      -self.x,
      -self.y,
      -self.z
    )
  end,
  dot = function( self, o )
    return self.x*o.x + self.y*o.y + self.z*o.z
  end,
  cross = function( self, o )
    return new(
      self.y*o.z - self.z*o.y,
      self.z*o.x - self.x*o.z,
      self.x*o.y - self.y*o.x
    )
  end,
  length = function( self )
    return math.sqrt( self.x*self.x + self.y*self.y + self.z*self.z )
  end,
  normalize = function( self )
    return self:mul( 1 / self:length() )
  end,
  round = function( self, nTolerance )
      nTolerance = nTolerance or 1.0
    return new(
      math.floor( (self.x + (nTolerance * 0.5)) / nTolerance ) * nTolerance,
      math.floor( (self.y + (nTolerance * 0.5)) / nTolerance ) * nTolerance,
      math.floor( (self.z + (nTolerance * 0.5)) / nTolerance ) * nTolerance
    )
  end,
  tostring = function( self )
    return self.x..","..self.y..","..self.z
  end,
}

local vmetatable = {
  __index = vector,
  __add = vector.add,
  __sub = vector.sub,
  __mul = vector.mul,
  __div = vector.div,
  __unm = vector.unm,
  __tostring = vector.tostring,
}

function new( x, y, z )
  local v = {
    x = x or 0,
    y = y or 0,
    z = z or 0
  }
  setmetatable( v, vmetatable )
  return v
end

local function trilaterate( A, B, C )
	local a2b = B.vPosition - A.vPosition
	local a2c = C.vPosition - A.vPosition
		
	if math.abs( a2b:normalize():dot( a2c:normalize() ) ) > 0.999 then
		return nil
	end
	
	local d = a2b:length()
	local ex = a2b:normalize( )
	local i = ex:dot( a2c )
	local ey = (a2c - (ex * i)):normalize()
	local j = ey:dot( a2c )
	local ez = ex:cross( ey )

	local r1 = A.nDistance
	local r2 = B.nDistance
	local r3 = C.nDistance
		
	local x = (r1*r1 - r2*r2 + d*d) / (2*d)
	local y = (r1*r1 - r3*r3 - x*x + (x-i)*(x-i) + j*j) / (2*j)
		
	local result = A.vPosition + (ex * x) + (ey * y)

	local zSquared = r1*r1 - x*x - y*y
	if zSquared > 0 then
		local z = math.sqrt( zSquared )
		local result1 = result + (ez * z)
		local result2 = result - (ez * z)
		
		local rounded1, rounded2 = result1:round( 0.01 ), result2:round( 0.01 )
		if rounded1.x ~= rounded2.x or rounded1.y ~= rounded2.y or rounded1.z ~= rounded2.z then
			return rounded1, rounded2
		else
			return rounded1
		end
	end
	return result:round( 0.01 )
	
end

local function narrow( p1, p2, fix )
	local dist1 = math.abs( (p1 - fix.vPosition):length() - fix.nDistance )
	local dist2 = math.abs( (p2 - fix.vPosition):length() - fix.nDistance )
	
	if math.abs(dist1 - dist2) < 0.01 then
		return p1, p2
	elseif dist1 < dist2 then
		return p1:round( 0.01 )
	else
		return p2:round( 0.01 )
	end
end

stations = {}
scount = 0
modem.broadcast(4300,"PING")
repeat
  ev,mcomp,scomp,channel,dist,msg = computer.pullSignal()
  if(ev=="modem_message" and channel==4300 and string.sub(msg,1,4)=="PONG") then
    if(stations[scomp]==nil) then
      x,y,z = string.match(string.sub(msg,6,string.len(msg)),"([^,]+):([^,]+):([^,]+)")
      stations[scomp]={vPosition=new(x,y,z),nDistance=dist}
      scount=scount+1
    end
  end
until scount>=3
print("i have 3 stations")
A,B,C = {}
count=1
for saddr,info in pairs(stations) do
  if(count==1) then A=info end
  if(count==2) then B=info end
  if(count==3) then C=info end
  count=count+1
end

fpos=trilaterate(A,B,C)
print(fpos)
