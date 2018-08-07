pico-8 cartridge // http://www.pico-8.com
version 16
__lua__


-- colour names/numbers
colours = {
 black      = 0,
 darkblue   = 1,
 maroon     = 2,
 darkgreen  = 3,
 brown      = 4,
 darkgrey   = 5,
 lightgrey  = 6,
 white      = 7,
 red        = 8,
 orange     = 9,
 yellow     = 10,
 lightgreen = 11,
 lightblue  = 12,
 mauve      = 13,
 pink       = 14,
 beige      = 15
}

-- sounds and music
sounds = {
 a = 0,
 b = 1,
 c = 2,
 d = 3,
 e = 4
}

-- play a sound by name
function playsound(sound)
 sfx(sounds[sound])
end

partlist = {}

--should define lifecycle  too
function addpart(_x,_y,_dx,_dy,_s,_flare,_decay)
 local part = {}
 part.x=_x+flr(rnd(_flare*2))-_flare
 part.y=_y+flr(rnd(_flare*2))-_flare
 part.dx=_dx
 part.dy=_dy
 part.s=_s
 part.c=flr(rnd(2))+6
 part.t=_decay
 add(partlist,part)
end

function updatepart()
 for p in all(partlist) do
  p.t-=1
  if p.t < 0 then
   p.s-=1
   p.x+=p.dx
   p.y+=p.dy
   p.t=3
  end
  if p.s < 1 then
   del(partlist,p)
  end
  p.t-=1
 end
end

-- stores game state
state = {}
state.__index = state

function state:create(props)
 local this = {}
 local props = props or {}
 this.next = props.next or nil
 this.time = props.time or 0
 this.timeremaining = this.time
 setmetatable(this, state)
 return this
end

-- keeps track and updates
-- a list of states
statemanager = {}
statemanager.__index = statemanager

function statemanager:create(props)
 local this = {}
 local props = props or {}
 this.current = nil
 this.next = props.next or {}
 --this.previous = nil
 this.frame = 0
 setmetatable(this, statemanager)
 return this
end

function statemanager:update()
 self.previous = self.current
 self.current = self.current:update()
 -- reset frame for new state
 if self.current ~= self.previous then
  self.frame = 0
 else
  -- stop integer overflow
  if self.frame < 3200 then
   self.frame += 1
  end
 end
end

function statemanager:draw()
 self.current:draw()
end

world      = {}

wins = {p1=0,p2=0}

raindata = {}
raindata.targetrainlevel = 0
raindata.currentrainlevel = 0
raindata.timeuntilnextlevel = 0
raindata.rainlist = {60,10,0}

playersalive = 2
animstate = 0

level = 1
--{name = "abandoned house", colour = 1, map_colour = 6, map_topx = 0, map_topy = 0, map_width = 32, map_height = 32, spawn = {}, poweruppos = {}, rain=false},
leveldata = {
 {name = "gardens", colour = 9, map_colour = 3, map_topx = 32, map_topy = 0, map_width = 32, map_height = 32, spawn = {}, poweruppos = {}, rain=true}
}

-----------
-- entities
-----------

entity = {}
entity.__index = entity

function entity:create(props)
  local this = {}
  local props = props or {}

  this.player    = props.player or false
  this.del       = false
  this.sprite    = props.sprite
  this.animation = props.animation
  this.position  = props.position
  this.controls  = props.controls
  this.intention = props.intention
  this.camera    = props.camera
  this.battle    = props.battle
  this.weapon    = props.weapon
  this.collision = props.collision
  this.powerup   = props.powerup

  setmetatable(this, entity)
  return this
end

function entity:has(key)
  return self[key] ~= nil
end

function entity:removepowerup()
 this.powerup = nil
end

---------
-- sprite
---------

sprite = {}
sprite.__index = sprite

function sprite:create(props)
    local this = {}
    local props = props or {}

    this.number          = props.number or 2
    this.currentnumber   = this.number
    this.spritesinsheet  = props.spritesinsheet or 8
    this.recolour        = props.recolour or {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}

    setmetatable(this, sprite)
    return this
end

------------
-- animation
------------

animation = {}
animation.__index = animation

function animation:create(props)
    local this = {}
    local props = props or {}

    this.frames = props.frames or 4
    this.animspeed = props.animspeed or 2
    this.timeoncurrent = 0
    this.animtype = props.movementanim or 'movement_only'

    setmetatable(this, animation)
    return this
end

-----------
-- position
-----------

position = {}
position.__index = position

function position:create(props)
    local this = {}
    local props = props or {}

    this.x         = props.x or 10
    this.y         = props.y or 10
    this.w         = props.w or 6
    this.h         = props.h or 8
    this.speed     = props.speed or 1
    this.angle     = props.angle or 180
    this.moving    = props.moving or false
    this.velocity  = props.velocity or 0
    this.ranged    = props.ranged or false
    this.range     = props.range or 0

    setmetatable(this, position)
    return this
end

-----------
-- controls
-----------

controls = {}
controls.__index = controls

function controls:create(props)
    local this = {}
    local props = props or {}

    this.l = props.l or 0
    this.r = props.r or 1
    this.u = props.u or 2
    this.d = props.d or 3
    this.o = props.o or 4
    this.x = props.x or 5
    this.p = props.p or 0

    setmetatable(this, controls)
    return this
end

------------
-- intention
------------

intention = {}
intention.__index = intention

function intention:create(props)
    local this = {}
    local props = props or {}

    this.l = false
    this.r = false
    this.u = false
    this.d = false
    this.o = false
    this.x = false

    setmetatable(this, intention)
    return this
end

---------
-- camera
---------

camera = {}
camera.__index = camera

function camera:create(props)
    local this = {}
    local props = props or {}

    this.bg             = props.bg or 0
    this.x              = props.x  or 0
    this.y              = props.y  or 0
    this.w              = props.w  or 8
    this.h              = props.h  or 16
    this.shake          = false
    this.shakeremaining = 6
    this.rainlist       = {}

    setmetatable(this, camera)
    return this
end

---------
-- battle
---------

battle = {}
battle.__index = battle

function battle:create(props)
    local this = {}
    local props = props or {}

    this.health    = props.health or 100
    this.maxhealth = props.maxhealth or 100
    this.lives     = props.lives or 2

    setmetatable(this, battle)
    return this
end

---------
-- weapon
---------

weapon = {}
weapon.__index = weapon

function weapon:create(props)
    local this = {}
    local props = props or {}

    this.damage    = props.damage or 25
    this.rate      = props.rate or 10
    this.lastfired = 0
    this.speed     = props.speed or 6
    this.range     = props.range or 15

    setmetatable(this, weapon)
    return this
end

----------
-- powerup
----------

powerup = {}
powerup.__index = powerup

function powerup:create(props)
    local this = {}
    local props = props or {}

    this.type          = props.type or 0
    this.timeremaining = 300
    this.numberleft    = props.numberleft

    setmetatable(this, powerup)
    return this
end

------------
-- collision
------------

collision = {}
collision.__index = collision

function collision:create(props)
    local this = {}
    local props = props or {}
    this.isdestroyed = props.isdestroyed or false
    this.destroys = props.destroys or false
    this.collisiondamage = props.collisiondamage or 0
    this.collidedwith = {}
    this.bouncy = props.bouncy or false

    setmetatable(this, collision)
    return this
end

function findfreeloc(structure,w)
 for pos in all(shuffle(structure)) do
  local found = true
  for e in all(w) do
   local x1=e.position.x
   local y1=e.position.y
   local x2=(e.position.x+(e.position.w))
   local y2=(e.position.y+(e.position.h))

   if pos[1] < x2 and pos[1] + 8 > x1 and pos[2] < y2 and pos[2] + 8 > y1 then
    found = false
   end
  end
  if found == true then
   return pos[1], pos[2]
  end
 end
end

-----------------
-- physics system
-----------------

physicssystem = {}
physicssystem.__index = physicssystem

function physicssystem:create(props)
    local this = {}
    local props = props or {}

    setmetatable(this, physicssystem)
    return this
end

