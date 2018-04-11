pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
local btns = {
  l = 0,
  r = 1,
  u = 2,
  d = 3,
}
local world={}

local function entity(props)
  local ent   = {}
  local props = props or {}

  ent.pos      = props.pos
  ent.int      = props.int
  ent.sprite   = props.sprite
  ent.controls = props.controls
  ent.cam      = props.cam
  ent.battle   = props.battle

  ent.has = function(key)
    return ent[key] ~= nil
  end

  ent.update = function(w)

    -- control system
    if ent.has('controls') and ent.has('pos') and ent.has('int') then
     ent.controls.update(ent)
    end

    -- physics system
    if ent.has('pos') and ent.has('int') then
     ent.pos.update(ent,w)
    end

  end

  return ent
end

local function camera(props)
  local obj   = {}
  local props = props or {}

  obj.bg = props.bg or 3
  obj.x  = props.x  or 0
  obj.y  = props.y  or 0
  obj.w  = props.w  or 8
  obj.h  = props.h  or 16

  obj.update = function(e,w)
    rectfill(e.cam.x * 8, e.cam.y * 8, e.cam.w * 8, e.cam.h * 8, e.cam.bg)

    local map_x = e.cam.x + (e.cam.w*8)/2 - e.pos.x - 4
    local map_y = e.cam.y + (e.cam.h*8)/2 - e.pos.y - 4

    clip(e.cam.x,e.cam.y,e.cam.w*8,e.cam.h*8)

    map(0,0,map_x,map_y)

    for o in all(w) do
     if o["pos"] and o["sprite"] then
       spr(o.sprite,o.pos.x + map_x,o.pos.y + map_y)
     end
    end

    clip()

    if e.has('battle') then

      for hearts=0,e.battle.lives - 1 do
       spr(3,obj.x+5+(10*(hearts)),(obj.y*8)+(obj.h*8)-10)
      end
     
      local startx = obj.x
      local starty = obj.y + obj.h*8
      rectfill(startx,starty,startx + 1, starty - (obj.h*8 / 100 * e.battle.health),8)

    end

  end

  return obj
end

local function controls(props)
  local obj   = {}
  local props = props or {}

  obj.l = props.l or btns.l
  obj.r = props.r or btns.r
  obj.u = props.u or btns.u
  obj.d = props.d or btns.d
  obj.p = props.p or 0

  obj.update = function(e)
    e.int.l = btn(obj.l, obj.p)
    e.int.r = btn(obj.r, obj.p)
    e.int.u = btn(obj.u, obj.p)
    e.int.d = btn(obj.d, obj.p)
  end

  return obj
end

local function int()
  local obj = {}

  obj.l = false
  obj.r = false
  obj.u = false
  obj.d = false
  obj.s = false

  return obj
end

local function battle(props)
  local obj   = {}
  local props = props or {}

  obj.health    = props.health or 100
  obj.maxhealth = props.maxhealth or 100
  obj.lives     = props.lives or 2

  obj.update = function(e)
  end

  return obj
end

local function weapon(props)
  local obj   = {}
  local props = props or {}

  obj.damage    = props.damage or 25
  obj.rate      = props.rate or 10
  obj.speed     = props.speed or 2

  obj.update = function(e)
  end

  return obj
end

local function pos(props)
  local obj   = {}
  local props = props or {}

  obj.x = props.x or 10
  obj.y = props.y or 10

  obj.update = function(e,w)
    local x_new = obj.x
    local y_new = obj.y

    -- if entity wants to move up
    if (e.int.u) then
      y_new = obj.y - 1
      e.int.u = false
    end

    -- if entity wants to move down
    if (e.int.d) then
      y_new = obj.y + 1
      e.int.d = false
    end

    -- if entity wants to move up
    if (e.int.l) then
      x_new = obj.x - 1
      e.int.l = false
    end

    -- if entity wants to move up
    if (e.int.r) then
      x_new = obj.x + 1
      e.int.r = false
    end

    -- do a hittest here

    -- update position
    obj.x = x_new
    obj.y = y_new
  end

  return obj
end

function _init()
 -- p1 entity
 add(world, entity({
  pos      = pos(),
  int      = int(),
  sprite   = 1,
  controls = controls({ p = 0 }),
  cam      = camera(),
  battle   = battle(),
  weapon   = weapon()
 }))

 -- p2 entity
 add(world, entity({
  pos      = pos({ y = 50 }),
  int      = int(),
  sprite   = 2,
  controls = controls({ p = 1 }),
  cam      = camera({ bg = 4 , x = 64 }),
  battle   = battle(),
  weapon   = weapon()
 }))
end

function _update()
 for e in all(world) do
  e.update(world)
 end
end

function _draw()
 cls()
 rectfill(0,0,127,127,9)
 for e in all(world) do
  if e.has('cam') then
   e.cam.update(e,world)
  end
 end
end
__gfx__
00000000001111000022220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011111100222222008800880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700111111112222222288888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000111111192222222988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000111111192222222908888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700111111112222222200888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011111100222222000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111000022220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7777f77755555555ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6666f76656666665ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6666f76656666665ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffff56666665ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f777777756666665ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f766666656666665ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f766666656666665ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffff55555555ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1111111111111111111112121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101010101112121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101010101112121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101010101112121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111101010101112121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101010101112121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101010101112121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101010101112121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111112121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121212121212121212121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121212121212121212121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121212121212121212121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121212121212121212121212121212121212121212121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
