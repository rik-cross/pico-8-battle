pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- battle
-- by rik

-- todo
-- if collision + speed then move entity until it's next to colliding thing
-- implement all powerups
-- tidy code
-- multiple game loop
-- sound and music

world      = {}
spawn      = {}
poweruppos = {}

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
    this.speed     = props.speed or 4
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

  local xhit = false

  local x1=x_new/8
  local y1=e.position.y/8
  local x2=(x_new+(e.position.w-1))/8
  local y2=(e.position.y+(e.position.h-1))/8
  local xa=fget(mget(x1,y1),0)
  local xb=fget(mget(x1,y2),0)
  local xc=fget(mget(x2,y2),0)
  local xd=fget(mget(x2,y1),0)

  if xa or xb or xc or xd then
   xhit = true
  end

  local yhit = false

  x1=e.position.x/8
  y1=y_new/8
  x2=(e.position.x+(e.position.w-1))/8
  y2=(y_new+(e.position.h-1))/8
  local ya=fget(mget(x1,y1),0)
  local yb=fget(mget(x1,y2),0)
  local yc=fget(mget(x2,y2),0)
  local yd=fget(mget(x2,y1),0)

  if ya or yb or yc or yd then
   yhit = true
  end

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

    if x_new < o_x2 and
           x_new + (e.position.w) > o_x1 and
           y_new < o_y2 and
           y_new + (e.position.h)> o_y1
           then
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

     speed = e.position.speed
     if e.player == true and e:has('powerup') and e.powerup.type == 0 then
      speed = speed + 1
     end

     local side
     if e.player == true and e:has('powerup') and e.powerup.type == 5 then

     if e.position.angle == 0 then
      xpos = e.position.x + e.position.w/2 - 2
      ypos = e.position.y + e.position.h + speed
     elseif e.position.angle == 45 then
      xpos = e.position.x - e.position.w/2 - 2
      ypos = e.position.y + speed + 2
     elseif e.position.angle == 90 then
      xpos = e.position.x - e.position.w/2 - speed - 2
      ypos = e.position.y + e.position.h/2 - 2
     elseif e.position.angle == 135 then
      xpos = e.position.x - e.position.w/2 - speed - 2
      ypos = e.position.y - e.position.h/2 - speed - 2
     elseif e.position.angle == 180 then
      xpos = e.position.x + e.position.w/2 -2
      ypos = e.position.y - e.position.h/2 - speed - 2
     elseif e.position.angle == 225 then
      xpos = e.position.x + e.position.w + 2
      ypos = e.position.y - speed - 2
     elseif e.position.angle == 270 then
      xpos = e.position.x + e.position.w + 2
      ypos = e.position.y + e.position.h/2 - 2
     elseif e.position.angle == 315 then
      xpos = e.position.x + e.position.w + 2
      ypos = e.position.y + e.position.h + 2
     end

     else

     if e.position.angle == 0 then
      xpos = e.position.x + e.position.w/2 - 1
      ypos = e.position.y - e.position.h/2 - speed
     elseif e.position.angle == 45 then
      xpos = e.position.x + e.position.w/2 + speed
      ypos = e.position.y - e.position.h/2 - speed
     elseif e.position.angle == 90 then
      xpos = e.position.x + e.position.w + speed
      ypos = e.position.y + e.position.h/2 - 1
     elseif e.position.angle == 135 then
      xpos = e.position.x + e.position.w + speed
      ypos = e.position.y + e.position.h/2 + speed
     elseif e.position.angle == 180 then
      xpos = e.position.x + e.position.w/2 -1
      ypos = e.position.y + e.position.h + speed
     elseif e.position.angle == 225 then
      xpos = e.position.x - e.position.w/2 - 1
      ypos = e.position.y + e.position.h/2 + speed
     elseif e.position.angle == 270 then
      xpos = e.position.x - e.position.w/2 - speed
      ypos = e.position.y + e.position.h/2 - 1
     elseif e.position.angle == 315 then
      xpos = e.position.x - e.position.w/2 - speed
      ypos = e.position.y - e.position.h/2 - speed
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

     add(w,entity:create({
      sprite    = sprite:create({ number=spritenumber, spritesinsheet = 1 }),
      position  = position:create({
         x = xpos, y=ypos,
         w=size, h=size,
         angle=e.position.angle,
         velocity=vel,
         ranged=r, range=range
       }),
      collision = collision:create({ isdestroyed=true, collisiondamage=damage })
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
      else
       local xnew, ynew = findfreeloc(spawn,w)
       c.position.x = xnew + 1
       c.position.y = ynew
       c.battle.health = 100
      end
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

    if e.player and e:has('powerup') then
     print(e.powerup.numberleft,e.camera.x + e.camera.w*4 + 6 , e.camera.y + e.camera.h*8 - 10 ,6)
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

  local px, py = findfreeloc(poweruppos,w)

  local ptype = 5 -- flr(rnd(2))
  local snum = ptype + 48 + (2*ptype) - ptype

  local nl
  if ptype == 5 then nl=3 else nl=1000 end

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

function _init()

 ---------------
 -- start screen
 ---------------

 cls(2)

 while (not btn(4) and
       not btn(5)) do

  spr(64,48,38,4,2)
  spr(68,20,38,2,2)
  pal(1,5)
  pal(8,14)
  pal(12,3)
  pal(15,4)
  spr(68,92,38,2,2,1)
  pal()
  print('  ⬆️     ',16,64,6)
  print('⬅️⬇️➡️ c ',16,70,6)
  print('     e  ',78,64,6)
  print('w  s d f',78,70,6)
  print('press any key',38,90,6)
  print('by rik-x',4,118,14)

 end

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

  for x=0, 32 do
   for y=0,32 do
    if fget(mget(x,y),6) then
     add(spawn,{x*8,y*8})
    end
    if fget(mget(x,y),7) then
     add(poweruppos,{x*8,y*8})
    end
   end
  end

  local sx, sy = findfreeloc(spawn,world)

  -- player 1
  add(world,entity:create({
    player    = true,
    sprite    = sprite:create(),
    animation = animation:create(),
    position  = position:create({ x=sx+1, y=sy }),
    controls  = controls:create(),
    intention = intention:create(),
    camera    = camera:create(),
    battle    = battle:create(),
    weapon    = weapon:create(),
    collision = collision:create()
  }))

  local sx2, sy2 = findfreeloc(spawn,world)

  -- player 2
  add(world,entity:create({
    player    = true,
    sprite    = sprite:create({ recolour = {0,5,2,3,4,5,6,7,14,9,10,11,3,13,14,4} }),
    animation = animation:create(),
    position  = position:create({ x = sx2+1, y = sy2 }),
    controls  = controls:create({ p = 1 }),
    intention = intention:create(),
    camera    = camera:create({ x = 64 }),
    battle    = battle:create(),
    weapon    = weapon:create(),
    collision = collision:create(),
  }))

end

function _update()

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

end

function _draw()
 gs:update(world)
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
08888000000880006666666677776777ffff6fff44454445bbbbbbbbccccccccaaaaaaaa4444444477777777999999996600000000000000ffff1fffffff8fff
0ff8800008888000666666666666666677776f7744454445bbbbbbbb7cccccc7aaaaaaaa444444447677767799999999660000000000000077771f7777778f77
0ff180000f888000666666666777777777776f7744454445bbbbbbbbc7cccc7caaaaaaaa444444446667666799999999000000000000000077771f7777778f77
011180000ff1800066666666666666666666666655554445bbbbbbbbccccccccaaaaaaaa444444447677767799aaaa9900000000000000001111111188888888
01f180000111800066666666777767776fffffff44454445bbbbbbbbccccccccaaaaaaaa444444447777777799aaaa9900000000000000001fffffff8fffffff
011f1000f111000066666666666666666f77777744454445bbbbbbbbccc77cccaaaaaaaa444444447776777699aaaa9900000000000000001f7777778f777777
011110000110000066666666677777776f77777744454445bbbbbbbbcc7cc7ccaaaaaaaa444444446766676699aaaa9900000000000000001f7777778f777777
0c0c000001c0000066666666666666666666666644455555bbbbbbbbccccccccaaaaaaaa444444447776777699aaaa9900000000000000001111111188888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555500000055550000
57447445564464455774444556644445544444455444444557774445566644455744447556444465544444455444444554444445544444455500000056650000
54744745546446455744444556444445544744455446444557744445566444455474474554644645545555455455554557744775566446650000000056650000
54474475544644655447744554466445547444455464444557474445564644455444444554444445545775455456654557777775566666650000000055550000
54474475544644655447444554464445574444455644444554447475544464655444444554444445545775455456654557777775566666650000000000000000
54744745546446455444477554444665547474455464644554444775544446655474474554644645545555455455554554777745546666450000000000000000
57447445564464455444477554444665544744455446444554447775544466655744447556444465544444455444444554477445544664450000000000000000
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000000000000000
66666666666666666666666666666666000000888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000
666666666666666666666666666666660000008888880000000000aaa00000000000000000000000000000000000000000000000000000000000000000000000
6677777777777777777777777777776600008888ff8800000000aaa9994000000000000000000000000000000000000000000000000000000000000000000000
6677777777777777777777777777776600008888ff880000000aa999444400000000000000000000000000000000000000000000000000000000000000000000
66755577755775557555757775557766000088ffffff000000aa9944444440000000000000000000000000000000000000000000000000000000000000000000
66757757577577577757757775777766000088ffffff000000a99444444440000000000000000000000000000000000000000000000000000000000000000000
66757757577577577757757775777766000088ff111100000aa94444444444000000000000000000000000000000000000000000000000000000000000000000
66755577555577577757757775577766000088ff111100000a994444444444000000000000000000000000000000000000000000000000000000000000000000
6675775757757757775775777577776600008811111100000a944444444444000000000000000000000000000000000000000000000000000000000000000000
66757757577577577757757775777766000088111111000000944444444440000000000000000000000000000000000000000000000000000000000000000000
66757757577577577757757775777766000011ff1111000000944444444440000000000000000000000000000000000000000000000000000000000000000000
66755577577577577757755575557766000011ff1111000000044444444400000000000000000000000000000000000000000000000000000000000000000000
6677777777777777777777777777776600001111cc00000000004444444000000000000000000000000000000000000000000000000000000000000000000000
6677777777777777777777777777776600001111cc00000000000044400000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666000000cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666000000cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000000010000000100000001000040800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2323232323232323232323232323232323232323232323232323232323232323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232e2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2e23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2323232323232323232324242424232323232323232323232a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a232f24242424242424242424242424242424242424242f232a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2324242424242424232324242424232324242424242424232a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2324242424242424232324242424232324242424242424232a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2324242424242424242424242424242424242424242424232a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2324242424242424242424242424242424242424242424232a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2324242423232323232325252525232323232323242424232a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2324242423252525252525252525252525252523242424232a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2324242423252525252525252525252525252523242424232a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2324242423252525252525252525252525252523242424232a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a23242424232f2525252525252525252525252523242424232a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2324242423232525252323232323232525252323242424232a2a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a232424242424242424242424242424242424242424242423222a2a23000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2324242424242424242424242424242424242424242424232a2a2223000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a2a2324242424242424242424242424242424242424242424232a222223000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a2a22232e24242423242424232424242f2324242423242424242322222223000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232a222223232323232324242423232323232324242423232323232322222223000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2322222222262626262626262626262626262626262626262626262626262623000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2322222222262626262626262626262626262626262626262626262626262623000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2322222222222626262626262626262626262626262626262626262626262623000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2322222222222226262626262626262626262626262626262626262626262623000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2322222222222222262626262626262626262626262626262626262626262623000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232323232323232323232323232323232323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002f4502e4502d4502a450274502545023450224501f4501c4501a450174501545013450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000013650226502265022650206501365016650196501c65014650146501465016650196500f6501d6501e6501e650156501f6501b6501b650196501e650236501a650216501a650136500f6501f6500e650