function physicssystem:update(w)
 for e in all(world) do
  if e:has('position') then
  e.position.moving = false

  local x_new = e.position.x
  local y_new = e.position.y

  local speed = e.position.speed
  if e.player == true and e:has('powerup') and e.powerup.type == 0 then
   speed = speed + 1
  end

  if e.position.ranged and e.position.range - speed < 1 then
   e.del = true
   do return end
  end

  e.position.range -= speed

  if e:has('intention') then

    -- if entity wants to move up
    if (e.intention.u) then
      y_new = e.position.y - speed
      e.position.moving = true
    end

    -- if entity wants to move down
    if (e.intention.d) then
      y_new = e.position.y + speed
      e.position.moving = true
    end

    -- if entity wants to move up
    if (e.intention.l) then
      x_new = e.position.x - speed
      e.position.moving = true
    end

    -- if entity wants to move up
    if (e.intention.r) then
      x_new = e.position.x + speed
      e.position.moving = true
    end

    if e.intention.u and not e.intention.d and not e.intention.l and not e.intention.r then
     e.position.angle = 0
    elseif e.intention.u and not e.intention.d and not e.intention.l and e.intention.r then
     e.position.angle = 45
    elseif not e.intention.u and not e.intention.d and not e.intention.l and e.intention.r then
     e.position.angle = 90
    elseif not e.intention.u and e.intention.d and not e.intention.l and e.intention.r then
     e.position.angle = 135
    elseif not e.intention.u and e.intention.d and not e.intention.l and not e.intention.r then
     e.position.angle = 180
    elseif not e.intention.u and e.intention.d and e.intention.l and not e.intention.r then
     e.position.angle = 225
    elseif not e.intention.u and not e.intention.d and e.intention.l and not e.intention.r then
     e.position.angle = 270
    elseif e.intention.u and not e.intention.d and e.intention.l and not e.intention.r then
     e.position.angle = 315
    end

  end

  if (e.position.angle > 0 and e.position.angle < 180) then
   x_new += e.position.velocity
  end
  if (e.position.angle > 180 and e.position.angle < 360) then
   x_new -= e.position.velocity
  end
  if (e.position.angle > 270 or e.position.angle < 90) then
   y_new -= e.position.velocity
  end
  if (e.position.angle < 270 and e.position.angle > 90) then
   y_new += e.position.velocity
  end

  if e:has('intention') then
    -- reset player intention
    e.intention.u = false
    e.intention.d = false
    e.intention.l = false
    e.intention.r = false
  end

  -- map hittest

  local xhit
  local x1
  local y1
  local x2
  local x2
  local xa
  local xb
  local xc
  local xd
  repeat
    xhit = false

    x1=x_new/8
    y1=e.position.y/8
    x2=(x_new+(e.position.w-1))/8
    y2=(e.position.y+(e.position.h-1))/8
    xa=fget(mget(x1,y1),0) and not (e.player == false and fget(mget(x1,y1),1))
    xb=fget(mget(x1,y2),0) and not (e.player == false and fget(mget(x1,y2),1))
    xc=fget(mget(x2,y2),0) and not (e.player == false and fget(mget(x2,y2),1))
    xd=fget(mget(x2,y1),0) and not (e.player == false and fget(mget(x2,y1),1))

    if xa or xb or xc or xd then
     xhit = true
     if e.position.angle > 0 and e.position.angle < 180 then
      x_new -= 1
     else
      x_new += 1
     end
    end
  until(xhit==false or (x_new == e.position.x))

  --xt = fget(mget(x1,y1),1) or fget(mget(x1,y2),1) or fget(mget(x2,y2),1) or fget(mget(x2,y1),1)

 local yhit
 local ya
 local yb
 local yc
 local yd
 repeat
  yhit = false

  x1=e.position.x/8
  y1=y_new/8
  x2=(e.position.x+(e.position.w-1))/8
  y2=(y_new+(e.position.h-1))/8
  ya=fget(mget(x1,y1),0) and not (e.player == false and fget(mget(x1,y1),1))
  yb=fget(mget(x1,y2),0) and not (e.player == false and fget(mget(x1,y2),1))
  yc=fget(mget(x2,y2),0) and not (e.player == false and fget(mget(x2,y2),1))
  yd=fget(mget(x2,y1),0) and not (e.player == false and fget(mget(x2,y1),1))

  if ya or yb or yc or yd then
   yhit = true
   if e.position.angle > 90 and e.position.angle < 270 then
    y_new -= 1
   else
    y_new += 1
   end
  end
 until(yhit==false or (y_new == e.position.y))

  --yt = fget(mget(x1,y1),1) or fget(mget(x1,y2),1) or fget(mget(x2,y2),1) or fget(mget(x2,y1),1)

  if (yhit or xhit) and e:has('collision') then
   if e.collision.isdestroyed then
    e.del = true
   end
  end

  -- other entity hittest
  for o in all(w) do
   if o ~= e and o:has('position') then
    local o_x1=o.position.x
    local o_y1=o.position.y
    local o_x2=(o.position.x+(o.position.w))
    local o_y2=(o.position.y+(o.position.h))

    if x_new < o_x2 and x_new + (e.position.w) > o_x1 and y_new < o_y2 and y_new + (e.position.h)> o_y1 then
     xhit = true
     yhit = true

     if e:has('collision') then
      add(e.collision.collidedwith,o)
     end
     if o:has('collision') then
      add(o.collision.collidedwith,e)
     end
    end

   end
  end

  if e:has('collision') then
   if e.collision.collisiondamage > 0 and e.position.velocity > 0 then
    addpart(e.position.x+(flr(e.position.w/2)),e.position.y+(flr(e.position.h/2)),0,0,1,1,5)
   end
  end

  -- update position
  if xhit == false then
   e.position.x = x_new
  end
  if yhit == false then
   e.position.y = y_new
  end
  end
 end
end

-----------------
-- control system
-----------------

controlsystem = {}
controlsystem.__index = controlsystem

function controlsystem:create(props)
    local this = {}
    local props = props or {}

    setmetatable(this, controlsystem)
    return this
end

function controlsystem:update(w)
 for e in all(world) do
  if e:has('controls') and e:has('position') and e:has('intention') then
  e.intention.l = btn(e.controls.l, e.controls.p)
  e.intention.r = btn(e.controls.r, e.controls.p)
  e.intention.u = btn(e.controls.u, e.controls.p)
  e.intention.d = btn(e.controls.d, e.controls.p)
  e.intention.o = btn(e.controls.o, e.controls.p)
  e.intention.x = btn(e.controls.x, e.controls.p)
  end
 end
end

-----------------
-- battle system
-----------------

battlesystem = {}
battlesystem.__index = battlesystem

function battlesystem:create(props)
    local this = {}
    local props = props or {}

    setmetatable(this, battlesystem)
    return this
end

function battlesystem:update(w)
 for e in all(w) do
  if e:has('battle') then
  if e:has('powerup') and e.player == true and e.powerup.type == 6 then
   e.battle.health += 1
   if e.battle.health > 99 and e.battle.lives < 2 then
    e.battle.lives += 1
    e.battle.health = 1
   end
   if e.battle.health > 99 and e.battle.lives > 1 then
    e.powerup = nil
   end
  end
  end
 end
end

-----------------
-- weapon system
-----------------

weaponsystem = {}
weaponsystem.__index = weaponsystem

function weaponsystem:create(props)
    local this = {}
    local props = props or {}

    setmetatable(this, weaponsystem)
    return this
end

function weaponsystem:update(w)
 for e in all(world) do
  if e:has('weapon') then
  if e:has('intention') then
   if e.intention.o then
    local rate = e.weapon.rate
    if e:has('powerup') and e.powerup.type == 1 then
     rate = rate / 2
    end
    if e.weapon.lastfired > rate then
     -- create a new bullet entity

     -- calculate angle

     local xpos = 0
     local ypos = 0
     -- don't need these if not having firing particles
     local x1=0
     local y1=0

     speed = e.position.speed
     if e.player == true and e:has('powerup') and e.powerup.type == 0 then
      speed = speed + 1
     end

     local side
     if e.player == true and e:has('powerup') and e.powerup.type == 5 then

     if e.position.angle == 0 then
      xpos = e.position.x + e.position.w/2 - 2
      ypos = e.position.y + e.position.h + speed
      y1=-1
     elseif e.position.angle == 45 then
      xpos = e.position.x - e.position.w/2 - 2
      ypos = e.position.y + speed + 2
      x1=1
      y1=-1
     elseif e.position.angle == 90 then
      xpos = e.position.x - e.position.w/2 - speed - 2
      ypos = e.position.y + e.position.h/2 - 2
      x1=1
     elseif e.position.angle == 135 then
      xpos = e.position.x - e.position.w/2 - speed - 2
      ypos = e.position.y - e.position.h/2 - speed - 2
      x1=1
      y1=1
     elseif e.position.angle == 180 then
      xpos = e.position.x + e.position.w/2 -2
      ypos = e.position.y - e.position.h/2 - speed - 2
      y1=1
     elseif e.position.angle == 225 then
      xpos = e.position.x + e.position.w + 2
      ypos = e.position.y - speed - 2
      x1=-1
      y1=1
     elseif e.position.angle == 270 then
      xpos = e.position.x + e.position.w + 2
      ypos = e.position.y + e.position.h/2 - 2
      y1=-1
     elseif e.position.angle == 315 then
      xpos = e.position.x + e.position.w + 2
      ypos = e.position.y + e.position.h + 2
      x1=-1
      y1=-1
     end

     else

     if e.position.angle == 0 then
      xpos = e.position.x + e.position.w/2 - 1
      ypos = e.position.y - e.position.h/2 - speed
      y1=-1
     elseif e.position.angle == 45 then
      xpos = e.position.x + e.position.w/2 + speed
      ypos = e.position.y - e.position.h/2 - speed
      y1=-1
      x1=1
     elseif e.position.angle == 90 then
      xpos = e.position.x + e.position.w + speed
      ypos = e.position.y + e.position.h/2 - 1
      x1=1
     elseif e.position.angle == 135 then
      xpos = e.position.x + e.position.w + speed
      ypos = e.position.y + e.position.h/2 + speed
      y1=1
      x1=1
     elseif e.position.angle == 180 then
      xpos = e.position.x + e.position.w/2 -1
      ypos = e.position.y + e.position.h + speed
      y1=1
     elseif e.position.angle == 225 then
      xpos = e.position.x - e.position.w/2 - 1
      ypos = e.position.y + e.position.h/2 + speed
      y1=1
      x1=-1
     elseif e.position.angle == 270 then
      xpos = e.position.x - e.position.w/2 - speed
      ypos = e.position.y + e.position.h/2 - 1
      x1=-1
     elseif e.position.angle == 315 then
      xpos = e.position.x - e.position.w/2 - speed
      ypos = e.position.y - e.position.h/2 - speed
      y1=-1
      x1=-1
     end

     end

     local damage
     if e:has('powerup') and e.player == true and e.powerup.type == 4 then
      damage = 100
     else
      damage = e.weapon.damage
     end

     local range = e.weapon.range
     if e:has('powerup') and e.player == true and e.powerup.type == 3 then
      range = range * 2
     end

     local vel = e.weapon.speed
     local size = 2
     local spritenumber = 62
     local r = true
     if e:has('powerup') and e.player == true and e.powerup.type == 5 then
      vel = 0
      spritenumber = 63
      r = false
      size = 4
      damage = 100
     end

     local b = false
     local isd = true
     if e:has('powerup') and e.player == true and e.powerup.type == 2 then
      b = true
      isd = false
     end

     add(w,entity:create({
      sprite    = sprite:create({ number=spritenumber, spritesinsheet = 1 }),
      position  = position:create({
         x = xpos, y=ypos,
         w=size, h=size,
         angle=e.position.angle,
         velocity=vel,
         ranged=r, range=range
       }),
      collision = collision:create({ isdestroyed=isd, collisiondamage=damage, bouncy=b })
     }))
     sfx(0)
     e.weapon.lastfired = 0

     if e:has('powerup') then
      e.powerup.numberleft -= 1
      if e.powerup.numberleft < 1 then
       e.powerup = nil
      end
     end

    end
   end
  end
  e.weapon.lastfired = e.weapon.lastfired + 1
  end
 end
end

-------------------
-- animation system
-------------------

animationsystem = {}
animationsystem.__index = animationsystem

function animationsystem:create(props)
    local this = {}
    local props = props or {}

    setmetatable(this, animationsystem)
    return this
end

function animationsystem:update(w)
 for e in all(w) do
  if e:has('animation') then
  if (e.animation.animtype == 'always') or e.animation.animtype == 'movement_only' and e.position.moving then
   e.animation.timeoncurrent += 1
   if e.animation.timeoncurrent > e.animation.animspeed then
    e.sprite.currentnumber += e.sprite.spritesinsheet
    if e.sprite.currentnumber >= (e.sprite.number) + (e.sprite.spritesinsheet * e.animation.frames) then
     e.sprite.currentnumber = e.sprite.number
    end
    e.animation.timeoncurrent = 0
   end
  end
  end
 end
end

-------------------
-- collision system
-------------------

collisionsystem = {}
collisionsystem.__index = collisionsystem

function collisionsystem:create(props)
    local this = {}
    local props = props or {}
    setmetatable(this, collisionsystem)
    return this
end

function collisionsystem:update(w)
 for e in all(w) do
  if e:has('collision') then

   for c in all(e.collision.collidedwith) do
    if e.player == true and c:has('powerup') and c.player == false then
     sfx(3)
     e.powerup = c.powerup
     c.powerup = nil
     c.del = true
    end

    if c:has('powerup') and c.player == false and e.collision.isdestroyed then
     e.del = true
    end

    if e.player == true and c:has('collision') and c.collision.isdestroyed then
     c.del = true
    end

    if c:has('battle') and e.collision.collisiondamage > 0 then
     c.camera.shake = true
     c.battle.health -= e.collision.collisiondamage
     if c.battle.health < 1 then
      c.battle.lives -= 1
      if c.battle.lives < 1 then
       del(w,c)
       playersalive -= 1
      else
       local xnew, ynew = findfreeloc(leveldata[level].spawn,w)
       c.position.x = xnew + 1
       c.position.y = ynew
       c.battle.health = 100
      end
     end
     local j=0
     while j<4 do
      addpart(c.position.x+flr(c.position.w/2),c.position.y+flr(c.position.h/2),0,0,4,3,3)
      j+=1
     end
     sfx(1)
    end

   end

  end
 end
end

------------------
-- graphics system
------------------

graphicssystem = {}
graphicssystem.__index = graphicssystem

function graphicssystem:create(props)
    local this = {}
    local props = props or {}

    setmetatable(this, graphicssystem)
    return this
end

function graphicssystem:update(w)
 cls()
 for e in all(w) do

 if e:has('camera') then

  rectfill(e.camera.x,e.camera.y,e.camera.x+(e.camera.w*8)-1,e.camera.y+(e.camera.h*8)-1,0)

  local map_x = e.camera.x + (e.camera.w*8)/2 - e.position.x - e.position.w/2
  local map_y = e.camera.y + (e.camera.h*8)/2 - e.position.y - e.position.h/2

  if e.camera.shake then
   map_x += rnd(4) - 2
   map_y += rnd(4) - 2
   e.camera.shakeremaining -= 1
   if e.camera.shakeremaining < 1 then
    e.camera.shake = false
    e.camera.shakeremaining = 6
   end
  end

  clip(e.camera.x,e.camera.y,e.camera.w*8,e.camera.h*8)
  map(0,0,map_x,map_y)

  for o in all(w) do
   if o:has('position') and o:has('sprite') then

       -- use sprite palette info to recolour sprite
       -- (arrys start at 1)
       for c=0,15 do
        pal(c,o.sprite.recolour[c+1])
       end

       spr(o.sprite.currentnumber+( min(o.sprite.spritesinsheet-1, flr(o.position.angle/45))),o.position.x + map_x, o.position.y + map_y)
     end
     pal()
    end

    -- black border to hide outside of current map
    -- **might be better to just move player towards edge**
    -- add leveldata x and y for future levels.
    -- top
    rectfill(e.camera.x,e.camera.y,e.camera.x+e.camera.w*8,(map_y+leveldata[level].map_topy*8)-1,leveldata[level].map_colour)
    -- bottom
    rectfill(e.camera.x,e.camera.y+e.camera.h*8,e.camera.x+e.camera.w*8,map_y+(leveldata[level].map_topy+(leveldata[level].map_height*8)),leveldata[level].map_colour)
    -- left
    rectfill(e.camera.x,e.camera.y,((leveldata[level].map_topx*8)+map_x)-1,e.camera.y+(e.camera.h*8),leveldata[level].map_colour)
    --right
    rectfill(e.camera.x+e.camera.w*8,e.camera.y,map_x+(((leveldata[level].map_topx*8)+(leveldata[level].map_width*8))),e.camera.y+e.camera.h*8,leveldata[level].map_colour)

    -- update rain -- where to put this
    if leveldata[level].rain then

    if raindata.timeuntilnextlevel < 1 then
      local r = flr(rnd(#raindata.rainlist))+1
      raindata.targetrainlevel = raindata.rainlist[r]
      raindata.timeuntilnextlevel = flr(rnd(2000))+3000

      if raindata.targetrainlevel == 0 then
      -- diff = flr(abs(raindata.targetrainlevel-raindata.currentrainlevel)*200)
       music(-1,6000)
      else
       music(0,6000)
      end

    end
    raindata.timeuntilnextlevel -= 1
    if raindata.currentrainlevel < raindata.targetrainlevel then
      raindata.currentrainlevel += 0.1
    end
    if raindata.currentrainlevel > raindata.targetrainlevel then
      raindata.currentrainlevel -= 0.1
    end

    -- use currentrainlevel below
    while #e.camera.rainlist < flr(raindata.currentrainlevel) do
     local rain = {}
     rain.x=rnd(140)-20
     rain.y=rnd(140)-20

     -- position relative to player
     if e.player then
      rain.px = e.position.x
      rain.py = e.position.y
     else
      rain.px = 0
      rain.py = 0
     end
     -- and then draw rain +/- the difference between player
     -- original position and current position.

     rain.f=3
     rain.t=3
     add(e.camera.rainlist,rain)
     if rnd(1) > 0.9 then
      break
     end
    end
    for r in all(e.camera.rainlist) do
     r.t-=1
     if r.t < 1 then
      r.f-=1
      r.t=3
     end
     if r.f < 0 then
      del(e.camera.rainlist,r)
     end
     r.t-=1
    end

    local rxdiff = 0
    local rydiff = 0
    -- draw rain
    for r in all(e.camera.rainlist) do
      if e.player then
       rxdiff = r.px - e.position.x
       rydiff = r.py - e.position.y
      else
       rxdiff = 0
       rydiff = 0
      end
      sspr((13*8)+(4*r.f),6*8,4,15,r.x+rxdiff,r.y+rydiff)
    end
    end

    -- draw particles
    for p in all(partlist) do
     if p.s > 1 then
      circfill( map_x + p.x, map_y + p.y, p.s, p.c )
     else
      -- draw pixel
      pset(map_x + p.x, map_y + p.y, p.c)
     end
    end

    clip()

    -- camera border
    rect(e.camera.x,e.camera.y,e.camera.x+(e.camera.w*8)-1,e.camera.y+(e.camera.h*8)-1,13)

    if e:has('battle') then
     for hearts=0,e.battle.lives - 1 do
      if e.camera.x < 64 then
       spr(1,e.camera.x+5+(10*(hearts)),(e.camera.y*8)+(e.camera.h*8)-10)
      else
       spr(1,e.camera.x+(e.camera.w*5)+(10*(hearts)),(e.camera.y*8)+(e.camera.h*8)-10)
      end
     end

     pal(8,5)

     for hearts=e.battle.lives,1 do
      if e.camera.x < 64 then
       spr(1,e.camera.x+5+(10*(hearts)),(e.camera.y*8)+(e.camera.h*8)-10)
      else
       spr(1,e.camera.x+(e.camera.w*5)+(10*(hearts)),(e.camera.y*8)+(e.camera.h*8)-10)
      end
     end

     pal()

     local startx = 0
     local starty = 0
     if e.camera.x < 64 then
      startx = e.camera.x + 1
      starty = (e.camera.y + e.camera.h*8) - 2
     else
      startx = e.camera.x + (e.camera.w*8) - 3
      starty = (e.camera.y + e.camera.h*8) - 2
     end
     if e.battle.health > 0 then
      rectfill(startx,starty,startx + 1, starty - (((e.camera.h*8)-3) / 100 * e.battle.health),8)
     end
    end

    if e:has('powerup') and e.player == true then
     spr(48 + e.powerup.type + (2*e.powerup.type) - e.powerup.type, e.camera.x + e.camera.w*4 - 4 , e.camera.y + e.camera.h*8 - 10)
    end

    if e.player and e:has('powerup') and e.powerup.numberleft < 5 then
     if e.camera.x < 64 then
      print(e.powerup.numberleft,e.camera.x + e.camera.w*4 + 6 , e.camera.y + e.camera.h*8 - 10 ,5)
     else
      print(e.powerup.numberleft,e.camera.x + e.camera.w*4 - 6 , e.camera.y + e.camera.h*8 - 10 ,5)
     end
    end

 end

 end
end

-----------------
-- powerup system
-----------------

powerupsystem = {}
powerupsystem.__index = powerupsystem

function powerupsystem:create(props)
    local this = {}
    local props = props or {}
    this.next = props.next or 300

    setmetatable(this, powerupsystem)
    return this
end

function powerupsystem:update(w)
 local powerupfound = false

 for e in all(w) do
  if e:has('powerup') and e.player == false then
   powerupfound = true
   self.next = 300
  end
 end

 self.next -= 1

 if powerupfound == false and self.next < 1 then

  self.next = 200

  local px, py = findfreeloc(leveldata[level].poweruppos,w)

  local ptype = 2

  -- bouncy bullets not implemented for now.
  while ptype == 2 do
   ptype = flr(rnd(6))
  end

  local snum = ptype + 48 + (2*ptype) - ptype

  local nl
  if ptype == 5 then nl=3 else nl=1000 end

  sfx(4)
  add(w,entity:create({
   sprite      = sprite:create({ number=snum, spritesinsheet=1 }),
   animation   = animation:create({ frames=2, animspeed=6, movementanim='always' }),
   position    = position:create({ x=px, y=py, w=8 }),
   camera      = camera:create({ x=52, y=100, w=3, h=3 }),
   collision   = collision:create({ isdestroyed=true }),
   powerup     = powerup:create({  type=ptype, numberleft=nl })
  }))

 end

 for e in all(w) do
  if e.player == true and e:has('powerup') then
   e.powerup.timeremaining -= 1
   if e.powerup.timeremaining < 1 then
    e.powerup = nil
   end
  end
 end

end

function shuffle(structure)
 local count = #structure
 for i=count,2,-1 do
  local j = flr(rnd(i))+1
  structure[i], structure[j] = structure[j], structure[i]
 end
 return structure
end

------------
-- game loop
------------

function reset_game()
--reset game
-- todo -- this needs to also happen when user selects a new level.
-- in a separate function.
world = {}
add(world,p1)
add(world,p2)
p1.position.x, p1.position.y = findfreeloc(leveldata[level].spawn,world)
p1.camera.shake          = false
p1.camera.shakeremaining = 6
p1.battle.lives = 2
p1.battle.health = p1.battle.maxhealth

p2.position.x, p2.position.y = findfreeloc(leveldata[level].spawn,world)
p2.camera.shake          = false
p2.camera.shakeremaining = 6
p2.battle.lives = 2
p2.battle.health = p2.battle.maxhealth

playersalive = 2
end

function _init()

-------------
-- start game
-------------

phys = physicssystem:create()
gs = graphicssystem:create()
cs = collisionsystem:create()
as = animationsystem:create()
ws = weaponsystem:create()
bs = battlesystem:create()
cts = controlsystem:create()
ps = powerupsystem:create()

 -- go through map and find
 -- spawn and powerup points

 local x = 0
 local y = 0

 for l=1,#leveldata do
 for x=leveldata[l].map_topx, leveldata[l].map_topx+leveldata[l].map_width do
  for y=leveldata[l].map_topy, leveldata[l].map_topy+leveldata[l].map_height do
   if fget(mget(x,y),6) then
    add(leveldata[l].spawn,{x*8,y*8})
   end
   if fget(mget(x,y),7) then
    add(leveldata[l].poweruppos,{x*8,y*8})
   end
  end
 end

 end

 --local sx, sy = findfreeloc(leveldata[level].spawn,world)

 -- player 1
 p1 = entity:create({
   player    = true,
   sprite    = sprite:create(),
   animation = animation:create(),
   position  = position:create({ }), -- x=sx+1, y=sy }),
   controls  = controls:create(),
   intention = intention:create(),
   camera    = camera:create(),
   battle    = battle:create(),
   weapon    = weapon:create(),
   collision = collision:create()
 })
 add(world,p1)

 --local sx2, sy2 = findfreeloc(leveldata[level].spawn,world)

 -- player 2
 p2 = entity:create({
   player    = true,
   sprite    = sprite:create({ recolour = {0,5,2,3,4,5,6,7,14,9,10,11,3,13,14,4} }),
   animation = animation:create(),
   position  = position:create({ }), --x = sx2+1, y = sy2 }),
   controls  = controls:create({ p = 1 }),
   intention = intention:create(),
   camera    = camera:create({ x = 64 }),
   battle    = battle:create(),
   weapon    = weapon:create(),
   collision = collision:create(),
 })
 add(world,p2)

 stateman = statemanager:create()

 startstate = state:create({})
 function startstate:draw()
  cls(2)
  spr(64,48,min(38, -20 + stateman.frame * 3),4,2)
  spr(68,min(20, -50 + stateman.frame * 3),38,2,2)
  pal(1,5)
  pal(8,14)
  pal(12,3)
  pal(15,4)
  spr(68,max(92, 16*8+35 - stateman.frame * 3),38,2,2,1)
  pal()
  spr(70,90,max(90, 200 - stateman.frame * 3))
  spr(111,30,max(90, 200 - stateman.frame * 3))
  print('instructions',10,max(100, 210 - stateman.frame * 3),6)
  print('start',84,max(100, 210 - stateman.frame * 3),6)

  print('by rik',4,118,14)
 end

 startstateout = state:create({time=30})
 function startstateout:draw()
  cls(2)
  spr(64,48,max(38, 38 + stateman.frame * 10),4,2)
  spr(68,20,max(38, 38 + stateman.frame * 10),2,2)
  pal(1,5)
  pal(8,14)
  pal(12,3)
  pal(15,4)
  spr(68,92,max(38, 38 + stateman.frame * 10),2,2,1)
  pal()
  --print('  ⬆️     ',16,max(64, 64 + stateman.frame * 10),6)
  --print('⬅️⬇️➡️ c ',16, max(70, 70 + stateman.frame * 10),6)
  --print('     e  ',78, max(64, 64 + stateman.frame * 10),6)
  --print('w  s d f',78,max(70, 70 + stateman.frame * 10),6)
  --print('by rik',4,max(118, 118 + stateman.frame * 10),14)
  spr(111,30,max(90, 90 + stateman.frame * 10))
  print('instructions',10,max(100, 100 + stateman.frame * 10),6)
  print('start',90,max(100, 100 + stateman.frame * 10),6)
  local offset = stateman.frame % 2
  if offset == 1 then
    if animstate == 0 then animstate = 1 else animstate = 0 end
  end
  if animstate == 1 then
   spr(70,90,90)
  else
   spr(71,90,90)
  end
 end

 instatein = state:create({time=30})
 function instatein:draw()
  cls(2)
  spr(64,48,max(38, 38 + stateman.frame * 10),4,2)
  spr(68,20,max(38, 38 + stateman.frame * 10),2,2)
  pal(1,5)
  pal(8,14)
  pal(12,3)
  pal(15,4)
  spr(68,92,max(38, 38 + stateman.frame * 10),2,2,1)
  pal()
  --print('  ⬆️     ',16,max(64, 64 + stateman.frame * 10),6)
  --print('⬅️⬇️➡️ c ',16, max(70, 70 + stateman.frame * 10),6)
  --print('     e  ',78, max(64, 64 + stateman.frame * 10),6)
  --print('w  s d f',78,max(70, 70 + stateman.frame * 10),6)
  --print('by rik',4,max(118, 118 + stateman.frame * 10),14)
  spr(70,90,max(90, 90 + stateman.frame * 10))
  print('instructions',10,max(100, 100 + stateman.frame * 10),6)
  print('start',90,max(100, 100 + stateman.frame * 10),6)
  local offset = stateman.frame % 2
  if offset == 1 then
    if animstate == 0 then animstate = 1 else animstate = 0 end
  end
  if animstate == 1 then
   spr(111,30,90)
  else
   spr(127,30,90)
  end
 end

 levelstate = state:create({})
 function levelstate:draw()
  cls(2)
  print(leveldata[level].name,min(-100+stateman.frame*10,10),10,6)
  if level > 1 then
   spr(86,32,max(110, 150 - stateman.frame * 3))
  end
  spr(70,60,max(110, 150 - stateman.frame * 3))
  if level < #leveldata then
   spr(87,128-40,max(110, 150 - stateman.frame * 3))
  end
  rectfill(min(27,-130+27+stateman.frame*10),27,min(128-28,-130+128-28+stateman.frame*10),128-27,leveldata[level].colour)
  map(leveldata[level].map_topx+(flr(leveldata[level].map_width/2))-4, leveldata[level].map_topy+(flr(leveldata[level].map_height/2))-4,max(32,150-stateman.frame * 10),32,8,8)
 end

 instate = state:create({})
 function instate:draw()
  cls(2)
  spr(68,min(20, -50 + stateman.frame * 3),8,2,2)
  pal(1,5)
  pal(8,14)
  pal(12,3)
  pal(15,4)
  spr(68,max(92, 16*8+35 - stateman.frame * 3),8,2,2,1)
  pal()
  print('  ⬆️     ',min(16, -100 + stateman.frame * 3),34,6)
  print('⬅️⬇️➡️ c ',min(16, -100 + stateman.frame * 3),40,6)
  print('     e  ',max(78, 16*8+70 - stateman.frame * 3),34,6)
  print('w  s d f',max(78, 16*8+70 - stateman.frame * 3),40,6)
  spr(48,max(30,200-stateman.frame*4),55)
  print('speed',max(40,210-stateman.frame*4),56)
  spr(50,max(30,205-stateman.frame*4),55+(8*1))
  print('rapid fire',max(40,215-stateman.frame*4),56+(8*1))
  spr(54,max(30,210-stateman.frame*4),55+(8*2))
  print('long range',max(40,220-stateman.frame*4),56+(8*2))
  spr(56,max(30,215-stateman.frame*4),55+(8*3))
  print('maximum damage',max(40,225-stateman.frame*4),56+(8*3))
  spr(58,max(30,220-stateman.frame*4),55+(8*4))
  print('landmines',max(40,230-stateman.frame*4),56+(8*4))
  spr(60,max(30,225-stateman.frame*4),55+(8*5))
  print('full health',max(40,235-stateman.frame*4),56+(8*5))
  spr(111,60,max(110, 150 - stateman.frame * 4))
 end


  instateout = state:create({time=30})
  function instateout:draw()
   cls(2)

   spr(68,20,max(8,8+stateman.frame*10),2,2)
   pal(1,5)
   pal(8,14)
   pal(12,3)
   pal(15,4)
   spr(68,92,max(8,8+stateman.frame*10),2,2,1)
   pal()
   print('  ⬆️     ',16,max(34,34+stateman.frame*10),6)
   print('⬅️⬇️➡️ c ',16,max(40,40+stateman.frame*10),6)
   print('     e  ',78,max(34,34+stateman.frame*10),6)
   print('w  s d f',78,max(40,40+stateman.frame*10),6)
   spr(48,30,max(55,55+stateman.frame*10))
   print('speed',40,max(56,56+stateman.frame*10))
   spr(50,30,max(55+(8*1),(55+(8*1))+stateman.frame*10))
   print('rapid fire',40,max(56+(8*1),(56+(8*1))+stateman.frame*10))
   spr(54,30,max(55+(8*2),(55+(8*2))+stateman.frame*10))
   print('long range',40,max(56+(8*2),(56+(8*2))+stateman.frame*10))
   spr(56,30,max(55+(8*3),(55+(8*3))+stateman.frame*10))
   print('maximum damage',40,max(56+(8*3),(56+(8*3))+stateman.frame*10))
   spr(58,30,max(55+(8*4),(55+(8*4))+stateman.frame*10))
   print('landmines',40,max(56+(8*4),(56+(8*4))+stateman.frame*10))
   spr(60,30,max(55+(8*5),(55+(8*5))+stateman.frame*10))
   print('full health',40,max(56+(8*5),(56+(8*5))+stateman.frame*10))

   --spr(111,60,max(110, 150 - stateman.frame * 3))

   local offset = stateman.frame % 2
   if offset == 1 then
     if animstate == 0 then animstate = 1 else animstate = 0 end
   end
   if animstate == 1 then
    spr(111,60,110)
   else
    spr(127,60,110)
   end
  end

 levelstateout = state:create({time=30})
 function levelstateout:draw()
  cls(2)
  print(leveldata[level].name,10,max(10,10 + stateman.frame * 10),6)
  if level > 1 then
   spr(86,32,max(110,110 + stateman.frame*10))
  end
  if level < #leveldata then
   spr(87,128-40,max(110,110+stateman.frame*10))
  end
   rectfill(27,max(27,27+stateman.frame*10),128-28,max(128-27,128-27 + stateman.frame*10),leveldata[level].colour)
   map(leveldata[level].map_topx+(flr(leveldata[level].map_width/2))-4, leveldata[level].map_topy+(flr(leveldata[level].map_height/2))-4,32,max(32,32+stateman.frame*10),8,8)
  local offset = stateman.frame % 2
  if offset == 1 then
    if animstate == 0 then animstate = 1 else animstate = 0 end
  end
  if animstate == 1 then
   spr(70,60,110)
  else
   spr(71,60,110)
  end
 end

 readystate = state:create({time=70})
 function readystate:draw()
  gs:update(world)
  local n = (stateman.frame - 40)*5
  if stateman.frame < 40 then
   rectfill(0,0,64,128,2)
   rectfill(65,0,128,128,2)
   print("ready?",54,min(60,-10+stateman.frame*5),6)
  else

  local i
  for i=0,128,4 do
   rectfill(0-n,i,128-n,i+1,2)
  end
  for i=2,128,4 do
   rectfill(0+n,i,128+n,i+1,2)
  end
 end
 end

 gamestate = state:create({})
 function gamestate:draw()
  gs:update(world)
  updatepart()
 end

 winnerstate = state:create({time=180})
 function winnerstate:draw()
  gs:update(world)

  local offset = stateman.frame % 5
  if offset == 1 and stateman.frame > 30 then
    if animstate == 0 then
     animstate = 1
     sfx(2)
    else
     animstate = 0
    end
  end

  cls()
  for e in all(world) do

   if e.player then

   -- use sprite palette info to recolour sprite
   -- (arrys start at 1)
   for c=0,15 do
    pal(c,e.sprite.recolour[c+1])
   end

    -- clip(e.camera.x,e.camera.y,e.camera.w*8,e.camera.h*8)
    local pos_x = e.camera.x + (e.camera.w*8)/2 -- + e.position.w/2
    local pos_y = e.camera.y + (e.camera.h*8)/2 -- + e.position.h/2
    spr(e.sprite.number+4, pos_x-(e.position.w/2), pos_y-(e.position.h/2) - 5*animstate)

    pal()

    for i=1,stateman.frame do
     circ(pos_x, pos_y, max(140-(i),15),2)
    end
    -- clip()
   end
  end

 end

 startstate.next = startstateout
 startstateout.next = levelstate
 instatein.next = instate
 instate.next = instateout
 instateout.next = startstate
 levelstate.next = levelstateout
 levelstateout.next = readystate
 readystate.next = gamestate
 gamestate.next = winnerstate
 winnerstate.next = startstate

 function startstate:update()
  if stateman.frame > 40 and btnp(4,0) then
    return self.next
  elseif stateman.frame > 40 and btnp(5,0) then
    return instatein
  else
   return self
  end
 end

 function instatein:update()
  if stateman.frame == 1 then sfx(5) end
  self.timeremaining -= 1
  if self.timeremaining < 1 then
   self.timeremaining = self.time
   return self.next
  end
  return self
 end

 function instate:update()
  if stateman.frame > 40 and btnp(5,0) then
    return self.next
  else
   return self
  end
 end

 function startstateout:update()
  if stateman.frame == 1 then sfx(5) end
  self.timeremaining -= 1
  if self.timeremaining < 1 then
   self.timeremaining = self.time
   return self.next
  end
  return self
 end

 function levelstate:update()
 if stateman.frame > 10 and btnp(4,0) then
  return self.next
 end
 -- left
 if btnp(0,0) and level > 1then
  level -= 1
  --if level < 1 or leveldata[level] == nil then level = #leveldata end
  stateman.frame = 0
  sfx(6)
 end
 -- right
 if btnp(1,0) and level < #leveldata then
  level += 1
  --if level > #leveldata then level = 1 end
  stateman.frame = 0
  sfx(6)
 end
 return self
 end

 function instateout:update()
 if stateman.frame == 1 then sfx(5) end
  self.timeremaining -= 1
  if self.timeremaining < 1 then
   self.timeremaining = self.time
   return self.next
  end
  return self
 end

 function levelstateout:update()
 if stateman.frame == 1 then sfx(5) end
  self.timeremaining -= 1
  if self.timeremaining < 1 then
   self.timeremaining = self.time
   return self.next
  end
  return self
 end
 function gamestate:update()
   phys:update(world)
   cs:update(world)
   as:update(world)
   ws:update(world)
   bs:update(world)
   cts:update(world)
   ps:update(world)

  -- delete entities
  for e in all(world) do
   if e.del then del(world,e) end
  end

  if playersalive < 2 then
   return self.next
  else
   return self
  end

 end

 function readystate:update()

  if stateman.frame == 1 then
   reset_game()
  end

  -- ready screen shows for
  -- a specific time
  self.timeremaining -= 1
  if self.timeremaining < 1 then
   self.timeremaining = self.time
   return self.next
  end
  return self
 end

 function winnerstate:update()
  -- stop rain sound
  music(-1,2000)

  -- screen shows for
  -- a specific time
  self.timeremaining -= 1

  if self.timeremaining < 1 then
   self.timeremaining = self.time
   return self.next
  end
  return self
 end

 stateman.current = startstate

end

function _update()
 stateman:update()
end

function _draw()
 stateman:draw()
end

__gfx__
00000000000000000888800008800000088880000088800008888000088800000888800000088000088880000880000008888000008880000888800008880000
00000000088008800888800008888000088ff000088f800008ff800008f880000ff88000088880000888800008888000088ff000088f800008ff800008f88000
0070070088888888018810000888f000081ff00008fff00001ff10000fff80000ff180000f888000018810000888f000081ff00008fff00001ff10000fff8000
000770008888888801811000081ff0000811100008f1100001111000011f8000011180000ff1800001811000081ff0000811100008f1100001111000011f8000
00077000088888800118100008111000081f1000081110000f11f0000111800001f1800001118000f118100008111000081f1000081110000f111f0001118000
0070070000888800018110000011f000011f100001f1100001111000011f100001f110000f11000001811000001f10000111f0000f111000011110000111f000
00000000000880000111100000c1100001111000011c00000111100000c1100001111000011c00000111100000c11000011110000110c000011110000c011000
00000000000000000c00c000000c100000cc000000c000000c00c000000c000000cc000001c000000c000000000010000c0c000000c000000000c000000c0000
08888000000880000888800008800000088880000088800008888000088800000888800000088000088880000880000008888000008880000888800008880000
0ff88000088880000888800008888000088ff000088f800008ff800008f880000ff88000088880000888800008888000088ff000088f800008ff800008f88000
0ff180000f888000018810000888f000081ff00008fff00001ff10000fff80000ff180000f888000018810000888f000081ff00008fff00001ff10000fff8000
011180000ff1800001811000081ff0000811100008f1100001111000011f8000011180000ff1800001811000081ff0000811100008f1100001111000011f8000
01f18000011180000118100008111000081f1000081110000f11f0000111800001f180000111800001181f0008111000081f100008111000f111f00001118000
0f11100001f10000018110000011f000011f100001f1100001111000011f100001f110000f1100000181100000111f0001f11000011f10000111100001f11000
01111000011c00000111100000c1100001111000011c00000111100000c1100001111000011c0000011110000001100001111000011000000111100000111000
00c0c000010000000c00c000000c100000cc000000c000000c00c000000c000000cc000001c000000000c000000c100000c0c000000c00000c00000000c00000
08888000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000066000000000000001111111122222222
0ff88000088880000000000000000000000000000000000000000000000000000000000000000000000000000000000066000000000000001155555122555522
0ff180000f8880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001511111125222252
011180000ff180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001155551125222252
01f18000011180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111115125555522
011f1000f11100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111115125222222
01111000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001555551125222222
0c0c000001c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111122222222
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555500000055550000
57447445564464455774444556644445544444455444444557774445566644455744447556444465544444455444444554444445544444455500000056650000
54744745546446455744444556444445544744455446444557744445566444455474474554644645545555455455554557744775566446650000000056650000
54474475544644655447744554466445547444455464444557474445564644455444444554444445545775455456654557777775566666650000000055550000
54474475544644655447444554464445574444455644444554447475544464655444444554444445545775455456654557777775566666650000000000000000
54744745546446455444477554444665547474455464644554444775544446655474474554644645545555455455554554777745546666450000000000000000
57447445564464455444477554444665544744455446444554447775544466655744447556444465544444455444444554477445544664450000000000000000
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000000000000000
666666666666666666666666666666660000008888880000666666655555555566666666666666666756666633333333333333333b33333333333333cccccccc
6666666666666666666666666666666600000088888800006655556555666655666666666766566666666666333333333333373333333333333333b3cc7ccccc
6677777777777777777777777777776600008888ff8800006566666556555555666666666666666666666766333333333333777333333b3333333333cccccccc
6677777777777777777777777777776600008888ff880000656666655655555566666666667666766676665633333333333337333b33333333733333ccccc7cc
66755577755775557555757775557766000088ffffff00006566666556555555666666666665666666667666333333333333333b33333333333a3333cccccccc
66757757577577577757757775777766000088ffffff00006655556555666655666666666666666676676567333333333a3333333333373333333333ccc7cccc
66757757577577577757757775777766000088ff111100006666666555555555666666666566756666656666333333333337333333337a7333333b33cccccccc
66755577555577577757757775577766000088ff11110000555555555555555566666666666666666676666633333333333333333333373333333333cccccccc
6675775757757757775775777577776600008811111100006666666566666665aaaaaaaaa9aaaaaaaaaaaaa944444444444c444c4444444444434443ccc7cccc
6675775757757757775775777577776600008811111100006665666566656665aaaaaaaaaaaaaaaaaa9aa9aa44444444444c444c4444444444434443ccc7cccc
66757757577577577757757775777766000011ff111100006656666566665665aaaaaaaaaaaaaaaaaaaaaaaa44444444444c444c4444444444434443cc7ccccc
66755577577577577757755575557766000011ff111100006555556565555565aaaaaaaaaaaaa9aaaaa9aaaacccccccc444c444c333333334443444377cccccc
6677777777777777777777777777776600001111cc0000006656666566665665aaaaaaaaaa9aaaaaa9aaa9aa44444444444c444c4444444444434443cccccc77
6677777777777777777777777777776600001111cc0000006665666566656665aaaaaaaaaaaaaaaaaaaaaaaa44444444444c444c4444444444434443ccccc7cc
66666666666666666666666666666666000000cc000000006666666566666665aaaaaaaaaa9aaaa9aa9aaaa944444444444c444c4444444444434443cccc7ccc
66666666666666666666666666666666000000cc000000005555555555555555aaaaaaaaaaaaaaaaaaaa9aaacccccccc444c444c3333333344434443cccc7ccc
ffff6fff6667666777777777ffff777766566566ccc44ccccccccccc333666333b3bbb3b3333333b3333333333333333333333bb000000000000000066666665
77776f776667666776777677ffff777766566566ccc44cccccc44ccc36666633bbb33bb333bb33bbb33b33333bb333bbb3b3bbbb00000000000000c065666565
77776f776667666766676667ffff777755666655cc4554cccc4554cc36666666bbbbb3b33bbb33bbbbbb3333333bbbbbbbbbbbb300000000000000c066565665
666666667777666776777677ffff777766666666c454454c44544544666666663b3bb3bb3bbbbbbbbbbbbb33333bbbbbbbbbbbb300000000000000c066656665
6fffffff66676667777777777777ffff66666666c454454c44544544666666663bbbbbb3333bbbbbbbbbbbb33bbbbbbbb3bbbb3300000000000000c066565665
6f77777766676667777677767777ffff55666655cc4554cccc4554cc6666666633bbbb3b333bbbbbbbbbbbb3bb3bbbbbbbbb3b330000000000c000c065666565
6f77777766676667676667667777ffff66566566ccc44cccccc44ccc366666333b3b3bb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbb330000000000c000c066666665
6666666666677777777677767777ffff66566566ccc44ccccccccccc3666333333b33b333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb30000000000c000c055555555
7777677733344333333333333333333333333333333443333334433336666633bb3bbb333bbbbbbbbbbbbbbb33bbbb3bbbbbbbb30000000000c0000055555555
66666666333443333334433333344333333443333334433333344333366666633bb3bbb33bbbbbbbbbbbbbbb33bbbbbbbbbbbbb3c000000000c0000056555655
67777777334554333345543333455433334554333345543333455433666666663b3bbb3333bbbbbbbbbbbbbb3bbbbbbbbbbbbbb30000000000c0000055656555
666666663454454344544544345445444454454334544544445445436666666633bbbbbb333bbbbbbbbbbbb33bbbbbbb33bbbb3300c0c00000c0000055565555
777767773454454344544544345445444454454334544544445445436666666633bbbbb333b3bbbbbbbbbb3333bbbbb3bbbbbb33000000000000000055656555
6666666633455433334554333345543333455433334554333345543366666666bbbbbb3b3bbbbbbbbbbbb333333bbbbbbbbbbb330c000c0c0c0c000056555655
67777777333443333334433333344333333443333334433333344333666666633b3bbbb33b333bbbb3bbbb3333333bbbbbb3bb33000000c000c0000055555555
666666663334433333333333333443333334433333333333333333333666663333b333b333333333333333333333333333333b33000000000000000055555555
__label__
88333333333333333333333333333333333333333333333333333333333333338844444444444444444444444444444444444444444444444444444444444444
88333333333333333333333333333333333333333333333333333333333333338844444444444444444444444444444444444444444444444444444444444444
88333333333333333333333333333333333333333333333333333333333333338844444444444444444444444444444444444444444444444444444444444444
88333333333333333333333333333333333333333333333333333333333333338844444444444444444444444444444444444444444444444444444444444444
88333333333333333333333333333333333333333333333333333333333333338844444444444444444444444444444444444444444444444444444444444444
88333333333333333333333333333333333333333333333333333333333333338844444444444444444444444444444444444444444444444444444444444444
88333333333333333333333333333333333333333333333333333333333333338844444444444444444444444444444444444444444444444444444444444444
88333333333333333333333333333333333333333333333333333333333333338844444444444444444444444444444444444444444444444444444444444444
88333333333333333333333333333333333333333333333333333333333333338844444444444444444444444444444444444444444444444444444444444444
88333333333333333333333333333333333333333333333333333333333333338844444444444444444444444444444444444444444444444444444444444444
88333333333333333333333333333333333333333333333333333333333333338844444444444444445555555555555555555555555555555555555555555555
88333333333333333333333333333333333333333333333333333333333333338844444444444444445666666556666665566666655666666556666665566666
88333333333333333333333333333333333333333333333333333333333333338844444444444444445666666556666665566666655666666556666665566666
88333333333333333333333333333333333333333333333333333333333333338844444444444444445666666556666665566666655666666556666665566666
88333333333333333333333333333333333333333333333333333333333333338844444444444444445666666556666665566666655666666556666665566666
88333333333333333333333333333333333333333333333333333333333333338844444444444444445666666556666665566666655666666556666665566666
88333333333333333333333333333333333333333333333333333333333333338844444444444444445666666556666665566666655666666556666665566666
88333333333333333333333333333333333333333333333333333333333333338844444444444444445555555555555555555555555555555555555555555555
8833333333333333333333333333333333333333333333333333333333333333884444444444444444555555557777f7777777f7777777f7777777f7777777f7
8833333333333333333333333333333333333333333333333333333333333333884444444444444444566666656666f7666666f7666666f7666666f7666666f7
8833333333333333333333333333333333333333333333333333333333333333884444444444444444566666656666f7666666f7666666f7666666f7666666f7
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665ffffffffffffffffffffffffffffffffff1fff
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665f7777777f7777777f7777777f7777777f71177
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665f7666666f7666666f7666666f7666661111116
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665f7666666f7666666f7666666f7666661111116
883333333333333333333333333333333333333333333333333333333333333388444444444444444455555555ffffffffffffffffffffffffffffffffff11ff
8833333333333333333333333333333333333333333333333333333333333333884444444444444444555555557777f7777777f7777777f7777777f7777717f7
8833333333333333333333333333333333333333333333333333333333333333884444444444444444566666656666f7666666f7666666f7666666f7666666f7
8833333333333333333333333333333333333333333333333333333333333333884444444444444444566666656666f7666666f7666666f7666666f7666666f7
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665ffffffffffffffffffffffffffffffffffffff
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665f7777777f7777777f7777777f7777777f77777
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665f7666666f7666666f7666666f7666666f76666
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665f7666666f7666666f7666666f7666666f76666
883333333333333333333333333333333333333333333333333333333333333388444444444444444455555555ffffffffffffffffffffffffffffffffffffff
8833333333333333333333333333333333333333333333333333333333333333884444444444444444555555557777f7777777f7777777f7777777f7777777f7
8833333333333333333333333333333333333333333333333333333333333333884444444444444444566666656666f7666666f7666666f7666666f7666666f7
8833333333333333333333333333333333333333333333333333333333333333884444444444444444566666656666f7666666f7666666f7666666f7666666f7
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665ffffffffffffffffffffffffffffffffffffff
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665f7777777f7777777f7777777f7777777f77777
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665f7666666f7666666f7666666f7666666f76666
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665f7666666f7666666f7666666f7666666f76666
883333333333333333333333333333333333333333333333333333333333333388444444444444444455555555ffffffffffffffffffffffffffffffffffffff
883333333333333333333333333333333333333333333333333333333333333388444444444444444455555555555555555555555555555555555555557777f7
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665566666655666666556666665566666656666f7
883333333333333333333333333333333333333333333333333333333333333388444444444444444456666665566666655666666556666665566666656666f7
88333333333333333333333333333333333333333333333333333333333333338844444444444444445666666556666665566666655666666556666665ffffff
88333333333333333333333333333333333333333333333333333333333333338844444444444444445666666556666665566666655666666556666665f77777
88333333333333333333333333333333333333333333333333333333333333338844444444444444445666666556666665566666655666666556666665f76666
88333333333333333333333333333333333333333333333333333333333333338844444444444444445666666556666665566666655666666556666665f76666
88333333333333333333333333333333333333333333333333333333333333338844444444444444445555555555555555555555555555555555555555ffffff
8855555555555555555555555555555555555555555555555555555555555555884444444444444444555555557777f7777777f7777777f7777777f7777777f7
8866655666666556666665566666655666666556666665566666655666666556884444444444444444566666656666f7666666f7666666f7666666f7666666f7
8866655666666556666665566666655666666556666665566666655666666556884444444444444444566666656666f7666666f7666666f7666666f7666666f7
886665566666655666666556666665566666655666666556666665566666655688444444444444444456666665ffffffffffffffffffffffffffffffffffffff
886665566666655666666556666665566666655666666556666665566666655688444444444444444456666665f7777777f7777777f7777777f7777777f77777
886665566666655666666556666665566666655666666556666665566666655688444444444444444456666665f7666666f7666666f7666666f7666666f76666
886665566666655666666556666665566666655666666556666665566666655688444444444444444456666665f7666666f7666666f7666666f7666666f76666
885555555555555555555555555555555555555555555555555555555555555588444444444444444455555555ffffffffffffffffffffffffffffffffffffff
88f7777777f7777777f7777777f7777777f7777777f7777777f7777777f77755884444444444444444555555557777f7777777f7777777f7777777f7777777f7
88f7666666f7666666f7666666f7666666f7666666f7666666f7666666f76656884444444444444444566666656666f7666666f7666666f7666666f7666666f7
88f7666666f7666666f7666666f7666666f7666666f7666666f7666666f76656884444444444444444566666656666f7666666f7666666f7666666f7666666f7
88ffffffffffffffffffffffffffffff1fffffffffffffffffffffffffffff5688444444444444444456666665fffff22fffffffffffffffffffffffffffffff
887777f7777777f7777777f7777777f7117777f7777777f7777777f77777775688444444444444444456666665f7772222f7777777f7777777f7777777f77777
886666f7666666f7666666f766666111111666f7666666f7666666f76666665688444444444444444456666665f762222227666666f7666666f7666666f76666
886666f7666666f7666666f766666111111666f7666666f7666666f76666665688444444444444444456666665f7666226f7666666f7666666f7666666f76666
88ffffffffffffffffffffffffffffff11ffffffffffffffffffffffffffff5588444444444444444455555555fffff22fffffffffffffffffffffffffffffff
88f7777777f7777777f7777777f7777717f7777777f7777777f7777777f77755884444444444444444555555557777f2277777f7777777f7777777f7777777f7
88f7666666f7666666f7666666f7666666f7666666f7666666f7666666f76656884444444444444444566666656666f7666666f7666666f7666666f7666666f7
88f7666666f7666666f7666666f7666666f7666666f7666666f7666666f76656884444444444444444566666656666f7666666f7666666f7666666f7666666f7
88ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5688444444444444444456666665ffffffffffffffffffffffffffffffffffffff
887777f7777777f7777777f7777777f7777777f7777777f7777777f77777775688444444444444444456666665f7777777f7777777f7777777f7777777f77777
886666f7666666f7666666f7666666f7666666f7666666f7666666f76666665688444444444444444456666665f7666666f7666666f7666666f7666666f76666
886666f7666666f7666666f7666666f7666666f7666666f7666666f76666665688444444444444444456666665f7666666f7666666f7666666f7666666f76666
88ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5588444444444444444455555555ffffffffffffffffffffffffffffffffffffff
88f7777777f7777777f7777777f7777777f7777777f7777777f7777777f777448844444444444444445555555555555555555555555555555555555555555555
88f7666666f7666666f7666666f7666666f7666666f7666666f7666666f766448844444444444444445666666556666665566666655666666556666665566666
88f7666666f7666666f7666666f7666666f7666666f7666666f7666666f766448844444444444444445666666556666665566666655666666556666665566666
88ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff558844444444444444445666666556666665566666655666666556666665566666
887777f7777777f7777777f7777777f7777777f7777777f7777777f7777777448844444444444444445666666556666665566666655666666556666665566666
886666f7666666f7666666f7666666f7666666f7666666f7666666f7666666448844444444444444445666666556666665566666655666666556666665566666
886666f7666666f7666666f7666666f7666666f7666666f7666666f7666666448844444444444444445666666556666665566666655666666556666665566666
88ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff448844444444444444445555555555555555555555555555555555555555555555
8855555555555555555555555555557777f7777777f7777777f7777777f77744884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
8866655666666556666665566666656666f7666666f7666666f7666666f76644884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
8866655666666556666665566666656666f7666666f7666666f7666666f76644884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
886665566666655666666556666665ffffffffffffffffffffffffffffffff55884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
886665566666655666666556666665f7777777f7777777f7777777f777777744884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
886665566666655666666556666665f7666666f7666666f7666666f766666644884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
886665566666655666666556666665f7666666f7666666f7666666f766666644884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
885555555555555555555555555555ffffffffffffffffffffffffffffffff44884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88f7777777f7777777f7777777f7777777f7777777f7777777f7777777f77744884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88f7666666f7666666f7666666f7666666f7666666f7666666f7666666f76644884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88f7666666f7666666f7666666f7666666f7666666f7666666f7666666f76644884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
887777f7777777f7777777f7777777f7777777f7777777f7777777f777777744884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
886666f7666666f7666666f7666666f7666666f7666666f7666666f766666644884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
886666f7666666f7666666f7666666f7666666f7666666f7666666f766666644884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88f7777777f7777777f7777777f7777777f7777777f7777777f7777777f77755884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88f7666666f7666666f7666666f7666666f7666666f7666666f7666666f76656884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88f7666666f7666666f7666666f7666666f7666666f7666666f7666666f76656884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88f22fffffffffffffffffffffffffffffffffffffffffffffffffffffffff56884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
882222f7777777f7777777f7777777f7777777f7777777f7777777f777777756884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88222227666666f7666666f7666666f7666666f7666666f7666666f766666656884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
886226f7666666f7666666f7666666f7666666f7666666f7666666f766666656884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88f22fffffffffffffffffffffffffffffffffffffffffffffffffffffffff55884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88f2277777f7777777f7777777f7777777f7777777f7777777f7777777f77755884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88f7666666f7666666f7666666f7666666f7666666f7666666f7666666f76656884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88f7666666f7666666f7666666f7666666f7666666f7666666f7666666f76656884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff56884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
887777f7777777f7777777f7777777f7777777f7777777f7777777f777777756884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
886666f7666666f7666666f7666666f7666666f7666666f7666666f766666656884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
886666f7666666f7666666f7666666f7666666f7666666f7666666f766666656884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55884444444444444444ffffffffffffffffffffffffffffffffffffffffffffff
88555555555555555555555555555555555555555555555555555555555555558844444444444444444444444444444444444444444444444444444444444444
88666556666665566666655666666556666665566666655666666556666665568844444444444444444444444444444444444444444444444444444444444444
88666556666665566666655666666556666665566666655666666556666665568844444444444444444444444444444444444444444444444444444444444444
88666556666665566666655666666556666665566666655666666556666665568844444444444444444444444444444444444444444444444444444444444444
88666556666665566666655666666556666665566666655666666556666665568844444444444444444444444444444444444444444444444444444444444444
88666588668865568866885666666556666665566666655666666556666665568844448844884444884488444444444444444444444444444444444444444444
88666888888885588888888666666556666665566666655666666556666665568844488888888448888888844444444444444444444444444444444444444444
88555888888885588888888555555555555555555555555555555555555555558844488888888448888888844444444444444444444444444444444444444444
88ffff888888ffff888888ffffffffffffffffffffffffffffffffffffffffff8844448888884444888888444444444444444444444444444444444444444444
88fffff8888ffffff8888fffffffffffffffffffffffffffffffffffffffffff8844444888844444488884444444444444444444444444444444444444444444
88ffffff88ffffffff88ffffffffffffffffffffffffffffffffffffffffffff8844444488444444448844444444444444444444444444444444444444444444
88ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8844444444444444444444444444444444444444444444444444444444444444
88ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8844444444444444444444444444444444444444444444444444444444444444
88ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8844444444444444444444444444444444444444444444444444444444444444

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040800000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000030000000000010101010101010100000001010101010101010101010101000000
0000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
707070707070707070707070707070707070707070707070707070707070707073727272727272727272727272727272727272727272727272727272727272747f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
702e484848484848484848484848484848484848484848484848484848482e70712e4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4d4b4b4b4b4b4b4e684b4b2e717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4e4b4b4b4b4b4b784b4b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70484848484848484848484848484848484848484848484848484848484848707167774b4b4b4d4b4b4b4b4b4b7868696a6b6c4b4b4b4b4c4b4b4b696c4e4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
704848484848484848484848484848484848484848488080484848484848487071774e4b4b4b4b4c4b4b4b4b4b4b4b797a7b7c4b4b4b4c4d7878687b7c4b68717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4d4b4b4b4b4b4b4b4b4b4b4e696c2f4d6b6c4b4b4b4b684b4b4b4b4b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b4b4b4b4b4b4b4b4b4b797c4b4b797a4b4b4b4b784b4b4b4b4b78717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b4d4b4b4b4b4b4b4c4b4b4b4b4b784b4b4d4c696a4b4b78686878717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b7b7a4b4b6b6a4b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714e4c4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b784b4b797c4b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b4b2f4f4f684b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4e4b4b4b4b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b4b4f4f4f4f4b4c4b4b4b4b4b4d4b4b4c4b4b4b4b4b4b4b4b4b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4c4b4b4f4f4f4f4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4d4b696a4f4f4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b775d5d674f4f4f5f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b797a4b4b4b4b4b4b4c4b4d4b4b4e4b4b4b4b4b675d5b4f4f4f5f5f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70484848484848484848484848482f2f2f2f4848484848484848484848484870714b4d4b4b4b4b4d4b4b4b4b4b4b4b78696a4b4b4b4f4f4f4f5b5b4f4f2e4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70484848484848484848484848482f2f2f2f4848484848484848484848484870714b4b4b4b4b4b4b4b4b4b4b4f4f4f4f797a4f4f4f4f4f4f4f5b5b784b4b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b4b4b4b4b4e4d4f4f4f4f4f4f4f5f4f4f4b4b2f675d5d774b4b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4c4b4b4b4b4b68784f4f4f5f5f5f5f5f4f784b4b67774b4b4b4b4b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b4b4b4b4e4c684f4f4f5f4f5f5f4f684b4b4b4b4b4b4b4b4c4b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b4b4e4b4b4b5e5c5c5c2f4f5f5f4f4b4b4b4b4b4b4b4d4b4b4b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4d4b4b4b4b4e4b5c5c5c5c5c4f4f4f4b4b4b4b4b4b4b727272744e4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b4b4b4b4d67774f4f4f4f4f4f4f4c4b4b4b4d4b4b4b4b4b714b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4e4b4b4b4b4b4b784f4f4f4f4f4b4b4b4b4b4b4b4b4b4b4b714b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4e4b4b4b4e4b4b4b4b4c4b4f4f4f4f4b4b4b4b4b4b4b4b4b4b4b714b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b4b4b4c4b4b4b4b4e4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b714b4b717f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4b4b4b4b4b4b4b4b4c4e4b4b4b4b4b4b4b4b4b4e4b4b4b4c4b714b2f4f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870716b6c4b684b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b7777674e4b4b4b4b4f4f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870717b7c4e2e784b4b4b4b4b4b4b4b4b4b4b4b4d4b6777674b4b4b4b4b4b4f5f5f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7048484848484848484848484848484848484848484848484848484848484870714b4b4e4d4b4b4b4b4b4b4b4b4b4b4b4b4b4b4c674b4b4d4b4f4f4f4f5f5f4f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
702e484848484848484848484848484848484848484848484848484848482e70714c4b4b4b4b4b4b4b4b4b4b4e4b4b4b4b4b4b4b4b4b4b4f4f4f4f5f5f5f5f4f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070707070707070707070707070707070707070707070707070707070707070757272727272727272727272727272727272724f4f5f5f5f5f5f4f4f4f4f4f4f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100002f4502e4502d4502a450274502545023450224501f4501c4501a450174501545013450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000013650226502265022650206501365016650196501c65014650146501465016650196500f6501d6501e6501e650156501f6501b6501b650196501e650236501a650216501a650136500f6501f6500e650
000200003603034030310302d02000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000a05014050230503d05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500003c55037550335500150001500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002105029100270502a1002f0502d000350502b0002f0000000026100000002b1000000029100000002710002300271000230027100023002710000000271003e600271000000027100000002710000000
000500002452010500036001050003600105000360003600036000360003600036000360003600036000360003600036000360003600036000360003600036000360003600036000360003600036000360003600
001200000161001610016100161001610016100161001610016100161001610016100161001610016100161001610016100161001610016100161001610016100161001610016100161001610016100161001610
001400002461024610246102461024610246102461024610246102461024610246102461024610246102461024610246102461024610246102461024610246102461024610246102461024610246102461024610
__music__
03 07464344
03 08464344
00 45474344
00 45474344
00 45474844
